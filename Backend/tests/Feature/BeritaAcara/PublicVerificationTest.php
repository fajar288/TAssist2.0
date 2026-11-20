<?php

use App\Models\BeritaAcara;
use App\Models\Bimbingan;
use App\Models\Dosen;
use App\Models\Mahasiswa;
use Illuminate\Support\Facades\Storage;

beforeEach(function () {
    Storage::fake('local');
});

it('displays verified status and details on public verification page for valid approved document', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();

    $content = 'dummy-approved-pdf-content';
    $filePath = 'berita_acara/sample_approved.pdf';
    Storage::put($filePath, $content);
    $hash = hash('sha256', $content);

    $ba = BeritaAcara::factory()->approved('pin')->create([
        'bimbingan_id'       => $bimbingan->bimbingan_id,
        'nomor'              => 'BA/TA/2026/0042',
        'file_path'          => $filePath,
        'approved_hash'      => $hash,
        'token_verifikasi'   => 'valid-verification-token-1234567890',
        'data_snapshot'      => [
            'mahasiswa'   => ['nama' => 'Budi Santoso', 'nim' => '1202200001', 'program_studi' => 'Teknik Informatika'],
            'dosen'       => ['nama' => 'Dr. Ir. Hendra', 'nid' => '0412345678'],
            'total_sesi'  => 10,
        ],
    ]);

    $response = $this->get("/verifikasi/{$ba->token_verifikasi}");

    $response->assertOk()
        ->assertSee('Keaslian Dokumen Terverifikasi')
        ->assertSee('BA/TA/2026/0042')
        ->assertSee('Budi Santoso')
        ->assertSee('Dr. Ir. Hendra')
        ->assertSee('10 Sesi Bimbingan');
});

it('detects tampering when the stored file hash does not match current file', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();

    $originalContent = 'original-pdf-content';
    $filePath = 'berita_acara/tampered.pdf';
    // Store tampered/different content
    Storage::put($filePath, 'tampered-modified-content');
    $originalHash = hash('sha256', $originalContent);

    $ba = BeritaAcara::factory()->approved('pin')->create([
        'bimbingan_id'     => $bimbingan->bimbingan_id,
        'file_path'        => $filePath,
        'approved_hash'    => $originalHash,
        'token_verifikasi' => 'tampered-token-123',
    ]);

    $response = $this->get("/verifikasi/{$ba->token_verifikasi}");

    $response->assertOk()
        ->assertSee('Pemeriksaan Integritas Gagal')
        ->assertDontSee('Keaslian Dokumen Terverifikasi');
});

it('shows generic document not found when an unknown token is requested', function () {
    $response = $this->get('/verifikasi/non-existent-token-abc');

    $response->assertOk()
        ->assertSee('Dokumen Tidak Ditemukan');
});

it('shows draft status when a draft Berita Acara is viewed', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();

    $content = 'dummy-draft-pdf';
    $filePath = 'berita_acara/draft.pdf';
    Storage::put($filePath, $content);

    $ba = BeritaAcara::factory()->create([
        'bimbingan_id'       => $bimbingan->bimbingan_id,
        'file_path'          => $filePath,
        'file_hash'          => hash('sha256', $content),
        'status_persetujuan' => 'draft',
        'token_verifikasi'   => 'draft-token-999',
    ]);

    $response = $this->get("/verifikasi/{$ba->token_verifikasi}");

    $response->assertOk()
        ->assertSee('Dokumen Berstatus Draft');
});
