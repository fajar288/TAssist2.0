<?php
// app/Models/User.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $primaryKey = 'user_id';

    protected $fillable = [
        'nama',
        'email',
        'password_hash',
        'role',
        'status_akun',
        'google_id',
        'avatar',
        'email_verified_at',
    ];

    protected $hidden = [
        'password_hash',
    ];

    protected $casts = [
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'email_verified_at' => 'datetime',
    ];

    // Override getAuthPassword agar Sanctum pakai password_hash
    public function getAuthPassword(): string
    {
        return $this->password_hash ?? '';
    }

    // ==================== RELASI ====================

    public function mahasiswa()
    {
        return $this->hasOne(Mahasiswa::class, 'user_id', 'user_id');
    }

    public function dosen()
    {
        return $this->hasOne(Dosen::class, 'user_id', 'user_id');
    }

    public function admin()
    {
        return $this->hasOne(Admin::class, 'user_id', 'user_id');
    }

    public function notifikasi()
    {
        return $this->hasMany(Notifikasi::class, 'user_id', 'user_id');
    }

    public function jadwalDiajukan()
    {
        return $this->hasMany(JadwalBimbingan::class, 'pengaju_user_id', 'user_id');
    }

    public function versiDiupload()
    {
        return $this->hasMany(VersiDokumen::class, 'uploader_user_id', 'user_id');
    }

    // ==================== HELPER ====================

    public function isMahasiswa(): bool
    {
        return $this->role === 'mahasiswa';
    }

    public function isDosen(): bool
    {
        return $this->role === 'dosen';
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }
}