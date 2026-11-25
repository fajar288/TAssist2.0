<?php

namespace App\Http\Controllers\Api\Dosen;

use App\Http\Controllers\Controller;
use App\Http\Requests\Dosen\DosenKetersediaanRequest;
use App\Models\DosenKetersediaan;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class KetersediaanController extends Controller
{
    use ApiResponse;

    /**
     * GET /api/v1/dosen/ketersediaan
     */
    public function index(Request $request): JsonResponse
    {
        $dosen = $request->user()->dosen;

        if (! $dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        $slots = DosenKetersediaan::where('dosen_id', $dosen->dosen_id)
            ->orderByRaw("CASE WHEN tipe = 'mingguan' THEN 0 ELSE 1 END")
            ->orderBy('tanggal')
            ->orderBy('waktu_mulai')
            ->get()
            ->map(fn (DosenKetersediaan $s) => $this->formatSlot($s));

        return $this->successResponse('Daftar slot ketersediaan berhasil diambil', $slots);
    }

    /**
     * POST /api/v1/dosen/ketersediaan
     */
    public function store(DosenKetersediaanRequest $request): JsonResponse
    {
        $dosen = $request->user()->dosen;

        if (! $dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        $slot = DosenKetersediaan::create([
            'dosen_id'      => $dosen->dosen_id,
            'tipe'          => $request->tipe,
            'hari'          => $request->tipe === 'mingguan' ? $request->hari : null,
            'tanggal'       => $request->tipe === 'khusus' ? $request->tanggal : null,
            'waktu_mulai'   => $request->waktu_mulai,
            'waktu_selesai' => $request->waktu_selesai,
            'is_available'  => $request->has('is_available') ? $request->boolean('is_available') : true,
            'catatan'       => $request->catatan,
        ]);

        return $this->successResponse(
            'Slot ketersediaan berhasil ditambahkan',
            $this->formatSlot($slot),
            201
        );
    }

    /**
     * PUT /api/v1/dosen/ketersediaan/{id}
     */
    public function update(DosenKetersediaanRequest $request, int $id): JsonResponse
    {
        $slot = DosenKetersediaan::findOrFail($id);

        Gate::authorize('update', $slot);

        $tipe = $request->input('tipe', $slot->tipe);

        if ($request->filled('waktu_mulai') && ! $request->filled('waktu_selesai')) {
            if (substr((string) $slot->waktu_selesai, 0, 5) <= $request->waktu_mulai) {
                return $this->errorResponse('Waktu selesai harus setelah waktu mulai.', null, 422);
            }
        }

        $slot->update([
            'tipe'          => $tipe,
            'hari'          => $tipe === 'mingguan' ? $request->input('hari', $slot->hari) : null,
            'tanggal'       => $tipe === 'khusus' ? $request->input('tanggal', $slot->tanggal?->format('Y-m-d')) : null,
            'waktu_mulai'   => $request->input('waktu_mulai', substr((string) $slot->waktu_mulai, 0, 5)),
            'waktu_selesai' => $request->input('waktu_selesai', substr((string) $slot->waktu_selesai, 0, 5)),
            'is_available'  => $request->has('is_available') ? $request->boolean('is_available') : $slot->is_available,
            'catatan'       => $request->has('catatan') ? $request->catatan : $slot->catatan,
        ]);

        $slot->refresh();

        return $this->successResponse(
            'Slot ketersediaan berhasil diperbarui',
            $this->formatSlot($slot)
        );
    }

    /**
     * DELETE /api/v1/dosen/ketersediaan/{id}
     */
    public function destroy(int $id): JsonResponse
    {
        $slot = DosenKetersediaan::findOrFail($id);

        Gate::authorize('delete', $slot);

        $slot->delete();

        return $this->successResponse('Slot ketersediaan berhasil dihapus.');
    }

    private function formatSlot(DosenKetersediaan $slot): array
    {
        return [
            'ketersediaan_id' => $slot->ketersediaan_id,
            'dosen_id'        => $slot->dosen_id,
            'tipe'            => $slot->tipe,
            'hari'            => $slot->hari,
            'tanggal'         => $slot->tanggal?->format('Y-m-d'),
            'waktu_mulai'     => substr((string) $slot->waktu_mulai, 0, 5),
            'waktu_selesai'   => substr((string) $slot->waktu_selesai, 0, 5),
            'is_available'    => (bool) $slot->is_available,
            'catatan'         => $slot->catatan,
        ];
    }
}
