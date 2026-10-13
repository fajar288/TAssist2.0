<?php
// database/seeders/AdminSeeder.php

namespace Database\Seeders;

use App\Models\Admin;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::create([
            'nama'          => 'Super Admin',
            'email'         => 'admin@tassist.ac.id',
            'password_hash' => Hash::make('password123'),
            'role'          => 'admin',
            'status_akun'   => 'aktif',
        ]);

        Admin::create([
            'user_id' => $user->user_id,
            'jabatan' => 'Koordinator Tugas Akhir',
        ]);

        $this->command->info('Admin seeder selesai.');
    }
}