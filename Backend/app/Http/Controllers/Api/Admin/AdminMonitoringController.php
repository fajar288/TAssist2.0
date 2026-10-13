<?php
// app/Http/Controllers/Api/Admin/AdminMonitoringController.php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Bimbingan;
use App\Models\DokumenTA;
use App\Models\JadwalBimbingan;
use App\Models\Notifikasi;
use App\Models\PermohonanBimbingan;
use App\Models\ProgresTA;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class AdminMonitoringController extends Controller
{
    use ApiResponse;

    // GET /api/admin/permohonan
    public function permohonan(Request $request): JsonResponse
    {
        $permohonan = PermohonanBimbingan::with([
                'mahasiswa.user',
                'dosen.user',
            ])
            ->when(
                $request->filled('status'),
                fn($q) => $q->where('status', $request->status)
            )
            ->when(
                $request->filled('dosen_id'),
                fn($q) => $q->where('dosen_id', $request->dosen_id)
            )
            ->orderByDesc('tanggal_pengajuan')
            ->paginate($request->get('per_page', 15));

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
            ],
            'dosen'             => [
                'dosen_id' => $p->dosen->dosen_id,
                'nama'     => $p->dosen->user->nama,
                'nid'      => $p->dosen->nid,
            ],
        ]);

        return $this->successResponse('Data permohonan berhasil diambil', $data);
    }

    // GET /api/admin/bimbingan
    public function bimbingan(Request $request): JsonResponse
    {
        $bimbingan = Bimbingan::with([
                'mahasiswa.user',
                'dosen.user',
                'progresAktif',
            ])
            ->when(
                $request->filled('status'),
                fn($q) => $q->where('status_bimbingan', $request->status)
            )
            ->when(
                $request->filled('dosen_id'),
                fn($q) => $q->where('dosen_id', $request->dosen_id)
            )
            ->orderByDesc('tanggal_mulai')
            ->paginate($request->get('per_page', 15));

        $data = $bimbingan->through(fn($b) => [
            'bimbingan_id'     => $b->bimbingan_id,
            'tanggal_mulai'    => $b->tanggal_mulai->format('Y-m-d'),
            'status_bimbingan' => $b->status_bimbingan,
            'mahasiswa'        => [
                'mahasiswa_id' => $b->mahasiswa->mahasiswa_id,
                'nama'         => $b->mahasiswa->user->nama,
                'nim'          => $b->mahasiswa->nim,
                'prodi'        => $b->mahasiswa->prodi,
                'judul_ta'     => $b->mahasiswa->judul_ta,
            ],
            'dosen'            => [
                'dosen_id' => $b->dosen->dosen_id,
                'nama'     => $b->dosen->user->nama,
                'nid'      => $b->dosen->nid,
            ],
            'progres_terkini'  => $b->progresAktif ? [
                'persentase'      => $b->progresAktif->persentase,
                'status_progress' => $b->progresAktif->status_progress,
                'updated_at'      => $b->progresAktif->updated_at->format('Y-m-d H:i:s'),
            ] : null,
        ]);

        return $this->successResponse('Data bimbingan berhasil diambil', $data);
    }

    // GET /api/admin/jadwal
    public function jadwal(Request $request): JsonResponse
    {
        $jadwal = JadwalBimbingan::with([
                'bimbingan.mahasiswa.user',
                'bimbingan.dosen.user',
                'pengaju',
            ])
            ->when(
                $request->filled('status'),
                fn($q) => $q->where('status_konfirmasi', $request->status)
            )
            ->when(
                $request->filled('tanggal'),
                fn($q) => $q->whereDate('tanggal', $request->tanggal)
            )
            ->orderByDesc('tanggal')
            ->paginate($request->get('per_page', 15));

        $data = $jadwal->through(fn($j) => [
            'jadwal_id'         => $j->jadwal_id,
            'tanggal'           => $j->tanggal->format('Y-m-d'),
            'waktu_mulai'       => $j->waktu_mulai,
            'waktu_selesai'     => $j->waktu_selesai,
            'mode'              => $j->mode,
            'status_konfirmasi' => $j->status_konfirmasi,
            'catatan'           => $j->catatan,
            'pengaju'           => [
                'nama' => $j->pengaju->nama,
                'role' => $j->pengaju->role,
            ],
            'mahasiswa'         => [
                'nama' => $j->bimbingan->mahasiswa->user->nama,
                'nim'  => $j->bimbingan->mahasiswa->nim,
            ],
            'dosen'             => [
                'nama' => $j->bimbingan->dosen->user->nama,
                'nid'  => $j->bimbingan->dosen->nid,
            ],
        ]);

        return $this->successResponse('Data jadwal berhasil diambil', $data);
    }

    // GET /api/admin/dokumen
    public function dokumen(Request $request): JsonResponse
    {
        $dokumen = DokumenTA::with([
                'bimbingan.mahasiswa.user',
                'bimbingan.dosen.user',
                'versiTerbaru',
            ])
            ->when(
                $request->filled('jenis_dokumen'),
                fn($q) => $q->where('jenis_dokumen', $request->jenis_dokumen)
            )
            ->orderByDesc('created_at')
            ->paginate($request->get('per_page', 15));

        $data = $dokumen->through(fn($d) => [
            'dokumen_id'    => $d->dokumen_id,
            'jenis_dokumen' => $d->jenis_dokumen,
            'judul_dokumen' => $d->judul_dokumen,
            'deskripsi'     => $d->deskripsi,
            'created_at'    => $d->created_at->format('Y-m-d H:i:s'),
            'mahasiswa'     => [
                'nama' => $d->bimbingan->mahasiswa->user->nama,
                'nim'  => $d->bimbingan->mahasiswa->nim,
            ],
            'dosen'         => [
                'nama' => $d->bimbingan->dosen->user->nama,
            ],
            'versi_terbaru' => $d->versiTerbaru ? [
                'nomor_versi' => $d->versiTerbaru->nomor_versi,
                'status_versi'=> $d->versiTerbaru->status_versi,
                'file_url'    => Storage::url($d->versiTerbaru->file_url_or_path),
                'uploaded_at' => $d->versiTerbaru->uploaded_at->format('Y-m-d H:i:s'),
            ] : null,
        ]);

        return $this->successResponse('Data dokumen berhasil diambil', $data);
    }

    // GET /api/admin/progres
    public function progres(Request $request): JsonResponse
    {
        $progres = ProgresTA::with([
                'bimbingan.mahasiswa.user',
                'bimbingan.dosen.user',
                'updatedDosen.user',
                'checklistProgress',
            ])
            ->when(
                $request->filled('status_progress'),
                fn($q) => $q->where('status_progress', $request->status_progress)
            )
            ->orderByDesc('updated_at')
            ->paginate($request->get('per_page', 15));

        $data = $progres->through(function ($p) {
            $totalChecklist   = $p->checklistProgress->count();
            $selesaiChecklist = $p->checklistProgress->where('tgl_selesai', true)->count();

            return [
                'progress_id'     => $p->progress_id,
                'persentase'      => $p->persentase,
                'status_progress' => $p->status_progress,
                'catatan'         => $p->catatan,
                'updated_at'      => $p->updated_at->format('Y-m-d H:i:s'),
                'mahasiswa'       => [
                    'nama'     => $p->bimbingan->mahasiswa->user->nama,
                    'nim'      => $p->bimbingan->mahasiswa->nim,
                    'judul_ta' => $p->bimbingan->mahasiswa->judul_ta,
                ],
                'dosen'           => [
                    'nama' => $p->bimbingan->dosen->user->nama,
                    'nid'  => $p->bimbingan->dosen->nid,
                ],
                'updated_oleh'    => $p->updatedDosen ? [
                    'nama' => $p->updatedDosen->user->nama,
                ] : null,
                'checklist'       => [
                    'total'   => $totalChecklist,
                    'selesai' => $selesaiChecklist,
                ],
            ];
        });

        return $this->successResponse('Data progres berhasil diambil', $data);
    }

    // GET /api/admin/dashboard — Statistik ringkasan
    public function dashboard(): JsonResponse
    {
        $stats = [
            'total_mahasiswa'       => \App\Models\Mahasiswa::count(),
            'total_dosen'           => \App\Models\Dosen::count(),
            'total_bimbingan_aktif' => Bimbingan::where('status_bimbingan', 'aktif')->count(),
            'total_bimbingan'       => Bimbingan::count(),
            'permohonan'            => [
                'menunggu' => PermohonanBimbingan::where('status', 'menunggu')->count(),
                'diterima' => PermohonanBimbingan::where('status', 'diterima')->count(),
                'ditolak'  => PermohonanBimbingan::where('status', 'ditolak')->count(),
            ],
            'jadwal'                => [
                'menunggu'     => JadwalBimbingan::where('status_konfirmasi', 'menunggu')->count(),
                'dikonfirmasi' => JadwalBimbingan::where('status_konfirmasi', 'dikonfirmasi')->count(),
            ],
            'total_dokumen'         => DokumenTA::count(),
            'rata_rata_progres'     => round(ProgresTA::avg('persentase') ?? 0, 2),
        ];

        return $this->successResponse('Data dashboard berhasil diambil', $stats);
    }
}