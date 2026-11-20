<?php
// tests/Feature/Anotasi/AnotasiLifecycleTest.php

use App\Models\AnotasiDokumen;
use App\Models\Bimbingan;
use App\Models\DokumenTA;
use App\Models\Dosen;
use App\Models\Mahasiswa;
use App\Models\Notifikasi;
use App\Models\VersiDokumen;

it('allows the supervising dosen to create an annotation on a PDF document version', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();
    $dokumen = DokumenTA::factory()->forBimbingan($bimbingan)->create();
    $versi = VersiDokumen::factory()->forDokumen($dokumen)->create([
        'file_url_or_path'       => 'dokumen_ta/proposal.pdf',
        'jumlah_anotasi_terbuka' => 0,
    ]);

    $payload = [
        'versi_id' => $versi->versi_id,
        'halaman'  => 3,
        'x'        => 0.45,
        'y'        => 0.60,
        'lebar'    => 0.20,
        'tinggi'   => 0.05,
        'tipe'     => 'komentar',
        'konten'   => 'Paragraf ini perlu diperjelas sumber referensinya.',
    ];

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->postJson('/api/v1/dosen/anotasi', $payload);

    $response->assertCreated()
        ->assertJsonPath('success', true)
        ->assertJsonPath('data.status', 'open')
        ->assertJsonPath('data.halaman', 3)
        ->assertJsonPath('data.tipe', 'komentar');

    expect($versi->fresh()->jumlah_anotasi_terbuka)->toBe(1);

    // Verify in-app notification sent to mahasiswa
    expect(Notifikasi::where('user_id', $mahasiswa->user_id)->where('tipe_notifikasi', 'anotasi_baru')->exists())->toBeTrue();
});

it('rejects creating annotations for non-PDF documents with 422', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();
    $dokumen = DokumenTA::factory()->forBimbingan($bimbingan)->create();
    $versi = VersiDokumen::factory()->forDokumen($dokumen)->create([
        'file_url_or_path' => 'dokumen_ta/laporan.docx',
    ]);

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->postJson('/api/v1/dosen/anotasi', [
            'versi_id' => $versi->versi_id,
            'halaman'  => 1,
            'x'        => 0.5,
            'y'        => 0.5,
            'tipe'     => 'komentar',
            'konten'   => 'Test',
        ]);

    $response->assertStatus(422)
        ->assertJsonPath('success', false)
        ->assertJsonPath('message', 'Anotasi hanya dapat dibuat untuk dokumen berformat PDF.');
});

it('validates normalized coordinates between 0.0 and 1.0', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();
    $dokumen = DokumenTA::factory()->forBimbingan($bimbingan)->create();
    $versi = VersiDokumen::factory()->forDokumen($dokumen)->create([
        'file_url_or_path' => 'dokumen_ta/proposal.pdf',
    ]);

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->postJson('/api/v1/dosen/anotasi', [
            'versi_id' => $versi->versi_id,
            'halaman'  => 1,
            'x'        => 1.5, // Invalid coordinate > 1.0
            'y'        => -0.2, // Invalid coordinate < 0.0
            'tipe'     => 'komentar',
            'konten'   => 'Invalid coordinates test',
        ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['x', 'y']);
});

it('allows mahasiswa to view annotations on their document version and filter by status', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();
    $dokumen = DokumenTA::factory()->forBimbingan($bimbingan)->create();
    $versi = VersiDokumen::factory()->forDokumen($dokumen)->create([
        'file_url_or_path' => 'dokumen_ta/proposal.pdf',
    ]);

    AnotasiDokumen::factory()->create([
        'versi_id' => $versi->versi_id,
        'dosen_id' => $dosen->dosen_id,
        'user_id'  => $dosen->user_id,
        'status'   => 'open',
    ]);
    AnotasiDokumen::factory()->create([
        'versi_id' => $versi->versi_id,
        'dosen_id' => $dosen->dosen_id,
        'user_id'  => $dosen->user_id,
        'status'   => 'resolved',
    ]);

    $response = $this->withHeaders(authHeaders($mahasiswa->user))
        ->getJson("/api/v1/mahasiswa/dokumen/{$versi->versi_id}/anotasi?status=open");

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonCount(1, 'data');
});

