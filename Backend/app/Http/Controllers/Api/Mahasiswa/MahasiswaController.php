<?php
// app/Http/Controllers/Api/Mahasiswa/MahasiswaController.php

namespace App\Http\Controllers\Api\Mahasiswa;

use App\Http\Controllers\Controller;
use App\Models\Mahasiswa;
use App\Models\Dosen;
use App\Traits\ApiResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MahasiswaController extends Controller
{
    use ApiResponse;

    // GET /api/mahasiswa/complete-profile
    public function completeProfile(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user || $user->role !== 'mahasiswa') {
            return $this->errorResponse(
                'Hanya mahasiswa yang dapat melengkapi profil.',
                null,
                403
            );
        }

        if ($user->mahasiswa) {
            return $this->errorResponse(
                'Profil mahasiswa sudah pernah dilengkapi.',
                null,
                409
            );
        }

        $validated = $request->validate([
            'nim'      => ['required', 'string', 'max:50', 'unique:mahasiswa,nim'],
            'prodi'    => ['required', 'string', 'max:100'],
            'angkatan' => ['required', 'integer', 'min:2000', 'max:' . (date('Y') + 1)],
            'topik_ta' => ['nullable', 'string', 'max:255'],
            'judul_ta' => ['nullable', 'string', 'max:255'],
        ]);

        try {
            $mahasiswa = DB::transaction(function () use ($user, $validated) {
                return Mahasiswa::create([
                    'user_id'  => $user->user_id,
                    'nim'      => $validated['nim'],
                    'prodi'    => $validated['prodi'],
                    'angkatan' => $validated['angkatan'],
                    'topik_ta' => $validated['topik_ta'] ?? null,
                    'judul_ta' => $validated['judul_ta'] ?? null,
                ]);
            });

            return $this->successResponse('Profil mahasiswa berhasil dilengkapi.', [
                'profile' => [
                    'mahasiswa_id' => $mahasiswa->mahasiswa_id,
                    'nim'          => $mahasiswa->nim,
                    'prodi'        => $mahasiswa->prodi,
                    'angkatan'     => $mahasiswa->angkatan,
                    'topik_ta'     => $mahasiswa->topik_ta,
                    'judul_ta'     => $mahasiswa->judul_ta,
                ],
            ], 201);

        } catch (\Throwable $e) {
            return $this->errorResponse(
                'Gagal melengkapi profil: ' . $e->getMessage(),
                null,
                500
            );
        }
    }

    // Lihat daftar semua dosen beserta profil, keahlian, kuota
    public function daftarDosen(Request $request): JsonResponse
    {
        $query = Dosen::with('user')
            ->whereHas('user', fn($q) => $q->where('status_akun', 'aktif'));

        // Filter by bidang keahlian jika ada
        if ($request->filled('bidang_keahlian')) {
            $query->where('bidang_keahlian', 'like', '%' . $request->bidang_keahlian . '%');
        }

        // Filter hanya yang masih ada kuota
        if ($request->boolean('ada_kuota')) {
            $query->whereRaw('kuota_bimbingan > (
                SELECT COUNT(*) FROM bimbingan
                WHERE bimbingan.dosen_id = dosen.dosen_id
                AND bimbingan.status_bimbingan = "aktif"
            )');
        }

        $dosen = $query->paginate($request->get('per_page', 10));

        $data = $dosen->through(function ($d) {
            $bimbinganAktif = $d->bimbinganAktif()->count();
            return [
                'dosen_id'        => $d->dosen_id,
                'nama'            => $d->user->nama,
                'email'           => $d->user->email,
                'avatar'          => $d->user->avatar ? \Illuminate\Support\Facades\Storage::url($d->user->avatar) : null,
                'nid'             => $d->nid,
                'bidang_keahlian' => $d->bidang_keahlian,
                'kuota_bimbingan' => $d->kuota_bimbingan,
                'sisa_kuota'      => max(0, $d->kuota_bimbingan - $bimbinganAktif),
                'profil_singkat'  => $d->profil_singkat,
            ];
        });

        return $this->successResponse('Daftar dosen berhasil diambil', $data);
    }
}