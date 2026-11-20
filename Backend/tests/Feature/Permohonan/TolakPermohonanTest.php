<?php
// tests/Feature/Permohonan/TolakPermohonanTest.php

use App\Models\Dosen;
use App\Models\Mahasiswa;
use App\Models\PermohonanBimbingan;

it('rejects a pending supervision request with a reason', function () {
    $dosen      = Dosen::factory()->create();
    $mahasiswa  = Mahasiswa::factory()->create();
    $permohonan = PermohonanBimbingan::factory()
        ->forMahasiswa($mahasiswa)
        ->forDosen($dosen)
        ->create();

    $alasan = 'Topik tidak sesuai dengan bidang keahlian saya.';

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->putJson("/api/v1/dosen/permohonan/{$permohonan->permohonan_id}/tolak", [
            'catatan_respons' => $alasan,
        ]);

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonPath('message', 'Permohonan berhasil ditolak')
        ->assertJsonPath('data.status', 'ditolak')
        ->assertJsonPath('data.catatan_respons', $alasan)
        ->assertJsonPath('data.mahasiswa.nim', $mahasiswa->nim);

    $this->assertDatabaseHas('permohonan_bimbingan', [
        'permohonan_id'   => $permohonan->permohonan_id,
        'status'          => 'ditolak',
        'catatan_respons' => $alasan,
    ]);

    // A rejection must never create a supervision.
    $this->assertDatabaseCount('bimbingan', 0);

    $this->assertDatabaseHas('notifikasi', [
        'user_id'         => $mahasiswa->user_id,
        'tipe_notifikasi' => 'permohonan_ditolak',
        'ref_tabel'       => 'permohonan_bimbingan',
        'ref_id'          => $permohonan->permohonan_id,
    ]);
});

it('requires a reason when rejecting a request', function () {
    $dosen      = Dosen::factory()->create();
    $mahasiswa  = Mahasiswa::factory()->create();
    $permohonan = PermohonanBimbingan::factory()
        ->forMahasiswa($mahasiswa)
        ->forDosen($dosen)
        ->create();

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->putJson("/api/v1/dosen/permohonan/{$permohonan->permohonan_id}/tolak", []);

    $response->assertStatus(422)
        ->assertJsonPath('success', false)
        ->assertJsonPath('message', 'Validasi gagal')
        ->assertJsonValidationErrors('catatan_respons');

    $this->assertDatabaseHas('permohonan_bimbingan', [
        'permohonan_id' => $permohonan->permohonan_id,
        'status'        => 'menunggu',
    ]);
});

it('returns 404 when the request belongs to another professor', function () {
    $dosenLain  = Dosen::factory()->create();
    $pemilik    = Dosen::factory()->create();
    $mahasiswa  = Mahasiswa::factory()->create();

    $permohonan = PermohonanBimbingan::factory()
        ->forMahasiswa($mahasiswa)
        ->forDosen($pemilik)
        ->create();

    $this->withHeaders(authHeaders($dosenLain->user))
        ->putJson("/api/v1/dosen/permohonan/{$permohonan->permohonan_id}/tolak", [
            'catatan_respons' => 'Bukan permohonan saya.',
        ])
        ->assertNotFound()
        ->assertJsonPath('success', false)
        ->assertJsonPath('message', 'Permohonan tidak ditemukan atau bukan milik Anda.');
});
