<?php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\AnotasiDokumen;
use App\Models\Bimbingan;
use App\Models\Dosen;
use App\Models\Mahasiswa;
use App\Models\PermohonanBimbingan;
use App\Models\RisikoSnapshot;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class AnalyticsController extends Controller
{
    /**
     * Display the Admin Analytics Dashboard (T-77, F-ANL-03).
     */
    public function index()
    {
        // 1. Funnel Metrics
        $totalPermohonan = PermohonanBimbingan::count();
        $totalDiterima   = PermohonanBimbingan::where('status', 'diterima')->count();
        $totalAktif      = Bimbingan::where('status_bimbingan', 'aktif')->count();
        $totalSelesai    = Bimbingan::where('status_bimbingan', 'selesai')->count();

        // 2. Latest Snapshots per Active Supervision
        $latestSub = DB::table('risiko_snapshot')
            ->select('bimbingan_id', DB::raw('MAX(snapshot_id) as max_snapshot_id'))
            ->groupBy('bimbingan_id');

        $latestSnapshots = DB::table('risiko_snapshot')
            ->joinSub($latestSub, 'latest', function ($join) {
                $join->on('risiko_snapshot.snapshot_id', '=', 'latest.max_snapshot_id');
            })
            ->join('bimbingan', 'risiko_snapshot.bimbingan_id', '=', 'bimbingan.bimbingan_id')
            ->join('mahasiswa', 'bimbingan.mahasiswa_id', '=', 'mahasiswa.mahasiswa_id')
            ->join('users as u_mhs', 'mahasiswa.user_id', '=', 'u_mhs.user_id')
            ->join('dosen', 'bimbingan.dosen_id', '=', 'dosen.dosen_id')
            ->join('users as u_dsn', 'dosen.user_id', '=', 'u_dsn.user_id')
            ->where('bimbingan.status_bimbingan', 'aktif')
            ->select([
                'risiko_snapshot.*',
                'u_mhs.nama as nama_mahasiswa',
                'mahasiswa.nim',
                'mahasiswa.prodi',
                'mahasiswa.judul_ta',
                'u_dsn.nama as nama_dosen',
                'dosen.nid',
            ])
            ->get();

        $atRiskCount        = $latestSnapshots->where('level', 'berisiko')->count();
        $perluPerhatianCount = $latestSnapshots->where('level', 'perlu_perhatian')->count();
        $amanCount          = $latestSnapshots->where('level', 'aman')->count();

        // 3. Risk Distribution per Prodi
        $prodis = Mahasiswa::select('prodi')->whereNotNull('prodi')->distinct()->pluck('prodi');
        $distribution = [];
        foreach ($prodis as $prodi) {
            $distribution[$prodi] = ['aman' => 0, 'perlu_perhatian' => 0, 'berisiko' => 0, 'total' => 0];
        }
        foreach ($latestSnapshots as $item) {
            $prodi = $item->prodi ?: 'Lainnya';
            if (! isset($distribution[$prodi])) {
                $distribution[$prodi] = ['aman' => 0, 'perlu_perhatian' => 0, 'berisiko' => 0, 'total' => 0];
            }
            $level = $item->level ?: 'aman';
            if (isset($distribution[$prodi][$level])) {
                $distribution[$prodi][$level]++;
            }
            $distribution[$prodi]['total']++;
        }

        // 4. At-Risk Supervisions (sorted by score desc)
        $atRiskList = $latestSnapshots
            ->whereIn('level', ['berisiko', 'perlu_perhatian'])
            ->sortByDesc('skor')
            ->values();

        // 5. Revision Cycle per Supervisor
        $dosens = Dosen::with('user')->get();
        $durations = AnotasiDokumen::where('status', 'resolved')
            ->whereNotNull('dosen_id')
            ->whereNull('parent_id')
            ->select('dosen_id', 'created_at', 'updated_at')
            ->get()
            ->groupBy('dosen_id');

        $revisionCycles = $dosens->map(function ($dosen) use ($durations) {
            $annots = $durations->get($dosen->dosen_id, collect());
            $count  = $annots->count();
            if ($count > 0) {
                $totalHours = $annots->sum(function ($a) {
                    return max(0, Carbon::parse($a->created_at)->diffInHours(Carbon::parse($a->updated_at)));
                });
                $avgDays = round(($totalHours / $count) / 24, 1);
            } else {
                $avgDays = 0.0;
            }

            return [
                'nama'     => $dosen->user?->nama ?? 'Dosen',
                'nid'      => $dosen->nid,
                'resolved' => $count,
                'avg_days' => $avgDays,
            ];
        })->sortByDesc('resolved')->values();

        return view('admin.analytics.index', compact(
            'totalPermohonan',
            'totalDiterima',
            'totalAktif',
            'totalSelesai',
            'atRiskCount',
            'perluPerhatianCount',
            'amanCount',
            'distribution',
            'atRiskList',
            'revisionCycles'
        ));
    }

    /**
     * Historical Risk Trend for a supervision (T-24, T-77).
     */
    public function trend(int|string $bimbinganId)
    {
        $bimbingan = Bimbingan::with(['mahasiswa.user', 'dosen.user'])->findOrFail($bimbinganId);

        $snapshots = RisikoSnapshot::where('bimbingan_id', $bimbinganId)
            ->orderBy('tanggal_hitung', 'asc')
            ->orderBy('snapshot_id', 'asc')
            ->get();

        return view('admin.analytics.trend', compact('bimbingan', 'snapshots'));
    }
}
