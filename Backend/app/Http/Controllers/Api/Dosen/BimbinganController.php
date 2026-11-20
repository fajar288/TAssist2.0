<?php
// app/Http/Controllers/Api/Dosen/BimbinganController.php

namespace App\Http\Controllers\Api\Dosen;

use App\Http\Controllers\Controller;
use App\Models\Bimbingan;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BimbinganController extends Controller
{
    use ApiResponse;

    /**
     * Transition the supervision lifecycle status (T-04).
     *
     * Permitted transitions from 'aktif':
     *   - 'selesai'   (Supervision completed successfully)
     *   - 'dibatalkan' (Supervision cancelled)
     *
     * Sets tanggal_selesai to now() upon closing.
     */
    public function updateStatus(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'status'  => 'required|in:selesai,dibatalkan',
            'catatan' => 'nullable|string|max:500',
        ]);

        $dosen = $request->user()->dosen;
        if (! $dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        $bimbingan = Bimbingan::with(['mahasiswa.user'])->find($id);
        if (! $bimbingan) {
            return $this->errorResponse('Bimbingan tidak ditemukan.', null, 404);
        }

        if ($bimbingan->dosen_id !== $dosen->dosen_id) {
            return $this->errorResponse('Anda tidak berhak mengubah status bimbingan ini.', null, 403);
        }

        if ($bimbingan->status_bimbingan !== 'aktif') {
            return $this->errorResponse(
                "Bimbingan sudah berstatus '{$bimbingan->status_bimbingan}' dan tidak dapat diubah lagi.",
                null,
                422
            );
        }

        $bimbingan->update([
            'status_bimbingan' => $validated['status'],
            'tanggal_selesai'  => now(),
        ]);

        return $this->successResponse('Status bimbingan berhasil diperbarui', [
            'bimbingan_id'     => $bimbingan->bimbingan_id,
            'status_bimbingan' => $bimbingan->status_bimbingan,
            'tanggal_selesai'  => $bimbingan->tanggal_selesai?->format('Y-m-d'),
        ]);
    }
}
