<?php

namespace Database\Factories;

use App\Models\BeritaAcara;
use App\Models\Bimbingan;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<BeritaAcara>
 */
class BeritaAcaraFactory extends Factory
{
    protected $model = BeritaAcara::class;

    public function definition(): array
    {
        $year = now()->year;
        $seq = str_pad((string)$this->faker->unique()->numberBetween(1, 9999), 4, '0', STR_PAD_LEFT);
        $token = Str::random(40);
        $hash = hash('sha256', "dummy-pdf-content-{$token}");

        return [
            'bimbingan_id'       => Bimbingan::factory(),
            'nomor'              => "BA/TA/{$year}/{$seq}",
            'periode_mulai'      => now()->subMonths(3)->startOfMonth()->toDateString(),
            'periode_selesai'    => now()->toDateString(),
            'data_snapshot'      => [
                'mahasiswa'   => ['nama' => $this->faker->name(), 'nim' => '12345678'],
                'dosen'       => ['nama' => $this->faker->name(), 'nid' => '87654321'],
                'sesi_count'  => 8,
                'revisi_count'=> 3,
                'progres'     => 75,
            ],
            'file_path'          => "berita_acara/BA_TA_{$year}_{$seq}.pdf",
            'file_hash'          => $hash,
            'token_verifikasi'   => $token,
            'status_persetujuan' => 'draft',
            'metode_persetujuan' => null,
            'tanda_tangan_path'  => null,
            'approved_at'        => null,
            'approved_hash'      => null,
        ];
    }

    public function approved(string $metode = 'pin'): static
    {
        return $this->state(function (array $attributes) use ($metode) {
            $approvedHash = hash('sha256', "approved-{$attributes['token_verifikasi']}");
            return [
                'status_persetujuan' => 'disetujui',
                'metode_persetujuan' => $metode,
                'approved_at'        => now(),
                'approved_hash'      => $approvedHash,
            ];
        });
    }
}
