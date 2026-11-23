<?php

namespace Tests\Feature\Analytics;

use App\Models\Admin;
use App\Models\Dosen;
use App\Models\Mahasiswa;
use App\Models\RisikoKonfigurasi;
use Database\Seeders\RisikoKonfigurasiSeeder;

beforeEach(function () {
    $this->seed(RisikoKonfigurasiSeeder::class);
});

it('lists all risk signals with weights, thresholds, and active status for admin', function () {
    $admin = Admin::factory()->create();

    $response = $this->withHeaders(authHeaders($admin->user))
        ->getJson('/api/v1/admin/risiko/konfigurasi');

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonStructure([
            'success',
            'message',
            'data' => [
                '*' => [
                    'konfigurasi_id',
                    'nama_sinyal',
                    'deskripsi',
                    'bobot',
                    'bobot_ternormalisasi',
                    'ambang_batas',
                    'is_active',
                ],
            ],
        ]);

    expect(count($response->json('data')))->toBeGreaterThanOrEqual(6);
});

it('allows admin to update a signal weight, thresholds, and active state', function () {
    $admin = Admin::factory()->create();
    $signal = RisikoKonfigurasi::where('nama_sinyal', 'hari_sejak_bimbingan_terakhir')->first();

    $payload = [
        'bobot'        => 0.30,
        'ambang_batas' => [
            'perlu_perhatian' => 10,
            'berisiko'        => 25,
        ],
        'is_active'    => true,
    ];

    $response = $this->withHeaders(authHeaders($admin->user))
        ->putJson("/api/v1/admin/risiko/konfigurasi/{$signal->konfigurasi_id}", $payload);

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonPath('data.bobot', 0.3)
        ->assertJsonPath('data.ambang_batas.perlu_perhatian', 10);

    $signal->refresh();
    expect($signal->bobot)->toBe(0.3)
        ->and($signal->ambang_batas['perlu_perhatian'])->toBe(10);
});

it('renormalizes weights dynamically when an admin deactivates a signal', function () {
    $admin = Admin::factory()->create();
    $signal = RisikoKonfigurasi::where('nama_sinyal', 'waktu_terpakai_periode')->first();

    // Deactivate one signal
    $this->withHeaders(authHeaders($admin->user))
        ->putJson("/api/v1/admin/risiko/konfigurasi/{$signal->konfigurasi_id}", [
            'is_active' => false,
        ])
        ->assertOk();

    // Fetch renormalized signals
    $active = RisikoKonfigurasi::getActiveWithRenormalizedWeights();
    expect($active->pluck('nama_sinyal'))->not->toContain('waktu_terpakai_periode');

    $sum = $active->sum('bobot_ternormalisasi');
    expect(round($sum, 2))->toBe(1.0);
});

it('forbids non-admin users from accessing risk configuration', function () {
    $mahasiswa = Mahasiswa::factory()->create();
    $dosen = Dosen::factory()->create();

    $this->withHeaders(authHeaders($mahasiswa->user))
        ->getJson('/api/v1/admin/risiko/konfigurasi')
        ->assertForbidden();

    $this->withHeaders(authHeaders($dosen->user))
        ->getJson('/api/v1/admin/risiko/konfigurasi')
        ->assertForbidden();
});
