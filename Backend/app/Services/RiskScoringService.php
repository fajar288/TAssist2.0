<?php

namespace App\Services;

use App\Models\AnotasiDokumen;
use App\Models\Bimbingan;
use App\Models\ChecklistProgress;
use App\Models\DokumenTA;
use App\Models\JadwalBimbingan;
use App\Models\ProgresTA;
use App\Models\RisikoKonfigurasi;
use App\Models\RisikoSnapshot;
use App\Models\VersiDokumen;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

class RiskScoringService
{
    /**
     * Calculate and return risk assessment for a specific supervision.
     *
     * @param Bimbingan $bimbingan
     * @param Carbon|null $date
     * @return array{skor: int, level: string, sinyal: array<int, array{nama: string, nilai: mixed, bobot: float, kontribusi: float, deskripsi: string}>}
     */
    public function calculateForBimbingan(Bimbingan $bimbingan, ?Carbon $date = null): array
    {
        $date = $date ? $date->copy()->startOfDay() : now()->startOfDay();

        // 1. Identify if TA period is missing. If missing, exclude 'waktu_terpakai_periode'
        $excluded = [];
        if (! $bimbingan->hasPeriode()) {
            $excluded[] = 'waktu_terpakai_periode';
        }

        // 2. Load active scoring signals with renormalized weights (T-21)
        $configuredSignals = RisikoKonfigurasi::getActiveWithRenormalizedWeights($excluded);

        $signalBreakdowns = [];
        $totalWeightedScore = 0.0;

        foreach ($configuredSignals as $config) {
            $name = $config->nama_sinyal;
            $weight = $config->bobot_ternormalisasi;
            $thresholds = $config->ambang_batas ?? [];

            $result = match ($name) {
                'hari_sejak_bimbingan_terakhir' => $this->evalHariBimbinganTerakhir($bimbingan, $date, $thresholds),
                'hari_sejak_versi_terakhir'     => $this->evalHariVersiTerakhir($bimbingan, $date, $thresholds),
                'anotasi_terbuka_lama'          => $this->evalAnotasiTerbukaLama($bimbingan, $date, $thresholds),
                'checklist_terlambat'           => $this->evalChecklistTerlambat($bimbingan, $date, $thresholds),
                'progres_stagnan'               => $this->evalProgresStagnan($bimbingan, $date, $thresholds),
                'waktu_terpakai_periode'        => $this->evalWaktuTerpakaiPeriode($bimbingan, $date, $thresholds),
                default                         => ['sub_score' => 0, 'nilai' => 0, 'deskripsi' => 'Sinyal tidak dikenal'],
            };

            $subScore = $result['sub_score'];
            $kontribusi = round($subScore * $weight, 1);
            $totalWeightedScore += ($subScore * $weight);

            $signalBreakdowns[] = [
                'nama'       => $name,
                'nilai'      => $result['nilai'],
                'bobot'      => round($weight, 4),
                'kontribusi' => $kontribusi,
                'deskripsi'  => $result['deskripsi'],
            ];
        }

        $finalScore = (int) min(100, max(0, round($totalWeightedScore)));

        $level = match (true) {
            $finalScore >= 70 => 'berisiko',
            $finalScore >= 40 => 'perlu_perhatian',
            default           => 'aman',
        };

        return [
            'skor'   => $finalScore,
            'level'  => $level,
            'sinyal' => $signalBreakdowns,
        ];
    }

    /**
     * Run calculation for all active supervisions and persist snapshots (T-22, F-ANL-02).
     *
     * @param Carbon|null $date
     * @return Collection<int, RisikoSnapshot>
     */
    public function calculateAllActive(?Carbon $date = null): Collection
    {
        $date = $date ? $date->copy()->startOfDay() : now()->startOfDay();

        $activeSupervisions = Bimbingan::where('status_bimbingan', 'aktif')->get();
        $createdSnapshots = collect();

        foreach ($activeSupervisions as $bimbingan) {
            $calculation = $this->calculateForBimbingan($bimbingan, $date);

            $snapshot = RisikoSnapshot::create([
                'bimbingan_id'   => $bimbingan->bimbingan_id,
                'skor'           => $calculation['skor'],
                'level'          => $calculation['level'],
                'sinyal'         => $calculation['sinyal'],
                'tanggal_hitung' => $date->toDateString(),
            ]);

            $createdSnapshots->push($snapshot);
        }

        return $createdSnapshots;
    }

