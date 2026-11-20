<?php
// database/factories/FeedbackDokumenFactory.php

namespace Database\Factories;

use App\Models\FeedbackDokumen;
use App\Models\VersiDokumen;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<FeedbackDokumen>
 */
class FeedbackDokumenFactory extends Factory
{
    protected $model = FeedbackDokumen::class;

    /**
     * The reviewer defaults to the professor of the supervision the version
     * belongs to.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'versi_id'       => VersiDokumen::factory(),
            'dosen_id'       => fn (array $attributes) => VersiDokumen::findOrFail($attributes['versi_id'])
                ->dokumen->bimbingan->dosen_id,
            'komentar'       => 'Perbaiki metodologi pada bab 3 dan tambahkan sitasi.',
            'halaman'        => 12,
            'posisi_anotasi' => null,
        ];
    }

    public function forVersi(VersiDokumen $versi): static
    {
        return $this->state(fn () => ['versi_id' => $versi->versi_id]);
    }
}
