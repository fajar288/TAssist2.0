<?php
// app/Services/NotifikasiService.php

namespace App\Services;

use App\Jobs\SendFcmNotificationJob;
use App\Models\Notifikasi;

class NotifikasiService
{
    /**
     * Kirim notifikasi ke satu user (in-app + queued FCM push).
     */
    public static function kirim(
        int $userId,
        string $tipe,
        string $judul,
        string $pesan,
        ?string $refTabel = null,
        ?int $refId = null
    ): Notifikasi {
        $notifikasi = Notifikasi::create([
            'user_id'         => $userId,
            'tipe_notifikasi' => $tipe,
            'judul'           => $judul,
            'pesan'           => $pesan,
            'ref_tabel'       => $refTabel,
            'ref_id'          => $refId,
            'is_read'         => false,
        ]);

        SendFcmNotificationJob::dispatch($userId, $judul, $pesan, [
            'notifikasi_id'   => (string) $notifikasi->notifikasi_id,
            'tipe_notifikasi' => $tipe,
            'ref_tabel'       => (string) ($refTabel ?? ''),
            'ref_id'          => (string) ($refId ?? ''),
        ]);

        return $notifikasi;
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