<?php
// database/seeders/MahasiswaSeeder.php

namespace Database\Seeders;

use App\Models\Mahasiswa;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class MahasiswaSeeder extends Seeder
{
    public function run(): void
    {
        $mahasiswaData = [
            [
                'nama'     => 'Aldi Firmansyah',
                'email'    => 'aldi.firmansyah@student.ac.id',
                'nim'      => '2021001001',
                'prodi'    => 'Teknik Informatika',
                'angkatan' => 2021,
                'topik_ta' => 'Implementasi Machine Learning untuk Prediksi Harga Saham',
                'judul_ta' => 'Prediksi Harga Saham Menggunakan LSTM dan GRU',
            ],
            [
                'nama'     => 'Bela Putri Amara',
                'email'    => 'bela.putri@student.ac.id',
                'nim'      => '2021001002',
                'prodi'    => 'Teknik Informatika',
                'angkatan' => 2021,
                'topik_ta' => 'Sistem Deteksi Penyakit Tanaman Berbasis Deep Learning',
                'judul_ta' => 'Deteksi Penyakit Daun Padi Menggunakan Convolutional Neural Network',
            ],
            [
                'nama'     => 'Cahyo Dwi Nugroho',
                'email'    => 'cahyo.dwi@student.ac.id',
                'nim'      => '2021001003',
                'prodi'    => 'Sistem Informasi',
                'angkatan' => 2021,
                'topik_ta' => 'Pengembangan Aplikasi E-Commerce dengan Rekomendasi Produk',
                'judul_ta' => null,
            ],
            [
                'nama'     => 'Dewi Rahayu',
                'email'    => 'dewi.rahayu@student.ac.id',
                'nim'      => '2022001001',
                'prodi'    => 'Teknik Informatika',
                'angkatan' => 2022,
                'topik_ta' => 'Keamanan Aplikasi Web',
                'judul_ta' => null,
            ],
            [
                'nama'     => 'Eko Prasetyo',
                'email'    => 'eko.prasetyo@student.ac.id',
                'nim'      => '2022001002',
                'prodi'    => 'Sistem Informasi',
                'angkatan' => 2022,
                'topik_ta' => null,
                'judul_ta' => null,
            ],
        ];

        foreach ($mahasiswaData as $data) {
            $user = User::create([
                'nama'          => $data['nama'],
                'email'         => $data['email'],
                'password_hash' => Hash::make('password123'),
                'role'          => 'mahasiswa',
                'status_akun'   => 'aktif',
            ]);

            Mahasiswa::create([
                'user_id'  => $user->user_id,
                'nim'      => $data['nim'],
                'prodi'    => $data['prodi'],
                'angkatan' => $data['angkatan'],
                'topik_ta' => $data['topik_ta'],
                'judul_ta' => $data['judul_ta'],
            ]);
        }

        $this->command->info('Mahasiswa seeder selesai: ' . count($mahasiswaData) . ' mahasiswa dibuat.');
    }
}