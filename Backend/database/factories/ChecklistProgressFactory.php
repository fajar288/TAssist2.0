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
     * `is_selesai` is the boolean "done" flag (renamed from `tgl_selesai` in T-44);
     * `tanggal_selesai` is the real completion date.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'progress_id'     => ProgresTA::factory(),
            'nama_item'       => 'Menyusun Bab 1 (Pendahuluan)',
            'is_selesai'      => false,
            'tanggal_selesai' => null,
            'catatan'         => null,
            'bobot'           => 1.0,
        ];
    }

    public function forProgress(ProgresTA $progres): static
    {
        return $this->state(fn () => ['progress_id' => $progres->progress_id]);
    }

    public function selesai(): static
    {
        return $this->state(fn () => [
            'is_selesai'      => true,
            'tanggal_selesai' => now()->toDateString(),
        ]);
    }
}
