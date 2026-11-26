<?php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\RekomendasiKonfigurasi;
use App\Models\RekomendasiLogPencarian;
use Illuminate\Http\Request;

class RekomendasiConfigController extends Controller
{
    /**
     * Display supervisor recommendation weight settings & anonymized low-score search logs (T-47, T-52).
     */
    public function index()
    {
        $config = RekomendasiKonfigurasi::current();
        $logs = RekomendasiLogPencarian::query()
            ->orderByDesc('created_at')
            ->orderByDesc('log_id')
            ->paginate(15);

        return view('admin.rekomendasi.index', compact('config', 'logs'));
    }

    /**
     * Update α / β / γ recommendation weights and low-score threshold (T-47).
     */
    public function update(Request $request)
    {
        $config = RekomendasiKonfigurasi::current();

        $validated = $request->validate([
            'bobot_kemiripan'    => 'required|numeric|min:0|max:1',
            'bobot_kuota'        => 'required|numeric|min:0|max:1',
            'bobot_beban'        => 'required|numeric|min:0|max:1',
            'ambang_skor_rendah' => 'required|numeric|min:0|max:1',
        ]);

        $sum = (float) $validated['bobot_kemiripan']
            + (float) $validated['bobot_kuota']
            + (float) $validated['bobot_beban'];

        if ($sum <= 0 || abs($sum - 1.0) > 0.001) {
            return redirect()
                ->route('admin.rekomendasi.index')
                ->withInput()
                ->with('error', 'Jumlah bobot kemiripan (α), kuota (β), dan beban (γ) harus sama dengan 1.00.');
        }

        $adminUser = session('admin_user');
        $validated['updated_by'] = is_array($adminUser) ? ($adminUser['user_id'] ?? null) : ($adminUser?->user_id ?? null);

        $config->update($validated);

        return redirect()
            ->route('admin.rekomendasi.index')
            ->with('success', 'Konfigurasi bobot rekomendasi dosen berhasil diperbarui.');
    }
}
