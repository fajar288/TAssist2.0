<?php
// app/Models/PermohonanBimbingan.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PermohonanBimbingan extends Model
{
    use HasFactory;

    protected $table = 'permohonan_bimbingan';
    protected $primaryKey = 'permohonan_id';

    protected $fillable = [
        'mahasiswa_id',
        'dosen_id',
        'topik_ta',
        'tanggal_pengajuan',
        'status',
        'catatan_respons',
    ];

    protected $casts = [
        'tanggal_pengajuan' => 'date',
        'created_at'        => 'datetime',
        'updated_at'        => 'datetime',
    ];

    // ==================== RELASI ====================

    public function mahasiswa()
    {
        return $this->belongsTo(Mahasiswa::class, 'mahasiswa_id', 'mahasiswa_id');
    }

    public function dosen()
    {
        return $this->belongsTo(Dosen::class, 'dosen_id', 'dosen_id');
    }

    public function bimbingan()
    {
        return $this->hasOne(Bimbingan::class, 'permohonan_id', 'permohonan_id');
    }

    // ==================== HELPER ====================

    public function isMenunggu(): bool
    {
        return $this->status === 'menunggu';
    }

    public function isDiterima(): bool
    {
        return $this->status === 'diterima';
    }

    public function isDitolak(): bool
    {
        return $this->status === 'ditolak';
    }
}