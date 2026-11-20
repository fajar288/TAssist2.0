<?php
// tests/Feature/Bimbingan/StatusTransitionTest.php

use App\Models\Bimbingan;
use App\Models\Dosen;
use App\Models\Mahasiswa;

it('allows the supervising dosen to complete an active bimbingan', function () {
    $dosen     = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create([
        'status_bimbingan' => 'aktif',
        'tanggal_selesai'  => null,
    ]);

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->putJson("/api/v1/dosen/bimbingan/{$bimbingan->bimbingan_id}/status", [
            'status'  => 'selesai',
            'catatan' => 'Bimbingan selesai, mahasiswa siap sidang.',
        ]);

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonPath('message', 'Status bimbingan berhasil diperbarui')
        ->assertJsonPath('data.status_bimbingan', 'selesai')
        ->assertJsonPath('data.tanggal_selesai', now()->toDateString());

    expect($bimbingan->fresh()->status_bimbingan)->toBe('selesai')
        ->and($bimbingan->fresh()->tanggal_selesai?->toDateString())->toBe(now()->toDateString());
});

it('allows the supervising dosen to cancel an active bimbingan', function () {
    $dosen     = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create([
        'status_bimbingan' => 'aktif',
    ]);

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->putJson("/api/v1/dosen/bimbingan/{$bimbingan->bimbingan_id}/status", [
            'status'  => 'dibatalkan',
            'catatan' => 'Topik tidak dapat dilanjutkan.',
        ]);

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonPath('data.status_bimbingan', 'dibatalkan');

    expect($bimbingan->fresh()->status_bimbingan)->toBe('dibatalkan')
        ->and($bimbingan->fresh()->tanggal_selesai)->not->toBeNull();
});

it('rejects transitioning a bimbingan that is already completed or cancelled', function () {
    $dosen     = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->selesai()->create();

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->putJson("/api/v1/dosen/bimbingan/{$bimbingan->bimbingan_id}/status", [
            'status' => 'dibatalkan',
        ]);

    $response->assertStatus(422)
        ->assertJsonPath('success', false);
});

it('validates allowed status transitions', function () {
    $dosen     = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->putJson("/api/v1/dosen/bimbingan/{$bimbingan->bimbingan_id}/status", [
            'status' => 'status_tidak_valid',
        ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['status']);
});

it('forbids another dosen from changing the status of another supervision', function () {
    $dosenAsli = Dosen::factory()->create();
    $dosenLain = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosenAsli)->create();

    $response = $this->withHeaders(authHeaders($dosenLain->user))
        ->putJson("/api/v1/dosen/bimbingan/{$bimbingan->bimbingan_id}/status", [
            'status' => 'selesai',
        ]);

    $response->assertStatus(403)
        ->assertJsonPath('success', false);
});

it('forbids a mahasiswa from accessing the dosen status transition endpoint', function () {
    $dosen     = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();

    $response = $this->withHeaders(authHeaders($mahasiswa->user))
        ->putJson("/api/v1/dosen/bimbingan/{$bimbingan->bimbingan_id}/status", [
            'status' => 'selesai',
        ]);

    $response->assertStatus(403);
});
