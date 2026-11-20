<?php
// app/Http/Controllers/Api/Mahasiswa/InformasiTAController.php

namespace App\Http\Controllers\Api\Mahasiswa;

use App\Http\Controllers\Controller;
use App\Models\InformasiTA;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InformasiTAController extends Controller
{
    use ApiResponse;

    /**
     * Student views published TA announcements/information (T-14).
     * Only published_at <= now() entries are returned.
     */
    public function index(Request $request): JsonResponse
    {
        $query = InformasiTA::with('admin.user')
            ->whereNotNull('published_at')
            ->where('published_at', '<=', now())
            ->when($request->filled('kategori'), fn ($q) => $q->where('kategori', $request->kategori))
            ->when($request->filled('search'), fn ($q) => $q->where('judul', 'like', '%' . $request->search . '%'))
            ->orderByDesc('published_at');

        $perPage = (int) $request->get('per_page', 10);
        $paginated = $query->paginate($perPage);

        $data = $paginated->through(fn ($i) => [
            'info_id'        => $i->info_id,
            'kategori'       => $i->kategori,
            'judul'          => $i->judul,
            'konten_or_file' => $i->konten_or_file,
            'published_at'   => $i->published_at?->format('Y-m-d H:i:s'),
            'created_at'     => $i->created_at?->format('Y-m-d H:i:s'),
            'penulis'        => $i->admin?->user?->nama ?? 'Admin TA',
        ]);

        return $this->successResponse('Daftar informasi TA berhasil diambil.', $data);
    }

    /**
     * Student views a single published TA announcement detail.
     */
    public function show(int $id): JsonResponse
    {
        $informasi = InformasiTA::with('admin.user')
            ->whereNotNull('published_at')
            ->where('published_at', '<=', now())
            ->findOrFail($id);

        return $this->successResponse('Detail informasi TA berhasil diambil.', [
            'info_id'        => $informasi->info_id,
            'kategori'       => $informasi->kategori,
            'judul'          => $informasi->judul,
            'konten_or_file' => $informasi->konten_or_file,
            'published_at'   => $informasi->published_at?->format('Y-m-d H:i:s'),
            'created_at'     => $informasi->created_at?->format('Y-m-d H:i:s'),
            'penulis'        => $informasi->admin?->user?->nama ?? 'Admin TA',
        ]);
    }
}
