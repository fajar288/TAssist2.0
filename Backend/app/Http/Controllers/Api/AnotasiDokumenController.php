<?php
// app/Http/Controllers/Api/AnotasiDokumenController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Anotasi\ReplyAnotasiRequest;
use App\Http\Requests\Dosen\StoreAnotasiRequest;
use App\Models\AnotasiDokumen;
use App\Models\DokumenTA;
use App\Models\VersiDokumen;
use App\Services\NotifikasiService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;

class AnotasiDokumenController extends Controller
{
    use ApiResponse;

    /**
     * Dosen creates a top-level annotation on a PDF document version (T-09, F-ANN-01).
     */
    public function store(StoreAnotasiRequest $request): JsonResponse
    {
        $versi = VersiDokumen::with([
            'dokumen.bimbingan.mahasiswa',
            'dokumen.bimbingan.dosen',
        ])->findOrFail($request->versi_id);

        Gate::authorize('create', [AnotasiDokumen::class, $versi]);

        // PDF-only validation (T-09)
        $filePath = strtolower($versi->file_url_or_path ?? '');
        if (! str_ends_with($filePath, '.pdf')) {
            return $this->errorResponse('Anotasi hanya dapat dibuat untuk dokumen berformat PDF.', null, 422);
        }

        $anotasi = DB::transaction(function () use ($request, $versi) {
            $created = AnotasiDokumen::create([
                'versi_id'     => $versi->versi_id,
                'dosen_id'     => $request->user()->dosen?->dosen_id,
                'user_id'      => $request->user()->user_id,
                'parent_id'    => null,
                'halaman'      => $request->halaman,
                'x'            => $request->x,
                'y'            => $request->y,
                'lebar'        => $request->lebar,
                'tinggi'       => $request->tinggi,
                'tipe'         => $request->tipe,
                'konten'       => $request->konten,
                'data_coretan' => $request->data_coretan,
                'status'       => 'open',
            ]);

            $versi->increment('jumlah_anotasi_terbuka');

            $studentUserId = $versi->dokumen?->bimbingan?->mahasiswa?->user_id;
            if ($studentUserId) {
                NotifikasiService::kirim(
                    $studentUserId,
                    'anotasi_baru',
                    'Anotasi Dokumen Baru',
                    'Dosen pembimbing telah menambahkan anotasi baru pada dokumen Anda.',
                    'anotasi_dokumen',
                    $created->anotasi_id
                );
            }

            return $created;
        });

        return $this->successResponse(
            'Anotasi berhasil dibuat.',
            $anotasi->load(['user:user_id,nama,role', 'dosen.user:user_id,nama', 'replies']),
            201
        );
    }

    /**
     * Mahasiswa views annotations on their document version (T-09, F-ANN-02).
     */
    public function indexMahasiswa(Request $request, int $versiId): JsonResponse
    {
        return $this->fetchAnnotations($request, $versiId);
    }

    /**
     * Dosen views annotations on their supervised student's document version (T-09, F-ANN-02).
     */
    public function indexDosen(Request $request, int $versiId): JsonResponse
    {
        return $this->fetchAnnotations($request, $versiId);
    }

    /**
     * Shared fetch logic for version annotations.
     */
    private function fetchAnnotations(Request $request, int $versiId): JsonResponse
    {
        $versi = VersiDokumen::with([
            'dokumen.bimbingan.mahasiswa',
            'dokumen.bimbingan.dosen',
        ])->findOrFail($versiId);

        Gate::authorize('viewAny', [AnotasiDokumen::class, $versi]);

        $query = AnotasiDokumen::with([
            'user:user_id,nama,role',
            'dosen.user:user_id,nama',
            'replies.user:user_id,nama,role',
            'replies.dosen.user:user_id,nama',
        ])
            ->where('versi_id', $versiId)
            ->whereNull('parent_id');

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('tipe')) {
            $query->where('tipe', $request->tipe);
        }

        if ($request->filled('halaman')) {
            $query->where('halaman', (int) $request->halaman);
        }

        $anotasi = $query->orderBy('halaman')->orderBy('created_at')->get();

