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
    ];

    protected $casts = [
        'tanggal_mulai' => 'date',
        'created_at'    => 'datetime',
        'updated_at'    => 'datetime',
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

    // ==================== HELPER ====================

    public function isAktif(): bool
    {
        return $this->status_bimbingan === 'aktif';
    }
}