<?php
// app/Http/Middleware/DosenAuthMiddleware.php

namespace App\Http\Middleware;

use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class DosenAuthMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        if (!session()->has('dosen_user')) {
            return redirect()->route('dosen.login')
                ->with('error', 'Silakan login sebagai dosen terlebih dahulu.');
        }

        $dosenSession = session('dosen_user');

        $user = User::with('dosen')
            ->where('user_id', $dosenSession['user_id'] ?? null)
            ->where('role', 'dosen')
            ->first();

        if (!$user || $user->status_akun !== 'aktif' || !$user->dosen) {
            session()->forget('dosen_user');

            return redirect()->route('dosen.login')
                ->with('error', 'Session tidak valid atau akun dosen tidak aktif.');
        }

        return $next($request);
    }
}