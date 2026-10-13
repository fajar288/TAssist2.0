<?php
// app/Http/Controllers/Api/Mahasiswa/PermohonanBimbinganController.php

namespace App\Http\Controllers\Api\Mahasiswa;

use App\Http\Controllers\Controller;
use App\Http\Requests\Mahasiswa\PermohonanBimbinganRequest;
use App\Models\Dosen;
use App\Models\PermohonanBimbingan;
use App\Services\NotifikasiService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PermohonanBimbinganController extends Controller
{
    use ApiResponse;

    // POST /api/mahasiswa/permohonan
    public function ajukan(PermohonanBimbinganRequest $request): JsonResponse
    {
        $user      = $request->user();
        $mahasiswa = $user->mahasiswa;

        if (!$mahasiswa) {
            return $this->errorResponse('Data mahasiswa tidak ditemukan.', null, 404);
        }

        // Cek apakah mahasiswa sudah punya bimbingan aktif
        if ($mahasiswa->bimbinganAktif()->exists()) {
            return $this->errorResponse(
                'Anda sudah memiliki bimbingan aktif. Tidak dapat mengajukan permohonan baru.',
                null, 422
            );
        }

        // Cek apakah mahasiswa sudah punya permohonan menunggu
        if ($mahasiswa->permohonanAktif()->exists()) {
            return $this->errorResponse(
                'Anda masih memiliki permohonan yang sedang menunggu. Tunggu hingga diproses.',
                null, 422
            );
        }

        // Cek kuota dosen
        $dosen = Dosen::findOrFail($request->dosen_id);

        if (!$dosen->masihAdaKuota()) {
            return $this->errorResponse(
                'Kuota bimbingan dosen ini sudah penuh. Pilih dosen lain.',
                null, 422
            );
        }

        $permohonan = PermohonanBimbingan::create([
            'mahasiswa_id'     => $mahasiswa->mahasiswa_id,
            'dosen_id'         => $dosen->dosen_id,
            'topik_ta'         => $request->topik_ta,
            'tanggal_pengajuan'=> now()->toDateString(),
            'status'           => 'menunggu',
        ]);

        // Kirim notifikasi ke dosen
        NotifikasiService::kirim(
            userId   : $dosen->user_id,
            tipe     : 'permohonan_bimbingan',
            judul    : 'Permohonan Bimbingan Baru',
            pesan    : "Mahasiswa {$user->nama} mengajukan permohonan bimbingan dengan topik: {$request->topik_ta}",
            refTabel : 'permohonan_bimbingan',
            refId    : $permohonan->permohonan_id
        );

        return $this->successResponse('Permohonan bimbingan berhasil diajukan', [
            'permohonan_id'     => $permohonan->permohonan_id,
            'dosen'             => [
                'dosen_id' => $dosen->dosen_id,
                'nama'     => $dosen->user->nama,
            ],
            'topik_ta'          => $permohonan->topik_ta,
            'tanggal_pengajuan' => $permohonan->tanggal_pengajuan->format('Y-m-d'),
            'status'            => $permohonan->status,
        ], 201);
    }

    // GET /api/mahasiswa/permohonan
    public function daftarPermohonan(Request $request): JsonResponse
    {
        $mahasiswa = $request->user()->mahasiswa;

        if (!$mahasiswa) {
            return $this->errorResponse('Data mahasiswa tidak ditemukan.', null, 404);
        }

        $permohonan = PermohonanBimbingan::with(['dosen.user'])
            ->where('mahasiswa_id', $mahasiswa->mahasiswa_id)
            ->orderByDesc('tanggal_pengajuan')
            ->paginate($request->get('per_page', 10));

        $data = $permohonan->through(function ($p) {
            return [
                'permohonan_id'     => $p->permohonan_id,
                'dosen'             => [
                    'dosen_id'        => $p->dosen->dosen_id,
                    'nama'            => $p->dosen->user->nama,
                    'bidang_keahlian' => $p->dosen->bidang_keahlian,
                ],
                'topik_ta'          => $p->topik_ta,
                'tanggal_pengajuan' => $p->tanggal_pengajuan->format('Y-m-d'),
                'status'            => $p->status,
                'catatan_respons'   => $p->catatan_respons,
            ];
        });

        return $this->successResponse('Daftar permohonan berhasil diambil', $data);
    }
}