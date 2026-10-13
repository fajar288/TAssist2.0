<?php
// app/Http/Controllers/Api/Dosen/PermohonanBimbinganController.php

namespace App\Http\Controllers\Api\Dosen;

use App\Http\Controllers\Controller;
use App\Models\Bimbingan;
use App\Models\PermohonanBimbingan;
use App\Models\ProgresTA;
use App\Services\NotifikasiService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PermohonanBimbinganController extends Controller
{
    use ApiResponse;

    // GET /api/dosen/permohonan
    public function index(Request $request): JsonResponse
    {
        $dosen = $request->user()->dosen;

        if (!$dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        $permohonan = PermohonanBimbingan::with(['mahasiswa.user'])
            ->where('dosen_id', $dosen->dosen_id)
            ->when(
                $request->filled('status'),
                fn($q) => $q->where('status', $request->status)
            )
            ->orderByDesc('tanggal_pengajuan')
            ->paginate($request->get('per_page', 10));

        $data = $permohonan->through(fn($p) => [
            'permohonan_id'     => $p->permohonan_id,
            'topik_ta'          => $p->topik_ta,
            'tanggal_pengajuan' => $p->tanggal_pengajuan->format('Y-m-d'),
            'status'            => $p->status,
            'catatan_respons'   => $p->catatan_respons,
            'mahasiswa'         => [
                'mahasiswa_id' => $p->mahasiswa->mahasiswa_id,
                'nama'         => $p->mahasiswa->user->nama,
                'nim'          => $p->mahasiswa->nim,
                'prodi'        => $p->mahasiswa->prodi,
                'angkatan'     => $p->mahasiswa->angkatan,
            ],
        ]);

        return $this->successResponse('Daftar permohonan berhasil diambil', $data);
    }

    // PUT /api/dosen/permohonan/{id}/terima
    public function terima(Request $request, int $id): JsonResponse
    {
        $dosen = $request->user()->dosen;

        if (!$dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        $permohonan = PermohonanBimbingan::with([
            'mahasiswa.user',
            'dosen.user',
        ])
        ->where('permohonan_id', $id)
        ->where('dosen_id', $dosen->dosen_id)
        ->first();

        if (!$permohonan) {
            return $this->errorResponse(
                'Permohonan tidak ditemukan atau bukan milik Anda.',
                null, 404
            );
        }

        if (!$permohonan->isMenunggu()) {
            return $this->errorResponse(
                'Permohonan ini sudah diproses sebelumnya.',
                null, 422
            );
        }

        $dosen->refresh();

        // Cek kuota dosen
        if (!$dosen->masihAdaKuota()) {
            return $this->errorResponse(
                'Kuota bimbingan Anda sudah penuh. Tidak dapat menerima permohonan.',
                null, 422
            );
        }

        // Cek apakah mahasiswa sudah punya bimbingan aktif
        $mahasiswa = $permohonan->mahasiswa;
        if ($mahasiswa->bimbinganAktif()->exists()) {
            return $this->errorResponse(
                'Mahasiswa ini sudah memiliki bimbingan aktif.',
                null, 422
            );
        }

        DB::beginTransaction();
        try {
            // Update status permohonan
            $permohonan->update(['status' => 'diterima']);

            // Buat data bimbingan otomatis
            $bimbingan = Bimbingan::create([
                'permohonan_id'    => $permohonan->permohonan_id,
                'mahasiswa_id'     => $permohonan->mahasiswa_id,
                'dosen_id'         => $dosen->dosen_id,
                'tanggal_mulai'    => now()->toDateString(),
                'status_bimbingan' => 'aktif',
            ]);

            // Buat progres TA awal
            $bimbingan->progresTA()->create([
                'bimbingan_id'     => $bimbingan->bimbingan_id,
                'persentase'       => 0,
                'status_progress'  => 'baru dimulai',
                'updated_dosen_id' => $dosen->dosen_id,
                'catatan'          => 'Bimbingan dimulai.',
            ]);

            DB::commit();

            // Notifikasi ke mahasiswa
            NotifikasiService::kirim(
                userId   : $mahasiswa->user_id,
                tipe     : 'permohonan_diterima',
                judul    : 'Permohonan Bimbingan Diterima',
                pesan    : "Selamat! Permohonan bimbingan Anda telah diterima oleh Dosen {$request->user()->nama}. Bimbingan Anda telah dimulai.",
                refTabel : 'bimbingan',
                refId    : $bimbingan->bimbingan_id
            );

            return $this->successResponse('Permohonan berhasil diterima dan bimbingan dibuat', [
                'permohonan_id'    => $permohonan->permohonan_id,
                'status'           => $permohonan->status,
                'bimbingan'        => [
                    'bimbingan_id'     => $bimbingan->bimbingan_id,
                    'tanggal_mulai'    => $bimbingan->tanggal_mulai->format('Y-m-d'),
                    'status_bimbingan' => $bimbingan->status_bimbingan,
                ],
                'mahasiswa'        => [
                    'nama' => $mahasiswa->user->nama,
                    'nim'  => $mahasiswa->nim,
                ],
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return $this->errorResponse('Gagal memproses permohonan: ' . $e->getMessage(), null, 500);
        }
    }

    // PUT /api/dosen/permohonan/{id}/tolak
    public function tolak(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'catatan_respons' => 'required|string|max:1000',
        ]);

        $dosen = $request->user()->dosen;

        if (!$dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        $permohonan = PermohonanBimbingan::with(['mahasiswa.user'])
            ->where('permohonan_id', $id)
            ->where('dosen_id', $dosen->dosen_id)
            ->first();

        if (!$permohonan) {
            return $this->errorResponse(
                'Permohonan tidak ditemukan atau bukan milik Anda.',
                null, 404
            );
        }

        if (!$permohonan->isMenunggu()) {
            return $this->errorResponse(
                'Permohonan ini sudah diproses sebelumnya.',
                null, 422
            );
        }

        $permohonan->update([
            'status'          => 'ditolak',
            'catatan_respons' => $request->catatan_respons,
        ]);

        // Notifikasi ke mahasiswa
        NotifikasiService::kirim(
            userId   : $permohonan->mahasiswa->user_id,
            tipe     : 'permohonan_ditolak',
            judul    : 'Permohonan Bimbingan Ditolak',
            pesan    : "Permohonan bimbingan Anda ditolak oleh Dosen {$request->user()->nama}. Alasan: {$request->catatan_respons}",
            refTabel : 'permohonan_bimbingan',
            refId    : $permohonan->permohonan_id
        );

        return $this->successResponse('Permohonan berhasil ditolak', [
            'permohonan_id'   => $permohonan->permohonan_id,
            'status'          => $permohonan->status,
            'catatan_respons' => $permohonan->catatan_respons,
            'mahasiswa'       => [
                'nama' => $permohonan->mahasiswa->user->nama,
                'nim'  => $permohonan->mahasiswa->nim,
            ],
        ]);
    }
}