<?php
// database/factories/PeriodeLiburFactory.php

namespace Database\Factories;

use App\Models\PeriodeLibur;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Carbon;

/**
 * @extends Factory<PeriodeLibur>
 */
class PeriodeLiburFactory extends Factory
{
    protected $model = PeriodeLibur::class;

    /**
     * Default window straddles today, so `scopeAktif()` / `isBerlangsung()`
     * match without extra arguments.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'mulai'      => now()->subDays(7)->toDateString(),
            'selesai'    => now()->addDays(7)->toDateString(),
            'keterangan' => 'Libur semester',
        ];
    }

    /**
     * Explicit window, used by boundary tests.
     */
    public function rentang($mulai, $selesai): static
    {
        return $this->state(fn () => [
            'mulai'   => Carbon::parse($mulai)->toDateString(),
            'selesai' => Carbon::parse($selesai)->toDateString(),
        ]);
    }
}
