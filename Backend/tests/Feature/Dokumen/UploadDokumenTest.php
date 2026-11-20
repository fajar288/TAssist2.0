<?php
// tests/Feature/Dokumen/UploadDokumenTest.php

use App\Models\Bimbingan;
use App\Models\DokumenTA;
use App\Models\Dosen;
use App\Models\Mahasiswa;
use App\Models\VersiDokumen;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

beforeEach(function () {
    Storage::fake('public');
});

it('uploads a document for a student with an active bimbingan', function () {
    $dosen     = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();

    $response = $this->withHeaders(authHeaders($mahasiswa->user))
        ->postJson('/api/v1/mahasiswa/dokumen', [
            'jenis_dokumen'  => 'proposal',
            'judul_dokumen'  => 'Proposal Tugas Akhir',
            'deskripsi'      => 'Versi pertama proposal.',
            'catatan_revisi' => 'Mohon ditinjau.',
            'file'           => UploadedFile::fake()->create('proposal-ta.pdf', 200, 'application/pdf'),
        ]);

    $response->assertCreated()
        ->assertJsonPath('success', true)
        ->assertJsonPath('message', 'Dokumen berhasil diunggah')
        ->assertJsonPath('data.jenis_dokumen', 'proposal')
        ->assertJsonPath('data.judul_dokumen', 'Proposal Tugas Akhir')
        ->assertJsonPath('data.versi.nomor_versi', 1)
        ->assertJsonPath('data.versi.status_versi', 'diajukan')
        ->assertJsonStructure([
            'success',
            'message',
            'data' => [
                'dokumen_id',
                'jenis_dokumen',
                'judul_dokumen',
                'deskripsi',
                'versi' => ['versi_id', 'nomor_versi', 'file_url', 'catatan_revisi', 'status_versi', 'uploaded_at'],
            ],
        ]);

    $dokumen = DokumenTA::first();

    expect($dokumen)->not->toBeNull()
        ->and($dokumen->bimbingan_id)->toBe($bimbingan->bimbingan_id)
        ->and($dokumen->judul_dokumen)->toBe('Proposal Tugas Akhir');

    $versi = VersiDokumen::first();

    expect($versi)->not->toBeNull()
        ->and($versi->dokumen_id)->toBe($dokumen->dokumen_id)
        ->and($versi->uploader_user_id)->toBe($mahasiswa->user_id)
        ->and($versi->nomor_versi)->toBe(1)
        ->and($versi->status_versi)->toBe('diajukan')
        ->and($versi->file_url_or_path)->toStartWith('dokumen_ta/'.$bimbingan->bimbingan_id.'/')
        ->and($versi->file_url_or_path)->toEndWith('proposal-ta.pdf');

    Storage::disk('public')->assertExists($versi->file_url_or_path);

    // The response exposes a public storage URL, not a bare path.
    expect($response->json('data.versi.file_url'))->toBeString()->toContain('/storage/');

    // The supervising professor is notified.
    $this->assertDatabaseHas('notifikasi', [
        'user_id'         => $dosen->user_id,
        'tipe_notifikasi' => 'upload_dokumen',
        'ref_tabel'       => 'dokumen_ta',
        'ref_id'          => $dokumen->dokumen_id,
    ]);
});

it('rejects an upload when the student has no active bimbingan', function () {
    $mahasiswa = Mahasiswa::factory()->create();

    $response = $this->withHeaders(authHeaders($mahasiswa->user))
        ->postJson('/api/v1/mahasiswa/dokumen', [
            'jenis_dokumen' => 'proposal',
            'judul_dokumen' => 'Proposal Tugas Akhir',
            'file'          => UploadedFile::fake()->create('proposal-ta.pdf', 200, 'application/pdf'),
        ]);

    $response->assertStatus(422)
        ->assertJsonPath('success', false)
        ->assertJsonPath('message', 'Anda tidak memiliki bimbingan aktif. Upload dokumen tidak diizinkan.');

    $this->assertDatabaseCount('dokumen_ta', 0);
    $this->assertDatabaseCount('versi_dokumen', 0);
    expect(Storage::disk('public')->allFiles())->toBe([]);
});

it('rejects an upload when the bimbingan is no longer active', function () {
    $dosen     = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();

    Bimbingan::factory()->untuk($mahasiswa, $dosen)->selesai()->create();

    $response = $this->withHeaders(authHeaders($mahasiswa->user))
        ->postJson('/api/v1/mahasiswa/dokumen', [
            'jenis_dokumen' => 'proposal',
            'judul_dokumen' => 'Proposal Tugas Akhir',
            'file'          => UploadedFile::fake()->create('proposal-ta.pdf', 200, 'application/pdf'),
        ]);

    $response->assertStatus(422)
        ->assertJsonPath('success', false)
        ->assertJsonPath('message', 'Anda tidak memiliki bimbingan aktif. Upload dokumen tidak diizinkan.');

    $this->assertDatabaseCount('dokumen_ta', 0);
    expect(Storage::disk('public')->allFiles())->toBe([]);
});

it('requires a file and the mandatory metadata', function () {
    $dosen     = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();

    $response = $this->withHeaders(authHeaders($mahasiswa->user))
        ->postJson('/api/v1/mahasiswa/dokumen', []);

    $response->assertStatus(422)
        ->assertJsonPath('success', false)
        ->assertJsonPath('message', 'Validasi gagal')
        ->assertJsonValidationErrors(['jenis_dokumen', 'judul_dokumen', 'file']);

    $this->assertDatabaseCount('dokumen_ta', 0);
});

it('forbids a dosen from using the mahasiswa upload endpoint', function () {
    $dosen = Dosen::factory()->create();

    $this->withHeaders(authHeaders($dosen->user))
        ->postJson('/api/v1/mahasiswa/dokumen', [
            'jenis_dokumen' => 'proposal',
            'judul_dokumen' => 'Proposal Tugas Akhir',
            'file'          => UploadedFile::fake()->create('proposal-ta.pdf', 200, 'application/pdf'),
        ])
        ->assertForbidden()
        ->assertJsonPath('success', false);

    $this->assertDatabaseCount('dokumen_ta', 0);
});
