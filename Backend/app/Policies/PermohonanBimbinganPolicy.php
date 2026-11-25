<?php

namespace App\Policies;

use App\Models\PermohonanBimbingan;
use App\Models\User;

/**
 * Authorization policy for proposal attachments on guidance requests (T-38).
 *
 * Allowed: requesting student, target supervisor, or admin.
 */
class PermohonanBimbinganPolicy
{
    public function viewProposal(User $user, PermohonanBimbingan $permohonan): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        if ($user->isMahasiswa() && $user->mahasiswa) {
            return (int) $permohonan->mahasiswa_id === (int) $user->mahasiswa->mahasiswa_id;
        }

        if ($user->isDosen() && $user->dosen) {
            return (int) $permohonan->dosen_id === (int) $user->dosen->dosen_id;
        }

        return false;
    }
}
