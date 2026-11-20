<?php
// database/factories/AnotasiDokumenFactory.php

namespace Database\Factories;

use App\Models\AnotasiDokumen;
use App\Models\Dosen;
use App\Models\User;
use App\Models\VersiDokumen;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<AnotasiDokumen>
 */
class AnotasiDokumenFactory extends Factory
{
    protected $model = AnotasiDokumen::class;

    public function definition(): array
    {
        return [
            'versi_id'     => VersiDokumen::factory(),
            'dosen_id'     => Dosen::factory(),
            'user_id'      => fn (array $attributes) => Dosen::find($attributes['dosen_id'])?->user_id ?? User::factory(),
            'parent_id'    => null,
            'halaman'      => $this->faker->numberBetween(1, 50),
            'x'            => $this->faker->randomFloat(4, 0.1, 0.9),
            'y'            => $this->faker->randomFloat(4, 0.1, 0.9),
            'lebar'        => $this->faker->randomFloat(4, 0.05, 0.5),
            'tinggi'       => $this->faker->randomFloat(4, 0.02, 0.2),
            'tipe'         => 'komentar',
            'konten'       => $this->faker->sentence(),
            'data_coretan' => null,
            'status'       => 'open',
        ];
    }

    public function highlight(): static
    {
        return $this->state(fn () => [
            'tipe' => 'highlight',
        ]);
    }

    public function revised(): static
    {
        return $this->state(fn () => [
            'status' => 'revised',
        ]);
    }

    public function resolved(): static
    {
        return $this->state(fn () => [
            'status' => 'resolved',
        ]);
    }
}
