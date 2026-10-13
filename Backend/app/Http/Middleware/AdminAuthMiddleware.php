<?php
// app/Http/Middleware/AdminAuthMiddleware.php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AdminAuthMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        // Cek session login admin
        if (!session()->has('admin_user')) {
            return redirect()->route('admin.login')
                ->with('error', 'Silakan login terlebih dahulu.');
        }

        $user = session('admin_user');

        if ($user['role'] !== 'admin') {
            session()->flush();
            return redirect()->route('admin.login')
                ->with('error', 'Akses ditolak. Hanya admin yang diizinkan.');
        }

        return $next($request);
    }
}