<?php

namespace Tests\Feature\Analytics;

use App\Models\Bimbingan;
use App\Models\Dosen;
use App\Models\Mahasiswa;
use App\Models\RisikoSnapshot;
use Database\Seeders\RisikoKonfigurasiSeeder;

beforeEach(function () {
    $this->seed(RisikoKonfigurasiSeeder::class);
});

it('allows dosen to view risk indicators only for their own supervised students (T-26, F-ANL-04)', function () {
    $dosenA = Dosen::factory()->create();
    $dosenB = Dosen::factory()->create();

    // Dosen A has 2 students
    $mhsA1 = Mahasiswa::factory()->create();
    $mhsA2 = Mahasiswa::factory()->create();
    $bA1 = Bimbingan::factory()->untuk($mhsA1, $dosenA)->create(['status_bimbingan' => 'aktif']);
    $bA2 = Bimbingan::factory()->untuk($mhsA2, $dosenA)->create(['status_bimbingan' => 'aktif']);

    // Dosen B has 1 student
    $mhsB1 = Mahasiswa::factory()->create();
    $bB1 = Bimbingan::factory()->untuk($mhsB1, $dosenB)->create(['status_bimbingan' => 'aktif']);

    RisikoSnapshot::factory()->create([
        'bimbingan_id' => $bA1->bimbingan_id,
        'skor'         => 20,
        'level'        => 'aman',
    ]);

    RisikoSnapshot::factory()->berisiko()->create([
        'bimbingan_id' => $bA2->bimbingan_id,
        'skor'         => 80,
    ]);

    RisikoSnapshot::factory()->create([
        'bimbingan_id' => $bB1->bimbingan_id,
        'skor'         => 50,
        'level'        => 'perlu_perhatian',
    ]);

    // Request as Dosen A
    $response = $this->withHeaders(authHeaders($dosenA->user))
        ->getJson('/api/v1/dosen/analytics/risk');

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonCount(2, 'data');

    $studentNames = collect($response->json('data'))->pluck('mahasiswa.nama')->toArray();
    expect($studentNames)->toContain($mhsA1->user->nama)
        ->and($studentNames)->toContain($mhsA2->user->nama)
        ->and($studentNames)->not->toContain($mhsB1->user->nama);

    // Verify signal breakdown is included
    $entryWithRisk = collect($response->json('data'))->firstWhere('bimbingan_id', $bA2->bimbingan_id);
    expect($entryWithRisk['risiko']['skor'])->toBe(80)
        ->and($entryWithRisk['risiko']['level'])->toBe('berisiko')
        ->and($entryWithRisk['risiko']['sinyal'])->not->toBeEmpty();
});

it('forbids mahasiswa from accessing dosen risk analytics endpoint', function () {
    $mahasiswa = Mahasiswa::factory()->create();

    $this->withHeaders(authHeaders($mahasiswa->user))
        ->getJson('/api/v1/dosen/analytics/risk')
        ->assertForbidden();
});
