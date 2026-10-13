<?php
// app/Http/Controllers/Api/Mahasiswa/DokumenTAController.php

namespace App\Http\Controllers\Api\Mahasiswa;

use App\Http\Controllers\Controller;
use App\Http\Requests\Mahasiswa\DokumenTARequest;
use App\Http\Requests\Mahasiswa\VersiDokumenRequest;
use App\Models\Bimbingan;
use App\Models\DokumenTA;
use App\Models\VersiDokumen;
use App\Services\NotifikasiService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class DokumenTAController extends Controller
{
    use ApiResponse;

    public function upload(DokumenTARequest $request): JsonResponse
    {
        $user      = $request->user();
        $mahasiswa = $user->mahasiswa;

        if (!$mahasiswa) {
            return $this->errorResponse('Data mahasiswa tidak ditemukan.', null, 404);
        }

        $bimbingan = Bimbingan::where('mahasiswa_id', $mahasiswa->mahasiswa_id)
            ->where('status_bimbingan', 'aktif')
            ->first();

        if (!$bimbingan) {
            return $this->errorResponse(
                'Anda tidak memiliki bimbingan aktif. Upload dokumen tidak diizinkan.',
                null,
                422
            );
        }

        DB::beginTransaction();

        try {
            $dokumen = DokumenTA::create([
                'bimbingan_id'  => $bimbingan->bimbingan_id,
                'jenis_dokumen' => $request->jenis_dokumen,
                'judul_dokumen' => $request->judul_dokumen,
                'deskripsi'     => $request->deskripsi,
            ]);

            $file     = $request->file('file');
            $fileName = time() . '_' . $user->user_id . '_' . $file->getClientOriginalName();
            $filePath = $file->storeAs(
                'dokumen_ta/' . $bimbingan->bimbingan_id,
                $fileName,
                'public'
            );

            $versi = VersiDokumen::create([
                'dokumen_id'       => $dokumen->dokumen_id,
                'uploader_user_id' => $user->user_id,
                'nomor_versi'      => 1,
                'file_url_or_path' => $filePath,
                'catatan_revisi'   => $request->catatan_revisi,
                'uploaded_at'      => now(),
                'status_versi'     => 'diajukan',
            ]);

            DB::commit();

            NotifikasiService::kirim(
                userId   : $bimbingan->dosen->user_id,
                tipe     : 'upload_dokumen',
                judul    : 'Dokumen Baru Diunggah',
                pesan    : "Mahasiswa {$user->nama} mengunggah dokumen: {$request->judul_dokumen}",
                refTabel : 'dokumen_ta',
                refId    : $dokumen->dokumen_id
            );

            return $this->successResponse('Dokumen berhasil diunggah', [
                'dokumen_id'    => $dokumen->dokumen_id,
                'jenis_dokumen' => $dokumen->jenis_dokumen,
                'judul_dokumen' => $dokumen->judul_dokumen,
                'deskripsi'     => $dokumen->deskripsi,
                'versi'         => [
                    'versi_id'        => $versi->versi_id,
                    'nomor_versi'     => $versi->nomor_versi,
                    'file_url'        => Storage::url($versi->file_url_or_path),
                    'catatan_revisi'  => $versi->catatan_revisi,
                    'status_versi'    => $versi->status_versi,
                    'uploaded_at'     => $versi->uploaded_at->format('Y-m-d H:i:s'),
                ],
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->errorResponse('Gagal mengunggah dokumen: ' . $e->getMessage(), null, 500);
        }
    }

    public function index(Request $request): JsonResponse
    {
        $mahasiswa = $request->user()->mahasiswa;

        if (!$mahasiswa) {
            return $this->errorResponse('Data mahasiswa tidak ditemukan.', null, 404);
        }

        $bimbingan = Bimbingan::where('mahasiswa_id', $mahasiswa->mahasiswa_id)
            ->where('status_bimbingan', 'aktif')
            ->first();

        if (!$bimbingan) {
            return $this->errorResponse('Tidak ada bimbingan aktif.', null, 404);
        }

        $dokumen = DokumenTA::with('versiTerbaru')
            ->where('bimbingan_id', $bimbingan->bimbingan_id)
            ->orderByDesc('created_at')
            ->paginate($request->get('per_page', 10));

        $data = $dokumen->through(function ($d) {
            return [
                'dokumen_id'    => $d->dokumen_id,
                'jenis_dokumen' => $d->jenis_dokumen,
                'judul_dokumen' => $d->judul_dokumen,
                'deskripsi'     => $d->deskripsi,
                'created_at'    => $d->created_at->format('Y-m-d H:i:s'),
                'versi_terbaru' => $d->versiTerbaru ? [
                    'versi_id'     => $d->versiTerbaru->versi_id,
                    'nomor_versi'  => $d->versiTerbaru->nomor_versi,
                    'file_url'     => Storage::url($d->versiTerbaru->file_url_or_path),
                    'status_versi' => $d->versiTerbaru->status_versi,
                    'uploaded_at'  => $d->versiTerbaru->uploaded_at->format('Y-m-d H:i:s'),
                ] : null,
            ];
        });

        return $this->successResponse('Daftar dokumen berhasil diambil', $data);
    }

    public function riwayatVersi(Request $request, int $id): JsonResponse
    {
        $mahasiswa = $request->user()->mahasiswa;

        if (!$mahasiswa) {
            return $this->errorResponse('Data mahasiswa tidak ditemukan.', null, 404);
        }

        $dokumen = DokumenTA::whereHas('bimbingan', function ($q) use ($mahasiswa) {
                $q->where('mahasiswa_id', $mahasiswa->mahasiswa_id);
            })
            ->findOrFail($id);

        $versi = VersiDokumen::with([
                'uploader',
                'feedbackDokumen.dosen.user',
            ])
            ->where('dokumen_id', $dokumen->dokumen_id)
            ->orderByDesc('nomor_versi')
            ->paginate($request->get('per_page', 10));

        $data = $versi->through(function ($v) {
            return [
                'versi_id'        => $v->versi_id,
                'nomor_versi'     => $v->nomor_versi,
                'file_url'        => Storage::url($v->file_url_or_path),
                'catatan_revisi'  => $v->catatan_revisi,
                'status_versi'    => $v->status_versi,
                'uploaded_at'     => $v->uploaded_at->format('Y-m-d H:i:s'),
                'uploader'        => [
                    'user_id' => $v->uploader->user_id,
                    'nama'    => $v->uploader->nama,
                    'role'    => $v->uploader->role,
                ],
                'feedback'        => $v->feedbackDokumen->map(fn($f) => [
                    'feedback_id'    => $f->feedback_id,
                    'komentar'       => $f->komentar,
                    'halaman'        => $f->halaman,
                    'posisi_anotasi' => $f->posisi_anotasi,
                    'created_at'     => $f->created_at->format('Y-m-d H:i:s'),
                    'dosen'          => [
                        'dosen_id' => $f->dosen->dosen_id,
                        'nama'     => $f->dosen->user->nama,
                    ],
                ]),
            ];
        });

        return $this->successResponse('Riwayat versi dokumen berhasil diambil', [
            'dokumen' => [
                'dokumen_id'    => $dokumen->dokumen_id,
                'judul_dokumen' => $dokumen->judul_dokumen,
                'jenis_dokumen' => $dokumen->jenis_dokumen,
            ],
            'versi' => $data,
        ]);
    }

    public function uploadVersi(VersiDokumenRequest $request, int $id): JsonResponse
    {
        $user      = $request->user();
        $mahasiswa = $user->mahasiswa;

        if (!$mahasiswa) {
            return $this->errorResponse('Data mahasiswa tidak ditemukan.', null, 404);
        }

        $dokumen = DokumenTA::whereHas('bimbingan', function ($q) use ($mahasiswa) {
                $q->where('mahasiswa_id', $mahasiswa->mahasiswa_id)
                  ->where('status_bimbingan', 'aktif');
            })
            ->findOrFail($id);

        $bimbingan = $dokumen->bimbingan;

        DB::beginTransaction();

        try {
            $nomorVersiTerbaru = VersiDokumen::where('dokumen_id', $dokumen->dokumen_id)
                ->max('nomor_versi') ?? 0;
            $nomorVersiBaru = $nomorVersiTerbaru + 1;

            $file     = $request->file('file');
            $fileName = time() . '_v' . $nomorVersiBaru . '_' . $file->getClientOriginalName();
            $filePath = $file->storeAs(
                'dokumen_ta/' . $bimbingan->bimbingan_id,
                $fileName,
                'public'
            );

            $versi = VersiDokumen::create([
                'dokumen_id'       => $dokumen->dokumen_id,
                'uploader_user_id' => $user->user_id,
                'nomor_versi'      => $nomorVersiBaru,
                'file_url_or_path' => $filePath,
                'catatan_revisi'   => $request->catatan_revisi,
                'uploaded_at'      => now(),
                'status_versi'     => 'diajukan',
            ]);

            DB::commit();

            NotifikasiService::kirim(
                userId   : $bimbingan->dosen->user_id,
                tipe     : 'upload_versi_dokumen',
                judul    : 'Versi Dokumen Baru',
                pesan    : "Mahasiswa {$user->nama} mengupload versi {$nomorVersiBaru} untuk dokumen: {$dokumen->judul_dokumen}",
                refTabel : 'versi_dokumen',
                refId    : $versi->versi_id
            );

            return $this->successResponse('Versi baru dokumen berhasil diunggah', [
                'versi_id'        => $versi->versi_id,
                'dokumen_id'      => $dokumen->dokumen_id,
                'nomor_versi'     => $versi->nomor_versi,
                'file_url'        => Storage::url($versi->file_url_or_path),
                'catatan_revisi'  => $versi->catatan_revisi,
                'status_versi'    => $versi->status_versi,
                'uploaded_at'     => $versi->uploaded_at->format('Y-m-d H:i:s'),
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->errorResponse('Gagal mengupload versi: ' . $e->getMessage(), null, 500);
        }
    }
}
