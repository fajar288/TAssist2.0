<?php
// app/Http/Controllers/Api/DokumenFileController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\VersiDokumen;
use App\Services\SignedUrlService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

/**
 * Signed access to TA documents (T-02).
 *
 * Two routes:
 *  - `GET /api/v1/dokumen/signed-url/{versi_id}` — authenticated, issues a
 *    15-minute signed URL after the policy says the caller may read the file.
 *  - `GET /api/v1/dokumen/{versi_id}/file` — signature-only. It deliberately
 *    has NO auth middleware: Flutter Web and the PDF viewer fetch it without
 *    an `Authorization` header, so the HMAC signature is the credential.
 */
class DokumenFileController extends Controller
{
    use ApiResponse;

    public function __construct(private SignedUrlService $signedUrls)
    {
    }

    /**
     * Issue a signed URL for one document version.
     */
    public function signedUrl(Request $request, int $versiId): JsonResponse
    {
        $versi = VersiDokumen::with([
            'dokumen.bimbingan.mahasiswa',
            'dokumen.bimbingan.dosen',
        ])->findOrFail($versiId);

        // The only authorization gate for document bytes. The file route below
        // cannot use a session or token (browsers/PDF viewers call it directly),
        // so the check happens here and the signature carries the grant for the
        // next 15 minutes. Tampering with the URL invalidates the HMAC.
        Gate::authorize('view', $versi);

        return $this->successResponse(
            'Signed URL berhasil dibuat',
            $this->signedUrls->forVersi($versi->versi_id)
        )->header('Access-Control-Allow-Origin', '*');
    }

    /**
     * Stream the file. Reached only with a valid, unexpired signature
     * (the `signed` middleware enforces that before this method runs).
     */
    public function show(int $versiId): BinaryFileResponse
    {
        $versi = VersiDokumen::find($versiId);

        if (! $versi) {
            abort(404);
        }

        $disk = Storage::disk('dokumen');
        $path = $versi->file_url_or_path;

        if (! $path || ! $disk->exists($path)) {
            abort(404);
        }

        $response = response()->file($disk->path($path), [
            'Content-Type'                => $disk->mimeType($path) ?: 'application/octet-stream',
            // Flutter Web and the PDF viewer need this; they send no credentials.
            'Access-Control-Allow-Origin' => '*',
            'Cache-Control'               => 'private, max-age=0',
        ]);

        $response->headers->set('Content-Disposition', 'inline');

        return $response;
    }
}
