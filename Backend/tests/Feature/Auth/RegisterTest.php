<?php
// tests/Feature/Auth/RegisterTest.php

use App\Models\Dosen;
use App\Models\Mahasiswa;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

it('registers a new mahasiswa account', function () {
    $payload = [
        'nama'                  => 'Test Mahasiswa',
        'email'                 => 'test.mahasiswa@student.ac.id',
        'password'              => 'password123',
        'password_confirmation' => 'password123',
        'nim'                   => '2021009999',
        'prodi'                 => 'Teknik Informatika',
        'angkatan'              => 2021,
        'topik_ta'              => 'Implementasi Machine Learning untuk Prediksi Harga Saham',
    ];

    $response = $this->postJson('/api/v1/register/mahasiswa', $payload);

    $response->assertCreated()
        ->assertJsonPath('success', true)
        ->assertJsonPath('message', 'Registrasi mahasiswa berhasil')
        ->assertJsonPath('data.user.role', 'mahasiswa')
        ->assertJsonPath('data.mahasiswa.nim', '2021009999')
        ->assertJsonStructure([
            'success',
            'message',
            'data' => [
                'user' => ['user_id', 'nama', 'email', 'role'],
                'mahasiswa' => ['mahasiswa_id', 'nim', 'prodi', 'angkatan'],
            ],
        ]);

    $user = User::where('email', 'test.mahasiswa@student.ac.id')->first();

    expect($user)->not->toBeNull()
        ->and($user->role)->toBe('mahasiswa')
        ->and($user->status_akun)->toBe('aktif')
        ->and(Hash::check('password123', $user->password_hash))->toBeTrue()
        ->and($user->password_hash)->not->toBe('password123');

    $mahasiswa = Mahasiswa::where('user_id', $user->user_id)->first();

    expect($mahasiswa)->not->toBeNull()
        ->and($mahasiswa->nim)->toBe('2021009999')
        ->and($mahasiswa->angkatan)->toBe(2021);
});

it('registers a new dosen account', function () {
    $payload = [
        'nama'                  => 'Dr. Test Dosen, M.Kom',
        'email'                 => 'test.dosen@tassist.ac.id',
        'password'              => 'password123',
        'password_confirmation' => 'password123',
        'nid'                   => '198701019999',
        'bidang_keahlian'       => 'Rekayasa Perangkat Lunak',
        'kuota_bimbingan'       => 4,
        'profil_singkat'        => 'Fokus pada metodologi Agile.',
    ];

    $response = $this->postJson('/api/v1/register/dosen', $payload);

    $response->assertCreated()
        ->assertJsonPath('success', true)
        ->assertJsonPath('message', 'Registrasi dosen berhasil')
        ->assertJsonPath('data.user.role', 'dosen')
        ->assertJsonPath('data.dosen.nid', '198701019999')
        ->assertJsonPath('data.dosen.kuota_bimbingan', 4);

    $user = User::where('email', 'test.dosen@tassist.ac.id')->first();

    expect($user)->not->toBeNull()
        ->and($user->role)->toBe('dosen');

    $dosen = Dosen::where('user_id', $user->user_id)->first();

    expect($dosen)->not->toBeNull()
        ->and($dosen->nid)->toBe('198701019999')
        ->and($dosen->kuota_bimbingan)->toBe(4)
        ->and($dosen->bidang_keahlian)->toBe('Rekayasa Perangkat Lunak');
});

it('rejects registration with an email that already exists', function () {
    User::factory()->create(['email' => 'dipakai@student.ac.id']);

    $response = $this->postJson('/api/v1/register/mahasiswa', [
        'nama'                  => 'Duplikat',
        'email'                 => 'dipakai@student.ac.id',
        'password'              => 'password123',
        'password_confirmation' => 'password123',
        'nim'                   => '2021008888',
        'prodi'                 => 'Teknik Informatika',
        'angkatan'              => 2021,
    ]);

    $response->assertStatus(422)
        ->assertJsonPath('success', false)
        ->assertJsonPath('message', 'Validasi gagal')
        ->assertJsonValidationErrors('email');

    $this->assertDatabaseCount('mahasiswa', 0);
});
