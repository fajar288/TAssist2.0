<?php
// app/Http/Controllers/Api/Dosen/DosenController.php

namespace App\Http\Controllers\Api\Dosen;

use App\Http\Controllers\Controller;
use App\Http\Requests\Dosen\UpdateDosenProfileRequest;
use App\Models\Bimbingan;
use App\Models\DokumenTA;
use App\Models\VersiDokumen;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;   // Import DB
use Illuminate\Support\Facades\Hash; // Import Hash

class DosenController extends Controller
{
    use ApiResponse;

    public function profile(Request $request): JsonResponse
    {
        $user  = $request->user();
        $dosen = $user->dosen;

        if (!$dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        $bimbinganAktif = $dosen->bimbinganAktif()->count();

        return $this->successResponse('Profil dosen berhasil diambil', [
            'user' => [
                'user_id'     => $user->user_id,
                'nama'        => $user->nama,
                'email'       => $user->email,
                'avatar'      => $user->avatar ? Storage::url($user->avatar) : null, // Tambahan avatar
                'status_akun' => $user->status_akun,
            ],
            'dosen' => [
                'dosen_id'        => $dosen->dosen_id,
                'nid'             => $dosen->nid,
                'bidang_keahlian' => $dosen->bidang_keahlian,
                'kuota_bimbingan' => $dosen->kuota_bimbingan,
                'sisa_kuota'      => max(0, $dosen->kuota_bimbingan - $bimbinganAktif),
                'bimbingan_aktif' => $bimbinganAktif,
                'profil_singkat'  => $dosen->profil_singkat,
            ],
        ]);
    }

    public function updateProfile(UpdateDosenProfileRequest $request): JsonResponse
    {
        $user  = $request->user();
        $dosen = $user->dosen;

        if (!$dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        try {
            // Memulai transaksi database agar data konsisten
            DB::transaction(function () use ($request, $user, $dosen) {
                
                // 1. Update tabel Users
                if ($request->filled('nama')) {
                    $user->nama = $request->nama;
                }

                if ($request->filled('password')) {
                    $user->password_hash = Hash::make($request->password);
                }

                if ($request->hasFile('avatar')) {
                    // Hapus avatar lama jika ada
                    if ($user->avatar) {
                        Storage::disk('public')->delete($user->avatar);
                    }
                    // Simpan avatar baru ke folder public/avatars
                    $path = $request->file('avatar')->store('avatars', 'public');
                    $user->avatar = $path;
                }
                
                $user->save();

                // 2. Update tabel Dosen (Mempertahankan gaya kodemu)
                $dosenFields = array_filter([
                    'bidang_keahlian' => $request->bidang_keahlian,
                    'kuota_bimbingan' => $request->kuota_bimbingan,
                    'profil_singkat'  => $request->profil_singkat,
                ], fn($v) => $v !== null);

                if (!empty($dosenFields)) {
                    $dosen->update($dosenFields);
                }
            });

            // Refresh data dari database setelah transaksi selesai
            $dosen->refresh();
            $user->refresh();

            return $this->successResponse('Profil berhasil diperbarui', [
                'user' => [
                    'user_id' => $user->user_id,
                    'nama'    => $user->nama,
                    'email'   => $user->email,
                    'avatar'  => $user->avatar ? Storage::url($user->avatar) : null, // Kembalikan URL avatar
                ],
                'dosen' => [
                    'dosen_id'        => $dosen->dosen_id,
                    'nid'             => $dosen->nid,
                    'bidang_keahlian' => $dosen->bidang_keahlian,
                    'kuota_bimbingan' => $dosen->kuota_bimbingan,
                    'profil_singkat'  => $dosen->profil_singkat,
                ],
            ]);

        } catch (\Exception $e) {
            // Jika ada kode yang gagal (misal gagal simpan foto), semua update dibatalkan
            return $this->errorResponse('Gagal memperbarui profil: ' . $e->getMessage(), null, 500);
        }
    }

    public function mahasiswaBimbingan(Request $request): JsonResponse
    {
        $dosen = $request->user()->dosen;

        if (!$dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        $bimbingan = Bimbingan::with(['mahasiswa.user', 'progresAktif'])
            ->where('dosen_id', $dosen->dosen_id)
            ->when(
                $request->filled('status'),
                fn($q) => $q->where('status_bimbingan', $request->status)
            )
            ->orderByDesc('tanggal_mulai')
            ->paginate($request->get('per_page', 10));

        $data = $bimbingan->through(function ($b) {
            return [
                'bimbingan_id'     => $b->bimbingan_id,
                'tanggal_mulai'    => $b->tanggal_mulai->format('Y-m-d'),
                'status_bimbingan' => $b->status_bimbingan,
                'mahasiswa'        => [
                    'mahasiswa_id' => $b->mahasiswa->mahasiswa_id,
                    'nama'         => $b->mahasiswa->user->nama,
                    'nim'          => $b->mahasiswa->nim,
                    'prodi'        => $b->mahasiswa->prodi,
                    'angkatan'     => $b->mahasiswa->angkatan,
                    'topik_ta'     => $b->mahasiswa->topik_ta,
                    'judul_ta'     => $b->mahasiswa->judul_ta,
                ],
                'progres_terkini'  => $b->progresAktif ? [
                    'persentase'      => $b->progresAktif->persentase,
                    'status_progress' => $b->progresAktif->status_progress,
                    'updated_at'      => $b->progresAktif->updated_at->format('Y-m-d H:i:s'),
                ] : null,
            ];
        });

        return $this->successResponse('Daftar mahasiswa bimbingan berhasil diambil', $data);
    }

    public function progreesMahasiswa(Request $request, int $id): JsonResponse
    {
        $dosen = $request->user()->dosen;

        if (!$dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        $bimbingan = Bimbingan::with(['mahasiswa.user', 'progresTA.checklistProgress'])
            ->where('bimbingan_id', $id)
            ->where('dosen_id', $dosen->dosen_id)
            ->first();

        if (!$bimbingan) {
            return $this->errorResponse(
                'Bimbingan tidak ditemukan atau bukan milik Anda.',
                null,
                404
            );
        }

        $progres = $bimbingan->progresTA->map(function ($p) {
            $totalChecklist   = $p->checklistProgress->count();
            $selesaiChecklist = $p->checklistProgress->where('tgl_selesai', true)->count();

            return [
                'progress_id'     => $p->progress_id,
                'persentase'      => $p->persentase,
                'status_progress' => $p->status_progress,
                'catatan'         => $p->catatan,
                'updated_at'      => $p->updated_at->format('Y-m-d H:i:s'),
                'checklist_summary' => [
                    'total'   => $totalChecklist,
                    'selesai' => $selesaiChecklist,
                ],
                'checklist'       => $p->checklistProgress->map(fn($c) => [
                    'checklist_id'    => $c->checklist_id,
                    'nama_item'       => $c->nama_item,
                    'tgl_selesai'     => $c->tgl_selesai,
                    'tanggal_selesai' => $c->tanggal_selesai?->format('Y-m-d'),
                    'catatan'         => $c->catatan,
                ]),
            ];
        });

        return $this->successResponse('Data progres mahasiswa berhasil diambil', [
            'bimbingan_id'     => $bimbingan->bimbingan_id,
            'status_bimbingan' => $bimbingan->status_bimbingan,
            'mahasiswa'        => [
                'mahasiswa_id' => $bimbingan->mahasiswa->mahasiswa_id,
                'nama'         => $bimbingan->mahasiswa->user->nama,
                'nim'          => $bimbingan->mahasiswa->nim,
                'judul_ta'     => $bimbingan->mahasiswa->judul_ta,
            ],
            'progres'          => $progres,
        ]);
    }

    public function dokumenMahasiswa(Request $request, int $id): JsonResponse
    {
        $dosen = $request->user()->dosen;

        if (!$dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        $bimbingan = Bimbingan::with('mahasiswa.user')
            ->where('bimbingan_id', $id)
            ->where('dosen_id', $dosen->dosen_id)
            ->first();

        if (!$bimbingan) {
            return $this->errorResponse(
                'Bimbingan tidak ditemukan atau bukan milik Anda.',
                null,
                404
            );
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

        return $this->successResponse('Daftar dokumen mahasiswa berhasil diambil', [
            'bimbingan_id' => $bimbingan->bimbingan_id,
            'mahasiswa'    => [
                'mahasiswa_id' => $bimbingan->mahasiswa->mahasiswa_id,
                'nama'         => $bimbingan->mahasiswa->user->nama,
                'nim'          => $bimbingan->mahasiswa->nim,
                'judul_ta'     => $bimbingan->mahasiswa->judul_ta,
            ],
            'dokumen'      => $data,
        ]);
    }

    public function riwayatVersiDokumen(Request $request, int $id): JsonResponse
    {
        $dosen = $request->user()->dosen;

        if (!$dosen) {
            return $this->errorResponse('Data dosen tidak ditemukan.', null, 404);
        }

        $dokumen = DokumenTA::with('bimbingan.mahasiswa.user')
            ->whereHas('bimbingan', function ($q) use ($dosen) {
                $q->where('dosen_id', $dosen->dosen_id);
            })
            ->findOrFail($id);

        $versi = VersiDokumen::with(['uploader', 'feedbackDokumen.dosen.user'])
            ->where('dokumen_id', $dokumen->dokumen_id)
            ->orderByDesc('nomor_versi')
            ->paginate($request->get('per_page', 10));

        $data = $versi->through(function ($v) {
            return [
                'versi_id'       => $v->versi_id,
                'nomor_versi'    => $v->nomor_versi,
                'file_url'       => Storage::url($v->file_url_or_path),
                'catatan_revisi' => $v->catatan_revisi,
                'status_versi'   => $v->status_versi,
                'uploaded_at'    => $v->uploaded_at->format('Y-m-d H:i:s'),
                'uploader'       => [
                    'user_id' => $v->uploader->user_id,
                    'nama'    => $v->uploader->nama,
                    'role'    => $v->uploader->role,
                ],
                'feedback'       => $v->feedbackDokumen->map(fn($f) => [
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
                'mahasiswa'     => [
                    'mahasiswa_id' => $dokumen->bimbingan->mahasiswa->mahasiswa_id,
                    'nama'         => $dokumen->bimbingan->mahasiswa->user->nama,
                    'nim'          => $dokumen->bimbingan->mahasiswa->nim,
                ],
            ],
            'versi' => $data,
        ]);
    }
}
