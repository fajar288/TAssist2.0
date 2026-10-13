<?php
// app/Http/Controllers/Api/Mahasiswa/JadwalBimbinganController.php

namespace App\Http\Controllers\Api\Mahasiswa;

use App\Http\Controllers\Controller;
use App\Http\Requests\JadwalBimbinganRequest;
use App\Models\Bimbingan;
use App\Models\JadwalBimbingan;
use App\Services\NotifikasiService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class JadwalBimbinganController extends Controller
{
    use ApiResponse;

    // POST /api/mahasiswa/jadwal
    public function ajukan(JadwalBimbinganRequest $request): JsonResponse
    {
        $user      = $request->user();
        $mahasiswa = $user->mahasiswa;

        if (!$mahasiswa) {
            return $this->errorResponse('Data mahasiswa tidak ditemukan.', null, 404);
        }

        // Pastikan bimbingan_id milik mahasiswa ini dan aktif
        $bimbingan = Bimbingan::where('bimbingan_id', $request->bimbingan_id)
            ->where('mahasiswa_id', $mahasiswa->mahasiswa_id)
            ->where('status_bimbingan', 'aktif')
            ->first();

        if (!$bimbingan) {
            return $this->errorResponse(
                'Bimbingan tidak ditemukan atau tidak aktif.',
                null, 404
            );
        }

        $jadwal = JadwalBimbingan::create([
            'bimbingan_id'     => $bimbingan->bimbingan_id,
            'pengaju_user_id'  => $user->user_id,
            'tanggal'          => $request->tanggal,
            'waktu_mulai'      => $request->waktu_mulai,
            'waktu_selesai'    => $request->waktu_selesai,
            'mode'             => $request->mode,
            'status_konfirmasi'=> 'menunggu',
            'catatan'          => $request->catatan,
        ]);

        // Notifikasi ke dosen
        NotifikasiService::kirim(
            userId   : $bimbingan->dosen->user_id,
            tipe     : 'jadwal_bimbingan',
            judul    : 'Pengajuan Jadwal Bimbingan',
            pesan    : "Mahasiswa {$user->nama} mengajukan jadwal bimbingan pada {$request->tanggal} pukul {$request->waktu_mulai}",
            refTabel : 'jadwal_bimbingan',
            refId    : $jadwal->jadwal_id
        );

        return $this->successResponse('Jadwal bimbingan berhasil diajukan', [
            'jadwal_id'         => $jadwal->jadwal_id,
            'tanggal'           => $jadwal->tanggal->format('Y-m-d'),
            'waktu_mulai'       => $jadwal->waktu_mulai,
            'waktu_selesai'     => $jadwal->waktu_selesai,
            'mode'              => $jadwal->mode,
            'status_konfirmasi' => $jadwal->status_konfirmasi,
            'catatan'           => $jadwal->catatan,
        ], 201);
    }

    // GET /api/mahasiswa/jadwal
    public function index(Request $request): JsonResponse
    {
        $mahasiswa = $request->user()->mahasiswa;

        if (!$mahasiswa) {
            return $this->errorResponse('Data mahasiswa tidak ditemukan.', null, 404);
        }

        // Ambil semua jadwal dari semua bimbingan milik mahasiswa ini
        $jadwal = JadwalBimbingan::with(['bimbingan.dosen.user', 'pengaju'])
            ->whereHas('bimbingan', function ($q) use ($mahasiswa) {
                $q->where('mahasiswa_id', $mahasiswa->mahasiswa_id);
            })
            ->orderByDesc('tanggal')
            ->paginate($request->get('per_page', 10));

        $data = $jadwal->through(function ($j) {
            return [
                'jadwal_id'         => $j->jadwal_id,
                'tanggal'           => $j->tanggal->format('Y-m-d'),
                'waktu_mulai'       => $j->waktu_mulai,
                'waktu_selesai'     => $j->waktu_selesai,
                'mode'              => $j->mode,
                'status_konfirmasi' => $j->status_konfirmasi,
                'catatan'           => $j->catatan,
                'pengaju'           => [
                    'user_id' => $j->pengaju->user_id,
                    'nama'    => $j->pengaju->nama,
                    'role'    => $j->pengaju->role,
                ],
                'dosen'             => [
                    'dosen_id' => $j->bimbingan->dosen->dosen_id,
                    'nama'     => $j->bimbingan->dosen->user->nama,
                ],
            ];
        });

        return $this->successResponse('Daftar jadwal bimbingan berhasil diambil', $data);
    }
}