<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\ChatbotPesan;
use App\Services\Chatbot\StemmerService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChatbotAnalyticsController extends Controller
{
    use ApiResponse;

    public function __construct(
        protected StemmerService $stemmer
    ) {}

    /**
     * Get most frequently asked question topics (T-36, F-BOT-05).
     * GET /api/v1/admin/chatbot/analytics/top-questions
     */
    public function topQuestions(Request $request): JsonResponse
    {
        // Fetch user messages from last 60 days
        $messages = ChatbotPesan::query()
            ->where('role', 'user')
            ->where('created_at', '>=', now()->subDays(60))
            ->pluck('pesan');

        $topicCounts = [];

        foreach ($messages as $msg) {
            $tokens = $this->stemmer->tokenizeAndStem($msg);
            foreach ($tokens as $token) {
                if (mb_strlen($token) < 3) {
                    continue;
                }
                $topicCounts[$token] = ($topicCounts[$token] ?? 0) + 1;
            }
        }

        arsort($topicCounts);

        $ranked = [];
        $rank = 1;
        foreach (array_slice($topicCounts, 0, 20, true) as $topic => $count) {
            $ranked[] = [
                'rank' => $rank++,
                'topik' => $topic,
                'frekuensi' => $count,
            ];
        }

        return $this->successResponse('Top pertanyaan chatbot berhasil diambil.', [
            'total_pertanyaan' => $messages->count(),
            'top_topik' => $ranked,
        ]);
    }

    /**
     * Get questions the chatbot could not answer (T-36, F-BOT-05).
     * GET /api/v1/admin/chatbot/analytics/unanswered
     */
    public function unanswered(Request $request): JsonResponse
    {
        // Unanswered: assistant messages that were NOT refused, but had no sources
        // or had the standard unknown response text
        $unansweredAssistantIds = ChatbotPesan::query()
            ->where('role', 'assistant')
            ->where('is_refused', false)
            ->where(function ($q) {
                $q->whereNull('sumber')
                  ->orWhere('sumber', '[]')
                  ->orWhere('pesan', 'like', '%tidak memiliki informasi%');
            })
            ->pluck('id');

        // Pair with the preceding user message in the same conversation
        $unansweredLogs = [];

        foreach ($unansweredAssistantIds as $asstId) {
            $assistant = ChatbotPesan::find($asstId);
            if (!$assistant) {
                continue;
            }

            $userMsg = ChatbotPesan::query()
                ->where('percakapan_id', $assistant->percakapan_id)
                ->where('role', 'user')
                ->where('id', '<', $assistant->id)
                ->orderBy('id', 'desc')
                ->first();

            if ($userMsg) {
                $unansweredLogs[] = [
                    'percakapan_id' => $assistant->percakapan_id,
                    'pertanyaan' => $userMsg->pesan,
                    'waktu' => $assistant->created_at->toIso8601String(),
                ];
            }
        }

        // Group identical or very similar questions
        $grouped = [];
        foreach ($unansweredLogs as $log) {
            $key = mb_strtolower(trim($log['pertanyaan']), 'UTF-8');
            if (!isset($grouped[$key])) {
                $grouped[$key] = [
                    'pertanyaan' => $log['pertanyaan'],
                    'jumlah' => 0,
                    'terakhir_ditanyakan' => $log['waktu'],
                ];
            }
            $grouped[$key]['jumlah']++;
            if ($log['waktu'] > $grouped[$key]['terakhir_ditanyakan']) {
                $grouped[$key]['terakhir_ditanyakan'] = $log['waktu'];
            }
        }

        usort($grouped, fn($a, $b) => $b['jumlah'] <=> $a['jumlah']);

        return $this->successResponse('Log pertanyaan belum terjawab berhasil diambil.', array_values($grouped));
    }
}
