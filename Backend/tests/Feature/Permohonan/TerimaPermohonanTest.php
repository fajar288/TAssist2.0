<?php
// tests/Feature/Permohonan/TerimaPermohonanTest.php

use App\Models\Bimbingan;
use App\Models\Dosen;
use App\Models\Mahasiswa;
use App\Models\PermohonanBimbingan;

it('accepts a pending supervision request and creates the bimbingan', function () {
    $dosen      = Dosen::factory()->create(['kuota_bimbingan' => 2]);
    $mahasiswa  = Mahasiswa::factory()->create();
    $permohonan = PermohonanBimbingan::factory()
        ->forMahasiswa($mahasiswa)
        ->forDosen($dosen)
        ->create();

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->putJson("/api/v1/dosen/permohonan/{$permohonan->permohonan_id}/terima");

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonPath('message', 'Permohonan berhasil diterima dan bimbingan dibuat')
        ->assertJsonPath('data.permohonan_id', $permohonan->permohonan_id)
        ->assertJsonPath('data.status', 'diterima')
        ->assertJsonPath('data.bimbingan.status_bimbingan', 'aktif')
        ->assertJsonPath('data.mahasiswa.nim', $mahasiswa->nim)
        ->assertJsonStructure([
            'success',
            'message',
            'data' => [
                'permohonan_id',
                'status',
                'bimbingan' => ['bimbingan_id', 'tanggal_mulai', 'status_bimbingan'],
                'mahasiswa' => ['nama', 'nim'],
            ],
        ]);

    $this->assertDatabaseHas('permohonan_bimbingan', [
        'permohonan_id' => $permohonan->permohonan_id,
        'status'        => 'diterima',
    ]);

    $bimbingan = Bimbingan::where('permohonan_id', $permohonan->permohonan_id)->first();

    expect($bimbingan)->not->toBeNull()
        ->and($bimbingan->status_bimbingan)->toBe('aktif')
        ->and($bimbingan->mahasiswa_id)->toBe($mahasiswa->mahasiswa_id)
        ->and($bimbingan->dosen_id)->toBe($dosen->dosen_id)
        ->and($bimbingan->tanggal_mulai->toDateString())->toBe(now()->toDateString());

    // The acceptance also seeds the initial progress row.
    $this->assertDatabaseHas('progres_ta', [
        'bimbingan_id'    => $bimbingan->bimbingan_id,
        'status_progress' => 'baru dimulai',
    ]);

    // ... and notifies the student.
    $this->assertDatabaseHas('notifikasi', [
        'user_id'         => $mahasiswa->user_id,
        'tipe_notifikasi' => 'permohonan_diterima',
        'ref_tabel'       => 'bimbingan',
        'ref_id'          => $bimbingan->bimbingan_id,
        'is_read'         => false,
    ]);
});

it('refuses to accept a request twice', function () {
    $dosen      = Dosen::factory()->create(['kuota_bimbingan' => 2]);
    $mahasiswa  = Mahasiswa::factory()->create();
    $permohonan = PermohonanBimbingan::factory()
        ->forMahasiswa($mahasiswa)
        ->forDosen($dosen)
        ->diterima()
        ->create();

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->putJson("/api/v1/dosen/permohonan/{$permohonan->permohonan_id}/terima");

    $response->assertStatus(422)
        ->assertJsonPath('success', false)
        ->assertJsonPath('message', 'Permohonan ini sudah diproses sebelumnya.');

    $this->assertDatabaseCount('bimbingan', 0);
});

it('refuses to accept a request when the professor quota is full', function () {
    $dosen     = Dosen::factory()->create(['kuota_bimbingan' => 1]);
    $mahasiswa = Mahasiswa::factory()->create();

    // Fill the single available slot.
    Bimbingan::factory()->untuk(Mahasiswa::factory()->create(), $dosen)->create();

    $permohonan = PermohonanBimbingan::factory()
        ->forMahasiswa($mahasiswa)
        ->forDosen($dosen)
        ->create();

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->putJson("/api/v1/dosen/permohonan/{$permohonan->permohonan_id}/terima");

    $response->assertStatus(422)
        ->assertJsonPath('success', false)
        ->assertJsonPath('message', 'Kuota bimbingan Anda sudah penuh. Tidak dapat menerima permohonan.');

    $this->assertDatabaseHas('permohonan_bimbingan', [
        'permohonan_id' => $permohonan->permohonan_id,
        'status'        => 'menunggu',
    ]);
});
