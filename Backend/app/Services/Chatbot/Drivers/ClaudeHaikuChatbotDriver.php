<?php

namespace App\Services\Chatbot\Drivers;

use App\Models\User;
use App\Services\Chatbot\GuardrailService;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class ClaudeHaikuChatbotDriver implements ChatbotDriverInterface
{
    public function __construct(
        protected GuardrailService $guardrails,
        protected ?string $apiKey = null,
        protected string $model = 'claude-3-5-haiku-20241022'
    ) {
        $this->apiKey = $this->apiKey ?: config('services.anthropic.api_key', env('ANTHROPIC_API_KEY'));
    }

    public function generateResponse(string $prompt, array $sources = [], array $conversationHistory = [], ?User $user = null): array
    {
        if (empty($this->apiKey)) {
            $fake = new FakeChatbotDriver($this->guardrails);
            return $fake->generateResponse($prompt, $sources, $conversationHistory, $user);
        }

        // Build context
        $contextText = '';
        if (!empty($sources)) {
            $contextText = "SUMBER INFORMASI TERSEDIA:\n";
            foreach ($sources as $idx => $s) {
                $contextText .= "[Sumber: {$s['label']}]\n{$s['konten']}\n\n";
            }
        }

        $redactedPrompt = $this->guardrails->redactSensitiveData($prompt);

        $messages = [];
        foreach ($conversationHistory as $msg) {
            $messages[] = [
                'role' => ($msg['role'] ?? 'user') === 'user' ? 'user' : 'assistant',
                'content' => $msg['pesan'] ?? '',
            ];
        }

        $messages[] = [
            'role' => 'user',
            'content' => "KONTEKS:\n{$contextText}\n\nPERTANYAAN:\n{$redactedPrompt}",
        ];

        try {
            $response = Http::withHeaders([
                'x-api-key' => $this->apiKey,
                'anthropic-version' => '2023-06-01',
                'content-type' => 'application/json',
            ])->timeout(20)->post('https://api.anthropic.com/v1/messages', [
                'model' => $this->model,
                'max_tokens' => 1024,
                'system' => $this->guardrails->getSystemPrompt(),
                'messages' => $messages,
            ]);

            if ($response->successful()) {
                $data = $response->json();
                $text = $data['content'][0]['text'] ?? '';
                $tokens = ($data['usage']['input_tokens'] ?? 0) + ($data['usage']['output_tokens'] ?? 0);

                return [
                    'text' => trim($text),
                    'tokens_used' => $tokens,
                    'model' => $this->model,
                ];
            }
        } catch (\Throwable $e) {
            Log::error('Claude API call failed: ' . $e->getMessage());
        }

        $fake = new FakeChatbotDriver($this->guardrails);
        return $fake->generateResponse($prompt, $sources, $conversationHistory, $user);
    }
}
