<?php
// app/Services/NotifikasiService.php

namespace App\Services;

use App\Models\Notifikasi;

class NotifikasiService
{
    /**
     * Kirim notifikasi ke satu user.
     */
    public static function kirim(
        int $userId,
        string $tipe,
        string $judul,
        string $pesan,
        ?string $refTabel = null,
        ?int $refId = null
    ): Notifikasi {
        return Notifikasi::create([
            'user_id'         => $userId,
            'tipe_notifikasi' => $tipe,
            'judul'           => $judul,
            'pesan'           => $pesan,
            'ref_tabel'       => $refTabel,
            'ref_id'          => $refId,
            'is_read'         => false,
        ]);
    }

    /**
     * Kirim notifikasi ke banyak user sekaligus.
     */
    public static function kirimKeBanyak(
        array $userIds,
        string $tipe,
        string $judul,
        string $pesan,
        ?string $refTabel = null,
        ?int $refId = null
    ): void {
        foreach ($userIds as $userId) {
            self::kirim($userId, $tipe, $judul, $pesan, $refTabel, $refId);
        }
    }
}