    // ==================== SIGNAL EVALUATORS ====================

    /**
     * 1. Hari sejak sesi bimbingan terakhir dikonfirmasi.
     */
    private function evalHariBimbinganTerakhir(Bimbingan $bimbingan, Carbon $date, array $thresholds): array
    {
        $p1 = $thresholds['perlu_perhatian'] ?? 14;
        $p2 = $thresholds['berisiko'] ?? 30;

        $lastMeeting = JadwalBimbingan::where('bimbingan_id', $bimbingan->bimbingan_id)
            ->where('status_konfirmasi', 'dikonfirmasi')
            ->where('tanggal', '<=', $date->toDateString())
            ->orderBy('tanggal', 'desc')
            ->first();

        $baseDate = $lastMeeting ? Carbon::parse($lastMeeting->tanggal) : ($bimbingan->tanggal_mulai ? Carbon::parse($bimbingan->tanggal_mulai) : $bimbingan->created_at);
        $days = (int) max(0, $baseDate->diffInDays($date));

        $subScore = $this->scaleLinearThreeTier($days, $p1, $p2);
        $deskripsi = "{$days} hari sejak pertemuan bimbingan terakhir (ambang: {$p1}/{$p2} hari)";

        return ['sub_score' => $subScore, 'nilai' => $days, 'deskripsi' => $deskripsi];
    }

    /**
     * 2. Hari sejak versi dokumen TA terakhir diunggah.
     */
    private function evalHariVersiTerakhir(Bimbingan $bimbingan, Carbon $date, array $thresholds): array
    {
        $p1 = $thresholds['perlu_perhatian'] ?? 21;
        $p2 = $thresholds['berisiko'] ?? 45;

        $dokumenIds = DokumenTA::where('bimbingan_id', $bimbingan->bimbingan_id)->pluck('dokumen_id');

        $lastVersion = VersiDokumen::whereIn('dokumen_id', $dokumenIds)
            ->where('created_at', '<=', $date->endOfDay())
            ->orderBy('created_at', 'desc')
            ->first();

        $baseDate = $lastVersion ? $lastVersion->created_at : ($bimbingan->tanggal_mulai ? Carbon::parse($bimbingan->tanggal_mulai) : $bimbingan->created_at);
        $days = (int) max(0, $baseDate->diffInDays($date));

        $subScore = $this->scaleLinearThreeTier($days, $p1, $p2);
        $deskripsi = "{$days} hari sejak unggahan versi dokumen terakhir (ambang: {$p1}/{$p2} hari)";

        return ['sub_score' => $subScore, 'nilai' => $days, 'deskripsi' => $deskripsi];
    }

    /**
     * 3. Jumlah anotasi terbuka yang lebih tua dari batas usia (ambang_hari).
     */
    private function evalAnotasiTerbukaLama(Bimbingan $bimbingan, Carbon $date, array $thresholds): array
    {
        $ageDays = $thresholds['ambang_hari'] ?? 14;
        $cutoff = $date->copy()->subDays($ageDays)->endOfDay();

        $dokumenIds = DokumenTA::where('bimbingan_id', $bimbingan->bimbingan_id)->pluck('dokumen_id');
        $versiIds = VersiDokumen::whereIn('dokumen_id', $dokumenIds)->pluck('versi_id');

        $count = AnotasiDokumen::whereIn('versi_id', $versiIds)
            ->where('status', 'open')
            ->whereNull('parent_id') // only parent annotations
            ->where('created_at', '<=', $cutoff)
            ->count();

        $subScore = match (true) {
            $count === 0 => 0,
            $count === 1 => 45,
            $count === 2 => 65,
            default      => min(100, 70 + ($count - 2) * 15),
        };

        $deskripsi = "{$count} anotasi terbuka melebihi {$ageDays} hari";

        return ['sub_score' => $subScore, 'nilai' => $count, 'deskripsi' => $deskripsi];
    }

