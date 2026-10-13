<?php
// app/Http/Controllers/Web/Admin/DosenController.php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\Dosen;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class DosenController extends Controller
{
    public function index(Request $request)
    {
        $query = Dosen::with('user')
        ->when($request->filled('search'), fn($q) =>
            $q->whereHas('user', fn($u) =>
                $u->where('nama', 'like', '%'.$request->search.'%')
            )->orWhere('nid', 'like', '%'.$request->search.'%')
        )
        ->when($request->filled('bidang_keahlian'), fn($q) =>
            $q->where('bidang_keahlian', 'like', '%'.$request->bidang_keahlian.'%')
        )
        ->when($request->filled('kuota'), function ($q) use ($request) {
            if ($request->kuota === 'full') {
                // Kuota penuh: bimbingan aktif >= kuota
                $q->whereRaw('kuota_bimbingan <= (
                    SELECT COUNT(*) FROM bimbingan
                    WHERE bimbingan.dosen_id = dosen.dosen_id
                    AND bimbingan.status_bimbingan = "aktif"
                )');
            } elseif ($request->kuota === 'available') {
                // Masih ada sisa
                $q->whereRaw('kuota_bimbingan > (
                    SELECT COUNT(*) FROM bimbingan
                    WHERE bimbingan.dosen_id = dosen.dosen_id
                    AND bimbingan.status_bimbingan = "aktif"
                )');
            }
        })
        ->orderByDesc('created_at');

    $dosen = $query->paginate(12)->withQueryString();

    // Ambil list bidang keahlian unik untuk dropdown filter
    $bidangKeahlianList = Dosen::whereNotNull('bidang_keahlian')
        ->distinct()
        ->pluck('bidang_keahlian')
        ->sort()
        ->values();

    return view('admin.dosen.index', compact('dosen', 'bidangKeahlianList'));
    }

    public function create()
    {
        return view('admin.dosen.create');
    }

    public function store(Request $request)
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

            Dosen::create([
                'user_id'         => $user->user_id,
                'nid'             => $request->nid,
                'bidang_keahlian' => $request->bidang_keahlian,
                'kuota_bimbingan' => $request->kuota_bimbingan,
                'profil_singkat'  => $request->profil_singkat,
            ]);

            DB::commit();
            return redirect()->route('admin.dosen.index')
                ->with('success', 'Dosen berhasil ditambahkan.');

        } catch (\Exception $e) {
            DB::rollBack();
            return back()->with('error', 'Gagal: '.$e->getMessage())->withInput();
        }
    }

    public function edit(int $id)
    {
        $dosen = Dosen::with('user')->findOrFail($id);
        return view('admin.dosen.edit', compact('dosen'));
    }

    public function update(Request $request, int $id)
    {
        $dosen = Dosen::with('user')->findOrFail($id);

        $request->validate([
            'nama'            => 'required|string|max:255',
            'email'           => ['required','email', Rule::unique('users','email')->ignore($dosen->user_id,'user_id')],
            'nid'             => ['required','string', Rule::unique('dosen','nid')->ignore($id,'dosen_id')],
            'bidang_keahlian' => 'nullable|string|max:255',
            'kuota_bimbingan' => 'required|integer|min:0',
            'profil_singkat'  => 'nullable|string|max:1000',
            'status_akun'     => 'required|in:aktif,nonaktif',
        ]);

        DB::beginTransaction();
        try {
            $dosen->user->update([
                'nama'        => $request->nama,
                'email'       => $request->email,
                'status_akun' => $request->status_akun,
            ]);

            $dosen->update([
                'nid'             => $request->nid,
                'bidang_keahlian' => $request->bidang_keahlian,
                'kuota_bimbingan' => $request->kuota_bimbingan,
                'profil_singkat'  => $request->profil_singkat,
            ]);

            DB::commit();
            return redirect()->route('admin.dosen.index')
                ->with('success', 'Data dosen berhasil diperbarui.');

        } catch (\Exception $e) {
            DB::rollBack();
            return back()->with('error', 'Gagal: '.$e->getMessage())->withInput();
        }
    }

    public function destroy(int $id)
    {
        $dosen = Dosen::with('user')->findOrFail($id);

        if ($dosen->bimbinganAktif()->exists()) {
            return back()->with('error', 'Tidak dapat menghapus dosen yang masih memiliki bimbingan aktif.');
        }

        DB::beginTransaction();
        try {
            $dosen->user->delete();
            DB::commit();
            return redirect()->route('admin.dosen.index')
                ->with('success', 'Dosen berhasil dihapus.');

        } catch (\Exception $e) {
            DB::rollBack();
            return back()->with('error', 'Gagal: '.$e->getMessage());
        }
    }

    public function updateKuota(Request $request, int $id)
    {
        $request->validate([
            'kuota_bimbingan' => 'required|integer|min:0',
        ]);

        $dosen          = Dosen::findOrFail($id);
        $bimbinganAktif = $dosen->bimbinganAktif()->count();

        if ($request->kuota_bimbingan < $bimbinganAktif) {
            return back()->with('error',
                "Kuota tidak bisa kurang dari bimbingan aktif saat ini ({$bimbinganAktif})."
            );
        }

        $dosen->update(['kuota_bimbingan' => $request->kuota_bimbingan]);

        return back()->with('success', 'Kuota bimbingan berhasil diperbarui.');
    }
}