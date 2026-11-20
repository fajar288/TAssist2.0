<?php
// tests/Feature/Dokumen/SignedUrlDokumenTest.php

use App\Models\Admin;
use App\Models\Bimbingan;
use App\Models\DokumenTA;
use App\Models\Dosen;
use App\Models\Mahasiswa;
use App\Models\VersiDokumen;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;

beforeEach(function () {
    Storage::fake('dokumen');
    Storage::fake('public');
});

it('issues a signed url for the document owner mahasiswa', function () {
    $dosen     = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();
    $dokumen   = DokumenTA::factory()->forBimbingan($bimbingan)->create();
    $versi     = VersiDokumen::factory()->forDokumen($dokumen)->create([
        'uploader_user_id' => $mahasiswa->user_id,
    ]);

    $response = $this->withHeaders(authHeaders($mahasiswa->user))
        ->getJson("/api/v1/dokumen/signed-url/{$versi->versi_id}");

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonStructure([
            'success',
            'message',
            'data' => ['url', 'expires_at'],
        ]);

    expect($response->json('data.url'))->toContain("/api/v1/dokumen/{$versi->versi_id}/file?expires=");
});

it('issues a signed url for the supervising dosen', function () {
    $dosen     = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();
    $dokumen   = DokumenTA::factory()->forBimbingan($bimbingan)->create();
    $versi     = VersiDokumen::factory()->forDokumen($dokumen)->create();

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->getJson("/api/v1/dokumen/signed-url/{$versi->versi_id}");

    $response->assertOk()
        ->assertJsonPath('success', true);
});

it('issues a signed url for an admin', function () {
    $admin     = Admin::factory()->create();
    $dosen     = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();
    $dokumen   = DokumenTA::factory()->forBimbingan($bimbingan)->create();
    $versi     = VersiDokumen::factory()->forDokumen($dokumen)->create();

    $response = $this->withHeaders(authHeaders($admin->user))
        ->getJson("/api/v1/dokumen/signed-url/{$versi->versi_id}");

    $response->assertOk()
        ->assertJsonPath('success', true);
});

it('forbids an unrelated student from obtaining a signed url', function () {
    $dosen          = Dosen::factory()->create();
    $mahasiswaOwner = Mahasiswa::factory()->create();
    $mahasiswaLain  = Mahasiswa::factory()->create();
    $bimbingan      = Bimbingan::factory()->untuk($mahasiswaOwner, $dosen)->create();
    $dokumen        = DokumenTA::factory()->forBimbingan($bimbingan)->create();
    $versi          = VersiDokumen::factory()->forDokumen($dokumen)->create();

    $response = $this->withHeaders(authHeaders($mahasiswaLain->user))
        ->getJson("/api/v1/dokumen/signed-url/{$versi->versi_id}");

    $response->assertStatus(403);
});

it('confirms the legacy /api/v1/image route is permanently retired', function () {
    $response = $this->get('/api/v1/image/dokumen_ta/1/secret.pdf');

    $response->assertStatus(404);
});

it('serves avatars with CORS header through the new avatar endpoint', function () {
    // Put test avatar in public disk
    $avatarDir = storage_path('app/public/avatars');
    if (!File::isDirectory($avatarDir)) {
        File::makeDirectory($avatarDir, 0755, true);
    }
    File::put($avatarDir . '/test_avatar.jpg', 'fake-image-bytes');

    $response = $this->get('/api/v1/avatar/test_avatar.jpg');

    $response->assertOk()
        ->assertHeader('Access-Control-Allow-Origin', '*');

    // Clean up
    @File::delete($avatarDir . '/test_avatar.jpg');
});
