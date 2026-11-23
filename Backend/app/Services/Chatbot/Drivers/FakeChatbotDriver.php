<?php

namespace App\Services\Chatbot\Drivers;

use App\Models\User;
use App\Services\Chatbot\GuardrailService;

class FakeChatbotDriver implements ChatbotDriverInterface
{
    public function __construct(
        protected ?GuardrailService $guardrails = null
    ) {}

    public function generateResponse(string $prompt, array $sources = [], array $conversationHistory = [], ?User $user = null): array
    {
        $dosenName = 'dosen pembimbing Anda';
        if ($user && $user->isMahasiswa()) {
            $bimbingan = $user->mahasiswa?->bimbinganAktif;
            if ($bimbingan && $bimbingan->dosen) {
                $dosenName = $bimbingan->dosen->user?->nama ?? $bimbingan->dosen->nama ?? $dosenName;
            }
        }

        // 1. If no sources found -> PRD standard refusal
        if (empty($sources)) {
            $text = "Maaf, saya tidak memiliki informasi tentang pertanyaan tersebut. Silakan hubungi dosen pembimbing Anda ({$dosenName}) atau admin TA untuk bantuan lebih lanjut.";
            return [
                'text' => $text,
                'tokens_used' => 35,
                'model' => 'fake-driver',
            ];
        }

        // 2. Synthesize grounded response using highest-ranked source
        $primary = $sources[0];
        $label = $primary['label'] ?? '';

        if (($primary['tipe'] ?? '') === 'data_pribadi') {
            $text = "Berdasarkan data akademik Anda saat ini:\n\n" . $primary['konten'] . "\n\n" . $label;
        } else {
            $text = "Berdasarkan informasi resmi TA:\n\n" . $primary['konten'] . "\n\n" . $label;
        }

        return [
            'text' => $text,
            'tokens_used' => 60,
            'model' => 'fake-driver',
        ];
    }
}
