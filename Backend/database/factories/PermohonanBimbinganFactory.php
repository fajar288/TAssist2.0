<?php
// database/factories/PermohonanBimbinganFactory.php

namespace Database\Factories;

use App\Models\Dosen;
use App\Models\Mahasiswa;
use App\Models\PermohonanBimbingan;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<PermohonanBimbingan>
 */
class PermohonanBimbinganFactory extends Factory
{
    protected $model = PermohonanBimbingan::class;

    /**
     * A student asking a professor for supervision. Defaults to the
     * "menunggu" state used by the mahasiswa `ajukan` endpoint.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'mahasiswa_id'      => Mahasiswa::factory(),
            'dosen_id'          => Dosen::factory(),
            'topik_ta'          => 'Sistem Deteksi Penyakit Tanaman Berbasis Deep Learning',
            'tanggal_pengajuan' => now()->toDateString(),
            'status'            => 'menunggu',
            'catatan_respons'   => null,
        ];
    }

    public function forMahasiswa(Mahasiswa $mahasiswa): static
    {
        return $this->state(fn () => ['mahasiswa_id' => $mahasiswa->mahasiswa_id]);
    }

    public function forDosen(Dosen $dosen): static
    {
        return $this->state(fn () => ['dosen_id' => $dosen->dosen_id]);
    }

    public function diterima(): static
    {
        return $this->state(fn () => [
            'status'          => 'diterima',
            'catatan_respons' => null,
        ]);
    }

    public function ditolak(): static
    {
        return $this->state(fn () => [
            'status'          => 'ditolak',
            'catatan_respons' => 'Topik tidak sesuai dengan bidang keahlian saya.',
        ]);
    }
}
