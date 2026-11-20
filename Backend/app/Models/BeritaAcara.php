<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BeritaAcara extends Model
{
    use HasFactory;

    protected $table = 'berita_acara';
    protected $primaryKey = 'berita_acara_id';

    protected $fillable = [
        'bimbingan_id',
        'nomor',
        'periode_mulai',
        'periode_selesai',
        'data_snapshot',
        'file_path',
        'file_hash',
        'token_verifikasi',
        'status_persetujuan',
        'metode_persetujuan',
        'tanda_tangan_path',
        'approved_at',
        'approved_hash',
    ];

    protected $casts = [
        'periode_mulai'   => 'date',
        'periode_selesai' => 'date',
        'data_snapshot'   => 'array',
        'approved_at'     => 'datetime',
        'created_at'      => 'datetime',
        'updated_at'      => 'datetime',
    ];

    // ==================== RELASI ====================

    public function bimbingan()
    {
        return $this->belongsTo(Bimbingan::class, 'bimbingan_id', 'bimbingan_id');
    }

    // ==================== HELPER ====================

    public function isDraft(): bool
    {
        return $this->status_persetujuan === 'draft';
    }

    public function isDisetujui(): bool
    {
        return $this->status_persetujuan === 'disetujui';
    }

    public function getActiveHash(): ?string
    {
        return $this->approved_hash ?: $this->file_hash;
    }
}
