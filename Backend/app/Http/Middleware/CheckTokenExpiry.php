<?php
// app/Http/Middleware/CheckTokenExpiry.php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckTokenExpiry
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user) {
            $token = $user->currentAccessToken();

            if ($token && $token->expires_at && $token->expires_at->isPast()) {
                $token->delete();

                return response()->json([
                    'success' => false,
                    'message' => 'Token sudah expired, silakan login ulang',
                ], 401);
            }
        }

        return $next($request);
    }
}