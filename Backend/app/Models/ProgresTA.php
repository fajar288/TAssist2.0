<?php
// app/Models/ProgresTA.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ProgresTA extends Model
{
    use HasFactory;

    protected $table = 'progres_ta';
    protected $primaryKey = 'progress_id';

    protected $fillable = [
        'bimbingan_id',
        'persentase',
        'status_progress',
        'updated_dosen_id',
        'catatan',
    ];

    protected $casts = [
        'persentase'  => 'float',
        'updated_at'  => 'datetime',
        'created_at'  => 'datetime',
    ];

    // ==================== RELASI ====================

    public function bimbingan()
    {
        return $this->belongsTo(Bimbingan::class, 'bimbingan_id', 'bimbingan_id');
    }

    public function updatedDosen()
    {
        return $this->belongsTo(Dosen::class, 'updated_dosen_id', 'dosen_id');
    }

    public function checklistProgress()
    {
        return $this->hasMany(ChecklistProgress::class, 'progress_id', 'progress_id');
    }
}