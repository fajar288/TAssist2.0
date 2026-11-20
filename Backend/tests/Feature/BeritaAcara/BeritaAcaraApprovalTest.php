<?php

use App\Models\BeritaAcara;
use App\Models\Bimbingan;
use App\Models\Dosen;
use App\Models\Mahasiswa;
use App\Models\Notifikasi;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

beforeEach(function () {
    Storage::fake('local');
});

it('allows supervising dosen to approve Berita Acara via PIN', function () {
    $dosen = Dosen::factory()->create([
        'pin' => Hash::make('654321'),
    ]);
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();
    $ba = BeritaAcara::factory()->create([
        'bimbingan_id'       => $bimbingan->bimbingan_id,
        'status_persetujuan' => 'draft',
    ]);

    $payload = [
        'metode' => 'pin',
        'pin'    => '654321',
    ];

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->putJson("/api/v1/dosen/berita-acara/{$ba->berita_acara_id}/approve", $payload);

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonPath('data.status_persetujuan', 'disetujui')
        ->assertJsonPath('data.metode_persetujuan', 'pin');

    $freshBa = $ba->fresh();
    expect($freshBa->status_persetujuan)->toBe('disetujui')
        ->and($freshBa->approved_at)->not->toBeNull()
        ->and($freshBa->approved_hash)->toHaveLength(64);

    // Verify notification sent to student
    expect(Notifikasi::where('user_id', $mahasiswa->user_id)
        ->where('tipe_notifikasi', 'berita_acara_disetujui')
        ->exists())->toBeTrue();
});

it('falls back to account password when dosen pin is not set', function () {
    $dosen = Dosen::factory()->create([
        'pin' => null,
    ]);
    // Set known password hash on user
    $dosen->user->update([
        'password_hash' => Hash::make('passwordDosen123'),
    ]);

    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();
    $ba = BeritaAcara::factory()->create([
        'bimbingan_id'       => $bimbingan->bimbingan_id,
        'status_persetujuan' => 'draft',
    ]);

    $payload = [
        'metode' => 'pin',
        'pin'    => 'passwordDosen123',
    ];

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->putJson("/api/v1/dosen/berita-acara/{$ba->berita_acara_id}/approve", $payload);

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonPath('data.status_persetujuan', 'disetujui');
});

it('rejects approval when wrong PIN is entered', function () {
    $dosen = Dosen::factory()->create([
        'pin' => Hash::make('654321'),
    ]);
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();
    $ba = BeritaAcara::factory()->create([
        'bimbingan_id'       => $bimbingan->bimbingan_id,
        'status_persetujuan' => 'draft',
    ]);

    $payload = [
        'metode' => 'pin',
        'pin'    => '000000',
    ];

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->putJson("/api/v1/dosen/berita-acara/{$ba->berita_acara_id}/approve", $payload);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['pin']);
});

it('allows supervising dosen to approve Berita Acara via drawn signature image', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();
    $ba = BeritaAcara::factory()->create([
        'bimbingan_id'       => $bimbingan->bimbingan_id,
        'status_persetujuan' => 'draft',
    ]);

    $signatureFile = UploadedFile::fake()->image('signature.png', 300, 150);

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->putJson("/api/v1/dosen/berita-acara/{$ba->berita_acara_id}/approve", [
            'metode'       => 'tanda_tangan',
            'tanda_tangan' => $signatureFile,
        ]);

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonPath('data.status_persetujuan', 'disetujui')
        ->assertJsonPath('data.metode_persetujuan', 'tanda_tangan');

    $freshBa = $ba->fresh();
    expect($freshBa->tanda_tangan_path)->not->toBeNull()
        ->and(Storage::exists($freshBa->tanda_tangan_path))->toBeTrue()
        ->and($freshBa->approved_hash)->toHaveLength(64);
});

it('forbids another dosen from approving a Berita Acara', function () {
    $dosenOwner = Dosen::factory()->create(['pin' => Hash::make('123456')]);
    $dosenOther = Dosen::factory()->create(['pin' => Hash::make('123456')]);
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosenOwner)->create();
    $ba = BeritaAcara::factory()->create([
        'bimbingan_id'       => $bimbingan->bimbingan_id,
        'status_persetujuan' => 'draft',
    ]);

    $response = $this->withHeaders(authHeaders($dosenOther->user))
        ->putJson("/api/v1/dosen/berita-acara/{$ba->berita_acara_id}/approve", [
            'metode' => 'pin',
            'pin'    => '123456',
        ]);

    $response->assertForbidden();
});

it('rejects approving an already approved Berita Acara', function () {
    $dosen = Dosen::factory()->create(['pin' => Hash::make('123456')]);
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();
    $ba = BeritaAcara::factory()->approved('pin')->create([
        'bimbingan_id' => $bimbingan->bimbingan_id,
    ]);

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->putJson("/api/v1/dosen/berita-acara/{$ba->berita_acara_id}/approve", [
            'metode' => 'pin',
            'pin'    => '123456',
        ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['berita_acara']);
});
