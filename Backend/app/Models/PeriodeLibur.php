<?php
// app/Models/PeriodeLibur.php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Carbon;

/**
 * Academic break calendar (decision C2).
 *
 * T-27's idle-supervision nudge is suppressed for any date inside a window
 * (`isBerlangsung()` / `scopeAktif()`). Windows are inclusive on both ends:
 * a break from 2026-12-20 to 2027-01-05 covers both of those days.
 */
class PeriodeLibur extends Model
{
    use HasFactory;

    protected $table = 'periode_libur';
    protected $primaryKey = 'periode_libur_id';

    protected $fillable = [
        'mulai',
        'selesai',
        'keterangan',
    ];

    protected $casts = [
        'mulai'      => 'date',
        'selesai'    => 'date',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ==================== SCOPE ====================

    /**
     * Windows containing the given date (defaults to today).
     */
    public function scopeAktif(Builder $query, $tanggal = null): Builder
    {
        $tanggal = $this->normalizeDate($tanggal);

        return $query->where('mulai', '<=', $tanggal)
                     ->where('selesai', '>=', $tanggal);
    }

    // ==================== HELPER ====================

    /**
     * Is the given date (defaults to today) inside this break window?
     * Inclusive on both boundaries.
     */
    public function isBerlangsung($tanggal = null): bool
    {
        $tanggal = Carbon::parse($this->normalizeDate($tanggal));

        return $tanggal->betweenIncluded($this->mulai, $this->selesai);
    }

    /**
     * Normalize a date-ish value to a `Y-m-d` string for comparison.
     */
    private function normalizeDate($tanggal = null): string
    {
        return $tanggal === null
            ? Carbon::today()->toDateString()
            : Carbon::parse($tanggal)->toDateString();
    }
}
