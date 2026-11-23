<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RisikoKonfigurasi extends Model
{
    use HasFactory;

    protected $table = 'risiko_konfigurasi';
    protected $primaryKey = 'konfigurasi_id';

    protected $fillable = [
        'nama_sinyal',
        'deskripsi',
        'bobot',
        'ambang_batas',
        'is_active',
    ];

    protected $casts = [
        'bobot'        => 'float',
        'ambang_batas' => 'array',
        'is_active'    => 'boolean',
        'created_at'   => 'datetime',
        'updated_at'   => 'datetime',
    ];

    /**
     * Scope for active signals only.
     */
    public function scopeActive(Builder $query): Builder
    {
        return $query->where('is_active', true);
    }

    /**
     * Scope for scoring signals (bobot > 0).
     */
    public function scopeScoring(Builder $query): Builder
    {
        return $query->where('bobot', '>', 0);
    }

    /**
     * Retrieve active scoring signals with renormalized weights summing to 1.0 (T-21, F-ANL-01).
     *
     * @param array<string> $excludedSignalNames Optional signal names to exclude (e.g. when TA period is null)
     * @return Collection<int, self>
     */
    public static function getActiveWithRenormalizedWeights(array $excludedSignalNames = []): Collection
    {
        $signals = self::active()
            ->scoring()
            ->when(!empty($excludedSignalNames), function (Builder $query) use ($excludedSignalNames) {
                $query->whereNotIn('nama_sinyal', $excludedSignalNames);
            })
            ->get();

        $totalWeight = $signals->sum('bobot');

        if ($totalWeight > 0) {
            foreach ($signals as $signal) {
                // Attach dynamic normalized weight
                $signal->bobot_ternormalisasi = round($signal->bobot / $totalWeight, 4);
            }
        } elseif ($signals->isNotEmpty()) {
            $equalShare = round(1.0 / $signals->count(), 4);
            foreach ($signals as $signal) {
                $signal->bobot_ternormalisasi = $equalShare;
            }
        }

        return $signals;
    }
}
