<?php

namespace App\Console\Commands;

use App\Models\Bimbingan;
use App\Models\ChatbotPercakapan;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

class PurgeExpiredChatbotConversations extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'chatbot:purge-retention';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Purge chatbot conversations 6 months after supervision completes (F-BOT-03)';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $retentionMonths = (int) config('chatbot.retention_months_after_completion', 6);
        $cutoffDate = Carbon::now()->subMonths($retentionMonths);

        $this->info("Scanning for completed supervisions ended on or before {$cutoffDate->toDateString()}...");

        // Find all completed supervisions where tanggal_selesai <= cutoff
        $completedSupervisions = Bimbingan::query()
            ->where('status_bimbingan', 'selesai')
            ->whereNotNull('tanggal_selesai')
            ->where('tanggal_selesai', '<=', $cutoffDate)
            ->with('mahasiswa')
            ->get();

        $purgedCount = 0;

        foreach ($completedSupervisions as $bimbingan) {
            $userId = $bimbingan->mahasiswa?->user_id;
            if (!$userId) {
                continue;
            }

            // Check if the student has any other active or non-expired supervision
            $hasOtherActiveSupervision = Bimbingan::query()
                ->where('mahasiswa_id', $bimbingan->mahasiswa_id)
                ->where(function ($q) use ($cutoffDate) {
                    $q->where('status_bimbingan', '!=', 'selesai')
                      ->orWhereNull('tanggal_selesai')
                      ->orWhere('tanggal_selesai', '>', $cutoffDate);
                })
                ->exists();

            if (!$hasOtherActiveSupervision) {
                $deleted = ChatbotPercakapan::where('user_id', $userId)->delete();
                $purgedCount += $deleted;
            }
        }

        $this->info("Purged {$purgedCount} conversation(s) past the 6-month post-completion retention window.");
        Log::info("Chatbot retention purge completed: {$purgedCount} conversations deleted.");

        return Command::SUCCESS;
    }
}
