<?php

namespace Database\Factories;

use App\Models\Bimbingan;
use App\Models\RisikoSnapshot;
use Illuminate\Database\Eloquent\Factories\Factory;

class RisikoSnapshotFactory extends Factory
{
    protected $model = RisikoSnapshot::class;

    public function definition(): array
    {
        return [
            'bimbingan_id'   => Bimbingan::factory(),
            'skor'           => 25,
            'level'          => 'aman',
            'sinyal'         => [
                [
                    'nama'       => 'hari_sejak_bimbingan_terakhir',
                    'nilai'      => 5,
                    'bobot'      => 0.25,
                    'kontribusi' => 3.5,
                    'deskripsi'  => '5 hari sejak bimbingan terakhir',
                ],
            ],
            'tanggal_hitung' => now()->toDateString(),
        ];
    }

    public function perluPerhatian(): self
    {
        return $this->state(fn () => [
            'skor'  => 55,
            'level' => 'perlu_perhatian',
        ]);
    }

    public function berisiko(): self
    {
        return $this->state(fn () => [
            'skor'  => 85,
            'level' => 'berisiko',
        ]);
    }
}
