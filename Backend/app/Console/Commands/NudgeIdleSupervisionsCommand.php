<?php

namespace App\Console\Commands;

use App\Models\Bimbingan;
use App\Models\JadwalBimbingan;
use App\Models\PeriodeLibur;
use App\Models\RisikoKonfigurasi;
use App\Services\NotifikasiService;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;

class NudgeIdleSupervisionsCommand extends Command
{
    protected $signature = 'nudge:idle-supervisions {--date= : Evaluation date (YYYY-MM-DD)}';
    protected $description = 'Dispatches idle supervision nudges to students and supervisors, suppressed during academic breaks (T-27, F-ANL-05)';

    public function handle(): int
    {
        $dateParam = $this->option('date');
        $date = $dateParam ? Carbon::parse($dateParam)->startOfDay() : now()->startOfDay();

        // 1. Check academic break windows (C2, F-ANL-05)
        if (PeriodeLibur::aktif($date)->exists()) {
            $this->info("Nudges suppressed: date {$date->toDateString()} is within an official academic break (periode_libur).");
            return Command::SUCCESS;
        }

        // 2. Fetch configurable idle threshold (default: 21 days)
        $idleConfig = RisikoKonfigurasi::where('nama_sinyal', 'ambang_hari_idle_nudge')->first();
        $thresholdDays = (int) ($idleConfig->ambang_batas['hari'] ?? 21);

        $activeSupervisions = Bimbingan::with(['mahasiswa.user', 'dosen.user'])
            ->where('status_bimbingan', 'aktif')
            ->get();

        $nudgesSent = 0;

        foreach ($activeSupervisions as $bimbingan) {
            $mahasiswaUser = $bimbingan->mahasiswa?->user;
            $dosenUser = $bimbingan->dosen?->user;

            if (! $mahasiswaUser || ! $dosenUser) {
                continue;
            }

            // Find last confirmed meeting
            $lastMeeting = JadwalBimbingan::where('bimbingan_id', $bimbingan->bimbingan_id)
                ->where('status_konfirmasi', 'dikonfirmasi')
                ->where('tanggal', '<=', $date->toDateString())
                ->orderBy('tanggal', 'desc')
                ->first();

            $baseDate = $lastMeeting ? Carbon::parse($lastMeeting->tanggal)->startOfDay() : ($bimbingan->tanggal_mulai ? Carbon::parse($bimbingan->tanggal_mulai)->startOfDay() : $bimbingan->created_at->copy()->startOfDay());
            $idleDays = (int) max(0, $baseDate->diffInDays($date));

            // Check if threshold is crossed
            if ($idleDays >= $thresholdDays) {
                // Verify one nudge per threshold crossing:
                // If a nudge was already sent AFTER the last meeting (or start date), don't send again.
                $alreadyNudgedForThisCycle = $bimbingan->last_nudge_at && Carbon::parse($bimbingan->last_nudge_at)->gte($baseDate->copy()->addDays($thresholdDays));

                if (! $alreadyNudgedForThisCycle) {
                    $studentName = $mahasiswaUser->nama;
                    $judul = 'Pengingat Bimbingan Tugas Akhir';
                    $pesan = "Bimbingan {$studentName} belum ada pertemuan dalam {$idleDays} hari terakhir.";

                    // Send to student
                    NotifikasiService::kirim(
                        $mahasiswaUser->user_id,
                        'peringatan_bimbingan',
                        $judul,
                        $pesan,
                        'bimbingan',
                        $bimbingan->bimbingan_id
                    );

                    // Send to supervisor
                    NotifikasiService::kirim(
                        $dosenUser->user_id,
                        'peringatan_bimbingan',
                        $judul,
                        $pesan,
                        'bimbingan',
                        $bimbingan->bimbingan_id
                    );

                    $bimbingan->update(['last_nudge_at' => $date]);
                    $nudgesSent++;
                }
            }
        }

        $this->info("Completed idle supervision check. Sent {$nudgesSent} nudges.");

        return Command::SUCCESS;
    }
}
