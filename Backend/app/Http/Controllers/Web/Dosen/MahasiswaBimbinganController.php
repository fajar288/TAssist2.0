<?php
// app/Http/Controllers/Web/Dosen/MahasiswaBimbinganController.php

namespace App\Http\Controllers\Web\Dosen;

use App\Http\Controllers\Controller;
use App\Models\Bimbingan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MahasiswaBimbinganController extends Controller
{
    public function index(Request $request)
    {
        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];

        $status = $request->query('status');
        $search = trim((string) $request->query('search'));

        $query = Bimbingan::with([
                'mahasiswa.user',
                'permohonan',
                'progresAktif',
            ])
            ->where('dosen_id', $dosenId);

        if ($status && in_array($status, ['aktif', 'selesai', 'nonaktif'])) {
            $query->where('status_bimbingan', $status);
        }

        if ($search !== '') {
            $query->where(function ($q) use ($search) {
                $q->whereHas('mahasiswa.user', function ($userQuery) use ($search) {
                    $userQuery->where('nama', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%");
                })
                ->orWhereHas('mahasiswa', function ($mahasiswaQuery) use ($search) {
                    $mahasiswaQuery->where('nim', 'like', "%{$search}%")
                        ->orWhere('prodi', 'like', "%{$search}%")
                        ->orWhere('topik_ta', 'like', "%{$search}%")
                        ->orWhere('judul_ta', 'like', "%{$search}%");
                })
                ->orWhereHas('permohonan', function ($permohonanQuery) use ($search) {
                    $permohonanQuery->where('topik_ta', 'like', "%{$search}%");
                });
            });
        }

        $bimbingan = $query
            ->orderByRaw("FIELD(status_bimbingan, 'aktif', 'selesai', 'nonaktif')")
            ->orderByDesc('tanggal_mulai')
            ->paginate(10)
            ->withQueryString();

        $stats = [
            'semua' => Bimbingan::where('dosen_id', $dosenId)->count(),
            'aktif' => Bimbingan::where('dosen_id', $dosenId)
                ->where('status_bimbingan', 'aktif')
                ->count(),
            'total_progress' => Bimbingan::where('dosen_id', $dosenId)
                ->whereHas('progresTA')
                ->count(),
        ];

        $avgProgress = DB::table('progres_ta')
            ->join('bimbingan', 'progres_ta.bimbingan_id', '=', 'bimbingan.bimbingan_id')
            ->where('bimbingan.dosen_id', $dosenId)
            ->whereIn('progres_ta.progress_id', function ($subQuery) {
                $subQuery->selectRaw('MAX(progress_id)')
                    ->from('progres_ta')
                    ->groupBy('bimbingan_id');
            })
            ->avg('progres_ta.persentase');

        $stats['rata_progress'] = round((float) $avgProgress, 1);

        return view('dosen.mahasiswa-bimbingan.index', compact(
            'bimbingan',
            'status',
            'search',
            'stats'
        ));
    }

    public function show(int $id)
    {
        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];

        $bimbingan = Bimbingan::with([
                'mahasiswa.user',
                'dosen.user',
                'permohonan',
                'progresTA.checklistProgress',
                'jadwalBimbingan.pengaju',
                'dokumenTA',
            ])
            ->withCount([
                'jadwalBimbingan',
                'dokumenTA',
                'progresTA',
            ])
            ->where('bimbingan_id', $id)
            ->where('dosen_id', $dosenId)
            ->firstOrFail();

        $latestProgress = $bimbingan->progresTA
            ->sortByDesc('updated_at')
            ->sortByDesc('progress_id')
            ->first();

        $latestChecklist = $latestProgress
            ? $latestProgress->checklistProgress->sortByDesc('created_at')->take(5)
            : collect();

        $recentJadwal = $bimbingan->jadwalBimbingan
            ->sortByDesc('tanggal')
            ->sortByDesc('waktu_mulai')
            ->take(5);

        $recentDokumen = $bimbingan->dokumenTA
            ->sortByDesc('updated_at')
            ->take(5);

        return view('dosen.mahasiswa-bimbingan.show', compact(
            'bimbingan',
            'latestProgress',
            'latestChecklist',
            'recentJadwal',
            'recentDokumen'
        ));
    }
}