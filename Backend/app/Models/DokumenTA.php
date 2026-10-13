<?php
// app/Models/DokumenTA.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DokumenTA extends Model
{
    use HasFactory;

    protected $table = 'dokumen_ta';
    protected $primaryKey = 'dokumen_id';

    protected $fillable = [
        'bimbingan_id',
        'jenis_dokumen',
        'judul_dokumen',
        'deskripsi',
    ];

    protected $casts = [
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ==================== RELASI ====================

    public function bimbingan()
    {
        return $this->belongsTo(Bimbingan::class, 'bimbingan_id', 'bimbingan_id');
    }

    public function versiDokumen()
    {
        return $this->hasMany(VersiDokumen::class, 'dokumen_id', 'dokumen_id');
    }

    public function versiTerbaru()
    {
        return $this->hasOne(VersiDokumen::class, 'dokumen_id', 'dokumen_id')
                    ->orderByDesc('nomor_versi');
    }
}