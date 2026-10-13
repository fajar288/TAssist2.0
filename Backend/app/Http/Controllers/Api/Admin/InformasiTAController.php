<?php
// app/Http/Controllers/Api/Admin/InformasiTAController.php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\InformasiTARequest;
use App\Models\InformasiTA;
use App\Models\Notifikasi;
use App\Models\User;
use App\Services\NotifikasiService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InformasiTAController extends Controller
{
    use ApiResponse;

    // GET /api/admin/informasi-ta
    public function index(Request $request): JsonResponse
    {
        $informasi = InformasiTA::with('admin.user')
            ->when(
                $request->filled('kategori'),
                fn($q) => $q->where('kategori', $request->kategori)
            )
            ->when(
                $request->filled('search'),
                fn($q) => $q->where('judul', 'like', '%' . $request->search . '%')
            )
            ->orderByDesc('published_at')
            ->paginate($request->get('per_page', 10));

        $data = $informasi->through(fn($i) => [
            'info_id'       => $i->info_id,
            'kategori'      => $i->kategori,
            'judul'         => $i->judul,
            'konten_or_file'=> $i->konten_or_file,
            'published_at'  => $i->published_at?->format('Y-m-d H:i:s'),
            'created_at'    => $i->created_at->format('Y-m-d H:i:s'),
            'admin'         => [
                'admin_id' => $i->admin->admin_id,
                'nama'     => $i->admin->user->nama,
            ],
        ]);

        return $this->successResponse('Daftar informasi TA berhasil diambil', $data);
    }

    // POST /api/admin/informasi-ta
    public function store(InformasiTARequest $request): JsonResponse
    {
        $admin = $request->user()->admin;

        if (!$admin) {
            return $this->errorResponse('Data admin tidak ditemukan.', null, 404);
        }

        $publishedAt = $request->filled('published_at')
            ? $request->input('published_at')
            : null;

        $informasi = InformasiTA::create([
            'admin_id'       => $admin->admin_id,
            'kategori'       => $request->kategori,
            'judul'          => $request->judul,
            'konten_or_file' => $request->konten_or_file,
            'published_at'   => $publishedAt,
        ]);

        if ($informasi->published_at !== null) {
            $this->kirimNotifikasiInformasiTA($informasi);
        }

        return $this->successResponse('Informasi TA berhasil ditambahkan', [
            'info_id'        => $informasi->info_id,
            'kategori'       => $informasi->kategori,
            'judul'          => $informasi->judul,
            'konten_or_file' => $informasi->konten_or_file,
            'published_at'   => $informasi->published_at?->format('Y-m-d H:i:s'),
        ], 201);
    }

    // PUT /api/admin/informasi-ta/{id}
    public function update(InformasiTARequest $request, int $id): JsonResponse
    {
        $admin = $request->user()->admin;

        if (!$admin) {
            return $this->errorResponse('Data admin tidak ditemukan.', null, 404);
        }

        $informasi = InformasiTA::findOrFail($id);

        $wasPublished = $informasi->published_at !== null;

        $publishedAt = $request->exists('published_at')
            ? (
                $request->filled('published_at')
                    ? $request->input('published_at')
                    : null
            )
            : $informasi->published_at;

        $informasi->update([
            'kategori'       => $request->kategori,
            'judul'          => $request->judul,
            'konten_or_file' => $request->konten_or_file,
            'published_at'   => $publishedAt,
        ]);

        $informasi->refresh();

        $nowPublished = $informasi->published_at !== null;

        if (!$wasPublished && $nowPublished) {
            $this->kirimNotifikasiInformasiTA($informasi);
        }

        return $this->successResponse('Informasi TA berhasil diperbarui', [
            'info_id'        => $informasi->info_id,
            'kategori'       => $informasi->kategori,
            'judul'          => $informasi->judul,
            'konten_or_file' => $informasi->konten_or_file,
            'published_at'   => $informasi->published_at?->format('Y-m-d H:i:s'),
        ]);
    }

    // DELETE /api/admin/informasi-ta/{id}
    public function destroy(int $id): JsonResponse
    {
        $informasi = InformasiTA::findOrFail($id);
        $judul = $informasi->judul;

        // Hapus notifikasi yang berhubungan dengan informasi TA ini
        Notifikasi::where('ref_tabel', 'informasi_ta')
            ->where('ref_id', $informasi->info_id)
            ->delete();

        $informasi->delete();

        return $this->successResponse("Informasi TA \"{$judul}\" berhasil dihapus.");
    }

    private function kirimNotifikasiInformasiTA(InformasiTA $informasi): void
    {
        Notifikasi::where('ref_tabel', 'informasi_ta')
            ->where('ref_id', $informasi->info_id)
            ->delete();

        $userIds = User::whereIn('role', ['mahasiswa', 'dosen'])
            ->where('status_akun', 'aktif')
            ->pluck('user_id')
            ->toArray();

        if (empty($userIds)) {
            return;
        }

        $konten = trim((string) $informasi->konten_or_file);

        $pesan = $konten !== ''
            ? $konten
            : "Informasi TA kategori {$informasi->kategori} telah dipublikasikan.";

        NotifikasiService::kirimKeBanyak(
            userIds: $userIds,
            tipe: 'informasi_ta',
            judul: 'Informasi TA: ' . $informasi->judul,
            pesan: $pesan,
            refTabel: 'informasi_ta',
            refId: $informasi->info_id
        );
    }
}