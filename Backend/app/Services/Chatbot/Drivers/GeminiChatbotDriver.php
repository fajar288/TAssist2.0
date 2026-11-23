<?php

namespace App\Services\Chatbot\Drivers;

use App\Models\User;
use App\Services\Chatbot\GuardrailService;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GeminiChatbotDriver implements ChatbotDriverInterface
{
    public function __construct(
        protected GuardrailService $guardrails,
        protected ?string $apiKey = null,
        protected ?string $model = null
    ) {
        $this->apiKey = $this->apiKey ?: config('services.gemini.api_key', env('GEMINI_API_KEY'));
        $this->model = $this->model ?: config('services.gemini.model', env('GEMINI_MODEL', 'gemini-2.0-flash'));
    }

    public function generateResponse(string $prompt, array $sources = [], array $conversationHistory = [], ?User $user = null): array
    {
        if (empty($this->apiKey)) {
            // Fallback to Fake driver if API key is not configured in environment
            $fakeDriver = new FakeChatbotDriver($this->guardrails);
            return $fakeDriver->generateResponse($prompt, $sources, $conversationHistory, $user);
        }

        // Build context from sources
        $contextText = '';
        if (!empty($sources)) {
            $contextText = "SUMBER INFORMASI YANG TERSEDIA:\n";
            foreach ($sources as $idx => $s) {
                $num = $idx + 1;
                $contextText .= "[{$num}] {$s['label']}\n{$s['konten']}\n\n";
            }
        } else {
            $contextText = "TIDAK ADA SUMBER INFORMASI YANG COCOK DITEMUKAN DALAM BASIS PENGETAHUAN.\n";
        }

        // Redact any sensitive personal information before external transmission
        $redactedPrompt = $this->guardrails->redactSensitiveData($prompt);

        $contents = [];
        // Add conversation history
        foreach ($conversationHistory as $msg) {
            $role = ($msg['role'] ?? 'user') === 'user' ? 'user' : 'model';
            $contents[] = [
                'role' => $role,
                'parts' => [['text' => $msg['pesan'] ?? '']],
            ];
        }

        // Add current user prompt with context
        $userMessage = "KONTEKS:\n{$contextText}\n\nPERTANYAAN PENGGUNA:\n{$redactedPrompt}";
        $contents[] = [
            'role' => 'user',
            'parts' => [['text' => $userMessage]],
        ];

        try {
            $url = "https://generativelanguage.googleapis.com/v1beta/models/{$this->model}:generateContent?key={$this->apiKey}";

            $response = Http::timeout(25)->post($url, [
                'system_instruction' => [
                    'parts' => [['text' => $this->guardrails->getSystemPrompt()]]
                ],
                'contents' => $contents,
                'generationConfig' => [
                    'temperature' => 0.2,
                    'maxOutputTokens' => 1024,
                ],
            ]);

            if ($response->successful()) {
                $data = $response->json();
                $text = $data['candidates'][0]['content']['parts'][0]['text'] ?? '';
                $tokensUsed = $data['usageMetadata']['totalTokenCount'] ?? 150;

                return [
                    'text' => trim($text),
                    'tokens_used' => (int) $tokensUsed,
                    'model' => $this->model,
                ];
            }

            Log::warning('Gemini API call returned non-200: ' . $response->status() . ' - ' . $response->body());
        } catch (\Throwable $e) {
            Log::error('Gemini API exception: ' . $e->getMessage());
        }

        // Graceful fallback to Fake driver if live API call failed
        $fake = new FakeChatbotDriver($this->guardrails);
        return $fake->generateResponse($prompt, $sources, $conversationHistory, $user);
    }
}
