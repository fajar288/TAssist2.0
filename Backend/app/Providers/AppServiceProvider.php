<?php

namespace App\Providers;

use App\Models\AnotasiDokumen;
use App\Models\VersiDokumen;
use App\Policies\AnotasiDokumenPolicy;
use App\Policies\VersiDokumenPolicy;
use Illuminate\Support\Facades\Gate;
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
    }
}

