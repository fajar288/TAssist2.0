<?php

namespace App\Console\Commands;

use App\Models\JadwalBimbingan;
use App\Services\NotifikasiService;
use Carbon\Carbon;
use Illuminate\Console\Command;

/**
 * T-43 (F-SCH-05): Send 24-hour and 1-hour reminders for confirmed guidance meetings.
 *
 * Uses atomic conditional updates on `reminder_24h_sent_at` / `reminder_1h_sent_at`
 * so a late or overlapping run never double-sends reminders.
 */
class SendMeetingRemindersCommand extends Command
{
    protected $signature = 'reminders:meetings';

    protected $description = 'Send 24h and 1h reminders for confirmed guidance meetings';

    public function handle(): int
    {
        $now = now();
        $fromDate = $now->copy()->subDay()->toDateString();
        $toDate = $now->copy()->addDays(2)->toDateString();

        $meetings = JadwalBimbingan::with(['bimbingan.mahasiswa.user', 'bimbingan.dosen.user'])
            ->where('status_konfirmasi', 'dikonfirmasi')
            ->whereBetween('tanggal', [$fromDate, $toDate])
            ->get();

        $sent24h = 0;
        $sent1h = 0;

        foreach ($meetings as $jadwal) {
            if (! $jadwal->bimbingan) {
                continue;
            }

            $timePart = substr((string) $jadwal->waktu_mulai, 0, 5);
            $meetingStart = Carbon::parse($jadwal->tanggal->format('Y-m-d') . ' ' . $timePart);
            $minutesUntil = $now->diffInMinutes($meetingStart, false);

            if ($minutesUntil <= 0) {
                continue;
            }

            $recipients = array_values(array_filter([
                $jadwal->bimbingan->mahasiswa?->user_id,
                $jadwal->bimbingan->dosen?->user_id,
            ]));

            if (empty($recipients)) {
                continue;
            }

            // 24-hour window: 22h to 24h15m before start (absorbs minor cron jitter without
            // sending a "tomorrow" reminder for a meeting confirmed just 2 hours ahead).
            if ($jadwal->reminder_24h_sent_at === null && $minutesUntil >= (22 * 60) && $minutesUntil <= (24 * 60 + 15)) {
                $claimed = JadwalBimbingan::where('jadwal_id', $jadwal->jadwal_id)
                    ->whereNull('reminder_24h_sent_at')
                    ->update(['reminder_24h_sent_at' => $now]);

                if ($claimed > 0) {
                    NotifikasiService::kirimKeBanyak(
                        userIds  : $recipients,
                        tipe     : 'pengingat_jadwal',
                        judul    : 'Pengingat Bimbingan Besok',
                        pesan    : "Reminder: Bimbingan besok pukul {$timePart} ({$jadwal->mode}).",
                        refTabel : 'jadwal_bimbingan',
                        refId    : $jadwal->jadwal_id
                    );
                    $sent24h++;
                }
            }

            // 1-hour window: up to 1h15m before start.
            if ($jadwal->reminder_1h_sent_at === null && $minutesUntil <= (60 + 15)) {
                $claimed = JadwalBimbingan::where('jadwal_id', $jadwal->jadwal_id)
                    ->whereNull('reminder_1h_sent_at')
                    ->update(['reminder_1h_sent_at' => $now]);

                if ($claimed > 0) {
                    NotifikasiService::kirimKeBanyak(
                        userIds  : $recipients,
                        tipe     : 'pengingat_jadwal',
                        judul    : 'Pengingat Bimbingan 1 Jam Lagi',
                        pesan    : "Reminder: Bimbingan 1 jam lagi pukul {$timePart} ({$jadwal->mode}).",
                        refTabel : 'jadwal_bimbingan',
                        refId    : $jadwal->jadwal_id
                    );
                    $sent1h++;
                }
            }
        }

        $this->info("Meeting reminders sent: {$sent24h} (24h), {$sent1h} (1h).");

        return self::SUCCESS;
    }
}
