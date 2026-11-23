<?php

namespace App\Services\Chatbot\Drivers;

use App\Models\User;

interface ChatbotDriverInterface
{
    /**
     * Generate a response based on user prompt, retrieved sources, and conversation history.
     *
     * @param string $prompt
     * @param array $sources
     * @param array $conversationHistory
     * @param User|null $user
     * @return array{text: string, tokens_used: int, model: string}
     */
    public function generateResponse(string $prompt, array $sources = [], array $conversationHistory = [], ?User $user = null): array;
}
