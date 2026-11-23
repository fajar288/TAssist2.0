<?php

namespace Database\Factories;

use App\Models\RisikoKonfigurasi;
use Illuminate\Database\Eloquent\Factories\Factory;

class RisikoKonfigurasiFactory extends Factory
{
    protected $model = RisikoKonfigurasi::class;

    public function definition(): array
    {
        return [
            'nama_sinyal'  => $this->faker->unique()->slug(2),
            'deskripsi'    => $this->faker->sentence(),
            'bobot'        => 0.20,
            'ambang_batas' => [
                'perlu_perhatian' => 14,
                'berisiko'        => 30,
            ],
            'is_active'    => true,
        ];
    }
}
