<?php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\ChatbotPercakapan;
use App\Models\ChatbotPesan;
use App\Services\Chatbot\StemmerService;
use Carbon\Carbon;
use Illuminate\Http\Request;

class ChatbotAnalyticsWebController extends Controller
{
    public function __construct(
        protected StemmerService $stemmer
    ) {}

    public function index(Request $request)
    {
        $today = Carbon::today();
        $totalPesanHariIni = ChatbotPesan::whereDate('created_at', $today)->count();
        $systemLimit = (int) config('chatbot.system_daily_limit', 1000);
        $sisaLimit = max(0, $systemLimit - $totalPesanHariIni);
        $totalPercakapan = ChatbotPercakapan::count();
        $totalPesan = ChatbotPesan::count();
        $totalRefused = ChatbotPesan::where('is_refused', true)->count();

        // 1. Top Question Topics (via Stemmer)
        $messages = ChatbotPesan::where('role', 'user')
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
        $topTopics = array_slice($topicCounts, 0, 15, true);

        // 2. Unanswered Questions Log
        $unansweredAssistant = ChatbotPesan::query()
            ->where('role', 'assistant')
            ->where('is_refused', false)
            ->where(function ($q) {
                $q->whereNull('sumber')
                  ->orWhere('sumber', '[]')
                  ->orWhere('pesan', 'like', '%tidak memiliki informasi%');
            })
            ->latest('created_at')
            ->take(50)
            ->get();

        $unansweredList = [];
        foreach ($unansweredAssistant as $asst) {
            $userMsg = ChatbotPesan::query()
                ->where('percakapan_id', $asst->percakapan_id)
                ->where('role', 'user')
                ->where('id', '<', $asst->id)
                ->orderBy('id', 'desc')
                ->first();

            if ($userMsg) {
                $unansweredList[] = [
                    'pertanyaan' => $userMsg->pesan,
                    'waktu' => $asst->created_at,
                    'percakapan_id' => $asst->percakapan_id,
                ];
            }
        }

        return view('admin.chatbot.analytics', compact(
            'totalPesanHariIni',
            'systemLimit',
            'sisaLimit',
            'totalPercakapan',
            'totalPesan',
            'totalRefused',
            'topTopics',
            'unansweredList'
        ));
    }
}
