<?php
// app/Policies/AnotasiDokumenPolicy.php

namespace App\Policies;

use App\Models\AnotasiDokumen;
use App\Models\User;
use App\Models\VersiDokumen;

/**
 * Authorization policy for document annotations (T-09, T-71, T-10, T-11).
 *
 * Rules:
 * - create: only the supervising professor of the bimbingan
 * - viewAny: student owner, supervising professor, or admin
 * - view: student owner, supervising professor, or admin
 * - reply: student owner or supervising professor of the bimbingan
 * - markRevised: student owner of the bimbingan only
 * - resolve: supervising professor of the bimbingan only (student gets 403)
 */
class AnotasiDokumenPolicy
{
    public function viewAny(User $user, VersiDokumen $versi): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        $bimbingan = $versi->dokumen?->bimbingan;
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

    public function view(User $user, AnotasiDokumen $anotasi): bool
    {
        $versi = $anotasi->versiDokumen;
        if (! $versi) {
            return false;
        }

        return $this->viewAny($user, $versi);
    }

    public function create(User $user, VersiDokumen $versi): bool
    {
        if (! $user->isDosen() || ! $user->dosen) {
            return false;
        }

        $bimbingan = $versi->dokumen?->bimbingan;
        if (! $bimbingan) {
            return false;
        }

        return (int) $bimbingan->dosen_id === (int) $user->dosen->dosen_id;
    }

    public function reply(User $user, AnotasiDokumen $anotasi): bool
    {
        $bimbingan = $anotasi->versiDokumen?->dokumen?->bimbingan;
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

    public function markRevised(User $user, AnotasiDokumen $anotasi): bool
    {
        if (! $user->isMahasiswa() || ! $user->mahasiswa) {
            return false;
        }

        $bimbingan = $anotasi->versiDokumen?->dokumen?->bimbingan;
        if (! $bimbingan) {
            return false;
        }

        return (int) $bimbingan->mahasiswa_id === (int) $user->mahasiswa->mahasiswa_id;
    }

    public function resolve(User $user, AnotasiDokumen $anotasi): bool
    {
        if (! $user->isDosen() || ! $user->dosen) {
            return false;
        }

        $bimbingan = $anotasi->versiDokumen?->dokumen?->bimbingan;
        if (! $bimbingan) {
            return false;
        }

        return (int) $bimbingan->dosen_id === (int) $user->dosen->dosen_id;
    }
}
