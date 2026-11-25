<?php

use App\Models\Bimbingan;
use App\Models\ChecklistProgress;
use App\Models\DokumenTA;
use App\Models\Dosen;
use App\Models\JadwalBimbingan;
use App\Models\Mahasiswa;
use App\Models\ProgresTA;
use App\Models\VersiDokumen;

it('allows owning student and supervising dosen to export history as PDF and Excel (F-DOC-07)', function () {
    $bimbingan = Bimbingan::factory()->create();
    JadwalBimbingan::factory()->dikonfirmasi()->forBimbingan($bimbingan)->create();
    $dok = DokumenTA::factory()->forBimbingan($bimbingan)->create();
    VersiDokumen::factory()->forDokumen($dok)->create();
    $progres = ProgresTA::factory()->forBimbingan($bimbingan)->create(['persentase' => 50]);
    ChecklistProgress::factory()->forProgress($progres)->selesai()->create();

    $mhsUser = $bimbingan->mahasiswa->user;
    $dosenUser = $bimbingan->dosen->user;

    // Student PDF export
    $pdfRes = $this->actingAs($mhsUser, 'sanctum')
        ->get("/api/v1/mahasiswa/bimbingan/{$bimbingan->bimbingan_id}/export?format=pdf");
    $pdfRes->assertOk();
    expect($pdfRes->headers->get('content-type'))->toContain('application/pdf');

    // Dosen Excel export
    $xlsxRes = $this->actingAs($dosenUser, 'sanctum')
        ->get("/api/v1/dosen/bimbingan/{$bimbingan->bimbingan_id}/export?format=excel");
    $xlsxRes->assertOk();
    expect($xlsxRes->headers->get('content-type'))->toContain('spreadsheetml');
});

it('forbids unrelated users from exporting supervision history and validates format', function () {
    $bimbingan = Bimbingan::factory()->create();
    $otherMhs = Mahasiswa::factory()->create();
    $otherDosen = Dosen::factory()->create();

    $this->actingAs($otherMhs->user, 'sanctum')
        ->getJson("/api/v1/mahasiswa/bimbingan/{$bimbingan->bimbingan_id}/export?format=pdf")
        ->assertStatus(403);

    $this->actingAs($otherDosen->user, 'sanctum')
        ->getJson("/api/v1/dosen/bimbingan/{$bimbingan->bimbingan_id}/export?format=excel")
        ->assertStatus(403);

    $this->actingAs($bimbingan->mahasiswa->user, 'sanctum')
        ->getJson("/api/v1/mahasiswa/bimbingan/{$bimbingan->bimbingan_id}/export?format=csv")
        ->assertStatus(422);
});
