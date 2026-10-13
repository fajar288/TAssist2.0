<?php
// app/Http/Controllers/Api/Admin/AdminMahasiswaController.php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\UpdateMahasiswaRequest;
use App\Models\Mahasiswa;
use App\Models\User;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class AdminMahasiswaController extends Controller
{
    use ApiResponse;

    // GET /api/admin/mahasiswa
    public function index(Request $request): JsonResponse
    {
        $mahasiswa = Mahasiswa::with('user')
            ->when(
                $request->filled('prodi'),
                fn($q) => $q->where('prodi', 'like', '%' . $request->prodi . '%')
            )
            ->when(
                $request->filled('angkatan'),
                fn($q) => $q->where('angkatan', $request->angkatan)
            )
            ->when(
                $request->filled('search'),
                fn($q) => $q->whereHas('user', function ($u) use ($request) {
                    $u->where('nama', 'like', '%' . $request->search . '%')
                      ->orWhere('email', 'like', '%' . $request->search . '%');
                })->orWhere('nim', 'like', '%' . $request->search . '%')
            )
            ->orderByDesc('created_at')
            ->paginate($request->get('per_page', 15));

        $data = $mahasiswa->through(fn($m) => [
            'mahasiswa_id' => $m->mahasiswa_id,
            'nim'          => $m->nim,
            'prodi'        => $m->prodi,
            'angkatan'     => $m->angkatan,
            'topik_ta'     => $m->topik_ta,
            'judul_ta'     => $m->judul_ta,
            'user'         => [
                'user_id'     => $m->user->user_id,
                'nama'        => $m->user->nama,
                'email'       => $m->user->email,
                'status_akun' => $m->user->status_akun,
                'created_at'  => $m->user->created_at->format('Y-m-d H:i:s'),
            ],
        ]);

        return $this->successResponse('Daftar mahasiswa berhasil diambil', $data);
    }

    // POST /api/admin/mahasiswa
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'nama'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users,email',
            'password' => 'required|string|min:8',
            'nim'      => 'required|string|unique:mahasiswa,nim',
            'prodi'    => 'required|string|max:255',
            'angkatan' => 'required|integer|min:2000|max:' . date('Y'),
            'topik_ta' => 'nullable|string|max:500',
            'judul_ta' => 'nullable|string|max:500',
        ]);

        DB::beginTransaction();
        try {
            $user = User::create([
                'nama'          => $request->nama,
                'email'         => $request->email,
                'password_hash' => Hash::make($request->password),
                'role'          => 'mahasiswa',
                'status_akun'   => 'aktif',
            ]);

            $mahasiswa = Mahasiswa::create([
                'user_id'  => $user->user_id,
                'nim'      => $request->nim,
                'prodi'    => $request->prodi,
                'angkatan' => $request->angkatan,
                'topik_ta' => $request->topik_ta,
                'judul_ta' => $request->judul_ta,
            ]);

            DB::commit();

            return $this->successResponse('Mahasiswa berhasil ditambahkan', [
                'mahasiswa_id' => $mahasiswa->mahasiswa_id,
                'nim'          => $mahasiswa->nim,
                'prodi'        => $mahasiswa->prodi,
                'angkatan'     => $mahasiswa->angkatan,
                'user'         => [
                    'user_id' => $user->user_id,
                    'nama'    => $user->nama,
                    'email'   => $user->email,
                ],
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return $this->errorResponse('Gagal menambahkan mahasiswa: ' . $e->getMessage(), null, 500);
        }
    }

    // PUT /api/admin/mahasiswa/{id}
    public function update(UpdateMahasiswaRequest $request, int $id): JsonResponse
    {
        $mahasiswa = Mahasiswa::with('user')->findOrFail($id);

        DB::beginTransaction();
        try {
            // Update user fields
            $userFields = [];
            if ($request->filled('nama'))  $userFields['nama']  = $request->nama;
            if ($request->filled('email')) $userFields['email'] = $request->email;
            if ($request->filled('status_akun')) {
                $userFields['status_akun'] = $request->status_akun;
            }
            if (!empty($userFields)) {
                $mahasiswa->user->update($userFields);
            }

            // Update mahasiswa fields
            $mahasiswaFields = [];
            if ($request->filled('nim'))      $mahasiswaFields['nim']      = $request->nim;
            if ($request->filled('prodi'))    $mahasiswaFields['prodi']    = $request->prodi;
            if ($request->filled('angkatan')) $mahasiswaFields['angkatan'] = $request->angkatan;
            if ($request->has('topik_ta'))    $mahasiswaFields['topik_ta'] = $request->topik_ta;
            if ($request->has('judul_ta'))    $mahasiswaFields['judul_ta'] = $request->judul_ta;
            if (!empty($mahasiswaFields)) {
                $mahasiswa->update($mahasiswaFields);
            }

            DB::commit();
            $mahasiswa->refresh();
            $mahasiswa->user->refresh();

            return $this->successResponse('Data mahasiswa berhasil diperbarui', [
                'mahasiswa_id' => $mahasiswa->mahasiswa_id,
                'nim'          => $mahasiswa->nim,
                'prodi'        => $mahasiswa->prodi,
                'angkatan'     => $mahasiswa->angkatan,
                'topik_ta'     => $mahasiswa->topik_ta,
                'judul_ta'     => $mahasiswa->judul_ta,
                'user'         => [
                    'user_id'     => $mahasiswa->user->user_id,
                    'nama'        => $mahasiswa->user->nama,
                    'email'       => $mahasiswa->user->email,
                    'status_akun' => $mahasiswa->user->status_akun,
                ],
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return $this->errorResponse('Gagal memperbarui data: ' . $e->getMessage(), null, 500);
        }
    }

    // DELETE /api/admin/mahasiswa/{id}
    public function destroy(int $id): JsonResponse
    {
        $mahasiswa = Mahasiswa::with('user')->findOrFail($id);

        // Cek apakah mahasiswa punya bimbingan aktif
        if ($mahasiswa->bimbinganAktif()->exists()) {
            return $this->errorResponse(
                'Tidak dapat menghapus mahasiswa yang memiliki bimbingan aktif.',
                null, 422
            );
        }

        DB::beginTransaction();
        try {
            $nama = $mahasiswa->user->nama;
            // Cascade delete via user (user delete akan hapus mahasiswa lewat FK cascade)
            $mahasiswa->user->delete();

            DB::commit();

            return $this->successResponse("Mahasiswa {$nama} berhasil dihapus.");

        } catch (\Exception $e) {
            DB::rollBack();
            return $this->errorResponse('Gagal menghapus mahasiswa: ' . $e->getMessage(), null, 500);
        }
    }
}