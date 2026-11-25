<?php
// app/Http/Controllers/Api/Dosen/ChecklistProgressController.php

namespace App\Http\Controllers\Api\Dosen;

use App\Http\Controllers\Controller;
use App\Http\Requests\Dosen\ChecklistProgressRequest;
use App\Models\ChecklistProgress;
use App\Models\ProgresTA;
use App\Services\NotifikasiService;
use App\Services\ProgresCalculatorService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ChecklistProgressController extends Controller
{
    use ApiResponse;

    public function __construct(private ProgresCalculatorService $calculator)
    {
    }

    // POST /api/v1/dosen/progres/{id}/checklist
    // id = progress_id
    public function store(ChecklistProgressRequest $request, int $id): JsonResponse
    {
        $dosen = $request->user()->dosen;

        if (! $dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        // Pastikan progres_id milik bimbingan dosen ini
        $progres = ProgresTA::with('bimbingan.mahasiswa')
            ->whereHas('bimbingan', fn ($q) => $q->where('dosen_id', $dosen->dosen_id))
            ->findOrFail($id);

        $isDone = $request->has('is_selesai')
            ? $request->boolean('is_selesai')
            : $request->boolean('tgl_selesai', false);

        [$checklist, $updatedProgres] = DB::transaction(function () use ($request, $progres, $isDone) {
            $checklist = ChecklistProgress::create([
                'progress_id'     => $progres->progress_id,
                'nama_item'       => $request->nama_item,
                'is_selesai'      => $isDone,
                'tanggal_selesai' => $isDone ? ($request->tanggal_selesai ?? now()->toDateString()) : null,
                'catatan'         => $request->catatan,
                'bobot'           => $request->filled('bobot') ? (float) $request->bobot : 1.0,
            ]);

            $updatedProgres = $this->calculator->recalculate($progres);

            return [$checklist, $updatedProgres];
        });

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
            'checklist_id'       => $checklist->checklist_id,
            'progress_id'        => $checklist->progress_id,
            'nama_item'          => $checklist->nama_item,
            'is_selesai'         => (bool) $checklist->is_selesai,
            'bobot'              => (float) $checklist->bobot,
            'tanggal_selesai'    => $checklist->tanggal_selesai?->format('Y-m-d'),
            'catatan'            => $checklist->catatan,
            'progres_persentase' => (float) $updatedProgres->persentase,
            'is_override'        => (bool) $updatedProgres->is_override,
        ], 201);
    }

    // PUT /api/v1/dosen/checklist/{id}
    public function update(ChecklistProgressRequest $request, int $id): JsonResponse
    {
        $dosen = $request->user()->dosen;

        if (! $dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        $checklist = ChecklistProgress::with('progresTA.bimbingan.mahasiswa')
            ->whereHas(
                'progresTA.bimbingan',
                fn ($q) => $q->where('dosen_id', $dosen->dosen_id)
            )
            ->findOrFail($id);

        $wasDone = (bool) $checklist->is_selesai;

        $hasDoneInput = $request->has('is_selesai') || $request->has('tgl_selesai');
        $isDone = $request->has('is_selesai')
            ? $request->boolean('is_selesai')
            : ($request->has('tgl_selesai') ? $request->boolean('tgl_selesai') : $wasDone);

        $updatedProgres = DB::transaction(function () use ($request, $checklist, $hasDoneInput, $isDone) {
            $checklist->update([
                'nama_item'       => $request->nama_item ?? $checklist->nama_item,
                'is_selesai'      => $isDone,
                'tanggal_selesai' => $hasDoneInput && $isDone
                    ? ($request->tanggal_selesai ?? $checklist->tanggal_selesai ?? now()->toDateString())
                    : ($hasDoneInput && ! $isDone ? null : $checklist->tanggal_selesai),
                'catatan'         => $request->has('catatan') ? $request->catatan : $checklist->catatan,
                'bobot'           => $request->filled('bobot') ? (float) $request->bobot : $checklist->bobot,
            ]);

            $checklist->refresh();

            return $this->calculator->recalculate($checklist->progresTA);
        });

        // Notifikasi ke mahasiswa hanya saat berubah dari belum selesai -> selesai
        if (! $wasDone && $checklist->is_selesai) {
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
            'checklist_id'       => $checklist->checklist_id,
            'progress_id'        => $checklist->progress_id,
            'nama_item'          => $checklist->nama_item,
            'is_selesai'         => (bool) $checklist->is_selesai,
            'bobot'              => (float) $checklist->bobot,
            'tanggal_selesai'    => $checklist->tanggal_selesai?->format('Y-m-d'),
            'catatan'            => $checklist->catatan,
            'progres_persentase' => (float) $updatedProgres->persentase,
            'is_override'        => (bool) $updatedProgres->is_override,
        ]);
    }

    // DELETE /api/v1/dosen/checklist/{id}
    public function destroy(Request $request, int $id): JsonResponse
    {
        $dosen = $request->user()->dosen;

        if (! $dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        $checklist = ChecklistProgress::with('progresTA')
            ->whereHas(
                'progresTA.bimbingan',
                fn ($q) => $q->where('dosen_id', $dosen->dosen_id)
            )
            ->findOrFail($id);

        $namaItem = $checklist->nama_item;
        $progres = $checklist->progresTA;

        $updatedProgres = DB::transaction(function () use ($checklist, $progres) {
            $checklist->delete();
            return $this->calculator->recalculate($progres);
        });

        return $this->successResponse("Item checklist \"{$namaItem}\" berhasil dihapus.", [
            'progres_persentase' => (float) $updatedProgres->persentase,
            'is_override'        => (bool) $updatedProgres->is_override,
        ]);
    }
}
