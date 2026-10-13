<?php
// app/Http/Controllers/Api/Dosen/ProgresTAController.php

namespace App\Http\Controllers\Api\Dosen;

use App\Http\Controllers\Controller;
use App\Http\Requests\Dosen\ProgresTARequest;
use App\Models\Bimbingan;
use App\Models\ProgresTA;
use App\Services\NotifikasiService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProgresTAController extends Controller
{
    use ApiResponse;

    // PUT /api/dosen/progres/{id}
    // id = bimbingan_id
    public function update(ProgresTARequest $request, int $id): JsonResponse
    {
        $dosen = $request->user()->dosen;

        if (!$dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        $bimbingan = Bimbingan::with('mahasiswa.user')
            ->where('bimbingan_id', $id)
            ->where('dosen_id', $dosen->dosen_id)
            ->first();

        if (!$bimbingan) {
            return $this->errorResponse(
                'Bimbingan tidak ditemukan atau bukan milik Anda.',
                null, 404
            );
        }

        if (!$bimbingan->isAktif()) {
            return $this->errorResponse(
                'Tidak dapat mengupdate progres bimbingan yang tidak aktif.',
                null, 422
            );
        }

        // Buat record progres baru
        $progres = ProgresTA::create([
            'bimbingan_id'     => $bimbingan->bimbingan_id,
            'persentase'       => $request->persentase,
            'status_progress'  => $request->status_progress,
            'updated_dosen_id' => $dosen->dosen_id,
            'catatan'          => $request->catatan,
        ]);

        // Notifikasi ke mahasiswa
        NotifikasiService::kirim(
            userId   : $bimbingan->mahasiswa->user_id,
            tipe     : 'update_progres',
            judul    : 'Progres TA Diperbarui',
            pesan    : "Dosen {$request->user()->nama} memperbarui progres TA Anda menjadi {$request->persentase}% - {$request->status_progress}",
            refTabel : 'progres_ta',
            refId    : $progres->progress_id
        );

        return $this->successResponse('Progres TA berhasil diperbarui', [
            'progress_id'     => $progres->progress_id,
            'bimbingan_id'    => $bimbingan->bimbingan_id,
            'persentase'      => $progres->persentase,
            'status_progress' => $progres->status_progress,
            'catatan'         => $progres->catatan,
            'updated_at'      => $progres->updated_at->format('Y-m-d H:i:s'),
            'mahasiswa'       => [
                'nama' => $bimbingan->mahasiswa->user->nama,
                'nim'  => $bimbingan->mahasiswa->nim,
            ],
        ]);
    }
}