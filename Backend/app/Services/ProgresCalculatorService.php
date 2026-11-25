<?php

namespace App\Services;

use App\Models\Bimbingan;
use App\Models\ChecklistProgress;
use App\Models\ProgresTA;

/**
 * Weighted checklist-driven progress calculator (T-40 / F-PRG-04).
 */
class ProgresCalculatorService
{
    /**
     * Recalculate `progres_ta.persentase` from its weighted checklist items
     * unless manual override (`is_override = true`) is active.
     */
    public function recalculate(ProgresTA $progres): ProgresTA
    {
        $progres->load('checklistProgress');

        if ($progres->is_override) {
            return $progres;
        }

        $items = $progres->checklistProgress;

        if ($items->isEmpty()) {
            $progres->update(['persentase' => 0.0]);
            return $progres->refresh();
        }

        $totalBobot = (float) $items->sum(fn (ChecklistProgress $item) => max(0.0, (float) ($item->bobot ?? 1.0)));

        if ($totalBobot <= 0.0) {
            $persentase = 0.0;
        } else {
            $doneBobot = (float) $items
                ->where('is_selesai', true)
                ->sum(fn (ChecklistProgress $item) => max(0.0, (float) ($item->bobot ?? 1.0)));

            $persentase = round(($doneBobot / $totalBobot) * 100, 2);
        }

        $progres->update(['persentase' => $persentase]);

        return $progres->refresh();
    }

    /**
     * Move active checklist items from the previous latest progress record onto
     * the newly created progress snapshot so checklist tracking stays continuous
     * across progress updates and override transitions.
     */
    public function carryOverLatestChecklist(Bimbingan $bimbingan, ProgresTA $newProgres): void
    {
        $previous = ProgresTA::where('bimbingan_id', $bimbingan->bimbingan_id)
            ->where('progress_id', '!=', $newProgres->progress_id)
            ->orderByDesc('updated_at')
            ->orderByDesc('progress_id')
            ->first();

        if (! $previous) {
            return;
        }

        ChecklistProgress::where('progress_id', $previous->progress_id)
            ->update(['progress_id' => $newProgres->progress_id]);
    }
}
