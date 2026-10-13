<?php
// app/Http/Controllers/Web/Admin/SupervisorQuotaController.php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\Dosen;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class SupervisorQuotaController extends Controller
{
    public function index(Request $request)
    {
        $query = Dosen::with('user')
            ->when($request->filled('search'), fn($q) =>
                $q->whereHas('user', fn($u) =>
                    $u->where('nama', 'like', '%'.$request->search.'%')
                )->orWhere('bidang_keahlian', 'like', '%'.$request->search.'%')
            );

        $semuaDosen = $query->get();

        // Hitung statistik global
        $totalLecturers  = $semuaDosen->count();
        $totalSlots      = $semuaDosen->sum('kuota_bimbingan');
        $usedSlots       = $semuaDosen->sum(fn($d) => $d->bimbinganAktif()->count());
        $availableSlots  = max(0, $totalSlots - $usedSlots);
        $usedPercent     = $totalSlots > 0 ? round(($usedSlots / $totalSlots) * 100) : 0;

        // Paginate untuk tabel
        $dosen = $query->paginate(15)->withQueryString();

        return view('admin.supervisor-quota.index', compact(
            'dosen',
            'totalLecturers',
            'totalSlots',
            'usedSlots',
            'availableSlots',
            'usedPercent'
        ));
    }

    public function updateKuota(Request $request, int $id)
    {
        $request->validate([
            'kuota_bimbingan' => 'required|integer|min:0',
        ], [
            'kuota_bimbingan.required' => 'Kuota bimbingan wajib diisi.',
            'kuota_bimbingan.min'      => 'Kuota tidak boleh negatif.',
        ]);

        $dosen          = Dosen::findOrFail($id);
        $bimbinganAktif = $dosen->bimbinganAktif()->count();

        if ($request->kuota_bimbingan < $bimbinganAktif) {
            return back()->with('error',
                "Kuota tidak bisa dikurangi di bawah jumlah bimbingan aktif saat ini ({$bimbinganAktif})."
            );
        }

        $dosen->update(['kuota_bimbingan' => $request->kuota_bimbingan]);

        return back()->with('success',
            "Kuota bimbingan {$dosen->user->nama} berhasil diperbarui menjadi {$request->kuota_bimbingan}."
        );
    }
}