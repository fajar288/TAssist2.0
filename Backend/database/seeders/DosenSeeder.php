<?php
// database/seeders/DosenSeeder.php

namespace Database\Seeders;

use App\Models\Dosen;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DosenSeeder extends Seeder
{
    public function run(): void
    {
        $dosenData = [
            [
                'nama'            => 'Dr. Budi Santoso, M.Kom',
                'email'           => 'budi.santoso@tassist.ac.id',
                'nid'             => 'NID001',
                'bidang_keahlian' => 'Kecerdasan Buatan dan Machine Learning',
                'kuota_bimbingan' => 5,
                'profil_singkat'  => 'Dosen berpengalaman di bidang AI dengan 10 tahun pengalaman penelitian.',
            ],
            [
                'nama'            => 'Dr. Sari Wulandari, M.T',
                'email'           => 'sari.wulandari@tassist.ac.id',
                'nid'             => 'NID002',
                'bidang_keahlian' => 'Rekayasa Perangkat Lunak',
                'kuota_bimbingan' => 4,
                'profil_singkat'  => 'Ahli rekayasa perangkat lunak dengan fokus pada metodologi Agile.',
            ],
            [
                'nama'            => 'Prof. Ahmad Fauzi, Ph.D',
                'email'           => 'ahmad.fauzi@tassist.ac.id',
                'nid'             => 'NID003',
                'bidang_keahlian' => 'Jaringan Komputer dan Keamanan Siber',
                'kuota_bimbingan' => 6,
                'profil_singkat'  => 'Profesor dengan keahlian di bidang keamanan jaringan dan kriptografi.',
            ],
            [
                'nama'            => 'Dr. Rina Kusuma, M.Cs',
                'email'           => 'rina.kusuma@tassist.ac.id',
                'nid'             => 'NID004',
                'bidang_keahlian' => 'Sistem Informasi dan Basis Data',
                'kuota_bimbingan' => 5,
                'profil_singkat'  => 'Spesialis sistem informasi enterprise dan optimasi basis data.',
            ],
            [
                'nama'            => 'Dr. Hendra Gunawan, M.Sc',
                'email'           => 'hendra.gunawan@tassist.ac.id',
                'nid'             => 'NID005',
                'bidang_keahlian' => 'Computer Vision dan Pengolahan Citra',
                'kuota_bimbingan' => 4,
                'profil_singkat'  => 'Peneliti aktif di bidang computer vision dan deep learning.',
            ],
        ];

        foreach ($dosenData as $data) {
            $user = User::create([
                'nama'          => $data['nama'],
                'email'         => $data['email'],
                'password_hash' => Hash::make('password123'),
                'role'          => 'dosen',
                'status_akun'   => 'aktif',
            ]);

            Dosen::create([
                'user_id'         => $user->user_id,
                'nid'             => $data['nid'],
                'bidang_keahlian' => $data['bidang_keahlian'],
                'kuota_bimbingan' => $data['kuota_bimbingan'],
                'profil_singkat'  => $data['profil_singkat'],
            ]);
        }

        $this->command->info('Dosen seeder selesai: ' . count($dosenData) . ' dosen dibuat.');
    }
}