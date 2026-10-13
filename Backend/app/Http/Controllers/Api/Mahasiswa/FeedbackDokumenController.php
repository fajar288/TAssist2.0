<?php
// app/Http/Controllers/Api/Mahasiswa/FeedbackDokumenController.php

namespace App\Http\Controllers\Api\Mahasiswa;

use App\Http\Controllers\Controller;
use App\Models\Bimbingan;
use App\Models\FeedbackDokumen;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class FeedbackDokumenController extends Controller
{
    use ApiResponse;

    // GET /api/mahasiswa/feedback
    public function index(Request $request): JsonResponse
    {
        $mahasiswa = $request->user()->mahasiswa;

        if (!$mahasiswa) {
            return $this->errorResponse('Data mahasiswa tidak ditemukan.', null, 404);
        }

        // Ambil bimbingan aktif mahasiswa
        $bimbinganIds = Bimbingan::where('mahasiswa_id', $mahasiswa->mahasiswa_id)
            ->pluck('bimbingan_id');

        $feedback = FeedbackDokumen::with([
                'versiDokumen.dokumen',
                'dosen.user',
            ])
            ->whereHas('versiDokumen.dokumen.bimbingan', function ($q) use ($bimbinganIds) {
                $q->whereIn('bimbingan_id', $bimbinganIds);
            })
            ->orderByDesc('created_at')
            ->paginate($request->get('per_page', 10));

        $data = $feedback->through(function ($f) {
            return [
                'feedback_id'    => $f->feedback_id,
                'komentar'       => $f->komentar,
                'halaman'        => $f->halaman,
                'posisi_anotasi' => $f->posisi_anotasi,
                'created_at'     => $f->created_at->format('Y-m-d H:i:s'),
                'dosen'          => [
                    'dosen_id' => $f->dosen->dosen_id,
                    'nama'     => $f->dosen->user->nama,
                ],
                'dokumen'        => [
                    'dokumen_id'    => $f->versiDokumen->dokumen->dokumen_id,
                    'judul_dokumen' => $f->versiDokumen->dokumen->judul_dokumen,
                    'nomor_versi'   => $f->versiDokumen->nomor_versi,
                    'file_url'      => Storage::url($f->versiDokumen->file_url_or_path),
                ],
            ];
        });

        return $this->successResponse('Daftar feedback berhasil diambil', $data);
    }
}