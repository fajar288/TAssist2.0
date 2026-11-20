<?php
// database/factories/BimbinganFactory.php

namespace Database\Factories;

use App\Models\Bimbingan;
use App\Models\Dosen;
use App\Models\Mahasiswa;
use App\Models\PermohonanBimbingan;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Bimbingan>
 */
class BimbinganFactory extends Factory
{
    protected $model = Bimbingan::class;

    /**
     * A bimbingan row always belongs to an accepted permohonan; the
     * mahasiswa/dosen pair is derived from that permohonan so the three
     * foreign keys can never disagree.
     *
     * `permohonan_id` must stay first: Laravel resolves the factory
     * attributes in declaration order and the closures below receive the
     * already-resolved primary key.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'permohonan_id'    => PermohonanBimbingan::factory()->diterima(),
            'mahasiswa_id'     => fn (array $attributes) => PermohonanBimbingan::findOrFail($attributes['permohonan_id'])->mahasiswa_id,
            'dosen_id'         => fn (array $attributes) => PermohonanBimbingan::findOrFail($attributes['permohonan_id'])->dosen_id,
            'tanggal_mulai'    => now()->toDateString(),
            'status_bimbingan' => 'aktif',
        ];
    }

    /**
     * Build a supervision for an existing student/professor pair.
     */
    public function untuk(Mahasiswa $mahasiswa, Dosen $dosen): static
    {
        $permohonan = PermohonanBimbingan::factory()
            ->forMahasiswa($mahasiswa)
            ->forDosen($dosen)
            ->diterima()
            ->create();

        return $this->state(fn () => [
            'permohonan_id' => $permohonan->permohonan_id,
            'mahasiswa_id'  => $mahasiswa->mahasiswa_id,
            'dosen_id'      => $dosen->dosen_id,
        ]);
    }

    public function selesai(): static
    {
        return $this->state(fn () => ['status_bimbingan' => 'selesai']);
    }

    public function dibatalkan(): static
    {
        return $this->state(fn () => ['status_bimbingan' => 'dibatalkan']);
    }
}
