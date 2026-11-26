<?php

namespace Database\Seeders;

use App\Models\RekomendasiKonfigurasi;
use Illuminate\Database\Seeder;

class RekomendasiKonfigurasiSeeder extends Seeder
{
    /**
     * T-47: Seed default supervisor recommendation weights (F-SUP-06).
     */
    public function run(): void
    {
        if (! RekomendasiKonfigurasi::query()->exists()) {
            RekomendasiKonfigurasi::create([
                'bobot_kemiripan'    => RekomendasiKonfigurasi::DEFAULT_ALPHA,
                'bobot_kuota'        => RekomendasiKonfigurasi::DEFAULT_BETA,
                'bobot_beban'        => RekomendasiKonfigurasi::DEFAULT_GAMMA,
                'ambang_skor_rendah' => RekomendasiKonfigurasi::DEFAULT_LOW_SCORE_THRESHOLD,
            ]);
        }
    }
}
