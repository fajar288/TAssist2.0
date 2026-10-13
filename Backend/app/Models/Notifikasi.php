<?php
// app/Models/Notifikasi.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Notifikasi extends Model
{
    use HasFactory;

    protected $table = 'notifikasi';
    protected $primaryKey = 'notifikasi_id';

    protected $fillable = [
        'user_id',
        'tipe_notifikasi',
        'judul',
        'pesan',
        'ref_tabel',
        'ref_id',
        'is_read',
    ];

    protected $casts = [
        'is_read'    => 'boolean',
        'ref_id'     => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ==================== RELASI ====================

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'user_id');
    }
}