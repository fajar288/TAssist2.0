<?php
// app/Http/Controllers/Api/Dosen/ChecklistProgressController.php

namespace App\Http\Controllers\Api\Dosen;

use App\Http\Controllers\Controller;
use App\Http\Requests\Dosen\ChecklistProgressRequest;
use App\Models\Bimbingan;
use App\Models\ChecklistProgress;
use App\Models\ProgresTA;
use App\Services\NotifikasiService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChecklistProgressController extends Controller
{
    use ApiResponse;

    // POST /api/dosen/progres/{id}/checklist
    // id = progress_id
    public function store(ChecklistProgressRequest $request, int $id): JsonResponse
    {
        $dosen = $request->user()->dosen;

        if (!$dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        // Pastikan progres_id milik bimbingan dosen ini
        $progres = ProgresTA::whereHas('bimbingan', fn($q) => $q->where('dosen_id', $dosen->dosen_id))
            ->findOrFail($id);

        $checklist = ChecklistProgress::create([
            'progress_id'     => $progres->progress_id,
            'nama_item'       => $request->nama_item,
            'tgl_selesai'     => $request->tgl_selesai ?? false,
            'tanggal_selesai' => $request->tgl_selesai ? ($request->tanggal_selesai ?? now()->toDateString()) : null,
            'catatan'         => $request->catatan,
        ]);

        // Notifikasi ke mahasiswa
        $mahasiswaUserId = $progres->bimbingan->mahasiswa->user_id;
        NotifikasiService::kirim(
            userId   : $mahasiswaUserId,
            tipe     : 'checklist_baru',
            judul    : 'Item Checklist Baru Ditambahkan',
            pesan    : "Dosen menambahkan item checklist: {$request->nama_item}",
            refTabel : 'checklist_progress',
            refId    : $checklist->checklist_id
        );

        return $this->successResponse('Checklist berhasil ditambahkan', [
            'checklist_id'    => $checklist->checklist_id,
            'progress_id'     => $checklist->progress_id,
            'nama_item'       => $checklist->nama_item,
            'tgl_selesai'     => $checklist->tgl_selesai,
            'tanggal_selesai' => $checklist->tanggal_selesai?->format('Y-m-d'),
            'catatan'         => $checklist->catatan,
        ], 201);
    }

    // PUT /api/dosen/checklist/{id}
    public function update(ChecklistProgressRequest $request, int $id): JsonResponse
    {
        $dosen = $request->user()->dosen;

        if (!$dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        $checklist = ChecklistProgress::whereHas(
                'progresTA.bimbingan',
                fn($q) => $q->where('dosen_id', $dosen->dosen_id)
            )
            ->findOrFail($id);

        $wasDone = (bool) $checklist->tgl_selesai;

        $checklist->update([
            'nama_item'       => $request->nama_item ?? $checklist->nama_item,
            'tgl_selesai'     => $request->has('tgl_selesai')
                                    ? $request->tgl_selesai
                                    : $checklist->tgl_selesai,
            'tanggal_selesai' => $request->has('tgl_selesai') && $request->tgl_selesai
                                    ? ($request->tanggal_selesai ?? now()->toDateString())
                                    : ($request->has('tgl_selesai') && !$request->tgl_selesai
                                        ? null
                                        : $checklist->tanggal_selesai),
            'catatan'         => $request->catatan ?? $checklist->catatan,
        ]);

        $checklist->refresh();

        // Notifikasi ke mahasiswa hanya saat berubah dari belum selesai -> selesai
        if (!$wasDone && $checklist->tgl_selesai) {
            $mahasiswaUserId = $checklist->progresTA->bimbingan->mahasiswa->user_id;
            NotifikasiService::kirim(
                userId   : $mahasiswaUserId,
                tipe     : 'checklist_selesai',
                judul    : 'Item Checklist Selesai',
                pesan    : "Item checklist \"{$checklist->nama_item}\" telah ditandai selesai oleh dosen.",
                refTabel : 'checklist_progress',
                refId    : $checklist->checklist_id
            );
        }

        return $this->successResponse('Checklist berhasil diperbarui', [
            'checklist_id'    => $checklist->checklist_id,
            'progress_id'     => $checklist->progress_id,
            'nama_item'       => $checklist->nama_item,
            'tgl_selesai'     => $checklist->tgl_selesai,
            'tanggal_selesai' => $checklist->tanggal_selesai?->format('Y-m-d'),
            'catatan'         => $checklist->catatan,
        ]);
    }

    // DELETE /api/dosen/checklist/{id}
    public function destroy(Request $request, int $id): JsonResponse
    {
        $dosen = $request->user()->dosen;

        if (!$dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        $checklist = ChecklistProgress::whereHas(
                'progresTA.bimbingan',
                fn($q) => $q->where('dosen_id', $dosen->dosen_id)
            )
            ->findOrFail($id);

        $namaItem = $checklist->nama_item;
        $checklist->delete();

        return $this->successResponse("Item checklist \"{$namaItem}\" berhasil dihapus.");
    }
}