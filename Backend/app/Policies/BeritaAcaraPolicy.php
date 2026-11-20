<?php

namespace App\Policies;

use App\Models\BeritaAcara;
use App\Models\Bimbingan;
use App\Models\User;

/**
 * Authorization policy for Berita Acara (T-17, T-18, T-19, T-20).
 *
 * Rules:
 * - create: only the supervising professor of the bimbingan
 * - approve: only the supervising professor of the bimbingan
 * - viewAny: student owner, supervising professor, or admin
 * - view: student owner, supervising professor, or admin
 * - download: student owner, supervising professor, or admin
 */
class BeritaAcaraPolicy
{
    public function viewAny(User $user, Bimbingan $bimbingan): bool
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

    public function view(User $user, BeritaAcara $ba): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        $bimbingan = $ba->bimbingan;
        if (! $bimbingan) {
            return false;
        }

        if ($user->isMahasiswa() && $user->mahasiswa) {
            return (int) $bimbingan->mahasiswa_id === (int) $user->mahasiswa->mahasiswa_id;
        }

        if ($user->isDosen() && $user->dosen) {
            return (int) $bimbingan->dosen_id === (int) $user->dosen->dosen_id;
        }

        return false;
    }

    public function create(User $user, Bimbingan $bimbingan): bool
    {
        if (! $user->isDosen() || ! $user->dosen) {
            return false;
        }

        return (int) $bimbingan->dosen_id === (int) $user->dosen->dosen_id;
    }

    public function approve(User $user, BeritaAcara $ba): bool
    {
        if (! $user->isDosen() || ! $user->dosen) {
            return false;
        }

        return (int) $ba->bimbingan?->dosen_id === (int) $user->dosen->dosen_id;
    }

    public function download(User $user, BeritaAcara $ba): bool
    {
        return $this->view($user, $ba);
    }
}
