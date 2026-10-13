<?php
namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreMahasiswaRequest;
use App\Http\Requests\Admin\UpdateMahasiswaRequest;
use App\Http\Resources\Admin\MahasiswaResource;
use App\Models\Mahasiswa;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class MahasiswaController extends Controller {

    public function index(Request $request) {
        $query = Mahasiswa::with('user');

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('nim', 'like', "%$search%")
                  ->orWhere('prodi', 'like', "%$search%")
                  ->orWhereHas('user', fn($u) => $u->where('nama', 'like', "%$search%")
                                                     ->orWhere('email', 'like', "%$search%"));
            });
        }

        if ($request->filled('prodi')) {
            $query->where('prodi', $request->prodi);
        }

        if ($request->filled('angkatan')) {
            $query->where('angkatan', $request->angkatan);
        }

        $data = $query->paginate($request->get('per_page', 15));

        return response()->json([
            'success' => true,
            'message' => 'Data mahasiswa berhasil diambil.',
            'data'    => MahasiswaResource::collection($data),
            'meta'    => [
                'current_page' => $data->currentPage(),
                'last_page'    => $data->lastPage(),
                'per_page'     => $data->perPage(),
                'total'        => $data->total(),
            ],
        ]);
    }

    public function show($id) {
        $mahasiswa = Mahasiswa::with(['user', 'permohonanBimbingan.dosen.user', 'bimbingan'])
                              ->findOrFail($id);

        return response()->json([
            'success' => true,
            'message' => 'Detail mahasiswa berhasil diambil.',
            'data'    => new MahasiswaResource($mahasiswa),
        ]);
    }

    public function store(StoreMahasiswaRequest $request) {
        DB::beginTransaction();
        try {
            $user = User::create([
                'nama'        => $request->nama,
                'email'       => $request->email,
                'password_hash' => Hash::make($request->password),
                'role'        => 'mahasiswa',
                'status_akun' => 'aktif',
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
            $mahasiswa->load('user');

            return response()->json([
                'success' => true,
                'message' => 'Mahasiswa berhasil ditambahkan.',
                'data'    => new MahasiswaResource($mahasiswa),
            ], 201);
        } catch (\Throwable $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function update(UpdateMahasiswaRequest $request, $id) {
        $mahasiswa = Mahasiswa::with('user')->findOrFail($id);

        DB::beginTransaction();
        try {
            if ($request->hasAny(['nama', 'email'])) {
                $mahasiswa->user->update(array_filter([
                    'nama'  => $request->nama,
                    'email' => $request->email,
                ]));
            }

            $mahasiswa->update(array_filter([
                'nim'      => $request->nim,
                'prodi'    => $request->prodi,
                'angkatan' => $request->angkatan,
                'topik_ta' => $request->topik_ta,
                'judul_ta' => $request->judul_ta,
            ], fn($v) => !is_null($v)));

            DB::commit();
            $mahasiswa->load('user');

            return response()->json([
                'success' => true,
                'message' => 'Data mahasiswa berhasil diperbarui.',
                'data'    => new MahasiswaResource($mahasiswa),
            ]);
        } catch (\Throwable $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function destroy($id) {
        $mahasiswa = Mahasiswa::with('user')->findOrFail($id);

        DB::beginTransaction();
        try {
            $user = $mahasiswa->user;
            $mahasiswa->delete();
            $user->delete();
            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Mahasiswa berhasil dihapus.',
            ]);
        } catch (\Throwable $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan: ' . $e->getMessage(),
            ], 500);
        }
    }
}