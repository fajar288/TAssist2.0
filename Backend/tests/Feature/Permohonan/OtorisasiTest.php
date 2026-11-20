<?php
// tests/Feature/Permohonan/OtorisasiTest.php

use App\Models\Dosen;
use App\Models\Mahasiswa;
use App\Models\PermohonanBimbingan;

it('forbids a mahasiswa from calling the dosen accept endpoint', function () {
    $dosen      = Dosen::factory()->create();
    $mahasiswa  = Mahasiswa::factory()->create();
    $permohonan = PermohonanBimbingan::factory()
        ->forMahasiswa($mahasiswa)
        ->forDosen($dosen)
        ->create();

    $response = $this->withHeaders(authHeaders($mahasiswa->user))
        ->putJson("/api/v1/dosen/permohonan/{$permohonan->permohonan_id}/terima");

    $response->assertForbidden()
        ->assertJsonPath('success', false)
        ->assertJsonPath('message', 'Akses ditolak. Anda tidak memiliki izin untuk mengakses resource ini.');

    $this->assertDatabaseHas('permohonan_bimbingan', [
        'permohonan_id' => $permohonan->permohonan_id,
        'status'        => 'menunggu',
    ]);
    $this->assertDatabaseCount('bimbingan', 0);
});

it('forbids a mahasiswa from calling the dosen reject endpoint', function () {
    $dosen      = Dosen::factory()->create();
    $mahasiswa  = Mahasiswa::factory()->create();
    $permohonan = PermohonanBimbingan::factory()
        ->forMahasiswa($mahasiswa)
        ->forDosen($dosen)
        ->create();

    $this->withHeaders(authHeaders($mahasiswa->user))
        ->putJson("/api/v1/dosen/permohonan/{$permohonan->permohonan_id}/tolak", [
            'catatan_respons' => 'Saya menolak permohonan saya sendiri.',
        ])
        ->assertForbidden()
        ->assertJsonPath('success', false);

    $this->assertDatabaseHas('permohonan_bimbingan', [
        'permohonan_id' => $permohonan->permohonan_id,
        'status'        => 'menunggu',
    ]);
});

it('rejects an unauthenticated call to the dosen endpoints', function () {
    $permohonan = PermohonanBimbingan::factory()->create();

    $this->putJson("/api/v1/dosen/permohonan/{$permohonan->permohonan_id}/terima")
        ->assertStatus(401)
        ->assertJsonPath('success', false);
});
