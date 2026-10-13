<?php
// app/Http/Controllers/Api/Dosen/FeedbackDokumenController.php

namespace App\Http\Controllers\Api\Dosen;

use App\Http\Controllers\Controller;
use App\Http\Requests\Dosen\FeedbackDokumenRequest;
use App\Models\Bimbingan;
use App\Models\FeedbackDokumen;
use App\Models\VersiDokumen;
use App\Services\NotifikasiService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class FeedbackDokumenController extends Controller
{
    use ApiResponse;

    // POST /api/dosen/feedback
    public function store(FeedbackDokumenRequest $request): JsonResponse
    {
        $dosen = $request->user()->dosen;

        if (!$dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        // Ambil versi dokumen beserta relasi
        $versi = VersiDokumen::with([
                'dokumen.bimbingan.dosen',
                'dokumen.bimbingan.mahasiswa.user',
            ])
            ->findOrFail($request->versi_id);

        $bimbingan = $versi->dokumen->bimbingan;

        // Pastikan dosen adalah pembimbing dari bimbingan ini
        if ($bimbingan->dosen_id !== $dosen->dosen_id) {
            return $this->forbiddenResponse(
                'Anda hanya dapat memberi feedback pada dokumen mahasiswa bimbingan Anda.'
            );
        }

        $feedback = FeedbackDokumen::create([
            'versi_id'       => $versi->versi_id,
            'dosen_id'       => $dosen->dosen_id,
            'komentar'       => $request->komentar,
            'halaman'        => $request->halaman,
            'posisi_anotasi' => $request->posisi_anotasi,
        ]);

        $mahasiswa = $bimbingan->mahasiswa;

        // Notifikasi ke mahasiswa
        NotifikasiService::kirim(
            userId   : $mahasiswa->user_id,
            tipe     : 'feedback_dokumen',
            judul    : 'Feedback Dokumen Baru',
            pesan    : "Dosen {$request->user()->nama} memberikan feedback pada dokumen: {$versi->dokumen->judul_dokumen} (Versi {$versi->nomor_versi})",
            refTabel : 'feedback_dokumen',
            refId    : $feedback->feedback_id
        );

        return $this->successResponse('Feedback berhasil dikirim', [
            'feedback_id'    => $feedback->feedback_id,
            'komentar'       => $feedback->komentar,
            'halaman'        => $feedback->halaman,
            'posisi_anotasi' => $feedback->posisi_anotasi,
            'created_at'     => $feedback->created_at->format('Y-m-d H:i:s'),
            'dokumen'        => [
                'dokumen_id'    => $versi->dokumen->dokumen_id,
                'judul_dokumen' => $versi->dokumen->judul_dokumen,
                'nomor_versi'   => $versi->nomor_versi,
                'file_url'      => Storage::url($versi->file_url_or_path),
            ],
            'mahasiswa'      => [
                'nama' => $mahasiswa->user->nama,
                'nim'  => $mahasiswa->nim,
            ],
        ], 201);
    }

    // GET /api/dosen/feedback — Lihat semua feedback yang pernah dosen berikan
    public function index(Request $request): JsonResponse
    {
        $dosen = $request->user()->dosen;

        if (!$dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        $feedback = FeedbackDokumen::with([
                'versiDokumen.dokumen.bimbingan.mahasiswa.user',
            ])
            ->where('dosen_id', $dosen->dosen_id)
            ->orderByDesc('created_at')
            ->paginate($request->get('per_page', 10));

        $data = $feedback->through(fn($f) => [
            'feedback_id'    => $f->feedback_id,
            'komentar'       => $f->komentar,
            'halaman'        => $f->halaman,
            'posisi_anotasi' => $f->posisi_anotasi,
            'created_at'     => $f->created_at->format('Y-m-d H:i:s'),
            'dokumen'        => [
                'dokumen_id'    => $f->versiDokumen->dokumen->dokumen_id,
                'judul_dokumen' => $f->versiDokumen->dokumen->judul_dokumen,
                'nomor_versi'   => $f->versiDokumen->nomor_versi,
                'file_url'      => Storage::url($f->versiDokumen->file_url_or_path),
            ],
            'mahasiswa'      => [
                'nama' => $f->versiDokumen->dokumen->bimbingan->mahasiswa->user->nama,
                'nim'  => $f->versiDokumen->dokumen->bimbingan->mahasiswa->nim,
            ],
        ]);

        return $this->successResponse('Daftar feedback berhasil diambil', $data);
    }
}