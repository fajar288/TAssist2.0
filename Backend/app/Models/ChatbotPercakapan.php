<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ChatbotPercakapan extends Model
{
    use HasFactory;

    protected $table = 'chatbot_percakapan';

    protected $fillable = [
        'user_id',
        'judul',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id', 'user_id');
    }

    public function pesan(): HasMany
    {
        return $this->hasMany(ChatbotPesan::class, 'percakapan_id')->orderBy('created_at', 'asc');
    }

    public function pesanTerakhir()
    {
        return $this->hasOne(ChatbotPesan::class, 'percakapan_id')->latestOfMany('created_at');
    }
}
