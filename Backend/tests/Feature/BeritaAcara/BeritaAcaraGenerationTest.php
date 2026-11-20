<?php

use App\Models\Bimbingan;
use App\Models\Dosen;
use App\Models\JadwalBimbingan;
use App\Models\Mahasiswa;
use Illuminate\Support\Facades\Storage;

beforeEach(function () {
    Storage::fake('local');
});

it('allows the supervising dosen to generate a draft Berita Acara PDF with snapshot and verification token', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create([
        'status_bimbingan' => 'selesai',
    ]);

    // Create confirmed meeting session in period
    JadwalBimbingan::factory()->create([
        'bimbingan_id'      => $bimbingan->bimbingan_id,
        'tanggal'           => now()->subDays(10)->toDateString(),
        'status_konfirmasi' => 'dikonfirmasi',
        'catatan'           => 'Pembahasan Bab 1 dan 2 selesai.',
    ]);

    $payload = [
        'periode_mulai'   => now()->subMonth()->toDateString(),
        'periode_selesai' => now()->toDateString(),
    ];

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->postJson("/api/v1/dosen/bimbingan/{$bimbingan->bimbingan_id}/berita-acara", $payload);

    $response->assertCreated()
        ->assertJsonPath('success', true)
        ->assertJsonPath('data.status_persetujuan', 'draft');

    $year = now()->year;
    $nomor = $response->json('data.nomor');
    expect($nomor)->toMatch("/^BA\/TA\/{$year}\/\d{4}$/");

    $token = $response->json('data.token_verifikasi');
    expect($token)->not->toBeEmpty();

    $fileHash = $response->json('data.file_hash');
    expect($fileHash)->toHaveLength(64);

    $filePath = $response->json('data.file_path');
    expect(Storage::exists($filePath))->toBeTrue();

    // Verify snapshot content
    $snapshot = $response->json('data.data_snapshot');
    expect($snapshot['mahasiswa']['nama'])->toBe($mahasiswa->user->nama)
        ->and($snapshot['dosen']['nama'])->toBe($dosen->user->nama)
        ->and($snapshot['total_sesi'])->toBe(1);
});

it('increments sequential numbers correctly across generations', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa1 = Mahasiswa::factory()->create();
    $mahasiswa2 = Mahasiswa::factory()->create();
    $bimbingan1 = Bimbingan::factory()->untuk($mahasiswa1, $dosen)->create();
    $bimbingan2 = Bimbingan::factory()->untuk($mahasiswa2, $dosen)->create();

    $payload = [
        'periode_mulai'   => now()->subMonth()->toDateString(),
        'periode_selesai' => now()->toDateString(),
    ];

    $res1 = $this->withHeaders(authHeaders($dosen->user))
        ->postJson("/api/v1/dosen/bimbingan/{$bimbingan1->bimbingan_id}/berita-acara", $payload);
    $res1->assertCreated();
    $nomor1 = $res1->json('data.nomor');

    $res2 = $this->withHeaders(authHeaders($dosen->user))
        ->postJson("/api/v1/dosen/bimbingan/{$bimbingan2->bimbingan_id}/berita-acara", $payload);
    $res2->assertCreated();
    $nomor2 = $res2->json('data.nomor');

    preg_match('/(\d{4})$/', $nomor1, $m1);
    preg_match('/(\d{4})$/', $nomor2, $m2);

    expect((int)$m2[1])->toBe((int)$m1[1] + 1);
});

it('forbids another dosen from generating Berita Acara for this supervision', function () {
    $dosenOwner = Dosen::factory()->create();
    $dosenOther = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosenOwner)->create();

    $payload = [
        'periode_mulai'   => now()->subMonth()->toDateString(),
        'periode_selesai' => now()->toDateString(),
    ];

    $response = $this->withHeaders(authHeaders($dosenOther->user))
        ->postJson("/api/v1/dosen/bimbingan/{$bimbingan->bimbingan_id}/berita-acara", $payload);

    $response->assertForbidden();
});

it('forbids mahasiswa from calling the generate endpoint', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();

    $payload = [
        'periode_mulai'   => now()->subMonth()->toDateString(),
        'periode_selesai' => now()->toDateString(),
    ];

    $response = $this->withHeaders(authHeaders($mahasiswa->user))
        ->postJson("/api/v1/dosen/bimbingan/{$bimbingan->bimbingan_id}/berita-acara", $payload);

    $response->assertForbidden();
});

it('rejects generating Berita Acara when periode_mulai is after periode_selesai', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();

    $payload = [
        'periode_mulai'   => now()->toDateString(),
        'periode_selesai' => now()->subMonth()->toDateString(),
    ];

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->postJson("/api/v1/dosen/bimbingan/{$bimbingan->bimbingan_id}/berita-acara", $payload);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['periode_selesai']);
});

it('rejects generating Berita Acara for a cancelled supervision', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create([
        'status_bimbingan' => 'dibatalkan',
    ]);

    $payload = [
        'periode_mulai'   => now()->subMonth()->toDateString(),
        'periode_selesai' => now()->toDateString(),
    ];

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->postJson("/api/v1/dosen/bimbingan/{$bimbingan->bimbingan_id}/berita-acara", $payload);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['bimbingan']);
});
