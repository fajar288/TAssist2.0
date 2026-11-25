<?php
// app/Models/ChecklistProgress.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ChecklistProgress extends Model
{
    use HasFactory;

    protected $table = 'checklist_progress';
    protected $primaryKey = 'checklist_id';

    protected $fillable = [
        'progress_id',
        'nama_item',
        'is_selesai',
        'tanggal_selesai',
        'catatan',
        'bobot',
    ];

    protected $casts = [
        'is_selesai'      => 'boolean',
        'bobot'           => 'float',
        'tanggal_selesai' => 'date',
        'created_at'      => 'datetime',
        'updated_at'      => 'datetime',
    ];

    // ==================== RELASI ====================

    public function progresTA()
    {
        return $this->belongsTo(ProgresTA::class, 'progress_id', 'progress_id');
    }
}