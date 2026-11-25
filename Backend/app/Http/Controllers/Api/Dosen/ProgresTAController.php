<?php
// app/Http/Controllers/Api/Dosen/ProgresTAController.php

namespace App\Http\Controllers\Api\Dosen;

use App\Http\Controllers\Controller;
use App\Http\Requests\Dosen\ProgresTARequest;
use App\Models\Bimbingan;
use App\Models\ProgresTA;
use App\Services\NotifikasiService;
use App\Services\ProgresCalculatorService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class ProgresTAController extends Controller
{
    use ApiResponse;

    public function __construct(private ProgresCalculatorService $calculator)
    {
    }

    // PUT /api/v1/dosen/progres/{id}
    // id = bimbingan_id
    public function update(ProgresTARequest $request, int $id): JsonResponse
    {
        $dosen = $request->user()->dosen;

        if (! $dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        $bimbingan = Bimbingan::with('mahasiswa.user')
            ->where('bimbingan_id', $id)
            ->where('dosen_id', $dosen->dosen_id)
            ->first();

        if (! $bimbingan) {
            return $this->errorResponse(
                'Bimbingan tidak ditemukan atau bukan milik Anda.',
                null, 404
            );
        }

        if (! $bimbingan->isAktif()) {
            return $this->errorResponse(
                'Tidak dapat mengupdate progres bimbingan yang tidak aktif.',
                null, 422
            );
        }

        $isOverride = $request->boolean('is_override', false);

        if (! $isOverride && ! $request->filled('persentase') && ! $request->has('is_override')) {
            return $this->errorResponse('Persentase wajib diisi.', [
                'persentase' => ['Persentase wajib diisi.'],
            ], 422);
        }

        $progres = DB::transaction(function () use ($request, $bimbingan, $dosen, $isOverride) {
            $progres = ProgresTA::create([
                'bimbingan_id'     => $bimbingan->bimbingan_id,
                'persentase'       => $request->filled('persentase') ? (float) $request->persentase : 0.0,
                'status_progress'  => $request->status_progress,
                'is_override'      => $isOverride,
                'updated_dosen_id' => $dosen->dosen_id,
                'catatan'          => $request->catatan,
            ]);

            $this->calculator->carryOverLatestChecklist($bimbingan, $progres);

            if (! $isOverride) {
                $progres->load('checklistProgress');
                if ($progres->checklistProgress->isNotEmpty()) {
                    $progres = $this->calculator->recalculate($progres);
                }
            }

            return $progres;
        });

        // Notifikasi ke mahasiswa
        NotifikasiService::kirim(
            userId   : $bimbingan->mahasiswa->user_id,
            tipe     : 'update_progres',
            judul    : 'Progres TA Diperbarui',
            pesan    : "Dosen {$request->user()->nama} memperbarui progres TA Anda menjadi {$progres->persentase}% - {$progres->status_progress}",
            refTabel : 'progres_ta',
            refId    : $progres->progress_id
        );

        return $this->successResponse('Progres TA berhasil diperbarui', [
            'progress_id'     => $progres->progress_id,
            'bimbingan_id'    => $bimbingan->bimbingan_id,
            'persentase'      => (float) $progres->persentase,
            'status_progress' => $progres->status_progress,
            'is_override'     => (bool) $progres->is_override,
            'catatan'         => $progres->catatan,
            'updated_at'      => $progres->updated_at->format('Y-m-d H:i:s'),
            'mahasiswa'       => [
                'nama' => $bimbingan->mahasiswa->user->nama,
                'nim'  => $bimbingan->mahasiswa->nim,
            ],
        ]);
    }
}
