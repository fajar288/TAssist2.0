<?php
// tests/Feature/Auth/MahasiswaAvatarTest.php

use App\Models\Dosen;
use App\Models\Mahasiswa;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

it('allows mahasiswa to upload a profile photo via multipart _method=PUT and returns it in profile', function () {
    Storage::fake('public');

    $mahasiswa = Mahasiswa::factory()->create();
    $file = UploadedFile::fake()->image('foto_profil.jpg', 300, 300);

    $response = $this->withHeaders(authHeaders($mahasiswa->user))
        ->post('/api/v1/mahasiswa/profile', [
            '_method'  => 'PUT',
            'topik_ta' => 'Deteksi Penyakit Daun Padi CNN',
            'judul_ta' => 'Implementasi MobileNetV3',
            'avatar'   => $file,
        ]);

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonPath('data.profile.topik_ta', 'Deteksi Penyakit Daun Padi CNN');

    $savedPath = $mahasiswa->user->fresh()->avatar;
    expect($savedPath)->not->toBeNull();
    expect($savedPath)->toStartWith('avatars/');
    Storage::disk('public')->assertExists($savedPath);

    $avatarUrl = $response->json('data.user.avatar');
    expect($avatarUrl)->toContain($savedPath);

    // GET /api/v1/profile returns the updated avatar
    $profileResponse = $this->withHeaders(authHeaders($mahasiswa->user))
        ->getJson('/api/v1/profile');

    $profileResponse->assertOk()
        ->assertJsonPath('data.user.avatar', $avatarUrl);
});

it('deletes the previous local avatar when mahasiswa uploads a new one', function () {
    Storage::fake('public');

    $mahasiswa = Mahasiswa::factory()->create();
    $oldFile = UploadedFile::fake()->image('lama.png', 200, 200);
    $oldPath = $oldFile->store('avatars', 'public');
    $mahasiswa->user->update(['avatar' => $oldPath]);

    Storage::disk('public')->assertExists($oldPath);

    $newFile = UploadedFile::fake()->image('baru.png', 200, 200);
    $this->withHeaders(authHeaders($mahasiswa->user))
        ->post('/api/v1/mahasiswa/profile', [
            '_method' => 'PUT',
            'avatar'  => $newFile,
        ])
        ->assertOk();

    Storage::disk('public')->assertMissing($oldPath);
    $newPath = $mahasiswa->user->fresh()->avatar;
    expect($newPath)->not->toBe($oldPath);
    Storage::disk('public')->assertExists($newPath);
});

it('rejects non-image files and oversized avatars for mahasiswa profile', function () {
    Storage::fake('public');
    $mahasiswa = Mahasiswa::factory()->create();

    $pdf = UploadedFile::fake()->create('dokumen.pdf', 100, 'application/pdf');
    $this->withHeaders(authHeaders($mahasiswa->user))
        ->post('/api/v1/mahasiswa/profile', [
            '_method' => 'PUT',
            'avatar'  => $pdf,
        ])
        ->assertStatus(422)
        ->assertJsonPath('success', false);

    $tooBig = UploadedFile::fake()->image('huge.jpg')->size(3072);
    $this->withHeaders(authHeaders($mahasiswa->user))
        ->post('/api/v1/mahasiswa/profile', [
            '_method' => 'PUT',
            'avatar'  => $tooBig,
        ])
        ->assertStatus(422)
        ->assertJsonPath('success', false);
});

it('forbids dosen from updating mahasiswa profile avatar', function () {
    Storage::fake('public');
    $dosen = Dosen::factory()->create();
    $file = UploadedFile::fake()->image('foto.jpg', 100, 100);

    $this->withHeaders(authHeaders($dosen->user))
        ->post('/api/v1/mahasiswa/profile', [
            '_method' => 'PUT',
            'avatar'  => $file,
        ])
        ->assertForbidden();
});

it('blocks path traversal on the public avatar delivery route', function () {
    $this->get('/api/v1/avatar/..%2F..%2F.env')
        ->assertStatus(400);
});
