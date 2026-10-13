<?php
// app/Http/Controllers/Api/Mahasiswa/ProgresTAController.php

namespace App\Http\Controllers\Api\Mahasiswa;

use App\Http\Controllers\Controller;
use App\Models\Bimbingan;
use App\Models\ProgresTA;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProgresTAController extends Controller
{
    use ApiResponse;

    // GET /api/mahasiswa/progres
    public function index(Request $request): JsonResponse
    {
        $mahasiswa = $request->user()->mahasiswa;

        if (!$mahasiswa) {
            return $this->errorResponse('Data mahasiswa tidak ditemukan.', null, 404);
        }

        $bimbingan = Bimbingan::where('mahasiswa_id', $mahasiswa->mahasiswa_id)
            ->where('status_bimbingan', 'aktif')
            ->first();

        if (!$bimbingan) {
            return $this->errorResponse('Tidak ada bimbingan aktif.', null, 404);
        }

        $progres = ProgresTA::with(['checklistProgress', 'updatedDosen.user'])
            ->where('bimbingan_id', $bimbingan->bimbingan_id)
            ->orderByDesc('updated_at')
            ->paginate($request->get('per_page', 5));

        $data = $progres->through(function ($p) {
            $totalChecklist   = $p->checklistProgress->count();
            $selesaiChecklist = $p->checklistProgress->where('tgl_selesai', true)->count();

            return [
                'progress_id'     => $p->progress_id,
                'persentase'      => $p->persentase,
                'status_progress' => $p->status_progress,
                'catatan'         => $p->catatan,
                'updated_at'      => $p->updated_at->format('Y-m-d H:i:s'),
                'updated_oleh'    => $p->updatedDosen ? [
                    'dosen_id' => $p->updatedDosen->dosen_id,
                    'nama'     => $p->updatedDosen->user->nama,
                ] : null,
                'checklist_summary' => [
                    'total'   => $totalChecklist,
                    'selesai' => $selesaiChecklist,
                ],
                'checklist'       => $p->checklistProgress->map(fn($c) => [
                    'checklist_id'    => $c->checklist_id,
                    'nama_item'       => $c->nama_item,
                    'tgl_selesai'     => $c->tgl_selesai,
                    'tanggal_selesai' => $c->tanggal_selesai?->format('Y-m-d'),
                    'catatan'         => $c->catatan,
                ]),
            ];
        });

        return $this->successResponse('Data progres TA berhasil diambil', [
            'bimbingan_id'   => $bimbingan->bimbingan_id,
            'status_bimbingan' => $bimbingan->status_bimbingan,
            'progres'        => $data,
        ]);
    }
}