    /**
     * 4. Jumlah item checklist progress yang belum selesai (terlambat/pending).
     */
    private function evalChecklistTerlambat(Bimbingan $bimbingan, Carbon $date, array $thresholds): array
    {
        $progressIds = ProgresTA::where('bimbingan_id', $bimbingan->bimbingan_id)->pluck('progress_id');

        $count = ChecklistProgress::whereIn('progress_id', $progressIds)
            ->where(function ($q) {
                $q->where('tgl_selesai', false)->orWhereNull('tgl_selesai');
            })
            ->count();

        $subScore = match (true) {
            $count === 0 => 0,
            $count === 1 => 50,
            default      => min(100, 70 + ($count - 2) * 20),
        };

        $deskripsi = "{$count} item checklist belum selesai";

        return ['sub_score' => $subScore, 'nilai' => $count, 'deskripsi' => $deskripsi];
    }

    /**
     * 5. Hari tanpa perubahan persentase progres TA (stagnan).
     */
    private function evalProgresStagnan(Bimbingan $bimbingan, Carbon $date, array $thresholds): array
    {
        $p1 = $thresholds['perlu_perhatian'] ?? 21;
        $p2 = $thresholds['berisiko'] ?? 45;

        $latestProgres = ProgresTA::where('bimbingan_id', $bimbingan->bimbingan_id)
            ->where('updated_at', '<=', $date->endOfDay())
            ->orderBy('updated_at', 'desc')
            ->first();

        $baseDate = $latestProgres ? $latestProgres->updated_at : ($bimbingan->tanggal_mulai ? Carbon::parse($bimbingan->tanggal_mulai) : $bimbingan->created_at);
        $days = (int) max(0, $baseDate->diffInDays($date));

        $subScore = $this->scaleLinearThreeTier($days, $p1, $p2);
        $deskripsi = "{$days} hari tanpa pembaruan progres TA (ambang: {$p1}/{$p2} hari)";

        return ['sub_score' => $subScore, 'nilai' => $days, 'deskripsi' => $deskripsi];
    }

    /**
     * 6. Waktu terpakai sebagai persentase dari periode TA.
     */
    private function evalWaktuTerpakaiPeriode(Bimbingan $bimbingan, Carbon $date, array $thresholds): array
    {
        $p1 = $thresholds['perlu_perhatian'] ?? 0.60;
        $p2 = $thresholds['berisiko'] ?? 0.80;

        $start = Carbon::parse($bimbingan->periode_mulai);
        $end = Carbon::parse($bimbingan->periode_selesai);

        $totalDays = max(1, $start->diffInDays($end));
        $elapsedDays = max(0, min($totalDays, $start->diffInDays($date)));
        $ratio = round($elapsedDays / $totalDays, 4);
        $percent = round($ratio * 100, 1);

        $subScore = match (true) {
            $ratio < $p1  => (int) round(($ratio / $p1) * 39),
            $ratio < $p2  => (int) round(40 + (($ratio - $p1) / ($p2 - $p1)) * 29),
            default       => (int) min(100, round(70 + (($ratio - $p2) / max(0.01, 1.0 - $p2)) * 30)),
        };

        $deskripsi = "{$percent}% durasi periode TA telah berlalu ({$elapsedDays}/{$totalDays} hari)";

        return ['sub_score' => $subScore, 'nilai' => $percent, 'deskripsi' => $deskripsi];
    }

    /**
     * Linear scaling across 3 tiers (0-39, 40-69, 70-100).
     */
    private function scaleLinearThreeTier(float|int $value, float|int $t1, float|int $t2): int
    {
        if ($value <= 0) {
            return 0;
        }

        if ($value < $t1) {
            return (int) round(($value / $t1) * 39);
        }

        if ($value < $t2) {
            return (int) round(40 + (($value - $t1) / ($t2 - $t1)) * 29);
        }

        $extra = $value - $t2;
        $headroom = max(1, $t2 * 0.5);

        return (int) min(100, round(70 + ($extra / $headroom) * 30));
    }
}
