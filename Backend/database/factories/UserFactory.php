<?php
// database/factories/UserFactory.php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    protected $model = User::class;

    /**
     * Defaults mirror database/seeders/{Admin,Dosen,Mahasiswa}Seeder.php:
     * password "password123", status_akun "aktif".
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'nama'          => $this->faker->name(),
            'email'         => $this->faker->unique()->safeEmail(),
            'password_hash' => Hash::make('password123'),
            'role'          => 'mahasiswa',
            'status_akun'   => 'aktif',
        ];
    }

    public function mahasiswa(): static
    {
        return $this->state(fn () => ['role' => 'mahasiswa']);
    }

    public function dosen(): static
    {
        return $this->state(fn () => ['role' => 'dosen']);
    }

    public function admin(): static
    {
        return $this->state(fn () => ['role' => 'admin']);
    }

    public function nonaktif(): static
    {
        return $this->state(fn () => ['status_akun' => 'nonaktif']);
    }

    /**
     * User created through Google login: no local password.
     */
    public function google(): static
    {
        return $this->state(fn () => [
            'password_hash'     => null,
            'google_id'         => $this->faker->unique()->numerify('####################'),
            'avatar'            => null,
            'email_verified_at' => now(),
        ]);
    }
}
