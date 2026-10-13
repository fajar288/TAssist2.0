<?php
// app/Models/InformasiTA.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class InformasiTA extends Model
{
    use HasFactory;

    protected $table = 'informasi_ta';
    protected $primaryKey = 'info_id';

    protected $fillable = [
        'admin_id',
        'kategori',
        'judul',
        'konten_or_file',
        'published_at',
    ];

    protected $casts = [
        'published_at' => 'datetime',
        'created_at'   => 'datetime',
        'updated_at'   => 'datetime',
    ];

    // ==================== RELASI ====================

    public function admin()
    {
        return $this->belongsTo(Admin::class, 'admin_id', 'admin_id');
    }
}