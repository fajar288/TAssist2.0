<?php
// tests/Feature/Auth/NimNidValidationTest.php

it('rejects registration with non-numeric NIM for mahasiswa', function () {
    $payload = [
        'nama'                  => 'Mahasiswa Alpha',
        'email'                 => 'alpha@test.com',
        'password'              => 'password123',
        'password_confirmation' => 'password123',
        'nim'                   => '331230ABCD', // Non-numeric
        'prodi'                 => 'Teknik Informatika',
        'angkatan'              => 2023,
    ];

    $response = $this->postJson('/api/v1/register/mahasiswa', $payload);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['nim']);
});

it('rejects registration with non-numeric NID for dosen', function () {
    $payload = [
        'nama'                  => 'Dosen Beta',
        'email'                 => 'beta@test.com',
        'password'              => 'password123',
        'password_confirmation' => 'password123',
        'nid'                   => 'NID12345XYZ', // Non-numeric
        'kuota_bimbingan'       => 10,
    ];

    $response = $this->postJson('/api/v1/register/dosen', $payload);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['nid']);
});

it('accepts registration with valid numeric NIM and NID', function () {
    $responseMahasiswa = $this->postJson('/api/v1/register/mahasiswa', [
        'nama'                  => 'Mahasiswa Gamma',
        'email'                 => 'gamma@test.com',
        'password'              => 'password123',
        'password_confirmation' => 'password123',
        'nim'                   => '3312301099',
        'prodi'                 => 'Teknik Informatika',
        'angkatan'              => 2023,
    ]);

    $responseMahasiswa->assertCreated();

    $responseDosen = $this->postJson('/api/v1/register/dosen', [
        'nama'                  => 'Dosen Delta',
        'email'                 => 'delta@test.com',
        'password'              => 'password123',
        'password_confirmation' => 'password123',
        'nid'                   => '198701012015',
        'kuota_bimbingan'       => 8,
    ]);

    $responseDosen->assertCreated();
});
