<?php

use App\Models\BeritaAcara;
use App\Models\Bimbingan;
use App\Models\Dosen;
use App\Models\Mahasiswa;
use App\Services\SignedUrlService;
use Illuminate\Support\Facades\Storage;

beforeEach(function () {
    Storage::fake('local');
});

it('allows dosen to list Berita Acara for their supervision', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();

    $ba1 = BeritaAcara::factory()->create(['bimbingan_id' => $bimbingan->bimbingan_id]);
    $ba2 = BeritaAcara::factory()->create(['bimbingan_id' => $bimbingan->bimbingan_id]);

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->getJson("/api/v1/dosen/bimbingan/{$bimbingan->bimbingan_id}/berita-acara");

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonCount(2, 'data');
});

it('allows mahasiswa to view Berita Acara for their supervision', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();

    $ba = BeritaAcara::factory()->approved('pin')->create([
        'bimbingan_id' => $bimbingan->bimbingan_id,
        'nomor'        => 'BA/TA/2026/0010',
    ]);

    $response = $this->withHeaders(authHeaders($mahasiswa->user))
        ->getJson("/api/v1/mahasiswa/bimbingan/{$bimbingan->bimbingan_id}/berita-acara");

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.nomor', 'BA/TA/2026/0010');
});

it('forbids an unrelated student from listing another supervision Berita Acara', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswaOwner = Mahasiswa::factory()->create();
    $mahasiswaOther = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswaOwner, $dosen)->create();

    $response = $this->withHeaders(authHeaders($mahasiswaOther->user))
        ->getJson("/api/v1/mahasiswa/bimbingan/{$bimbingan->bimbingan_id}/berita-acara");

    $response->assertForbidden();
});

it('generates a signed download URL payload via download endpoint', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();
    $ba = BeritaAcara::factory()->approved('pin')->create([
        'bimbingan_id' => $bimbingan->bimbingan_id,
    ]);

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->getJson("/api/v1/berita-acara/{$ba->berita_acara_id}/download");

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonStructure([
            'data' => ['url', 'expires_at'],
        ]);

    $downloadUrl = $response->json('data.url');
    expect($downloadUrl)->toContain('/api/v1/berita-acara/' . $ba->berita_acara_id . '/file');
});

it('serves PDF binary file with CORS header when requested with valid signed URL', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();

    $pdfContent = '%PDF-1.4 dummy binary content';
    $filePath = 'berita_acara/test_ba.pdf';
    Storage::put($filePath, $pdfContent);

    $ba = BeritaAcara::factory()->approved('pin')->create([
        'bimbingan_id' => $bimbingan->bimbingan_id,
        'file_path'    => $filePath,
    ]);

    $signedUrl = app(SignedUrlService::class)->beritaAcaraFileUrl($ba->berita_acara_id);

    // Call without auth header, as signed route grants access
    $response = $this->get($signedUrl);

    $response->assertOk()
        ->assertHeader('Content-Type', 'application/pdf')
        ->assertHeader('Access-Control-Allow-Origin', '*');
});

it('rejects an invalid or unsigned file request with 403', function () {
    $ba = BeritaAcara::factory()->create();

    // Call the file route directly without HMAC signature
    $response = $this->get("/api/v1/berita-acara/{$ba->berita_acara_id}/file");

    $response->assertForbidden();
});
