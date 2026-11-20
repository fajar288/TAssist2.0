<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BeritaAcara;
use App\Models\Bimbingan;
use App\Services\BeritaAcaraService;
use App\Services\SignedUrlService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class BeritaAcaraController extends Controller
{
    use ApiResponse;

    public function __construct(
        protected BeritaAcaraService $beritaAcaraService,
        protected SignedUrlService $signedUrlService
    ) {}

    /**
     * Dosen generates draft Berita Acara for a supervision (T-17, F-BA-01).
     * POST /api/v1/dosen/bimbingan/{id}/berita-acara
     */
    public function generate(Request $request, int|string $id): JsonResponse
    {
        $request->validate([
            'periode_mulai'   => ['required', 'date'],
            'periode_selesai' => ['required', 'date', 'after_or_equal:periode_mulai'],
        ], [
            'periode_mulai.required'   => 'Tanggal mulai periode wajib diisi.',
            'periode_selesai.required' => 'Tanggal selesai periode wajib diisi.',
            'periode_selesai.after_or_equal' => 'Tanggal selesai tidak boleh sebelum tanggal mulai.',
        ]);

        $bimbingan = Bimbingan::with(['mahasiswa.user', 'dosen.user'])->findOrFail($id);

        Gate::authorize('create', [BeritaAcara::class, $bimbingan]);

        $ba = $this->beritaAcaraService->createDraft(
            $bimbingan,
            $request->periode_mulai,
            $request->periode_selesai
        );

        $ba->download_url = $this->signedUrlService->beritaAcaraFileUrl($ba->berita_acara_id);

        return $this->successResponse(
            'Berita Acara berhasil dibuat (status draft).',
            $ba,
            201
        );
    }

    /**
     * Dosen approves Berita Acara with PIN or drawn signature image (T-18, F-BA-02).
     * PUT /api/v1/dosen/berita-acara/{id}/approve
     */
    public function approve(Request $request, int|string $id): JsonResponse
    {
        $request->validate([
            'metode'        => ['required', 'in:pin,tanda_tangan'],
            'pin'           => ['required_if:metode,pin', 'nullable', 'string'],
            'tanda_tangan'  => ['required_if:metode,tanda_tangan', 'nullable', 'image', 'max:2048'],
        ], [
            'metode.required'               => 'Metode persetujuan wajib dipilih.',
            'metode.in'                     => 'Metode persetujuan harus berupa pin atau tanda_tangan.',
            'pin.required_if'               => 'PIN dosen wajib diisi jika metode adalah PIN.',
            'tanda_tangan.required_if'      => 'Gambar tanda tangan wajib diunggah jika metode adalah tanda tangan.',
            'tanda_tangan.image'            => 'File tanda tangan harus berupa gambar (PNG/JPG).',
            'tanda_tangan.max'              => 'Ukuran file tanda tangan maksimal 2MB.',
        ]);

        $ba = BeritaAcara::with('bimbingan.dosen')->findOrFail($id);

        Gate::authorize('approve', $ba);

        $dosen = $request->user()->dosen;
        if (! $dosen) {
            return $this->forbiddenResponse('Hanya dosen yang dapat menyetujui Berita Acara.');
        }

        $approvedBa = $this->beritaAcaraService->approve(
            $ba,
            $dosen,
            $request->metode,
            $request->pin,
            $request->file('tanda_tangan')
        );

        $approvedBa->download_url = $this->signedUrlService->beritaAcaraFileUrl($approvedBa->berita_acara_id);

        return $this->successResponse(
            'Berita Acara berhasil disetujui.',
            $approvedBa
        );
    }

    /**
     * Dosen lists all Berita Acara for a supervision (T-20, F-BA-04).
     * GET /api/v1/dosen/bimbingan/{id}/berita-acara
     */
    public function listDosen(Request $request, int|string $id): JsonResponse
    {
        $bimbingan = Bimbingan::findOrFail($id);

        Gate::authorize('viewAny', [BeritaAcara::class, $bimbingan]);

        $list = BeritaAcara::where('bimbingan_id', $bimbingan->bimbingan_id)
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($ba) {
                $ba->download_url = $this->signedUrlService->beritaAcaraFileUrl($ba->berita_acara_id);
                return $ba;
            });

        return $this->successResponse(
            'Daftar Berita Acara berhasil diambil.',
            $list
        );
    }

    /**
     * Mahasiswa views Berita Acara for their supervision (T-20, F-BA-04).
     * GET /api/v1/mahasiswa/bimbingan/{id}/berita-acara
     */
    public function listMahasiswa(Request $request, int|string $id): JsonResponse
    {
        $bimbingan = Bimbingan::findOrFail($id);

        Gate::authorize('viewAny', [BeritaAcara::class, $bimbingan]);

        $list = BeritaAcara::where('bimbingan_id', $bimbingan->bimbingan_id)
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($ba) {
                $ba->download_url = $this->signedUrlService->beritaAcaraFileUrl($ba->berita_acara_id);
                return $ba;
            });

        return $this->successResponse(
            'Daftar Berita Acara berhasil diambil.',
            $list
        );
    }

    /**
     * Issues signed URL for downloading Berita Acara PDF (T-20, F-BA-04).
     * GET /api/v1/berita-acara/{id}/download
     */
    public function download(Request $request, int|string $id): JsonResponse
    {
        $ba = BeritaAcara::with('bimbingan')->findOrFail($id);

        Gate::authorize('download', $ba);

        $payload = $this->signedUrlService->forBeritaAcara($ba->berita_acara_id);

        return $this->successResponse(
            'URL unduhan Berita Acara berhasil dibuat.',
            $payload
        );
    }

    /**
     * Serves Berita Acara PDF binary via signed URL (T-20, F-DOC-06).
     * GET /api/v1/berita-acara/{id}/file
     */
    public function showFile(Request $request, int|string $id): BinaryFileResponse
    {
        $ba = BeritaAcara::findOrFail($id);

        if (! Storage::exists($ba->file_path)) {
            abort(404, 'File Berita Acara tidak ditemukan pada media penyimpanan.');
        }

        $fullPath = Storage::path($ba->file_path);
        $fileName = basename($ba->file_path);

        return response()->file($fullPath, [
            'Content-Type'        => 'application/pdf',
            'Content-Disposition' => 'inline; filename="' . $fileName . '"',
            'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => 'GET, OPTIONS',
            'Access-Control-Allow-Headers' => '*',
        ]);
    }
}
