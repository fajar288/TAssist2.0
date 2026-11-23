<?php

namespace App\Services\Chatbot;

use App\Models\ChatbotPercakapan;
use App\Models\ChatbotPesan;
use App\Models\User;
use App\Services\Chatbot\Drivers\ChatbotDriverInterface;
use App\Services\Chatbot\Drivers\ClaudeHaikuChatbotDriver;
use App\Services\Chatbot\Drivers\FakeChatbotDriver;
use App\Services\Chatbot\Drivers\GeminiChatbotDriver;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpException;

class ChatbotService
{
    protected ChatbotDriverInterface $driver;

    public function __construct(
        protected RetrievalService $retrieval,
        protected RefusalService $refusal,
        protected GuardrailService $guardrails,
        protected StemmerService $stemmer,
        ?ChatbotDriverInterface $driver = null
    ) {
        $this->driver = $driver ?: $this->resolveDriver();
    }

    /**
     * Resolve the active LLM driver.
     */
    protected function resolveDriver(): ChatbotDriverInterface
    {
        $driverName = config('chatbot.driver', env('CHATBOT_DRIVER', 'gemini'));

        return match ($driverName) {
            'gemini' => app(GeminiChatbotDriver::class),
            'claude' => app(ClaudeHaikuChatbotDriver::class),
            'fake' => app(FakeChatbotDriver::class),
            default => app(GeminiChatbotDriver::class),
        };
    }

    /**
     * Set driver explicitly (useful for testing or runtime switching).
     */
    public function setDriver(ChatbotDriverInterface $driver): self
    {
        $this->driver = $driver;
        return $this;
    }

    /**
     * Get the active driver instance.
     */
    public function getDriver(): ChatbotDriverInterface
    {
        return $this->driver;
    }

    /**
     * Check if system-wide daily cost cap has been exceeded (T-35, F-BOT-07).
     * Returns true if exceeded.
     */
    public function isSystemLimitExceeded(): bool
    {
        $limit = (int) config('chatbot.system_daily_limit', 1000);
        $todayCount = ChatbotPesan::query()
            ->whereDate('created_at', Carbon::today())
            ->count();

        return $todayCount >= $limit;
    }

    /**
     * Get or create a conversation for user.
     */
    public function getOrCreateConversation(User $user, ?int $conversationId = null, string $initialPrompt = ''): ChatbotPercakapan
    {
        if ($conversationId) {
            $conversation = ChatbotPercakapan::query()
                ->where('id', $conversationId)
                ->where('user_id', $user->user_id)
                ->firstOrFail();

            return $conversation;
        }

        // Generate a descriptive title from first prompt (max 50 chars)
        $cleanPrompt = trim(preg_replace('/[^\p{L}\p{N}\s]/u', '', $initialPrompt));
        $title = mb_substr($cleanPrompt, 0, 45, 'UTF-8');
        if (mb_strlen($cleanPrompt) > 45) {
            $title .= '...';
        }
        if (empty($title)) {
            $title = 'Percakapan ' . Carbon::now()->format('d M H:i');
        }

        return ChatbotPercakapan::create([
            'user_id' => $user->user_id,
            'judul' => $title,
        ]);
    }

    /**
     * Send a message and generate assistant response.
     *
     * @param User $user
     * @param string $prompt
     * @param int|null $conversationId
     * @return array{percakapan: ChatbotPercakapan, pesan_user: ChatbotPesan, pesan_asisten: ChatbotPesan}
     */
    public function sendMessage(User $user, string $prompt, ?int $conversationId = null): array
    {
        $trimmedPrompt = trim($prompt);
        if (empty($trimmedPrompt)) {
            throw ValidationException::withMessages(['pesan' => 'Pesan tidak boleh kosong.']);
        }

        // 1. T-35: Circuit Breaker / System-Wide Daily Cost Cap check
        if ($this->isSystemLimitExceeded()) {
            throw new HttpException(
                503,
                'Kapasitas layanan chatbot harian telah tercapai. Silakan coba lagi besok.'
            );
        }

        return DB::transaction(function () use ($user, $trimmedPrompt, $conversationId) {
            $conversation = $this->getOrCreateConversation($user, $conversationId, $trimmedPrompt);

            // Save user message
            $userMessage = ChatbotPesan::create([
                'percakapan_id' => $conversation->id,
                'role' => 'user',
                'pesan' => $trimmedPrompt,
                'sumber' => null,
                'is_refused' => false,
                'tokens_used' => 0,
            ]);

            // 2. T-72: Injection check
            if ($this->guardrails->detectInjection($trimmedPrompt)) {
                $refusalText = 'Maaf, sistem mendeteksi instruksi di luar ketentuan. Saya hanya dapat menjawab pertanyaan seputar informasi dan prosedur Tugas Akhir.';
                $assistantMessage = ChatbotPesan::create([
                    'percakapan_id' => $conversation->id,
                    'role' => 'assistant',
                    'pesan' => $refusalText,
                    'sumber' => null,
                    'is_refused' => true,
                    'tokens_used' => 20,
                ]);

                $conversation->touch();

                return [
                    'percakapan' => $conversation,
                    'pesan_user' => $userMessage,
                    'pesan_asisten' => $assistantMessage,
                ];
            }

            // 3. T-32: Refusal check (8 categories in F-BOT-02)
            $refusalResult = $this->refusal->checkRefusal($trimmedPrompt);
            if ($refusalResult['refused']) {
                $assistantMessage = ChatbotPesan::create([
                    'percakapan_id' => $conversation->id,
                    'role' => 'assistant',
                    'pesan' => $refusalResult['response'],
                    'sumber' => null,
                    'is_refused' => true,
                    'tokens_used' => 30,
                ]);

                $conversation->touch();

                return [
                    'percakapan' => $conversation,
                    'pesan_user' => $userMessage,
                    'pesan_asisten' => $assistantMessage,
                ];
            }

            // 4. T-30: Retrieve matching sources
            $sources = $this->retrieval->retrieve($trimmedPrompt, $user);

            // Fetch recent conversation history (last 6 messages)
            $history = ChatbotPesan::query()
                ->where('percakapan_id', $conversation->id)
                ->where('id', '!=', $userMessage->id)
                ->orderBy('created_at', 'desc')
                ->take(6)
                ->get()
                ->reverse()
                ->map(fn($m) => ['role' => $m->role, 'pesan' => $m->pesan])
                ->values()
                ->toArray();

            // 5. T-31: Call LLM Driver
            $llmResponse = $this->driver->generateResponse($trimmedPrompt, $sources, $history, $user);

            // Format citations array for storage and API
            $sourceCitations = array_map(function ($s) {
                return [
                    'judul' => $s['judul'],
                    'tipe' => $s['tipe'] ?? 'panduan',
                    'label' => $s['label'] ?? '',
                ];
            }, $sources);

            // Save assistant message
            $assistantMessage = ChatbotPesan::create([
                'percakapan_id' => $conversation->id,
                'role' => 'assistant',
                'pesan' => $llmResponse['text'],
                'sumber' => !empty($sourceCitations) ? $sourceCitations : null,
                'is_refused' => false,
                'tokens_used' => $llmResponse['tokens_used'] ?? 0,
            ]);

            $conversation->touch();

            return [
                'percakapan' => $conversation,
                'pesan_user' => $userMessage,
                'pesan_asisten' => $assistantMessage,
            ];
        });
    }
}
