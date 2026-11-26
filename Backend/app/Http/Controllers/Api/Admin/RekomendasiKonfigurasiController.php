<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\RekomendasiKonfigurasi;
use App\Models\RekomendasiLogPencarian;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RekomendasiKonfigurasiController extends Controller
{
    use ApiResponse;

    /**
     * Get the current supervisor recommendation weights (T-47, F-SUP-06).
     * GET /api/v1/admin/rekomendasi/konfigurasi
     */
    public function show(): JsonResponse
    {
        $config = RekomendasiKonfigurasi::current();

        return $this->successResponse('Konfigurasi rekomendasi dosen berhasil dimuat', [
            'konfigurasi_id'     => $config->konfigurasi_id,
            'bobot_kemiripan'    => $config->bobot_kemiripan,
            'bobot_kuota'        => $config->bobot_kuota,
            'bobot_beban'        => $config->bobot_beban,
            'ambang_skor_rendah' => $config->ambang_skor_rendah,
            'bobot_ternormalisasi' => $config->normalizedWeights(),
            'updated_at'         => $config->updated_at?->toIso8601String(),
        ]);
    }

    /**
     * Update supervisor recommendation weights (T-47, F-SUP-06).
     * PUT /api/v1/admin/rekomendasi/konfigurasi
     */
    public function update(Request $request): JsonResponse
    {
        $config = RekomendasiKonfigurasi::current();

        $validated = $request->validate([
            'bobot_kemiripan'    => 'sometimes|numeric|min:0|max:1',
            'bobot_kuota'        => 'sometimes|numeric|min:0|max:1',
            'bobot_beban'        => 'sometimes|numeric|min:0|max:1',
            'ambang_skor_rendah' => 'sometimes|numeric|min:0|max:1',
        ]);

        $alpha = array_key_exists('bobot_kemiripan', $validated) ? (float) $validated['bobot_kemiripan'] : (float) $config->bobot_kemiripan;
        $beta = array_key_exists('bobot_kuota', $validated) ? (float) $validated['bobot_kuota'] : (float) $config->bobot_kuota;
        $gamma = array_key_exists('bobot_beban', $validated) ? (float) $validated['bobot_beban'] : (float) $config->bobot_beban;

        $sum = $alpha + $beta + $gamma;
        if ($sum <= 0.0) {
            return $this->validationErrorResponse(
                ['bobot' => ['Total bobot (alpha + beta + gamma) harus lebih besar dari 0.']]
            );
        }

        if (abs($sum - 1.0) > 0.001) {
            return $this->validationErrorResponse(
                ['bobot' => ['Jumlah bobot kemiripan (α), kuota (β), dan beban (γ) harus sama dengan 1.00.']]
            );
        }

        $validated['updated_by'] = $request->user()?->user_id;
        $config->update($validated);
        $config->refresh();

        return $this->successResponse('Konfigurasi rekomendasi dosen berhasil diperbarui', [
            'konfigurasi_id'       => $config->konfigurasi_id,
            'bobot_kemiripan'      => $config->bobot_kemiripan,
            'bobot_kuota'          => $config->bobot_kuota,
            'bobot_beban'          => $config->bobot_beban,
            'ambang_skor_rendah'   => $config->ambang_skor_rendah,
            'bobot_ternormalisasi' => $config->normalizedWeights(),
            'updated_at'           => $config->updated_at?->toIso8601String(),
        ]);
    }

    /**
     * List anonymized low-score topic search logs for expertise gap analysis (T-52, F-SUP-06).
     * GET /api/v1/admin/rekomendasi/log-pencarian
     */
    public function logs(Request $request): JsonResponse
    {
        $perPage = min(100, max(1, (int) $request->integer('per_page', 20)));

        $logs = RekomendasiLogPencarian::query()
            ->orderByDesc('created_at')
            ->orderByDesc('log_id')
            ->paginate($perPage);

        return $this->successResponse('Log pencarian topik skor rendah berhasil dimuat', $logs);
    }
}
