<?php
// app/Models/Mahasiswa.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Mahasiswa extends Model
{
    use HasFactory;

    protected $table = 'mahasiswa';
    protected $primaryKey = 'mahasiswa_id';

    protected $fillable = [
        'user_id',
        'nim',
        'prodi',
        'angkatan',
        'topik_ta',
        'judul_ta',
    ];

    protected $casts = [
        'angkatan'   => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ==================== RELASI ====================

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'user_id');
    }

    public function permohonanBimbingan()
    {
        return $this->hasMany(PermohonanBimbingan::class, 'mahasiswa_id', 'mahasiswa_id');
    }

    public function bimbingan()
    {
        return $this->hasMany(Bimbingan::class, 'mahasiswa_id', 'mahasiswa_id');
    }

    public function bimbinganAktif()
    {
        return $this->hasOne(Bimbingan::class, 'mahasiswa_id', 'mahasiswa_id')
                    ->where('status_bimbingan', 'aktif');
    }

    public function permohonanAktif()
    {
        return $this->hasOne(PermohonanBimbingan::class, 'mahasiswa_id', 'mahasiswa_id')
                    ->where('status', 'menunggu');
    }
}