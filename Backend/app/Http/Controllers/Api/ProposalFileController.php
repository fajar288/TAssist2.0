<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PermohonanBimbingan;
use App\Services\SignedUrlService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Signed access to optional proposal PDF attachments on guidance requests (T-38).
 */
class ProposalFileController extends Controller
{
    use ApiResponse;

    public function __construct(private SignedUrlService $signedUrls)
    {
    }

    public function signedUrl(Request $request, int $id): JsonResponse
    {
        $permohonan = PermohonanBimbingan::with(['mahasiswa', 'dosen'])->findOrFail($id);

        Gate::authorize('viewProposal', $permohonan);

        if (! $permohonan->file_proposal) {
            return $this->errorResponse('Permohonan ini tidak memiliki lampiran proposal.', null, 404);
        }

        return $this->successResponse(
            'Signed URL proposal berhasil dibuat',
            $this->signedUrls->forProposal($permohonan->permohonan_id)
        )->header('Access-Control-Allow-Origin', '*');
    }

    public function show(int $id): StreamedResponse
    {
        $permohonan = PermohonanBimbingan::find($id);

        if (! $permohonan || ! $permohonan->file_proposal) {
            abort(404);
        }

        $disk = Storage::disk('dokumen');
        $path = $permohonan->file_proposal;

        if (! $disk->exists($path)) {
            abort(404);
        }

        return $disk->response($path, basename($path), [
            'Content-Type'                => $disk->mimeType($path) ?: 'application/pdf',
            'Access-Control-Allow-Origin' => '*',
            'Cache-Control'               => 'private, max-age=0',
        ], 'inline');
    }
}