        return $this->successResponse('Daftar anotasi berhasil diambil.', $anotasi);
    }

    /**
     * Mahasiswa marks an annotation as addressed/revised (T-10, F-ANN-04).
     */
    public function markRevised(Request $request, int $id): JsonResponse
    {
        $anotasi = AnotasiDokumen::with([
            'versiDokumen.dokumen.bimbingan.dosen',
            'versiDokumen.dokumen.bimbingan.mahasiswa',
        ])->findOrFail($id);

        Gate::authorize('markRevised', $anotasi);

        if ($anotasi->status !== 'open') {
            return $this->errorResponse('Hanya anotasi berstatus open yang dapat ditandai sebagai revised.', null, 422);
        }

        DB::transaction(function () use ($anotasi) {
            $anotasi->update(['status' => 'revised']);

            $dosenUserId = $anotasi->versiDokumen?->dokumen?->bimbingan?->dosen?->user_id;
            if ($dosenUserId) {
                NotifikasiService::kirim(
                    $dosenUserId,
                    'anotasi_direvisi',
                    'Anotasi Telah Direvisi',
                    'Mahasiswa bimbingan telah menandai anotasi sebagai direvisi.',
                    'anotasi_dokumen',
                    $anotasi->anotasi_id
                );
            }
        });

        return $this->successResponse('Anotasi berhasil ditandai sebagai revised.', $anotasi->fresh(['user', 'replies']));
    }

    /**
     * Dosen resolves an annotation (T-10, F-ANN-04).
     * Decrements versi_dokumen.jumlah_anotasi_terbuka.
     */
    public function resolve(Request $request, int $id): JsonResponse
    {
        $anotasi = AnotasiDokumen::with([
            'versiDokumen.dokumen.bimbingan.dosen',
            'versiDokumen.dokumen.bimbingan.mahasiswa',
        ])->findOrFail($id);

        Gate::authorize('resolve', $anotasi);

        DB::transaction(function () use ($anotasi) {
            $wasResolved = ($anotasi->status === 'resolved');

            $anotasi->update(['status' => 'resolved']);

            if (! $wasResolved) {
                $versi = $anotasi->versiDokumen;
                if ($versi && $versi->jumlah_anotasi_terbuka > 0) {
                    $versi->decrement('jumlah_anotasi_terbuka');
                }
            }

            $studentUserId = $anotasi->versiDokumen?->dokumen?->bimbingan?->mahasiswa?->user_id;
            if ($studentUserId) {
                NotifikasiService::kirim(
                    $studentUserId,
                    'anotasi_selesai',
                    'Anotasi Telah Diselesaikan',
                    'Dosen pembimbing telah mengonfirmasi anotasi selesai.',
                    'anotasi_dokumen',
                    $anotasi->anotasi_id
                );
            }
        });

        return $this->successResponse('Anotasi berhasil diselesaikan.', $anotasi->fresh(['user', 'replies']));
    }

    /**
     * Threaded reply to an annotation (T-11, F-ANN-03).
     * Parent annotation status remains unchanged.
     */
    public function reply(ReplyAnotasiRequest $request, int $id): JsonResponse
    {
        $parent = AnotasiDokumen::with([
            'versiDokumen.dokumen.bimbingan.mahasiswa',
            'versiDokumen.dokumen.bimbingan.dosen',
        ])->findOrFail($id);

        Gate::authorize('reply', $parent);

        // Keep replies attached to the root parent
        $rootId = $parent->parent_id ?: $parent->anotasi_id;
        $rootAnotasi = AnotasiDokumen::findOrFail($rootId);

        $reply = DB::transaction(function () use ($request, $rootAnotasi) {
            $created = AnotasiDokumen::create([
                'versi_id'     => $rootAnotasi->versi_id,
                'user_id'      => $request->user()->user_id,
                'dosen_id'     => $request->user()->dosen?->dosen_id,
                'parent_id'    => $rootAnotasi->anotasi_id,
                'halaman'      => $rootAnotasi->halaman,
                'x'            => $rootAnotasi->x,
                'y'            => $rootAnotasi->y,
                'tipe'         => 'komentar',
                'konten'       => $request->konten,
                'status'       => $rootAnotasi->status, // Parent status remains unchanged
            ]);

            $bimbingan = $rootAnotasi->versiDokumen?->dokumen?->bimbingan;
            $targetUserId = ($request->user()->isMahasiswa())
                ? $bimbingan?->dosen?->user_id
                : $bimbingan?->mahasiswa?->user_id;

            if ($targetUserId) {
                NotifikasiService::kirim(
                    $targetUserId,
                    'anotasi_balasan',
                    'Balasan Anotasi Baru',
                    $request->user()->nama . ' membalas anotasi dokumen.',
                    'anotasi_dokumen',
                    $rootAnotasi->anotasi_id
                );
            }

            return $created;
        });

        return $this->successResponse(
            'Balasan anotasi berhasil dikirim.',
            $reply->load('user:user_id,nama,role'),
            201
        );
    }

    /**
     * Cross-version annotation summary for a document (T-12, F-ANN-05).
     */
    public function summary(Request $request, int $dokumenId): JsonResponse
    {
        $dokumen = DokumenTA::with([
            'bimbingan.mahasiswa',
            'bimbingan.dosen',
            'versiDokumen' => fn ($q) => $q->orderBy('nomor_versi', 'asc'),
        ])->findOrFail($dokumenId);

        $user = $request->user();
        $bimbingan = $dokumen->bimbingan;

        $isOwner = $bimbingan && $user->mahasiswa && (int) $bimbingan->mahasiswa_id === (int) $user->mahasiswa->mahasiswa_id;
        $isDosen = $bimbingan && $user->dosen && (int) $bimbingan->dosen_id === (int) $user->dosen->dosen_id;

        if (! $user->isAdmin() && ! $isOwner && ! $isDosen) {
            abort(403, 'Anda tidak memiliki akses ke ringkasan dokumen ini.');
        }

        $versiSummary = $dokumen->versiDokumen->map(function ($v) {
            $open = AnotasiDokumen::where('versi_id', $v->versi_id)
                ->whereNull('parent_id')
                ->where('status', 'open')
                ->count();

            $revised = AnotasiDokumen::where('versi_id', $v->versi_id)
                ->whereNull('parent_id')
                ->where('status', 'revised')
                ->count();

            $resolved = AnotasiDokumen::where('versi_id', $v->versi_id)
                ->whereNull('parent_id')
                ->where('status', 'resolved')
                ->count();

            return [
                'versi_id'               => $v->versi_id,
                'nomor_versi'            => $v->nomor_versi,
                'file_name'              => basename($v->file_url_or_path ?? ''),
                'uploaded_at'            => $v->uploaded_at?->format('Y-m-d H:i:s'),
                'status_versi'           => $v->status_versi,
                'open'                   => $open,
                'revised'                => $revised,
                'resolved'               => $resolved,
                'total'                  => $open + $revised + $resolved,
                'jumlah_anotasi_terbuka' => $v->jumlah_anotasi_terbuka,
            ];
        });

        return $this->successResponse('Ringkasan anotasi dokumen berhasil diambil.', [
            'dokumen_id'   => $dokumen->dokumen_id,
            'nama_dokumen' => $dokumen->nama_dokumen,
            'versi'        => $versiSummary,
        ]);
    }
}
