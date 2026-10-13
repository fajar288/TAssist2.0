<?php
// app/Http/Controllers/Api/NotifikasiController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notifikasi;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotifikasiController extends Controller
{
    use ApiResponse;

    // GET /api/mahasiswa/notifikasi atau GET /api/dosen/notifikasi
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $notifikasi = Notifikasi::where('user_id', $user->user_id)
            ->when($request->boolean('unread_only'), fn($q) => $q->where('is_read', false))
            ->orderByDesc('created_at')
            ->paginate($request->get('per_page', 15));

        $unreadCount = Notifikasi::where('user_id', $user->user_id)
            ->where('is_read', false)
            ->count();

        $data = $notifikasi->through(fn($n) => [
            'notifikasi_id'   => $n->notifikasi_id,
            'tipe_notifikasi' => $n->tipe_notifikasi,
            'judul'           => $n->judul,
            'pesan'           => $n->pesan,
            'ref_tabel'       => $n->ref_tabel,
            'ref_id'          => $n->ref_id,
            'is_read'         => $n->is_read,
            'created_at'      => $n->created_at->format('Y-m-d H:i:s'),
        ]);

        return $this->successResponse('Notifikasi berhasil diambil', [
            'unread_count' => $unreadCount,
            'notifikasi'   => $data,
        ]);
    }

    // PUT /api/notifikasi/{id}/read — Tandai satu notifikasi sebagai dibaca
    public function markAsRead(Request $request, int $id): JsonResponse
    {
        $notifikasi = Notifikasi::where('notifikasi_id', $id)
            ->where('user_id', $request->user()->user_id)
            ->firstOrFail();

        $notifikasi->update(['is_read' => true]);

        return $this->successResponse('Notifikasi ditandai sebagai dibaca.');
    }

    // PUT /api/notifikasi/read-all — Tandai semua notifikasi sebagai dibaca
    public function markAllAsRead(Request $request): JsonResponse
    {
        Notifikasi::where('user_id', $request->user()->user_id)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return $this->successResponse('Semua notifikasi ditandai sebagai dibaca.');
    }
}