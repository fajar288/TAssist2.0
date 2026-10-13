<?php
namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreDosenRequest;
use App\Http\Resources\Admin\DosenResource;
use App\Models\Dosen;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class DosenController extends Controller {

    public function index(Request $request) {
        $query = Dosen::with('user');

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('nidn', 'like', "%$search%")
                  ->orWhere('bidang_keahlian', 'like', "%$search%")
                  ->orWhereHas('user', fn($u) => $u->where('nama', 'like', "%$search%"));
            });
        }

        $data = $query->paginate($request->get('per_page', 15));

        return response()->json([
            'success' => true,
            'message' => 'Data dosen berhasil diambil.',
            'data'    => DosenResource::collection($data),
            'meta'    => [
                'current_page' => $data->currentPage(),
                'last_page'    => $data->lastPage(),
                'per_page'     => $data->perPage(),
                'total'        => $data->total(),
            ],
        ]);
    }

    public function show($id) {
        $dosen = Dosen::with(['user', 'bimbingan.mahasiswa.user', 'permohonanBimbingan'])
                      ->findOrFail($id);

        return response()->json([
            'success' => true,
            'message' => 'Detail dosen berhasil diambil.',
            'data'    => new DosenResource($dosen),
        ]);
    }

    public function store(StoreDosenRequest $request) {
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
                'nidn'            => $request->nidn,
                'bidang_keahlian' => $request->bidang_keahlian,
                'kuota_bimbingan' => $request->kuota_bimbingan,
                'profil_singkat'  => $request->profil_singkat,
            ]);

            DB::commit();
            $dosen->load('user');

            return response()->json([
                'success' => true,
                'message' => 'Dosen berhasil ditambahkan.',
                'data'    => new DosenResource($dosen),
            ], 201);
        } catch (\Throwable $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function update(Request $request, $id) {
        $dosen = Dosen::with('user')->findOrFail($id);

        $request->validate([
            'nama'            => 'sometimes|string|max:255',
            'email'           => 'sometimes|email|unique:users,email,'.$dosen->user_id.',user_id',
            'nidn'            => 'sometimes|string|unique:dosen,nidn,'.$id.',dosen_id',
            'bidang_keahlian' => 'nullable|string|max:255',
            'kuota_bimbingan' => 'sometimes|integer|min:1|max:20',
            'profil_singkat'  => 'nullable|string',
        ]);

        DB::beginTransaction();
        try {
            if ($request->hasAny(['nama', 'email'])) {
                $dosen->user->update(array_filter([
                    'nama'  => $request->nama,
                    'email' => $request->email,
                ]));
            }

            $dosen->update(array_filter([
                'nidn'            => $request->nidn,
                'bidang_keahlian' => $request->bidang_keahlian,
                'kuota_bimbingan' => $request->kuota_bimbingan,
                'profil_singkat'  => $request->profil_singkat,
            ], fn($v) => !is_null($v)));

            DB::commit();
            $dosen->load('user');

            return response()->json([
                'success' => true,
                'message' => 'Data dosen berhasil diperbarui.',
                'data'    => new DosenResource($dosen),
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
        $dosen = Dosen::with('user')->findOrFail($id);

        DB::beginTransaction();
        try {
            $user = $dosen->user;
            $dosen->delete();
            $user->delete();
            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Dosen berhasil dihapus.',
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