it('allows mahasiswa to mark open annotations as revised and notifies professor', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();
    $dokumen = DokumenTA::factory()->forBimbingan($bimbingan)->create();
    $versi = VersiDokumen::factory()->forDokumen($dokumen)->create([
        'file_url_or_path'       => 'dokumen_ta/proposal.pdf',
        'jumlah_anotasi_terbuka' => 1,
    ]);
    $anotasi = AnotasiDokumen::factory()->create([
        'versi_id' => $versi->versi_id,
        'dosen_id' => $dosen->dosen_id,
        'user_id'  => $dosen->user_id,
        'status'   => 'open',
    ]);

    $response = $this->withHeaders(authHeaders($mahasiswa->user))
        ->putJson("/api/v1/mahasiswa/anotasi/{$anotasi->anotasi_id}/revised");

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonPath('data.status', 'revised');

    expect($anotasi->fresh()->status)->toBe('revised');
    // Open counter does not decrement until professor marks resolved
    expect($versi->fresh()->jumlah_anotasi_terbuka)->toBe(1);

    expect(Notifikasi::where('user_id', $dosen->user_id)->where('tipe_notifikasi', 'anotasi_direvisi')->exists())->toBeTrue();
});

it('allows dosen to mark annotations as resolved and decrements open annotation counter', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();
    $dokumen = DokumenTA::factory()->forBimbingan($bimbingan)->create();
    $versi = VersiDokumen::factory()->forDokumen($dokumen)->create([
        'file_url_or_path'       => 'dokumen_ta/proposal.pdf',
        'jumlah_anotasi_terbuka' => 1,
    ]);
    $anotasi = AnotasiDokumen::factory()->create([
        'versi_id' => $versi->versi_id,
        'dosen_id' => $dosen->dosen_id,
        'user_id'  => $dosen->user_id,
        'status'   => 'revised',
    ]);

    $response = $this->withHeaders(authHeaders($dosen->user))
        ->putJson("/api/v1/dosen/anotasi/{$anotasi->anotasi_id}/resolved");

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonPath('data.status', 'resolved');

    expect($anotasi->fresh()->status)->toBe('resolved');
    expect($versi->fresh()->jumlah_anotasi_terbuka)->toBe(0);

    expect(Notifikasi::where('user_id', $mahasiswa->user_id)->where('tipe_notifikasi', 'anotasi_selesai')->exists())->toBeTrue();
});

it('allows replying to an annotation without changing parent status', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();
    $dokumen = DokumenTA::factory()->forBimbingan($bimbingan)->create();
    $versi = VersiDokumen::factory()->forDokumen($dokumen)->create([
        'file_url_or_path' => 'dokumen_ta/proposal.pdf',
    ]);
    $parent = AnotasiDokumen::factory()->create([
        'versi_id' => $versi->versi_id,
        'dosen_id' => $dosen->dosen_id,
        'user_id'  => $dosen->user_id,
        'status'   => 'open',
    ]);

    $response = $this->withHeaders(authHeaders($mahasiswa->user))
        ->postJson("/api/v1/mahasiswa/anotasi/{$parent->anotasi_id}/reply", [
            'konten' => 'Baik Pak, bagian metodologi sudah saya perbarui dengan acuan paper IEEE.',
        ]);

    $response->assertCreated()
        ->assertJsonPath('success', true)
        ->assertJsonPath('data.parent_id', $parent->anotasi_id)
        ->assertJsonPath('data.konten', 'Baik Pak, bagian metodologi sudah saya perbarui dengan acuan paper IEEE.');

    // Parent status remains open (F-ANN-03)
    expect($parent->fresh()->status)->toBe('open');
    expect($parent->replies()->count())->toBe(1);
});

it('provides cross-version annotation summary for a document', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();
    $dokumen = DokumenTA::factory()->forBimbingan($bimbingan)->create();

    $versi1 = VersiDokumen::factory()->forDokumen($dokumen, 1)->create([
        'file_url_or_path'       => 'dokumen_ta/v1.pdf',
        'jumlah_anotasi_terbuka' => 1,
    ]);
    AnotasiDokumen::factory()->create([
        'versi_id' => $versi1->versi_id,
        'dosen_id' => $dosen->dosen_id,
        'user_id'  => $dosen->user_id,
        'status'   => 'open',
    ]);
    AnotasiDokumen::factory()->create([
        'versi_id' => $versi1->versi_id,
        'dosen_id' => $dosen->dosen_id,
        'user_id'  => $dosen->user_id,
        'status'   => 'resolved',
    ]);

    $versi2 = VersiDokumen::factory()->forDokumen($dokumen, 2)->create([
        'file_url_or_path'       => 'dokumen_ta/v2.pdf',
        'jumlah_anotasi_terbuka' => 0,
    ]);

    $response = $this->withHeaders(authHeaders($mahasiswa->user))
        ->getJson("/api/v1/dokumen/{$dokumen->dokumen_id}/anotasi-summary");

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonPath('data.dokumen_id', $dokumen->dokumen_id)
        ->assertJsonCount(2, 'data.versi')
        ->assertJsonPath('data.versi.0.open', 1)
        ->assertJsonPath('data.versi.0.resolved', 1)
        ->assertJsonPath('data.versi.0.total', 2)
        ->assertJsonPath('data.versi.1.total', 0);
});
