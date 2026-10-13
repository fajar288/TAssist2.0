<?php
// app/Http/Controllers/Api/Mahasiswa/BimbinganController.php

namespace App\Http\Controllers\Api\Mahasiswa;

use App\Http\Controllers\Controller;
use App\Models\Bimbingan;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BimbinganController extends Controller
{
    use ApiResponse;

    // GET /api/mahasiswa/bimbingan
    public function index(Request $request): JsonResponse
    {
        $mahasiswa = $request->user()->mahasiswa;

        if (!$mahasiswa) {
            return $this->errorResponse('Data mahasiswa tidak ditemukan.', null, 404);
        }

        $bimbingan = Bimbingan::with([
                'dosen.user',
                'permohonan',
                'progresAktif',
            ])
            ->where('mahasiswa_id', $mahasiswa->mahasiswa_id)
            ->orderByDesc('tanggal_mulai')
            ->paginate($request->get('per_page', 10));

        $data = $bimbingan->through(function ($b) {
            return [
                'bimbingan_id'    => $b->bimbingan_id,
                'dosen'           => [
                    'dosen_id'        => $b->dosen->dosen_id,
                    'nama'            => $b->dosen->user->nama,
                    'bidang_keahlian' => $b->dosen->bidang_keahlian,
                ],
                'tanggal_mulai'   => $b->tanggal_mulai->format('Y-m-d'),
                'status_bimbingan'=> $b->status_bimbingan,
                'progres_terkini' => $b->progresAktif ? [
                    'persentase'      => $b->progresAktif->persentase,
                    'status_progress' => $b->progresAktif->status_progress,
                    'updated_at'      => $b->progresAktif->updated_at->format('Y-m-d H:i:s'),
                ] : null,
            ];
        });

        return $this->successResponse('Data bimbingan berhasil diambil', $data);
    }
}