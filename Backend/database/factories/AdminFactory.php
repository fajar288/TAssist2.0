<?php
// database/factories/AdminFactory.php

namespace Database\Factories;

use App\Models\Admin;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Admin>
 */
class AdminFactory extends Factory
{
    protected $model = Admin::class;

    /**
     * Defaults mirror database/seeders/AdminSeeder.php.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory()->admin(),
            'jabatan' => 'Koordinator Tugas Akhir',
        ];
    }

    /**
     * Attach the profile to an existing user account.
     */
    public function forUser(User $user): static
    {
        return $this->state(fn () => ['user_id' => $user->user_id]);
    }
}
