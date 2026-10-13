<?php
// app/Http/Controllers/Web/Admin/MonitoringController.php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\Bimbingan;
use App\Models\DokumenTA;
use App\Models\JadwalBimbingan;
use App\Models\PermohonanBimbingan;
use App\Models\ProgresTA;
use Illuminate\Http\Request;

class MonitoringController extends Controller
{
    public function permohonan(Request $request)
    {
        $permohonan = PermohonanBimbingan::with(['mahasiswa.user', 'dosen.user'])
            ->when($request->filled('status'), fn($q) => $q->where('status', $request->status))
            ->orderByDesc('tanggal_pengajuan')
            ->paginate(15)->withQueryString();

        return view('admin.monitoring.permohonan', compact('permohonan'));
    }

    public function bimbingan(Request $request)
    {
        $bimbingan = Bimbingan::with(['mahasiswa.user', 'dosen.user', 'progresAktif'])
            ->when($request->filled('status'), fn($q) => $q->where('status_bimbingan', $request->status))
            ->orderByDesc('tanggal_mulai')
            ->paginate(15)->withQueryString();

        return view('admin.monitoring.bimbingan', compact('bimbingan'));
    }

    public function jadwal(Request $request)
    {
        $jadwal = JadwalBimbingan::with(['bimbingan.mahasiswa.user', 'bimbingan.dosen.user', 'pengaju'])
            ->when($request->filled('status'), fn($q) => $q->where('status_konfirmasi', $request->status))
            ->orderByDesc('tanggal')
            ->paginate(15)->withQueryString();

        return view('admin.monitoring.jadwal', compact('jadwal'));
    }

    public function dokumen(Request $request)
    {
        $dokumen = DokumenTA::with(['bimbingan.mahasiswa.user', 'bimbingan.dosen.user', 'versiTerbaru'])
            ->orderByDesc('created_at')
            ->paginate(15)->withQueryString();

        return view('admin.monitoring.dokumen', compact('dokumen'));
    }

    public function progres(Request $request)
    {
        $progres = ProgresTA::with([
                'bimbingan.mahasiswa.user',
                'bimbingan.dosen.user',
                'checklistProgress',
            ])
            ->orderByDesc('updated_at')
            ->paginate(15)->withQueryString();

        return view('admin.monitoring.progres', compact('progres'));
    }
}