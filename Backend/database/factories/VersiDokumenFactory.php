<?php
// database/factories/VersiDokumenFactory.php

namespace Database\Factories;

use App\Models\DokumenTA;
use App\Models\VersiDokumen;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<VersiDokumen>
 */
class VersiDokumenFactory extends Factory
{
    protected $model = VersiDokumen::class;

    /**
     * The uploader defaults to the student who owns the supervision, which
     * is what the mahasiswa upload endpoints produce.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'dokumen_id'       => DokumenTA::factory(),
            'uploader_user_id' => fn (array $attributes) => DokumenTA::findOrFail($attributes['dokumen_id'])
                ->bimbingan->mahasiswa->user_id,
            'nomor_versi'      => 1,
            'file_url_or_path' => 'dokumen_ta/dummy/proposal-v1.pdf',
            'catatan_revisi'   => null,
            'uploaded_at'      => now(),
            'status_versi'     => 'diajukan',
        ];
    }

    public function forDokumen(DokumenTA $dokumen, int $nomorVersi = 1): static
    {
        return $this->state(fn () => [
            'dokumen_id'  => $dokumen->dokumen_id,
            'nomor_versi' => $nomorVersi,
        ]);
    }
}
