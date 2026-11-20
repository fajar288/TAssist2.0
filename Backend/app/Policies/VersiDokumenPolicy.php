<?php
// app/Policies/VersiDokumenPolicy.php

namespace App\Policies;

use App\Models\User;
use App\Models\VersiDokumen;

/**
 * Who may read a document version (T-02).
 *
 * Allowed: the student who owns the supervision, the professor supervising
 * that bimbingan, and any admin. Everyone else is denied.
 *
 * Auto-discovered by the Gate: App\Models\VersiDokumen → this class.
 */
class VersiDokumenPolicy
{
    public function view(User $user, VersiDokumen $versi): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        $bimbingan = $versi->dokumen?->bimbingan;

        if (! $bimbingan) {
            return false;
        }

        $pemilikUserId = $bimbingan->mahasiswa?->user_id;

        if ($pemilikUserId !== null && (int) $pemilikUserId === (int) $user->user_id) {
            return true;
        }

        $pembimbingUserId = $bimbingan->dosen?->user_id;

        return $pembimbingUserId !== null && (int) $pembimbingUserId === (int) $user->user_id;
    }
}
