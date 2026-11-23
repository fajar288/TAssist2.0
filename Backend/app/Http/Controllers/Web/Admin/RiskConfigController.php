<?php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\RisikoKonfigurasi;
use App\Services\RiskScoringService;
use Illuminate\Http\Request;

class RiskConfigController extends Controller
{
    /**
     * Display Risk Signal Configurations (T-77, F-ANL-01).
     */
    public function index()
    {
        $signals = RisikoKonfigurasi::orderBy('konfigurasi_id')->get();
        $renormalized = RisikoKonfigurasi::getActiveWithRenormalizedWeights()->keyBy('konfigurasi_id');

        return view('admin.risiko.index', compact('signals', 'renormalized'));
    }

    /**
     * Update a risk signal configuration (T-77, F-ANL-01).
     */
    public function update(Request $request, int|string $id)
    {
        $signal = RisikoKonfigurasi::findOrFail($id);

        $validated = $request->validate([
            'bobot'        => 'required|numeric|min:0|max:1',
            'deskripsi'    => 'required|string|max:255',
            'ambang_batas' => 'required|array',
            'is_active'    => 'nullable|boolean',
        ]);

        $validated['is_active'] = $request->has('is_active') ? (bool) $request->input('is_active') : false;

        $signal->update($validated);

        return redirect()->route('admin.risiko.index')
            ->with('success', "Konfigurasi sinyal '{$signal->nama_sinyal}' berhasil diperbarui.");
    }

    /**
     * Trigger manual recalculation of risk scores.
     */
    public function recalculate(RiskScoringService $service)
    {
        $snapshots = $service->calculateAllActive(now());

        return redirect()->route('admin.risiko.index')
            ->with('success', "Perhitungan ulang skor risiko berhasil dijalankan untuk {$snapshots->count()} bimbingan aktif.");
    }
}
