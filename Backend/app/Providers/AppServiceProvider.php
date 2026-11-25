<?php

namespace App\Providers;

use App\Models\AnotasiDokumen;
use App\Models\Bimbingan;
use App\Models\DosenKetersediaan;
use App\Models\PermohonanBimbingan;
use App\Models\VersiDokumen;
use App\Policies\AnotasiDokumenPolicy;
use App\Policies\BimbinganPolicy;
use App\Policies\DosenKetersediaanPolicy;
use App\Policies\PermohonanBimbinganPolicy;
use App\Policies\VersiDokumenPolicy;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Gate::policy(VersiDokumen::class, VersiDokumenPolicy::class);
        Gate::policy(AnotasiDokumen::class, AnotasiDokumenPolicy::class);
        Gate::policy(PermohonanBimbingan::class, PermohonanBimbinganPolicy::class);
        Gate::policy(DosenKetersediaan::class, DosenKetersediaanPolicy::class);
        Gate::policy(Bimbingan::class, BimbinganPolicy::class);

        // T-34 (F-BOT-04): Per-user daily rate limit (50 messages/day)
        RateLimiter::for('chatbot', function (Request $request) {
            $limit = (int) config('chatbot.per_user_daily_limit', 50);
            $userId = $request->user()?->user_id ?? $request->ip();

            return Limit::perDay($limit)->by($userId)->response(function (Request $request, array $headers) {
                return response()->json([
                    'success' => false,
                    'message' => 'Batas harian tercapai. Silakan coba lagi besok.',
                ], 429, $headers);
            });
        });
    }
}
