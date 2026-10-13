<?php
// app/Models/JadwalBimbingan.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class JadwalBimbingan extends Model
{
    use HasFactory;

    protected $table = 'jadwal_bimbingan';
    protected $primaryKey = 'jadwal_id';

    protected $fillable = [
        'bimbingan_id',
        'pengaju_user_id',
        'tanggal',
        'waktu_mulai',
        'waktu_selesai',
        'mode',
        'status_konfirmasi',
        'catatan',
    ];

    protected $casts = [
        'tanggal'    => 'date',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ==================== RELASI ====================

    public function bimbingan()
    {
        return $this->belongsTo(Bimbingan::class, 'bimbingan_id', 'bimbingan_id');
    }

    public function pengaju()
    {
        return $this->belongsTo(User::class, 'pengaju_user_id', 'user_id');
    }
}