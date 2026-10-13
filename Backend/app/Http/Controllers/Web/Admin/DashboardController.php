<?php
// app/Http/Controllers/Web/Admin/DashboardController.php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\Bimbingan;
use App\Models\Dosen;
use App\Models\JadwalBimbingan;
use App\Models\Mahasiswa;
use App\Models\PermohonanBimbingan;
use App\Models\ProgresTA;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function index()
    {
        // ==================== STATS CARDS ====================
        $totalMahasiswa     = Mahasiswa::count();
        $totalDosen         = Dosen::count();
        $totalSlots         = Dosen::sum('kuota_bimbingan');
        $usedSlots          = Bimbingan::where('status_bimbingan', 'aktif')->count();
        $availableSlots     = max(0, $totalSlots - $usedSlots);
        $permohonanMenunggu = PermohonanBimbingan::where('status', 'menunggu')->count();

        // Tambahan bulan ini
        $mahasiswaBulanIni = Mahasiswa::whereMonth('created_at', now()->month)
            ->whereYear('created_at', now()->year)->count();
        $dosenBulanIni = Dosen::whereMonth('created_at', now()->month)
            ->whereYear('created_at', now()->year)->count();
        $permohonanMingguIni = PermohonanBimbingan::where('created_at', '>=', now()->startOfWeek())
            ->count();

        // ==================== RECENT STUDENTS ====================
        $recentMahasiswa = Mahasiswa::with(['user', 'bimbinganAktif.dosen.user'])
            ->orderByDesc('created_at')
            ->limit(5)
            ->get();

        // ==================== LECTURER QUOTA ====================
        $dosenQuota = Dosen::with('user')
            ->orderByDesc('kuota_bimbingan')
            ->limit(4)
            ->get()
            ->map(function ($d) {
                $aktif = $d->bimbinganAktif()->count();
                $pct   = $d->kuota_bimbingan > 0
                    ? round(($aktif / $d->kuota_bimbingan) * 100)
                    : 0;
                return [
                    'nama'            => $d->user->nama,
                    'initial'         => strtoupper(substr($d->user->nama, 0, 1)),
                    'bidang_keahlian' => $d->bidang_keahlian ?? '-',
                    'kuota'           => $d->kuota_bimbingan,
                    'aktif'           => $aktif,
                    'sisa'            => max(0, $d->kuota_bimbingan - $aktif),
                    'pct'             => $pct,
                    'isFull'          => $aktif >= $d->kuota_bimbingan,
                    'barColor'        => $aktif >= $d->kuota_bimbingan
                        ? '#FF4D4D'
                        : ($pct > 70 ? '#FFB900' : '#3DDC97'),
                ];
            });

        // ==================== RECENT ACTIVITY ====================
        $recentActivity = collect();

        // Mahasiswa baru
        Mahasiswa::with('user')->orderByDesc('created_at')->limit(3)->get()
            ->each(function ($m) use (&$recentActivity) {
                $recentActivity->push([
                    'type'    => 'mahasiswa',
                    'color'   => '#0057B8',
                    'title'   => 'Mahasiswa baru terdaftar',
                    'desc'    => $m->user->nama,
                    'time'    => $m->created_at,
                ]);
            });

        // Permohonan terbaru
        PermohonanBimbingan::with(['mahasiswa.user', 'dosen.user'])
            ->orderByDesc('created_at')->limit(3)->get()
            ->each(function ($p) use (&$recentActivity) {
                $statusColor = match($p->status) {
                    'diterima' => '#3DDC97',
                    'ditolak'  => '#FF4D4D',
                    default    => '#FFB900',
                };
                $recentActivity->push([
                    'type'  => 'permohonan',
                    'color' => $statusColor,
                    'title' => 'Permohonan ' . $p->status,
                    'desc'  => $p->mahasiswa->user->nama . ' → ' . $p->dosen->user->nama,
                    'time'  => $p->created_at,
                ]);
            });

        // Kuota diupdate
        Dosen::with('user')->orderByDesc('updated_at')->limit(2)->get()
            ->each(function ($d) use (&$recentActivity) {
                $recentActivity->push([
                    'type'  => 'kuota',
                    'color' => '#4DA3FF',
                    'title' => 'Kuota diperbarui',
                    'desc'  => $d->user->nama . " ({$d->kuota_bimbingan} slot)",
                    'time'  => $d->updated_at,
                ]);
            });

        // Sort by time desc, ambil 6 terbaru
        $recentActivity = $recentActivity->sortByDesc('time')->take(6)->values();

        // ==================== CHART DATA (per bulan) ====================
        $chartData = [];
        for ($i = 5; $i >= 0; $i--) {
            $bulan = now()->subMonths($i);
            $chartData[] = [
                'label'      => $bulan->format('M Y'),
                'permohonan' => PermohonanBimbingan::whereYear('created_at', $bulan->year)
                                    ->whereMonth('created_at', $bulan->month)->count(),
                'diterima'   => PermohonanBimbingan::where('status', 'diterima')
                                    ->whereYear('created_at', $bulan->year)
                                    ->whereMonth('created_at', $bulan->month)->count(),
            ];
        }

        return view('admin.dashboard.index', compact(
            'totalMahasiswa',
            'totalDosen',
            'availableSlots',
            'permohonanMenunggu',
            'mahasiswaBulanIni',
            'dosenBulanIni',
            'permohonanMingguIni',
            'recentMahasiswa',
            'dosenQuota',
            'recentActivity',
            'chartData'
        ));
    }
}