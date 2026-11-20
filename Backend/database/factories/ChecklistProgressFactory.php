<?php
// database/factories/ChecklistProgressFactory.php

namespace Database\Factories;

use App\Models\ChecklistProgress;
use App\Models\ProgresTA;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ChecklistProgress>
 */
class ChecklistProgressFactory extends Factory
{
    protected $model = ChecklistProgress::class;

    /**
     * `tgl_selesai` is the (misnamed) boolean "done" flag; `tanggal_selesai`
     * is the real completion date. See T-44 for the planned rename.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'progress_id'     => ProgresTA::factory(),
            'nama_item'       => 'Menyusun Bab 1 (Pendahuluan)',
            'tgl_selesai'     => false,
            'tanggal_selesai' => null,
            'catatan'         => null,
        ];
    }

    public function forProgress(ProgresTA $progres): static
    {
        return $this->state(fn () => ['progress_id' => $progres->progress_id]);
    }

    public function selesai(): static
    {
        return $this->state(fn () => [
            'tgl_selesai'     => true,
            'tanggal_selesai' => now()->toDateString(),
        ]);
    }
}
