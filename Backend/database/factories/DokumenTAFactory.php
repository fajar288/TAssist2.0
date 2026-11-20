<?php
// database/factories/DokumenTAFactory.php

namespace Database\Factories;

use App\Models\Bimbingan;
use App\Models\DokumenTA;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<DokumenTA>
 */
class DokumenTAFactory extends Factory
{
    protected $model = DokumenTA::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'bimbingan_id'  => Bimbingan::factory(),
            'jenis_dokumen' => 'proposal',
            'judul_dokumen' => 'Proposal Tugas Akhir',
            'deskripsi'     => 'Dokumen proposal yang diajukan untuk ditinjau dosen pembimbing.',
        ];
    }

    public function forBimbingan(Bimbingan $bimbingan): static
    {
        return $this->state(fn () => ['bimbingan_id' => $bimbingan->bimbingan_id]);
    }
}
