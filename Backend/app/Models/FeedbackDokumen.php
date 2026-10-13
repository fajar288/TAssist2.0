<?php
// app/Models/FeedbackDokumen.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FeedbackDokumen extends Model
{
    use HasFactory;

    protected $table = 'feedback_dokumen';
    protected $primaryKey = 'feedback_id';

    protected $fillable = [
        'versi_id',
        'dosen_id',
        'komentar',
        'halaman',
        'posisi_anotasi',
    ];

    protected $casts = [
        'halaman'    => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
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
}