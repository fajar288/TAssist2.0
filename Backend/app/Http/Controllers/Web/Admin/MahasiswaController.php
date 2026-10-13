<?php
// app/Http/Controllers/Web/Admin/MahasiswaController.php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\Mahasiswa;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class MahasiswaController extends Controller
{
    public function index(Request $request)
    {
        $mahasiswa = Mahasiswa::with('user')
            ->when($request->filled('search'), fn($q) =>
                $q->whereHas('user', fn($u) =>
                    $u->where('nama', 'like', '%'.$request->search.'%')
                      ->orWhere('email', 'like', '%'.$request->search.'%')
                )->orWhere('nim', 'like', '%'.$request->search.'%')
            )
            ->when($request->filled('prodi'), fn($q) =>
                $q->where('prodi', $request->prodi)
            )
            ->when($request->filled('angkatan'), fn($q) =>
                $q->where('angkatan', $request->angkatan)
            )
            ->orderByDesc('created_at')
            ->paginate(15)
            ->withQueryString();

        return view('admin.mahasiswa.index', compact('mahasiswa'));
    }

    public function create()
    {
        return view('admin.mahasiswa.create');
    }

    public function store(Request $request)
    {
        $request->validate([
            'nama'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users,email',
            'password' => 'required|string|min:8',
            'nim'      => 'required|string|unique:mahasiswa,nim',
            'prodi'    => 'required|string|max:255',
            'angkatan' => 'required|integer|min:2000|max:'.date('Y'),
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

            Mahasiswa::create([
                'user_id'  => $user->user_id,
                'nim'      => $request->nim,
                'prodi'    => $request->prodi,
                'angkatan' => $request->angkatan,
                'topik_ta' => $request->topik_ta,
                'judul_ta' => $request->judul_ta,
            ]);

            DB::commit();
            return redirect()->route('admin.mahasiswa.index')
                ->with('success', 'Mahasiswa berhasil ditambahkan.');

        } catch (\Exception $e) {
            DB::rollBack();
            return back()->with('error', 'Gagal menambahkan mahasiswa: '.$e->getMessage())
                ->withInput();
        }
    }

    public function edit(int $id)
    {
        $mahasiswa = Mahasiswa::with('user')->findOrFail($id);
        return view('admin.mahasiswa.edit', compact('mahasiswa'));
    }

    public function update(Request $request, int $id)
    {
        $mahasiswa = Mahasiswa::with('user')->findOrFail($id);

        $request->validate([
            'nama'     => 'required|string|max:255',
            'email'    => ['required','email', Rule::unique('users','email')->ignore($mahasiswa->user_id, 'user_id')],
            'nim'      => ['required','string', Rule::unique('mahasiswa','nim')->ignore($id, 'mahasiswa_id')],
            'prodi'    => 'required|string|max:255',
            'angkatan' => 'required|integer|min:2000|max:'.date('Y'),
            'topik_ta' => 'nullable|string|max:500',
            'judul_ta' => 'nullable|string|max:500',
            'status_akun' => 'required|in:aktif,nonaktif',
        ]);

        DB::beginTransaction();
        try {
            $mahasiswa->user->update([
                'nama'        => $request->nama,
                'email'       => $request->email,
                'status_akun' => $request->status_akun,
            ]);

            $mahasiswa->update([
                'nim'      => $request->nim,
                'prodi'    => $request->prodi,
                'angkatan' => $request->angkatan,
                'topik_ta' => $request->topik_ta,
                'judul_ta' => $request->judul_ta,
            ]);

            DB::commit();
            return redirect()->route('admin.mahasiswa.index')
                ->with('success', 'Data mahasiswa berhasil diperbarui.');

        } catch (\Exception $e) {
            DB::rollBack();
            return back()->with('error', 'Gagal memperbarui data: '.$e->getMessage())
                ->withInput();
        }
    }

    public function destroy(int $id)
    {
        $mahasiswa = Mahasiswa::with('user')->findOrFail($id);

        if ($mahasiswa->bimbinganAktif()->exists()) {
            return back()->with('error', 'Tidak dapat menghapus mahasiswa yang memiliki bimbingan aktif.');
        }

        DB::beginTransaction();
        try {
            $mahasiswa->user->delete();
            DB::commit();
            return redirect()->route('admin.mahasiswa.index')
                ->with('success', 'Mahasiswa berhasil dihapus.');

        } catch (\Exception $e) {
            DB::rollBack();
            return back()->with('error', 'Gagal menghapus: '.$e->getMessage());
        }
    }
}