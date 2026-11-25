<?php

namespace App\Policies;

use App\Models\Bimbingan;
use App\Models\User;

/**
 * Authorization policy for supervision records & history exports (T-41).
 */
class BimbinganPolicy
{
    public function view(User $user, Bimbingan $bimbingan): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        if ($user->isMahasiswa() && $user->mahasiswa) {
            return (int) $bimbingan->mahasiswa_id === (int) $user->mahasiswa->mahasiswa_id;
        }

        if ($user->isDosen() && $user->dosen) {
            return (int) $bimbingan->dosen_id === (int) $user->dosen->dosen_id;
        }

        return false;
    }
}
