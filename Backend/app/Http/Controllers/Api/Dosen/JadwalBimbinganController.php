<?php
// app/Http/Controllers/Api/Dosen/JadwalBimbinganController.php

namespace App\Http\Controllers\Api\Dosen;

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

    // POST /api/dosen/jadwal — Dosen buat jadwal bimbingan
    public function store(JadwalBimbinganRequest $request): JsonResponse
    {
        $user  = $request->user();
        $dosen = $user->dosen;

        if (!$dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        // Pastikan bimbingan_id milik dosen ini
        $bimbingan = Bimbingan::where('bimbingan_id', $request->bimbingan_id)
            ->where('dosen_id', $dosen->dosen_id)
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

        // Notifikasi ke mahasiswa
        NotifikasiService::kirim(
            userId   : $bimbingan->mahasiswa->user_id,
            tipe     : 'jadwal_bimbingan',
            judul    : 'Jadwal Bimbingan Baru dari Dosen',
            pesan    : "Dosen {$user->nama} mengajukan jadwal bimbingan pada {$request->tanggal} pukul {$request->waktu_mulai}. Mohon konfirmasi.",
            refTabel : 'jadwal_bimbingan',
            refId    : $jadwal->jadwal_id
        );

        return $this->successResponse('Jadwal bimbingan berhasil dibuat', [
            'jadwal_id'         => $jadwal->jadwal_id,
            'tanggal'           => $jadwal->tanggal->format('Y-m-d'),
            'waktu_mulai'       => $jadwal->waktu_mulai,
            'waktu_selesai'     => $jadwal->waktu_selesai,
            'mode'              => $jadwal->mode,
            'status_konfirmasi' => $jadwal->status_konfirmasi,
            'catatan'           => $jadwal->catatan,
        ], 201);
    }

    // PUT /api/dosen/jadwal/{id}/konfirmasi — Dosen konfirmasi jadwal dari mahasiswa
    public function konfirmasi(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'status_konfirmasi' => 'required|in:dikonfirmasi,ditolak',
            'mode'              => 'nullable|in:online,offline',
            'catatan'           => 'nullable|string|max:500',
        ]);

        $dosen = $request->user()->dosen;

        if (!$dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        $jadwal = JadwalBimbingan::with([
                'bimbingan.mahasiswa.user',
            ])
            ->whereHas('bimbingan', fn($q) => $q->where('dosen_id', $dosen->dosen_id))
            ->findOrFail($id);

        if ($jadwal->status_konfirmasi !== 'menunggu') {
            return $this->errorResponse(
                'Jadwal ini sudah dikonfirmasi sebelumnya.',
                null, 422
            );
        }

        // Pastikan yang mengajukan adalah mahasiswa (bukan dosen sendiri)
        if ($jadwal->pengaju_user_id === $request->user()->user_id) {
            return $this->errorResponse(
                'Anda tidak dapat mengkonfirmasi jadwal yang Anda ajukan sendiri.',
                null, 422
            );
        }

        $jadwal->update([
            'status_konfirmasi' => $request->status_konfirmasi,
            'mode'              => $request->mode ?? $jadwal->mode,
            'catatan'           => $request->catatan ?? $jadwal->catatan,
        ]);

        $statusPesan = $request->status_konfirmasi === 'dikonfirmasi' ? 'dikonfirmasi' : 'ditolak';
        $mahasiswa   = $jadwal->bimbingan->mahasiswa;

        // Notifikasi ke mahasiswa
        NotifikasiService::kirim(
            userId   : $mahasiswa->user_id,
            tipe     : 'konfirmasi_jadwal',
            judul    : 'Update Status Jadwal Bimbingan',
            pesan    : "Jadwal bimbingan Anda pada {$jadwal->tanggal->format('Y-m-d')} pukul {$jadwal->waktu_mulai} telah {$statusPesan} oleh dosen. Mode bimbingan: {$jadwal->mode}.",
            refTabel : 'jadwal_bimbingan',
            refId    : $jadwal->jadwal_id
        );

        return $this->successResponse("Jadwal berhasil {$statusPesan}", [
            'jadwal_id'         => $jadwal->jadwal_id,
            'tanggal'           => $jadwal->tanggal->format('Y-m-d'),
            'waktu_mulai'       => $jadwal->waktu_mulai,
            'waktu_selesai'     => $jadwal->waktu_selesai,
            'mode'              => $jadwal->mode,
            'status_konfirmasi' => $jadwal->status_konfirmasi,
            'catatan'           => $jadwal->catatan,
        ]);
    }

    // GET /api/dosen/jadwal — Lihat semua jadwal bimbingan dosen
    public function index(Request $request): JsonResponse
    {
        $dosen = $request->user()->dosen;

        if (!$dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        $jadwal = JadwalBimbingan::with([
                'bimbingan.mahasiswa.user',
                'pengaju',
            ])
            ->whereHas('bimbingan', fn($q) => $q->where('dosen_id', $dosen->dosen_id))
            ->when(
                $request->filled('status'),
                fn($q) => $q->where('status_konfirmasi', $request->status)
            )
            ->orderByDesc('tanggal')
            ->paginate($request->get('per_page', 10));

        $data = $jadwal->through(fn($j) => [
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
            'mahasiswa'         => [
                'mahasiswa_id' => $j->bimbingan->mahasiswa->mahasiswa_id,
                'nama'         => $j->bimbingan->mahasiswa->user->nama,
                'nim'          => $j->bimbingan->mahasiswa->nim,
            ],
        ]);

        return $this->successResponse('Daftar jadwal berhasil diambil', $data);
    }
}