<?php

namespace App\Models;

use App\Services\Chatbot\StemmerService;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BasisPengetahuanTA extends Model
{
    use HasFactory;

    protected $table = 'basis_pengetahuan_ta';

    protected $fillable = [
        'kategori',
        'judul',
        'konten',
        'tags',
        'stemmed_konten',
        'is_active',
    ];

    protected $casts = [
        'tags' => 'array',
        'is_active' => 'boolean',
    ];

    protected static function booted()
    {
        static::saving(function ($model) {
            $stemmer = app(StemmerService::class);
            $combined = ($model->judul ?? '') . ' ' . ($model->konten ?? '');
            if (is_array($model->tags)) {
                $combined .= ' ' . implode(' ', $model->tags);
            }
            $tokens = $stemmer->tokenizeAndStem($combined);
            $model->stemmed_konten = implode(' ', $tokens);
        });
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }
}
