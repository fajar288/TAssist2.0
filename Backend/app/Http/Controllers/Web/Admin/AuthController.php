<?php
// app/Http/Controllers/Web/Admin/AuthController.php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function showLogin()
    {
        if (session()->has('admin_user')) {
            return redirect()->route('admin.dashboard');
        }
        return view('admin.auth.login');
    }

    public function login(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required|string',
        ], [
            'email.required'    => 'Email wajib diisi.',
            'password.required' => 'Password wajib diisi.',
        ]);

        $user = User::where('email', $request->email)
            ->where('role', 'admin')
            ->first();

        if (!$user || !Hash::check($request->password, $user->password_hash)) {
            return back()->withErrors([
                'email' => 'Email atau password salah, atau akun bukan admin.',
            ])->withInput($request->only('email'));
        }

        if ($user->status_akun !== 'aktif') {
            return back()->withErrors([
                'email' => 'Akun Anda tidak aktif.',
            ]);
        }

        session()->forget('dosen_user');

        // Simpan data admin ke session
        session([
            'admin_user' => [
                'user_id'  => $user->user_id,
                'nama'     => $user->nama,
                'email'    => $user->email,
                'role'     => $user->role,
                'admin_id' => $user->admin->admin_id,
                'jabatan'  => $user->admin->jabatan,
            ]
        ]);

        return redirect()->route('admin.dashboard')
            ->with('success', 'Selamat datang, ' . $user->nama . '!');
    }

    public function logout(Request $request)
    {
        session()->flush();
        return redirect()->route('admin.login')
            ->with('success', 'Anda telah logout.');
    }
}