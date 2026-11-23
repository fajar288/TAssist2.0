<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\BasisPengetahuanTA;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BasisPengetahuanController extends Controller
{
    use ApiResponse;

    /**
     * Display a listing of knowledge base entries (T-29, F-BOT-01).
     * GET /api/v1/admin/basis-pengetahuan
     */
    public function index(Request $request): JsonResponse
    {
        $query = BasisPengetahuanTA::query();

        if ($request->filled('kategori')) {
            $query->where('kategori', $request->kategori);
        }

        if ($request->filled('q')) {
            $search = $request->q;
            $query->where(function ($q) use ($search) {
                $q->where('judul', 'like', "%{$search}%")
                  ->orWhere('konten', 'like', "%{$search}%");
            });
        }

        if ($request->has('is_active')) {
            $query->where('is_active', filter_var($request->is_active, FILTER_VALIDATE_BOOLEAN));
        }

        $items = $query->orderBy('kategori')->orderBy('judul')->paginate(15);

        return $this->successResponse('Data basis pengetahuan berhasil diambil.', $items);
    }

    /**
     * Store a new knowledge base entry (T-29).
     * POST /api/v1/admin/basis-pengetahuan
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'kategori' => ['required', 'string', 'max:50'],
            'judul' => ['required', 'string', 'max:255'],
            'konten' => ['required', 'string'],
            'tags' => ['nullable', 'array'],
            'tags.*' => ['string', 'max:50'],
            'is_active' => ['nullable', 'boolean'],
        ], [
            'kategori.required' => 'Kategori wajib diisi.',
            'judul.required' => 'Judul wajib diisi.',
            'konten.required' => 'Konten wajib diisi.',
        ]);

        $item = BasisPengetahuanTA::create([
            'kategori' => $validated['kategori'],
            'judul' => $validated['judul'],
            'konten' => $validated['konten'],
            'tags' => $validated['tags'] ?? [],
            'is_active' => $validated['is_active'] ?? true,
        ]);

        return $this->successResponse('Entri basis pengetahuan berhasil ditambahkan.', $item, 201);
    }

    /**
     * Show knowledge base entry detail.
     * GET /api/v1/admin/basis-pengetahuan/{id}
     */
    public function show(int $id): JsonResponse
    {
        $item = BasisPengetahuanTA::find($id);
        if (!$item) {
            return $this->notFoundResponse('Entri basis pengetahuan tidak ditemukan.');
        }

        return $this->successResponse('Detail basis pengetahuan berhasil diambil.', $item);
    }

    /**
     * Update knowledge base entry.
     * PUT /api/v1/admin/basis-pengetahuan/{id}
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $item = BasisPengetahuanTA::find($id);
        if (!$item) {
            return $this->notFoundResponse('Entri basis pengetahuan tidak ditemukan.');
        }

        $validated = $request->validate([
            'kategori' => ['sometimes', 'required', 'string', 'max:50'],
            'judul' => ['sometimes', 'required', 'string', 'max:255'],
            'konten' => ['sometimes', 'required', 'string'],
            'tags' => ['nullable', 'array'],
            'tags.*' => ['string', 'max:50'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $item->update($validated);

        return $this->successResponse('Entri basis pengetahuan berhasil diperbarui.', $item);
    }

    /**
     * Delete knowledge base entry.
     * DELETE /api/v1/admin/basis-pengetahuan/{id}
     */
    public function destroy(int $id): JsonResponse
    {
        $item = BasisPengetahuanTA::find($id);
        if (!$item) {
            return $this->notFoundResponse('Entri basis pengetahuan tidak ditemukan.');
        }

        $item->delete();

        return $this->successResponse('Entri basis pengetahuan berhasil dihapus.');
    }
}
