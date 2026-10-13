<?php
// app/Models/VersiDokumen.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class VersiDokumen extends Model
{
    use HasFactory;

    protected $table = 'versi_dokumen';
    protected $primaryKey = 'versi_id';

    protected $fillable = [
        'dokumen_id',
        'uploader_user_id',
        'nomor_versi',
        'file_url_or_path',
        'catatan_revisi',
        'uploaded_at',
        'status_versi',
    ];

    protected $casts = [
        'uploaded_at' => 'datetime',
        'created_at'  => 'datetime',
        'updated_at'  => 'datetime',
    ];

    // ==================== RELASI ====================

    public function dokumen()
    {
        return $this->belongsTo(DokumenTA::class, 'dokumen_id', 'dokumen_id');
    }

    public function uploader()
    {
        return $this->belongsTo(User::class, 'uploader_user_id', 'user_id');
    }

    public function feedbackDokumen()
    {
        return $this->hasMany(FeedbackDokumen::class, 'versi_id', 'versi_id');
    }
}