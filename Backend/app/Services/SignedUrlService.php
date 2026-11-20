<?php
// app/Services/SignedUrlService.php

namespace App\Services;

use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\URL;

/**
 * Issues signed, short-lived URLs for TA documents (T-02).
 *
 * Signing uses Laravel's native signed routes: HMAC-SHA256 over the absolute
 * URL (including the `expires` query parameter) keyed with the application
 * key. There is no custom HMAC scheme here on purpose — the framework's
 * `signed` middleware and `URL::hasValidSignature()` are the implementation.
 *
 * TTL is 15 minutes (product decision, T-02).
 */
class SignedUrlService
{
    /** Lifetime of every issued document link, in minutes. */
    public const TTL_MINUTES = 15;

    /**
     * Absolute expiration timestamp for a link issued right now.
     */
    public function expiry(): Carbon
    {
        return now()->addMinutes(self::TTL_MINUTES);
    }

    /**
     * Full payload for `GET /api/v1/dokumen/signed-url/{versi_id}`.
     *
     * @return array{url: string, expires_at: string}
     */
    public function forVersi(int $versiId): array
    {
        $expiresAt = $this->expiry();

        return [
            'url'        => $this->buildUrl($versiId, $expiresAt),
            'expires_at' => $expiresAt->toIso8601String(),
        ];
    }

    /**
     * Just the signed URL — used wherever the API used to return
     * `Storage::url(...)` in a `file_url` field, and by the Blade views.
     */
    public function fileUrl(int $versiId): string
    {
        return $this->buildUrl($versiId, $this->expiry());
    }

    private function buildUrl(int $versiId, Carbon $expiresAt): string
    {
        return URL::temporarySignedRoute(
            'dokumen.file',
            $expiresAt,
            ['versi_id' => $versiId]
        );
    }
}
