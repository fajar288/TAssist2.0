<?php
// app/Models/Bimbingan.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Bimbingan extends Model
{
    use HasFactory;

    protected $table = 'bimbingan';
    protected $primaryKey = 'bimbingan_id';

    protected $fillable = [
        'permohonan_id',
        'mahasiswa_id',
        'dosen_id',
        'tanggal_mulai',
        'status_bimbingan',
        'tanggal_selesai',
        'periode_mulai',
        'periode_selesai',
        'last_nudge_at',
    ];

    protected $casts = [
        'tanggal_mulai'   => 'date',
        'tanggal_selesai' => 'date',
        'periode_mulai'   => 'date',
        'periode_selesai' => 'date',
        'last_nudge_at'   => 'datetime',
        'created_at'      => 'datetime',
        'updated_at'      => 'datetime',
    ];

    // ==================== RELASI ====================

    public function permohonan()
    {
        return $this->belongsTo(PermohonanBimbingan::class, 'permohonan_id', 'permohonan_id');
    }

    public function mahasiswa()
    {
        return $this->belongsTo(Mahasiswa::class, 'mahasiswa_id', 'mahasiswa_id');
    }

    public function dosen()
    {
        return $this->belongsTo(Dosen::class, 'dosen_id', 'dosen_id');
    }

    public function jadwalBimbingan()
    {
        return $this->hasMany(JadwalBimbingan::class, 'bimbingan_id', 'bimbingan_id');
    }

    public function dokumenTA()
    {
        return $this->hasMany(DokumenTA::class, 'bimbingan_id', 'bimbingan_id');
    }

    public function progresTA()
    {
        return $this->hasMany(ProgresTA::class, 'bimbingan_id', 'bimbingan_id');
    }

    public function progresAktif()
    {
        return $this->hasOne(ProgresTA::class, 'bimbingan_id', 'bimbingan_id')
                    ->latest('updated_at');
    }

    public function beritaAcara()
    {
        return $this->hasMany(BeritaAcara::class, 'bimbingan_id', 'bimbingan_id');
    }

    public function risikoSnapshot()
    {
        return $this->hasMany(RisikoSnapshot::class, 'bimbingan_id', 'bimbingan_id');
    }

    public function latestRisikoSnapshot()
    {
        return $this->hasOne(RisikoSnapshot::class, 'bimbingan_id', 'bimbingan_id')
            ->latestOfMany('tanggal_hitung');
    }

    // ==================== HELPER ====================

    public function isAktif(): bool
    {
        return $this->status_bimbingan === 'aktif';
    }

    public function isSelesai(): bool
    {
        return $this->status_bimbingan === 'selesai';
    }

    public function isDibatalkan(): bool
    {
        return $this->status_bimbingan === 'dibatalkan';
    }

    /**
     * A TA period only counts when both bounds are present (decision C1).
     * A half-filled period is treated as "not set" by the analytics signal.
     */
    public function hasPeriode(): bool
    {
        return $this->periode_mulai !== null && $this->periode_selesai !== null;
    }
}