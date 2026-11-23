<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use InvalidArgumentException;

class RisikoSnapshot extends Model
{
    use HasFactory;

    protected $table = 'risiko_snapshot';
    protected $primaryKey = 'snapshot_id';

    protected $fillable = [
        'bimbingan_id',
        'skor',
        'level',
        'sinyal',
        'tanggal_hitung',
    ];

    protected $casts = [
        'skor'           => 'integer',
        'sinyal'         => 'array',
        'tanggal_hitung' => 'date',
        'created_at'     => 'datetime',
        'updated_at'     => 'datetime',
    ];

    /**
     * Enforce explainability contract (T-23, F-ANL-02).
     */
    protected static function booted(): void
    {
        static::saving(function (RisikoSnapshot $snapshot) {
            $signals = $snapshot->sinyal;

            if (!is_array($signals) || empty($signals)) {
                throw new InvalidArgumentException(
                    'Explainability contract violation: sinyal must be a non-empty array of signal breakdowns.'
                );
            }

            $requiredKeys = ['nama', 'nilai', 'bobot', 'kontribusi', 'deskripsi'];

            foreach ($signals as $index => $item) {
                if (!is_array($item)) {
                    throw new InvalidArgumentException(
                        "Explainability contract violation: signal entry at index {$index} must be an object/array."
                    );
                }

                foreach ($requiredKeys as $key) {
                    if (!array_key_exists($key, $item)) {
                        throw new InvalidArgumentException(
                            "Explainability contract violation: signal entry at index {$index} is missing required key '{$key}'."
                        );
                    }
                }
            }
        });
    }

    // ==================== RELASI ====================

    public function bimbingan()
    {
        return $this->belongsTo(Bimbingan::class, 'bimbingan_id', 'bimbingan_id');
    }

    // ==================== SCOPES ====================

    public function scopeLatestPerBimbingan(Builder $query): Builder
    {
        return $query->orderBy('tanggal_hitung', 'desc')->orderBy('snapshot_id', 'desc');
    }
}
