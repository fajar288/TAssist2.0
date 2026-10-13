<?php
// app/Http/Controllers/Api/Admin/AdminDosenController.php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\UpdateDosenRequest;
use App\Models\Dosen;
use App\Models\User;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class AdminDosenController extends Controller
{
    use ApiResponse;

    // GET /api/admin/dosen
    public function index(Request $request): JsonResponse
    {
        $dosen = Dosen::with('user')
            ->when(
                $request->filled('bidang_keahlian'),
                fn($q) => $q->where(
                    'bidang_keahlian', 'like',
                    '%' . $request->bidang_keahlian . '%'
                )
            )
            ->when(
                $request->filled('search'),
                fn($q) => $q->whereHas('user', function ($u) use ($request) {
                    $u->where('nama', 'like', '%' . $request->search . '%')
                      ->orWhere('email', 'like', '%' . $request->search . '%');
                })->orWhere('nid', 'like', '%' . $request->search . '%')
            )
            ->orderByDesc('created_at')
            ->paginate($request->get('per_page', 15));

        $data = $dosen->through(function ($d) {
            $bimbinganAktif = $d->bimbinganAktif()->count();
            return [
                'dosen_id'        => $d->dosen_id,
                'nid'             => $d->nid,
                'bidang_keahlian' => $d->bidang_keahlian,
                'kuota_bimbingan' => $d->kuota_bimbingan,
                'sisa_kuota'      => max(0, $d->kuota_bimbingan - $bimbinganAktif),
                'bimbingan_aktif' => $bimbinganAktif,
                'profil_singkat'  => $d->profil_singkat,
                'user'            => [
                    'user_id'     => $d->user->user_id,
                    'nama'        => $d->user->nama,
                    'email'       => $d->user->email,
                    'status_akun' => $d->user->status_akun,
                    'created_at'  => $d->user->created_at->format('Y-m-d H:i:s'),
                ],
            ];
        });

        return $this->successResponse('Daftar dosen berhasil diambil', $data);
    }

    // POST /api/admin/dosen
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'nama'            => 'required|string|max:255',
            'email'           => 'required|email|unique:users,email',
            'password'        => 'required|string|min:8',
            'nid'             => 'required|string|unique:dosen,nid',
            'bidang_keahlian' => 'nullable|string|max:255',
            'kuota_bimbingan' => 'required|integer|min:0',
            'profil_singkat'  => 'nullable|string|max:1000',
        ]);

        DB::beginTransaction();
        try {
            $user = User::create([
                'nama'          => $request->nama,
                'email'         => $request->email,
                'password_hash' => Hash::make($request->password),
                'role'          => 'dosen',
                'status_akun'   => 'aktif',
            ]);

            $dosen = Dosen::create([
                'user_id'         => $user->user_id,
                'nid'             => $request->nid,
                'bidang_keahlian' => $request->bidang_keahlian,
                'kuota_bimbingan' => $request->kuota_bimbingan,
                'profil_singkat'  => $request->profil_singkat,
            ]);

            DB::commit();

            return $this->successResponse('Dosen berhasil ditambahkan', [
                'dosen_id'        => $dosen->dosen_id,
                'nid'             => $dosen->nid,
                'bidang_keahlian' => $dosen->bidang_keahlian,
                'kuota_bimbingan' => $dosen->kuota_bimbingan,
                'user'            => [
                    'user_id' => $user->user_id,
                    'nama'    => $user->nama,
                    'email'   => $user->email,
                ],
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return $this->errorResponse('Gagal menambahkan dosen: ' . $e->getMessage(), null, 500);
        }
    }

    // PUT /api/admin/dosen/{id}
    public function update(UpdateDosenRequest $request, int $id): JsonResponse
    {
        $dosen = Dosen::with('user')->findOrFail($id);

        DB::beginTransaction();
        try {
            // Update user fields
            $userFields = [];
            if ($request->filled('nama'))        $userFields['nama']        = $request->nama;
            if ($request->filled('email'))       $userFields['email']       = $request->email;
            if ($request->filled('status_akun')) $userFields['status_akun'] = $request->status_akun;
            if (!empty($userFields)) {
                $dosen->user->update($userFields);
            }

            // Update dosen fields
            $dosenFields = [];
            if ($request->filled('nid'))              $dosenFields['nid']             = $request->nid;
            if ($request->filled('bidang_keahlian'))  $dosenFields['bidang_keahlian'] = $request->bidang_keahlian;
            if ($request->has('kuota_bimbingan'))     $dosenFields['kuota_bimbingan'] = $request->kuota_bimbingan;
            if ($request->has('profil_singkat'))      $dosenFields['profil_singkat']  = $request->profil_singkat;
            if (!empty($dosenFields)) {
                $dosen->update($dosenFields);
            }

            DB::commit();
            $dosen->refresh();
            $dosen->user->refresh();

            return $this->successResponse('Data dosen berhasil diperbarui', [
                'dosen_id'        => $dosen->dosen_id,
                'nid'             => $dosen->nid,
                'bidang_keahlian' => $dosen->bidang_keahlian,
                'kuota_bimbingan' => $dosen->kuota_bimbingan,
                'profil_singkat'  => $dosen->profil_singkat,
                'user'            => [
                    'user_id'     => $dosen->user->user_id,
                    'nama'        => $dosen->user->nama,
                    'email'       => $dosen->user->email,
                    'status_akun' => $dosen->user->status_akun,
                ],
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return $this->errorResponse('Gagal memperbarui data: ' . $e->getMessage(), null, 500);
        }
    }

    // DELETE /api/admin/dosen/{id}
    public function destroy(int $id): JsonResponse
    {
        $dosen = Dosen::with('user')->findOrFail($id);

        if ($dosen->bimbinganAktif()->exists()) {
            return $this->errorResponse(
                'Tidak dapat menghapus dosen yang masih memiliki bimbingan aktif.',
                null, 422
            );
        }

        DB::beginTransaction();
        try {
            $nama = $dosen->user->nama;
            $dosen->user->delete();

            DB::commit();

            return $this->successResponse("Dosen {$nama} berhasil dihapus.");

        } catch (\Exception $e) {
            DB::rollBack();
            return $this->errorResponse('Gagal menghapus dosen: ' . $e->getMessage(), null, 500);
        }
    }

    // PUT /api/admin/dosen/{id}/kuota
    public function updateKuota(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'kuota_bimbingan' => 'required|integer|min:0',
        ], [
            'kuota_bimbingan.required' => 'Kuota bimbingan wajib diisi.',
            'kuota_bimbingan.integer'  => 'Kuota bimbingan harus berupa angka.',
            'kuota_bimbingan.min'      => 'Kuota bimbingan tidak boleh negatif.',
        ]);

        $dosen = Dosen::with('user')->findOrFail($id);

        $bimbinganAktif = $dosen->bimbinganAktif()->count();

        // Pastikan kuota baru tidak lebih kecil dari jumlah bimbingan aktif
        if ($request->kuota_bimbingan < $bimbinganAktif) {
            return $this->errorResponse(
                "Kuota tidak bisa dikurangi di bawah jumlah bimbingan aktif saat ini ({$bimbinganAktif}).",
                null, 422
            );
        }

        $dosen->update(['kuota_bimbingan' => $request->kuota_bimbingan]);

        return $this->successResponse('Kuota bimbingan berhasil diperbarui', [
            'dosen_id'        => $dosen->dosen_id,
            'nama'            => $dosen->user->nama,
            'kuota_bimbingan' => $dosen->kuota_bimbingan,
            'bimbingan_aktif' => $bimbinganAktif,
            'sisa_kuota'      => max(0, $dosen->kuota_bimbingan - $bimbinganAktif),
        ]);
    }
}