<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\RisikoKonfigurasi;
use App\Services\RiskScoringService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RisikoKonfigurasiController extends Controller
{
    use ApiResponse;

    /**
     * List all risk signals and their weights/thresholds (T-21, F-ANL-01).
     * GET /api/v1/admin/risiko/konfigurasi
     */
    public function index(): JsonResponse
    {
        $signals = RisikoKonfigurasi::orderBy('konfigurasi_id')->get();
        $renormalized = RisikoKonfigurasi::getActiveWithRenormalizedWeights();

        $renormalizedMap = $renormalized->keyBy('konfigurasi_id');

        $data = $signals->map(function ($signal) use ($renormalizedMap) {
            $normalizedWeight = $renormalizedMap->has($signal->konfigurasi_id)
                ? $renormalizedMap[$signal->konfigurasi_id]->bobot_ternormalisasi
                : 0.0;

            return [
                'konfigurasi_id'       => $signal->konfigurasi_id,
                'nama_sinyal'          => $signal->nama_sinyal,
                'deskripsi'            => $signal->deskripsi,
                'bobot'                => $signal->bobot,
                'bobot_ternormalisasi' => $normalizedWeight,
                'ambang_batas'         => $signal->ambang_batas,
                'is_active'            => $signal->is_active,
                'updated_at'           => $signal->updated_at?->toIso8601String(),
            ];
        });

        return $this->successResponse('Konfigurasi sinyal risiko berhasil dimuat', $data);
    }

    /**
     * Update a risk signal's weight, thresholds, or active status (T-21, F-ANL-01).
     * PUT /api/v1/admin/risiko/konfigurasi/{id}
     */
    public function update(Request $request, int|string $id): JsonResponse
    {
        $signal = RisikoKonfigurasi::find($id);

        if (! $signal) {
            return $this->notFoundResponse('Konfigurasi sinyal risiko tidak ditemukan');
        }

        $validated = $request->validate([
            'deskripsi'    => 'sometimes|string|max:255',
            'bobot'        => 'sometimes|numeric|min:0|max:1',
            'ambang_batas' => 'sometimes|array',
            'is_active'    => 'sometimes|boolean',
        ]);

        $signal->update($validated);

        return $this->successResponse('Konfigurasi sinyal risiko berhasil diperbarui', $signal->fresh());
    }

    /**
     * Trigger instant recalculation of risk scores for all active supervisions.
     * POST /api/v1/admin/risiko/hitung-ulang
     */
    public function recalculate(RiskScoringService $service): JsonResponse
    {
        $snapshots = $service->calculateAllActive(now());

        return $this->successResponse('Perhitungan ulang skor risiko berhasil dilakukan', [
            'total_dihitung' => $snapshots->count(),
            'tanggal_hitung' => now()->toDateString(),
        ]);
    }
}
