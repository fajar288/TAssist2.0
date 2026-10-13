<?php
// app/Http/Controllers/Web/Dosen/DashboardController.php

namespace App\Http\Controllers\Web\Dosen;

use App\Http\Controllers\Controller;
use App\Models\Bimbingan;
use App\Models\JadwalBimbingan;
use App\Models\Notifikasi;
use App\Models\PermohonanBimbingan;

class DashboardController extends Controller
{
    public function index()
    {
        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];

        $permohonanMenunggu = PermohonanBimbingan::where('dosen_id', $dosenId)
            ->where('status', 'menunggu')
            ->count();

        $mahasiswaAktif = Bimbingan::where('dosen_id', $dosenId)
            ->where('status_bimbingan', 'aktif')
            ->count();

        $jadwalMenunggu = JadwalBimbingan::whereHas('bimbingan', function ($query) use ($dosenId) {
                $query->where('dosen_id', $dosenId);
            })
            ->where('status_konfirmasi', 'menunggu')
            ->count();

        $notifikasiBelumDibaca = Notifikasi::where('user_id', $dosenSession['user_id'])
            ->where('is_read', false)
            ->count();

        $recentPermohonan = PermohonanBimbingan::with(['mahasiswa.user'])
            ->where('dosen_id', $dosenId)
            ->orderByDesc('created_at')
            ->limit(5)
            ->get();

        $recentJadwal = JadwalBimbingan::with(['bimbingan.mahasiswa.user', 'pengaju'])
            ->whereHas('bimbingan', function ($query) use ($dosenId) {
                $query->where('dosen_id', $dosenId);
            })
            ->orderByDesc('tanggal')
            ->orderByDesc('waktu_mulai')
            ->limit(5)
            ->get();

        return view('dosen.dashboard.index', compact(
            'permohonanMenunggu',
            'mahasiswaAktif',
            'jadwalMenunggu',
            'notifikasiBelumDibaca',
            'recentPermohonan',
            'recentJadwal'
        ));
    }
}