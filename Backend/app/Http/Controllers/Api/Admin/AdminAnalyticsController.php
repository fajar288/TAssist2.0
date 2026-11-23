<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AnotasiDokumen;
use App\Models\Bimbingan;
use App\Models\Dosen;
use App\Models\Mahasiswa;
use App\Models\PermohonanBimbingan;
use App\Models\RisikoSnapshot;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class AdminAnalyticsController extends Controller
{
    use ApiResponse;

    /**
     * Risk level distribution per study program (prodi) (T-25, F-ANL-03).
     * GET /api/v1/admin/analytics/risk-distribution
     */
    public function riskDistribution(): JsonResponse
    {
        // Get all prodi
        $prodis = Mahasiswa::select('prodi')
            ->whereNotNull('prodi')
            ->distinct()
            ->pluck('prodi');

        // Fetch latest snapshot for each active supervision
        $latestSnapshots = $this->getLatestSnapshotsQuery()->get();

        $distribution = [];

        foreach ($prodis as $prodi) {
            $distribution[$prodi] = [
                'prodi'           => $prodi,
                'aman'            => 0,
                'perlu_perhatian' => 0,
                'berisiko'        => 0,
                'total'           => 0,
            ];
        }

        foreach ($latestSnapshots as $item) {
            $prodi = $item->prodi ?: 'Lainnya';
            if (! isset($distribution[$prodi])) {
                $distribution[$prodi] = [
                    'prodi'           => $prodi,
                    'aman'            => 0,
                    'perlu_perhatian' => 0,
                    'berisiko'        => 0,
                    'total'           => 0,
                ];
            }

            $level = $item->level ?: 'aman';
            if (isset($distribution[$prodi][$level])) {
                $distribution[$prodi][$level]++;
            }
            $distribution[$prodi]['total']++;
        }

        return $this->successResponse(
            'Distribusi tingkat risiko per program studi berhasil dimuat',
            array_values($distribution)
        );
    }

    /**
     * Average revision-cycle duration per supervisor (T-25, F-ANL-03).
     * GET /api/v1/admin/analytics/revision-cycle
     */
    public function revisionCycle(): JsonResponse
    {
        $dosens = Dosen::with('user')->get();

        // Calculate average duration in hours from annotation created to resolved
        $durations = AnotasiDokumen::where('status', 'resolved')
            ->whereNotNull('dosen_id')
            ->whereNull('parent_id')
            ->select('dosen_id', 'created_at', 'updated_at')
            ->get()
            ->groupBy('dosen_id');

        $result = $dosens->map(function ($dosen) use ($durations) {
            $annotList = $durations->get($dosen->dosen_id, collect());
            $count = $annotList->count();

            if ($count > 0) {
                $totalHours = $annotList->sum(function ($annot) {
                    $created = Carbon::parse($annot->created_at);
                    $resolved = Carbon::parse($annot->updated_at);
                    return max(0, $created->diffInHours($resolved));
                });
                $avgHours = round($totalHours / $count, 1);
                $avgDays = round($avgHours / 24, 1);
            } else {
                $avgHours = 0.0;
                $avgDays = 0.0;
            }

            return [
                'dosen_id'              => $dosen->dosen_id,
                'nama'                  => $dosen->user?->nama ?? 'Tanpa Nama',
                'nid'                   => $dosen->nid,
                'jumlah_anotasi_selesai'=> $count,
                'rata_rata_jam'         => $avgHours,
                'rata_rata_hari'        => $avgDays,
            ];
        });

        return $this->successResponse(
            'Rata-rata siklus revisi per dosen pembimbing berhasil dimuat',
            $result->values()
        );
    }

    /**
     * Supervision funnel metrics (T-25, F-ANL-03).
     * GET /api/v1/admin/analytics/supervision-funnel
     */
    public function supervisionFunnel(): JsonResponse
    {
        $totalPermohonan = PermohonanBimbingan::count();
        $totalDiterima = PermohonanBimbingan::where('status', 'diterima')->count();
        $totalAktif = Bimbingan::where('status_bimbingan', 'aktif')->count();
        $totalSelesai = Bimbingan::where('status_bimbingan', 'selesai')->count();

        // Count of active supervisions currently at-risk
        $atRiskCount = $this->getLatestSnapshotsQuery()
            ->where('risiko_snapshot.level', 'berisiko')
            ->count();

        $data = [
            'permohonan'  => $totalPermohonan,
            'diterima'    => $totalDiterima,
            'aktif'       => $totalAktif,
            'berisiko'    => $atRiskCount,
            'selesai'     => $totalSelesai,
        ];

        return $this->successResponse('Metrik supervision funnel berhasil dimuat', $data);
    }

    /**
     * List of at-risk supervisions sorted by risk score descending, with explainability (T-25, F-ANL-03).
     * GET /api/v1/admin/analytics/at-risk
     */
    public function atRisk(): JsonResponse
    {
        $snapshots = $this->getLatestSnapshotsQuery()
            ->whereIn('risiko_snapshot.level', ['berisiko', 'perlu_perhatian'])
            ->orderBy('risiko_snapshot.skor', 'desc')
            ->get();

        $data = $snapshots->map(function ($item) {
            $signals = is_string($item->sinyal) ? json_decode($item->sinyal, true) : $item->sinyal;

            return [
                'snapshot_id'    => $item->snapshot_id,
                'bimbingan_id'   => $item->bimbingan_id,
                'skor'           => (int) $item->skor,
                'level'          => $item->level,
                'tanggal_hitung' => $item->tanggal_hitung,
                'mahasiswa'      => [
                    'mahasiswa_id' => $item->mahasiswa_id,
                    'nama'         => $item->nama_mahasiswa,
                    'nim'          => $item->nim,
                    'prodi'        => $item->prodi,
                    'judul_ta'     => $item->judul_ta,
                ],
                'dosen'          => [
                    'dosen_id'     => $item->dosen_id,
                    'nama'         => $item->nama_dosen,
                    'nid'          => $item->nid,
                ],
                'sinyal'         => $signals ?: [],
            ];
        });

        return $this->successResponse('Daftar bimbingan berisiko berhasil dimuat', $data);
    }

    /**
     * Historical risk score trend for a specific supervision (T-24, F-ANL-03).
     * GET /api/v1/admin/analytics/risk-trend/{bimbingan_id}
     */
    public function riskTrend(int|string $bimbinganId): JsonResponse
    {
        $bimbingan = Bimbingan::with(['mahasiswa.user', 'dosen.user'])->find($bimbinganId);

        if (! $bimbingan) {
            return $this->notFoundResponse('Bimbingan tidak ditemukan');
        }

        $snapshots = RisikoSnapshot::where('bimbingan_id', $bimbinganId)
            ->orderBy('tanggal_hitung', 'asc')
            ->orderBy('snapshot_id', 'asc')
            ->get();

        $data = [
            'bimbingan_id' => $bimbingan->bimbingan_id,
            'mahasiswa'    => [
                'nama'     => $bimbingan->mahasiswa?->user?->nama,
                'nim'      => $bimbingan->mahasiswa?->nim,
                'prodi'    => $bimbingan->mahasiswa?->prodi,
                'judul_ta' => $bimbingan->mahasiswa?->judul_ta,
            ],
            'dosen'        => [
                'nama' => $bimbingan->dosen?->user?->nama,
                'nid'  => $bimbingan->dosen?->nid,
            ],
            'trend'        => $snapshots->map(function ($s) {
                return [
                    'snapshot_id'    => $s->snapshot_id,
                    'tanggal_hitung' => $s->tanggal_hitung?->toDateString(),
                    'skor'           => $s->skor,
                    'level'          => $s->level,
                    'sinyal'         => $s->sinyal,
                ];
            }),
        ];

        return $this->successResponse('Tren risiko bimbingan berhasil dimuat', $data);
    }

    /**
     * Query helper to get latest snapshot per active supervision.
     */
    private function getLatestSnapshotsQuery()
    {
        $latestSub = DB::table('risiko_snapshot')
            ->select('bimbingan_id', DB::raw('MAX(snapshot_id) as max_snapshot_id'))
            ->groupBy('bimbingan_id');

        return DB::table('risiko_snapshot')
            ->joinSub($latestSub, 'latest_risk', function ($join) {
                $join->on('risiko_snapshot.snapshot_id', '=', 'latest_risk.max_snapshot_id');
            })
            ->join('bimbingan', 'risiko_snapshot.bimbingan_id', '=', 'bimbingan.bimbingan_id')
            ->join('mahasiswa', 'bimbingan.mahasiswa_id', '=', 'mahasiswa.mahasiswa_id')
            ->join('users as u_mhs', 'mahasiswa.user_id', '=', 'u_mhs.user_id')
            ->join('dosen', 'bimbingan.dosen_id', '=', 'dosen.dosen_id')
            ->join('users as u_dsn', 'dosen.user_id', '=', 'u_dsn.user_id')
            ->where('bimbingan.status_bimbingan', 'aktif')
            ->select([
                'risiko_snapshot.snapshot_id',
                'risiko_snapshot.bimbingan_id',
                'risiko_snapshot.skor',
                'risiko_snapshot.level',
                'risiko_snapshot.sinyal',
                'risiko_snapshot.tanggal_hitung',
                'mahasiswa.mahasiswa_id',
                'u_mhs.nama as nama_mahasiswa',
                'mahasiswa.nim',
                'mahasiswa.prodi',
                'mahasiswa.judul_ta',
                'dosen.dosen_id',
                'u_dsn.nama as nama_dosen',
                'dosen.nid',
            ]);
    }
}
