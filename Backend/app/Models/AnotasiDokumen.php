<?php
// app/Models/AnotasiDokumen.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AnotasiDokumen extends Model
{
    use HasFactory;

    protected $table = 'anotasi_dokumen';
    protected $primaryKey = 'anotasi_id';

    protected $fillable = [
        'versi_id',
        'dosen_id',
        'user_id',
        'parent_id',
        'halaman',
        'x',
        'y',
        'lebar',
        'tinggi',
        'tipe',
        'konten',
        'data_coretan',
        'status',
    ];

    protected $casts = [
        'halaman'      => 'integer',
        'x'            => 'float',
        'y'            => 'float',
        'lebar'        => 'float',
        'tinggi'       => 'float',
        'data_coretan' => 'array',
        'created_at'   => 'datetime',
        'updated_at'   => 'datetime',
    ];

    // ==================== RELASI ====================

    public function versiDokumen()
    {
        return $this->belongsTo(VersiDokumen::class, 'versi_id', 'versi_id');
    }

    public function dosen()
    {
        return $this->belongsTo(Dosen::class, 'dosen_id', 'dosen_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'user_id');
    }

    public function parent()
    {
        return $this->belongsTo(AnotasiDokumen::class, 'parent_id', 'anotasi_id');
    }

    public function replies()
    {
        return $this->hasMany(AnotasiDokumen::class, 'parent_id', 'anotasi_id');
    }

    // ==================== HELPERS ====================

    public function isOpen(): bool
    {
        return $this->status === 'open';
    }

    public function isRevised(): bool
    {
        return $this->status === 'revised';
    }

    public function isResolved(): bool
    {
        return $this->status === 'resolved';
    }
}
