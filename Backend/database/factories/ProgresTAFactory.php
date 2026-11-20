<?php
// database/factories/ProgresTAFactory.php

namespace Database\Factories;

use App\Models\Bimbingan;
use App\Models\ProgresTA;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ProgresTA>
 */
class ProgresTAFactory extends Factory
{
    protected $model = ProgresTA::class;

    /**
     * Mirrors the initial progress row created when a permohonan is
     * accepted (App\Http\Controllers\Api\Dosen\PermohonanBimbinganController).
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'bimbingan_id'     => Bimbingan::factory(),
            'persentase'       => 0,
            'status_progress'  => 'baru dimulai',
            'updated_dosen_id' => fn (array $attributes) => Bimbingan::findOrFail($attributes['bimbingan_id'])->dosen_id,
            'catatan'          => 'Bimbingan dimulai.',
        ];
    }

    public function forBimbingan(Bimbingan $bimbingan): static
    {
        return $this->state(fn () => ['bimbingan_id' => $bimbingan->bimbingan_id]);
    }
}
