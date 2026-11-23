<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChatbotPesan extends Model
{
    use HasFactory;

    protected $table = 'chatbot_pesan';

    protected $fillable = [
        'percakapan_id',
        'role',
        'pesan',
        'sumber',
        'is_refused',
        'tokens_used',
    ];

    protected $casts = [
        'sumber' => 'array',
        'is_refused' => 'boolean',
        'tokens_used' => 'integer',
    ];

    public function percakapan(): BelongsTo
    {
        return $this->belongsTo(ChatbotPercakapan::class, 'percakapan_id');
    }
}
