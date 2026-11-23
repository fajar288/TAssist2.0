<?php

namespace Database\Seeders;

use App\Models\RisikoKonfigurasi;
use Illuminate\Database\Seeder;

class RisikoKonfigurasiSeeder extends Seeder
{
    /**
     * Run the database seeds.
     * T-21: Initial risk signals configuration (F-ANL-01 & F-ANL-05).
     */
    public function run(): void
    {
        $signals = [
            [
                'nama_sinyal'  => 'hari_sejak_bimbingan_terakhir',
                'deskripsi'    => 'Hari sejak sesi bimbingan terakhir dikonfirmasi',
                'bobot'        => 0.25,
                'ambang_batas' => [
                    'perlu_perhatian' => 14,
                    'berisiko'        => 30,
                ],
                'is_active'    => true,
            ],
            [
                'nama_sinyal'  => 'hari_sejak_versi_terakhir',
                'deskripsi'    => 'Hari sejak unggahan versi dokumen TA terakhir',
                'bobot'        => 0.20,
                'ambang_batas' => [
                    'perlu_perhatian' => 21,
                    'berisiko'        => 45,
                ],
                'is_active'    => true,
            ],
            [
                'nama_sinyal'  => 'anotasi_terbuka_lama',
                'deskripsi'    => 'Jumlah anotasi dokumen terbuka yang melebihi batas usia',
                'bobot'        => 0.15,
                'ambang_batas' => [
                    'ambang_hari'     => 14,
                    'perlu_perhatian' => 1,
                    'berisiko'        => 3,
                ],
                'is_active'    => true,
            ],
            [
                'nama_sinyal'  => 'checklist_terlambat',
                'deskripsi'    => 'Jumlah item checklist progress yang melewati tenggat waktu',
                'bobot'        => 0.15,
                'ambang_batas' => [
                    'ambang_item'     => 2,
                    'perlu_perhatian' => 1,
                    'berisiko'        => 2,
                ],
                'is_active'    => true,
            ],
            [
                'nama_sinyal'  => 'progres_stagnan',
                'deskripsi'    => 'Hari tanpa perubahan persentase progress TA',
                'bobot'        => 0.15,
                'ambang_batas' => [
                    'perlu_perhatian' => 21,
                    'berisiko'        => 45,
                ],
                'is_active'    => true,
            ],
            [
                'nama_sinyal'  => 'waktu_terpakai_periode',
                'deskripsi'    => 'Persentase waktu periode TA yang telah terpakai',
                'bobot'        => 0.10,
                'ambang_batas' => [
                    'perlu_perhatian' => 0.60,
                    'berisiko'        => 0.80,
                ],
                'is_active'    => true,
            ],
            [
                'nama_sinyal'  => 'ambang_hari_idle_nudge',
                'deskripsi'    => 'Ambang batas hari tanpa bimbingan untuk pengiriman notifikasi idle nudge',
                'bobot'        => 0.00,
                'ambang_batas' => [
                    'hari' => 21,
                ],
                'is_active'    => true,
            ],
        ];

        foreach ($signals as $signal) {
            RisikoKonfigurasi::updateOrCreate(
                ['nama_sinyal' => $signal['nama_sinyal']],
                $signal
            );
        }
    }
}
