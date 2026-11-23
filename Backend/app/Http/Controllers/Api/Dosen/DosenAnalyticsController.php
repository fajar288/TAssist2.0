<?php

namespace App\Http\Controllers\Api\Dosen;

use App\Http\Controllers\Controller;
use App\Models\Bimbingan;
use App\Models\RisikoSnapshot;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DosenAnalyticsController extends Controller
{
    use ApiResponse;

    /**
     * Professor-scoped risk indicator (T-26, F-ANL-04).
     * GET /api/v1/dosen/analytics/risk
     */
    public function risk(Request $request): JsonResponse
    {
        $dosen = $request->user()->dosen;

        if (! $dosen) {
            return $this->forbiddenResponse('Hanya dosen yang dapat mengakses indikator risiko bimbingan.');
        }

        // Fetch active supervisions for this dosen only
        $supervisions = Bimbingan::with(['mahasiswa.user'])
            ->where('dosen_id', $dosen->dosen_id)
            ->where('status_bimbingan', 'aktif')
            ->get();

        $bimbinganIds = $supervisions->pluck('bimbingan_id');

        // Fetch latest snapshot for each supervision
        $latestSub = DB::table('risiko_snapshot')
            ->whereIn('bimbingan_id', $bimbinganIds)
            ->select('bimbingan_id', DB::raw('MAX(snapshot_id) as max_snapshot_id'))
            ->groupBy('bimbingan_id');

        $snapshots = DB::table('risiko_snapshot')
            ->joinSub($latestSub, 'latest', function ($join) {
                $join->on('risiko_snapshot.snapshot_id', '=', 'latest.max_snapshot_id');
            })
            ->get()
            ->keyBy('bimbingan_id');

        $data = $supervisions->map(function ($bimbingan) use ($snapshots) {
            $snapshot = $snapshots->get($bimbingan->bimbingan_id);
            $signals = $snapshot ? (is_string($snapshot->sinyal) ? json_decode($snapshot->sinyal, true) : $snapshot->sinyal) : [];

            return [
                'bimbingan_id'   => $bimbingan->bimbingan_id,
                'tanggal_mulai'  => $bimbingan->tanggal_mulai?->toDateString(),
                'mahasiswa'      => [
                    'mahasiswa_id' => $bimbingan->mahasiswa?->mahasiswa_id,
                    'nama'         => $bimbingan->mahasiswa?->user?->nama,
                    'nim'          => $bimbingan->mahasiswa?->nim,
                    'prodi'        => $bimbingan->mahasiswa?->prodi,
                    'judul_ta'     => $bimbingan->mahasiswa?->judul_ta,
                ],
                'risiko'         => [
                    'snapshot_id'    => $snapshot?->snapshot_id,
                    'skor'           => $snapshot ? (int) $snapshot->skor : 0,
                    'level'          => $snapshot ? $snapshot->level : 'aman',
                    'tanggal_hitung' => $snapshot?->tanggal_hitung,
                    'sinyal'         => $signals ?: [],
                ],
            ];
        });

        return $this->successResponse('Indikator risiko mahasiswa bimbingan berhasil dimuat', $data);
    }
}
