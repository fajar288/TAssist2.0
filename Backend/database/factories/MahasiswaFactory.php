<?php
// database/factories/MahasiswaFactory.php

namespace Database\Factories;

use App\Models\Mahasiswa;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Mahasiswa>
 */
class MahasiswaFactory extends Factory
{
    protected $model = Mahasiswa::class;

    /**
     * Defaults mirror database/seeders/MahasiswaSeeder.php.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id'  => User::factory()->mahasiswa(),
            'nim'      => $this->faker->unique()->numerify('##########'),
            'prodi'    => 'Teknik Informatika',
            'angkatan' => 2021,
            'topik_ta' => 'Implementasi Machine Learning untuk Prediksi Harga Saham',
            'judul_ta' => 'Prediksi Harga Saham Menggunakan LSTM dan GRU',
        ];
    }

    /**
     * Attach the profile to an existing user account.
     */
    public function forUser(User $user): static
    {
        return $this->state(fn () => ['user_id' => $user->user_id]);
    }

    public function tanpaJudul(): static
    {
        return $this->state(fn () => ['judul_ta' => null]);
    }
}
