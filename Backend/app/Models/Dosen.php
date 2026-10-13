<?php
// app/Models/Dosen.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Dosen extends Model
{
    use HasFactory;

    protected $table = 'dosen';
    protected $primaryKey = 'dosen_id';

    protected $fillable = [
        'user_id',
        'nid',
        'bidang_keahlian',
        'kuota_bimbingan',
        'profil_singkat',
    ];

    protected $casts = [
        'kuota_bimbingan' => 'integer',
        'created_at'      => 'datetime',
        'updated_at'      => 'datetime',
    ];

    // ==================== RELASI ====================

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'user_id');
    }

    public function permohonanBimbingan()
    {
        return $this->hasMany(PermohonanBimbingan::class, 'dosen_id', 'dosen_id');
    }

    public function bimbingan()
    {
        return $this->hasMany(Bimbingan::class, 'dosen_id', 'dosen_id');
    }

    public function bimbinganAktif()
    {
        return $this->hasMany(Bimbingan::class, 'dosen_id', 'dosen_id')
                    ->where('status_bimbingan', 'aktif');
    }

    public function feedbackDokumen()
    {
        return $this->hasMany(FeedbackDokumen::class, 'dosen_id', 'dosen_id');
    }

    public function progresUpdated()
    {
        return $this->hasMany(ProgresTA::class, 'updated_dosen_id', 'dosen_id');
    }

    // ==================== HELPER ====================

    public function sisaKuota(): int
    {
        $bimbinganAktif = $this->bimbinganAktif()->count();
        return max(0, $this->kuota_bimbingan - $bimbinganAktif);
    }

    public function masihAdaKuota(): bool
    {
        return $this->sisaKuota() > 0;
    }
}