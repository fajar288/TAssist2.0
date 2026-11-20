<?php
// database/factories/JadwalBimbinganFactory.php

namespace Database\Factories;

use App\Models\Bimbingan;
use App\Models\JadwalBimbingan;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<JadwalBimbingan>
 */
class JadwalBimbinganFactory extends Factory
{
    protected $model = JadwalBimbingan::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'bimbingan_id'      => Bimbingan::factory(),
            'pengaju_user_id'   => fn (array $attributes) => Bimbingan::findOrFail($attributes['bimbingan_id'])
                ->mahasiswa->user_id,
            'tanggal'           => now()->addDays(3)->toDateString(),
            'waktu_mulai'       => '09:00:00',
            'waktu_selesai'     => '10:00:00',
            'mode'              => 'online',
            'status_konfirmasi' => 'menunggu',
            'catatan'           => 'Mohon konfirmasi jadwal bimbingan.',
        ];
    }

    public function forBimbingan(Bimbingan $bimbingan): static
    {
        return $this->state(fn () => ['bimbingan_id' => $bimbingan->bimbingan_id]);
    }

    public function dikonfirmasi(): static
    {
        return $this->state(fn () => ['status_konfirmasi' => 'dikonfirmasi']);
    }

    public function ditolak(): static
    {
        return $this->state(fn () => ['status_konfirmasi' => 'ditolak']);
    }
}
