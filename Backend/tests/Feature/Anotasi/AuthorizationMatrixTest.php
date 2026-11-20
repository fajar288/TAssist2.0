<?php
// tests/Feature/Anotasi/AuthorizationMatrixTest.php

use App\Models\Admin;
use App\Models\AnotasiDokumen;
use App\Models\Bimbingan;
use App\Models\DokumenTA;
use App\Models\Dosen;
use App\Models\Mahasiswa;
use App\Models\VersiDokumen;

it('forbids professor A from creating an annotation on professor B supervision', function () {
    $dosenA = Dosen::factory()->create();
    $dosenB = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();

    // Supervision belongs to dosen B
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosenB)->create();
    $dokumen = DokumenTA::factory()->forBimbingan($bimbingan)->create();
    $versi = VersiDokumen::factory()->forDokumen($dokumen)->create([
        'file_url_or_path' => 'dokumen_ta/proposal.pdf',
    ]);

    // Dosen A attempts to annotate
    $response = $this->withHeaders(authHeaders($dosenA->user))
        ->postJson('/api/v1/dosen/anotasi', [
            'versi_id' => $versi->versi_id,
            'halaman'  => 1,
            'x'        => 0.2,
            'y'        => 0.3,
            'tipe'     => 'komentar',
            'konten'   => 'Anotasi dari dosen lain',
        ]);

    $response->assertForbidden();
});

it('forbids professor A from viewing annotations on professor B supervision', function () {
    $dosenA = Dosen::factory()->create();
    $dosenB = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();

    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosenB)->create();
    $dokumen = DokumenTA::factory()->forBimbingan($bimbingan)->create();
    $versi = VersiDokumen::factory()->forDokumen($dokumen)->create([
        'file_url_or_path' => 'dokumen_ta/proposal.pdf',
    ]);

    $response = $this->withHeaders(authHeaders($dosenA->user))
        ->getJson("/api/v1/dosen/dokumen/{$versi->versi_id}/anotasi");

    $response->assertForbidden();
});

it('forbids professor A from resolving annotations on professor B supervision', function () {
    $dosenA = Dosen::factory()->create();
    $dosenB = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();

    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosenB)->create();
    $dokumen = DokumenTA::factory()->forBimbingan($bimbingan)->create();
    $versi = VersiDokumen::factory()->forDokumen($dokumen)->create([
        'file_url_or_path' => 'dokumen_ta/proposal.pdf',
    ]);
    $anotasi = AnotasiDokumen::factory()->create([
        'versi_id' => $versi->versi_id,
        'dosen_id' => $dosenB->dosen_id,
        'user_id'  => $dosenB->user_id,
        'status'   => 'revised',
    ]);

    $response = $this->withHeaders(authHeaders($dosenA->user))
        ->putJson("/api/v1/dosen/anotasi/{$anotasi->anotasi_id}/resolved");

    $response->assertForbidden();
});

it('forbids a student from resolving annotations (403)', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();
    $dokumen = DokumenTA::factory()->forBimbingan($bimbingan)->create();
    $versi = VersiDokumen::factory()->forDokumen($dokumen)->create([
        'file_url_or_path' => 'dokumen_ta/proposal.pdf',
    ]);
    $anotasi = AnotasiDokumen::factory()->create([
        'versi_id' => $versi->versi_id,
        'dosen_id' => $dosen->dosen_id,
        'user_id'  => $dosen->user_id,
        'status'   => 'open',
    ]);

    // Student calls resolve endpoint
    $response = $this->withHeaders(authHeaders($mahasiswa->user))
        ->putJson("/api/v1/dosen/anotasi/{$anotasi->anotasi_id}/resolved");

    // Blocked by role middleware or policy (403)
    $response->assertForbidden();
});

it('forbids student B from viewing student A document annotations', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswaA = Mahasiswa::factory()->create();
    $mahasiswaB = Mahasiswa::factory()->create();

    $bimbinganA = Bimbingan::factory()->untuk($mahasiswaA, $dosen)->create();
    $dokumenA = DokumenTA::factory()->forBimbingan($bimbinganA)->create();
    $versiA = VersiDokumen::factory()->forDokumen($dokumenA)->create([
        'file_url_or_path' => 'dokumen_ta/proposalA.pdf',
    ]);

    $response = $this->withHeaders(authHeaders($mahasiswaB->user))
        ->getJson("/api/v1/mahasiswa/dokumen/{$versiA->versi_id}/anotasi");

    $response->assertForbidden();
});

it('allows admin to view annotations and document summary', function () {
    $admin = Admin::factory()->create();
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();
    $dokumen = DokumenTA::factory()->forBimbingan($bimbingan)->create();
    $versi = VersiDokumen::factory()->forDokumen($dokumen)->create([
        'file_url_or_path' => 'dokumen_ta/proposal.pdf',
    ]);

    $response = $this->withHeaders(authHeaders($admin->user))
        ->getJson("/api/v1/dokumen/{$dokumen->dokumen_id}/anotasi-summary");

    $response->assertOk()
        ->assertJsonPath('success', true);
});
