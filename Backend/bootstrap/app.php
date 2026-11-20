<?php
// bootstrap/app.php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\URL;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    // `withRouting(commands: ...)` only registers routes/console.php, so the
    // app/Console/Commands directory is NOT auto-discovered here. Register it
    // explicitly (Laravel 11 way) for `dokumen:pindahkan-ke-privat` (T-02).
    ->withCommands([__DIR__.'/../app/Console/Commands'])
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->alias([
            'role'               => \App\Http\Middleware\RoleMiddleware::class,
            'check.token.expiry' => \App\Http\Middleware\CheckTokenExpiry::class,
            'admin.auth'         => \App\Http\Middleware\AdminAuthMiddleware::class,
            'dosen.auth'         => \App\Http\Middleware\DosenAuthMiddleware::class,
        ]);

        // Tambahkan check.token.expiry ke group api
        $middleware->appendToGroup('api', [
            \App\Http\Middleware\CheckTokenExpiry::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        $exceptions->render(function (AuthenticationException $e, Request $request) {
            if ($request->expectsJson()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthenticated. Silakan login terlebih dahulu.',
                ], 401);
            }
        });

        $exceptions->render(function (
            \Illuminate\Validation\ValidationException $e,
            Request $request
        ) {
            if ($request->expectsJson()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validasi gagal',
                    'errors'  => $e->errors(),
                ], 422);
            }
        });

        $exceptions->render(function (
            \Illuminate\Database\Eloquent\ModelNotFoundException $e,
            Request $request
        ) {
            if ($request->expectsJson()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Data tidak ditemukan.',
                ], 404);
            }
        });

        $exceptions->render(function (
            \Symfony\Component\HttpKernel\Exception\NotFoundHttpException $e,
            Request $request
        ) {
            if ($request->expectsJson()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Endpoint tidak ditemukan.',
                ], 404);
            }
        });

        /*
         * T-02 — signed document URLs.
         *
         * Laravel's ValidateSignature middleware always throws the same
         * exception with the message "Invalid signature.", so the distinction
         * between an expired link and a tampered one is made here: a URL whose
         * HMAC is correct but whose `expires` is in the past is "expired".
         * Anything else stays a plain 403.
         */
        $exceptions->render(function (
            \Illuminate\Routing\Exceptions\InvalidSignatureException $e,
            Request $request
        ) {
            $signatureIsCorrect = URL::hasCorrectSignature($request);
            $expired = $signatureIsCorrect && ! URL::signatureHasNotExpired($request);

            $message = $expired ? 'Link has expired' : 'Invalid signature.';

            if ($request->expectsJson() || $request->is('api/*')) {
                return response()->json([
                    'success' => false,
                    'message' => $message,
                ], 403);
            }

            return response($message, 403);
        });
    })->create();