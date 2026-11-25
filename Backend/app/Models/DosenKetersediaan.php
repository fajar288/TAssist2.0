<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DosenKetersediaan extends Model
{
    use HasFactory;

    protected $table = 'dosen_ketersediaan';
    protected $primaryKey = 'ketersediaan_id';

    protected $fillable = [
        'dosen_id',
        'tipe',
        'hari',
        'tanggal',
        'waktu_mulai',
        'waktu_selesai',
        'is_available',
        'catatan',
    ];

    protected $casts = [
        'tanggal'      => 'date',
        'is_available' => 'boolean',
        'created_at'   => 'datetime',
        'updated_at'   => 'datetime',
    ];

    public function dosen()
    {
        return $this->belongsTo(Dosen::class, 'dosen_id', 'dosen_id');
    }
}
