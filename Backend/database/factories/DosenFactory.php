<?php
// database/factories/DosenFactory.php

namespace Database\Factories;

use App\Models\Dosen;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Dosen>
 */
class DosenFactory extends Factory
{
    protected $model = Dosen::class;

    /**
     * Defaults mirror database/seeders/DosenSeeder.php.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id'         => User::factory()->dosen(),
            'nid'             => $this->faker->unique()->numerify('NID###'),
            'bidang_keahlian' => 'Kecerdasan Buatan dan Machine Learning',
            'kuota_bimbingan' => 5,
            'profil_singkat'  => 'Dosen berpengalaman di bidang AI dengan 10 tahun pengalaman penelitian.',
        ];
    }

    /**
     * Attach the profile to an existing user account.
     */
    public function forUser(User $user): static
    {
        return $this->state(fn () => ['user_id' => $user->user_id]);
    }

    public function tanpaKuota(): static
    {
        return $this->state(fn () => ['kuota_bimbingan' => 0]);
    }
}
