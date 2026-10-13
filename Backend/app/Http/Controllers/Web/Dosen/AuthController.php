<?php
// app/Http/Controllers/Web/Dosen/AuthController.php

namespace App\Http\Controllers\Web\Dosen;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function showLogin()
    {
        if (session()->has('dosen_user')) {
            return redirect()->route('dosen.dashboard');
        }

        return view('dosen.auth.login');
    }

    public function login(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required|string',
        ], [
            'email.required'    => 'Email wajib diisi.',
            'email.email'       => 'Format email tidak valid.',
            'password.required' => 'Password wajib diisi.',
        ]);

        $user = User::with('dosen')
            ->where('email', $request->email)
            ->where('role', 'dosen')
            ->first();

        if (!$user || !$user->password_hash || !Hash::check($request->password, $user->password_hash)) {
            return back()->withErrors([
                'email' => 'Email atau password salah, atau akun bukan dosen.',
            ])->withInput($request->only('email'));
        }

        if ($user->status_akun !== 'aktif') {
            return back()->withErrors([
                'email' => 'Akun Anda tidak aktif. Hubungi administrator.',
            ])->withInput($request->only('email'));
        }

        if (!$user->dosen) {
            return back()->withErrors([
                'email' => 'Data profil dosen tidak ditemukan.',
            ])->withInput($request->only('email'));
        }

        // Pastikan session admin tidak ikut aktif saat login sebagai dosen
        session()->forget('admin_user');

        session([
            'dosen_user' => [
                'user_id'          => $user->user_id,
                'nama'             => $user->nama,
                'email'            => $user->email,
                'role'             => $user->role,
                'dosen_id'         => $user->dosen->dosen_id,
                'nid'              => $user->dosen->nid,
                'bidang_keahlian'  => $user->dosen->bidang_keahlian,
                'kuota_bimbingan'  => $user->dosen->kuota_bimbingan,
            ],
        ]);

        return redirect()->route('dosen.dashboard')
            ->with('success', 'Selamat datang, ' . $user->nama . '!');
    }

    public function logout(Request $request)
    {
        session()->forget('dosen_user');

        return redirect()->route('dosen.login')
            ->with('success', 'Anda telah logout.');
    }
}