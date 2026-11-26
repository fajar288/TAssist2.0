<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * T-52: Anonymized low-score topic search log for admin expertise-gap analysis.
 * Deliberately carries no user_id or mahasiswa_id foreign key.
 */
class RekomendasiLogPencarian extends Model
{
    use HasFactory;

    protected $table = 'rekomendasi_log_pencarian';
    protected $primaryKey = 'log_id';
    public $timestamps = false;

    protected $fillable = [
        'topik_kueri',
        'kata_kunci_stemmed',
        'skor_tertinggi',
        'jumlah_kandidat',
        'created_at',
    ];

    protected $casts = [
        'kata_kunci_stemmed' => 'array',
        'skor_tertinggi'     => 'float',
        'jumlah_kandidat'    => 'integer',
        'created_at'         => 'datetime',
    ];
}
