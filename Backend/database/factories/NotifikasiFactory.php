<?php
// database/factories/NotifikasiFactory.php

namespace Database\Factories;

use App\Models\Notifikasi;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Notifikasi>
 */
class NotifikasiFactory extends Factory
{
    protected $model = Notifikasi::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id'         => User::factory(),
            'tipe_notifikasi' => 'permohonan_diterima',
            'judul'           => 'Permohonan Bimbingan Diterima',
            'pesan'           => 'Permohonan bimbingan Anda telah diterima.',
            'ref_tabel'       => null,
            'ref_id'          => null,
            'is_read'         => false,
        ];
    }

    public function forUser(User $user): static
    {
        return $this->state(fn () => ['user_id' => $user->user_id]);
    }

    public function sudahDibaca(): static
    {
        return $this->state(fn () => ['is_read' => true]);
    }
}
