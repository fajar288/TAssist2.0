<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RekomendasiKonfigurasi extends Model
{
    use HasFactory;

    protected $table = 'rekomendasi_konfigurasi';
    protected $primaryKey = 'konfigurasi_id';

    public const DEFAULT_ALPHA = 0.60;
    public const DEFAULT_BETA = 0.25;
    public const DEFAULT_GAMMA = 0.15;
    public const DEFAULT_LOW_SCORE_THRESHOLD = 0.30;

    protected $fillable = [
        'bobot_kemiripan',
        'bobot_kuota',
        'bobot_beban',
        'ambang_skor_rendah',
        'updated_by',
    ];

    protected $casts = [
        'bobot_kemiripan'    => 'float',
        'bobot_kuota'        => 'float',
        'bobot_beban'        => 'float',
        'ambang_skor_rendah' => 'float',
        'updated_by'         => 'integer',
        'created_at'         => 'datetime',
        'updated_at'         => 'datetime',
    ];

    public function updater()
    {
        return $this->belongsTo(User::class, 'updated_by', 'user_id');
    }

    /**
     * Retrieve the active configuration row, creating defaults if the table is empty.
     */
    public static function current(): self
    {
        $config = self::query()->orderBy('konfigurasi_id')->first();

        if (! $config) {
            $config = self::create([
                'bobot_kemiripan'    => self::DEFAULT_ALPHA,
                'bobot_kuota'        => self::DEFAULT_BETA,
                'bobot_beban'        => self::DEFAULT_GAMMA,
                'ambang_skor_rendah' => self::DEFAULT_LOW_SCORE_THRESHOLD,
            ]);
        }

        return $config;
    }

    /**
     * Return weights normalized so alpha + beta + gamma = 1.0.
     *
     * @return array{alpha: float, beta: float, gamma: float}
     */
    public function normalizedWeights(): array
    {
        $alpha = max(0.0, (float) $this->bobot_kemiripan);
        $beta = max(0.0, (float) $this->bobot_kuota);
        $gamma = max(0.0, (float) $this->bobot_beban);

        $sum = $alpha + $beta + $gamma;

        if ($sum <= 0.0) {
            return [
                'alpha' => self::DEFAULT_ALPHA,
                'beta'  => self::DEFAULT_BETA,
                'gamma' => self::DEFAULT_GAMMA,
            ];
        }

        return [
            'alpha' => round($alpha / $sum, 4),
            'beta'  => round($beta / $sum, 4),
            'gamma' => round($gamma / $sum, 4),
        ];
    }
}
