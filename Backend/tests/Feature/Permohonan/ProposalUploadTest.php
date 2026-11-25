<?php

use App\Models\Dosen;
use App\Models\Mahasiswa;
use App\Models\PermohonanBimbingan;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

it('allows student to submit guidance request with optional PDF proposal (F-SUP-05)', function () {
    Storage::fake('dokumen');

    $mhs = Mahasiswa::factory()->create();
    $dosen = Dosen::factory()->create(['kuota_bimbingan' => 5]);

    $response = $this->actingAs($mhs->user, 'sanctum')
        ->postJson('/api/v1/mahasiswa/permohonan', [
            'dosen_id'      => $dosen->dosen_id,
            'topik_ta'      => 'Sistem Rekomendasi Dosen Pembimbing',
            'file_proposal' => UploadedFile::fake()->create('proposal_ta.pdf', 256, 'application/pdf'),
        ]);

    $response->assertStatus(201)
        ->assertJsonPath('success', true)
        ->assertJsonStructure(['data' => ['permohonan_id', 'file_proposal', 'proposal_url']]);

    $permohonan = PermohonanBimbingan::first();
    expect($permohonan->file_proposal)->not->toBeNull();
    Storage::disk('dokumen')->assertExists($permohonan->file_proposal);
});

it('remains backward compatible when file_proposal is omitted', function () {
    $mhs = Mahasiswa::factory()->create();
    $dosen = Dosen::factory()->create(['kuota_bimbingan' => 5]);

    $response = $this->actingAs($mhs->user, 'sanctum')
        ->postJson('/api/v1/mahasiswa/permohonan', [
            'dosen_id' => $dosen->dosen_id,
            'topik_ta' => 'Topik Tanpa Lampiran',
        ]);

    $response->assertStatus(201)
        ->assertJsonPath('data.file_proposal', null)
        ->assertJsonPath('data.proposal_url', null);
});

it('rejects non-PDF file_proposal uploads', function () {
    $mhs = Mahasiswa::factory()->create();
    $dosen = Dosen::factory()->create(['kuota_bimbingan' => 5]);

    $response = $this->actingAs($mhs->user, 'sanctum')
        ->postJson('/api/v1/mahasiswa/permohonan', [
            'dosen_id'      => $dosen->dosen_id,
            'topik_ta'      => 'Topik File Salah',
            'file_proposal' => UploadedFile::fake()->create('proposal.docx', 100, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'),
        ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['file_proposal']);
});

it('enforces authorization on proposal signed URLs and serves PDF via signed route', function () {
    Storage::fake('dokumen');

    $mhs = Mahasiswa::factory()->create();
    $otherMhs = Mahasiswa::factory()->create();
    $dosen = Dosen::factory()->create(['kuota_bimbingan' => 5]);
    $otherDosen = Dosen::factory()->create(['kuota_bimbingan' => 5]);

    Storage::disk('dokumen')->put('proposals/sample.pdf', '%PDF-1.4 fake');
    $permohonan = PermohonanBimbingan::factory()->create([
        'mahasiswa_id'  => $mhs->mahasiswa_id,
        'dosen_id'      => $dosen->dosen_id,
        'file_proposal' => 'proposals/sample.pdf',
    ]);

    // Owning student & target dosen allowed
    $resMhs = $this->actingAs($mhs->user, 'sanctum')
        ->getJson("/api/v1/permohonan/{$permohonan->permohonan_id}/proposal-url");
    $resMhs->assertOk()->assertJsonStructure(['data' => ['url', 'expires_at']]);

    $this->actingAs($dosen->user, 'sanctum')
        ->getJson("/api/v1/permohonan/{$permohonan->permohonan_id}/proposal-url")
        ->assertOk();

    // Unrelated student & unrelated dosen blocked
    $this->actingAs($otherMhs->user, 'sanctum')
        ->getJson("/api/v1/permohonan/{$permohonan->permohonan_id}/proposal-url")
        ->assertStatus(403);

    $this->actingAs($otherDosen->user, 'sanctum')
        ->getJson("/api/v1/permohonan/{$permohonan->permohonan_id}/proposal-url")
        ->assertStatus(403);

    // Signed URL delivers the PDF
    $signedUrl = $resMhs->json('data.url');
    $this->get($signedUrl)->assertOk();
});
