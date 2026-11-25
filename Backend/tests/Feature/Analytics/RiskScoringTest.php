<?php

namespace Tests\Feature\Analytics;

use App\Models\Admin;
use App\Models\AnotasiDokumen;
use App\Models\Bimbingan;
use App\Models\ChecklistProgress;
use App\Models\DokumenTA;
use App\Models\Dosen;
use App\Models\JadwalBimbingan;
use App\Models\Mahasiswa;
use App\Models\ProgresTA;
use App\Models\RisikoSnapshot;
use App\Models\VersiDokumen;
use App\Services\RiskScoringService;
use Database\Seeders\RisikoKonfigurasiSeeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Artisan;
use InvalidArgumentException;

beforeEach(function () {
    $this->seed(RisikoKonfigurasiSeeder::class);
});

it('calculates a high risk score for a delayed supervision (F-ANL-02 AC 1)', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();

    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create([
        'status_bimbingan' => 'aktif',
        'periode_mulai'   => now()->subDays(150)->toDateString(),
        'periode_selesai' => now()->addDays(50)->toDateString(), // 200 total days, 150 elapsed = 75%
    ]);

    // 1. Last confirmed meeting 35 days ago
    JadwalBimbingan::factory()->create([
        'bimbingan_id'      => $bimbingan->bimbingan_id,
        'tanggal'           => now()->subDays(35)->toDateString(),
        'status_konfirmasi' => 'dikonfirmasi',
    ]);

    // 2. Last document version 50 days old
    $dokumen = DokumenTA::factory()->forBimbingan($bimbingan)->create();
    $versi = VersiDokumen::factory()->forDokumen($dokumen)->create([
        'created_at' => now()->subDays(50),
    ]);

    // 3. 3 open annotations older than 14 days
    for ($i = 0; $i < 3; $i++) {
        AnotasiDokumen::factory()->create([
            'versi_id'   => $versi->versi_id,
            'dosen_id'   => $dosen->dosen_id,
            'user_id'    => $dosen->user_id,
            'status'     => 'open',
            'created_at' => now()->subDays(20),
        ]);
    }

    // 4. 1 overdue checklist item
    $progres = ProgresTA::factory()->create([
        'bimbingan_id' => $bimbingan->bimbingan_id,
        'updated_at'   => now()->subDays(40), // 5. progress stagnan 40 days
    ]);

    ChecklistProgress::factory()->create([
        'progress_id' => $progres->progress_id,
        'is_selesai'  => false,
    ]);

    $service = app(RiskScoringService::class);
    $result = $service->calculateForBimbingan($bimbingan, now());

    expect($result['skor'])->toBeGreaterThanOrEqual(70)
        ->and($result['level'])->toBe('berisiko')
        ->and(count($result['sinyal']))->toBe(6);

    // Verify each signal payload has required explainability keys
    foreach ($result['sinyal'] as $signal) {
        expect($signal)->toHaveKeys(['nama', 'nilai', 'bobot', 'kontribusi', 'deskripsi']);
    }
});

it('calculates a low score and safe level for an on-track supervision (F-ANL-02 AC 2)', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();

    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create([
        'status_bimbingan' => 'aktif',
        'periode_mulai'   => now()->subDays(30)->toDateString(),
        'periode_selesai' => now()->addDays(70)->toDateString(), // 100 days total, 30 elapsed = 30%
    ]);

    // Recent meeting 3 days ago
    JadwalBimbingan::factory()->create([
        'bimbingan_id'      => $bimbingan->bimbingan_id,
        'tanggal'           => now()->subDays(3)->toDateString(),
        'status_konfirmasi' => 'dikonfirmasi',
    ]);

    // Recent document version 2 days ago
    $dokumen = DokumenTA::factory()->forBimbingan($bimbingan)->create();
    VersiDokumen::factory()->forDokumen($dokumen)->create([
        'created_at' => now()->subDays(2),
    ]);

    // Recent progress update
    ProgresTA::factory()->create([
        'bimbingan_id' => $bimbingan->bimbingan_id,
        'updated_at'   => now()->subDays(2),
    ]);

    $service = app(RiskScoringService::class);
    $result = $service->calculateForBimbingan($bimbingan, now());

    expect($result['skor'])->toBeLessThan(30)
        ->and($result['level'])->toBe('aman');
});

it('excludes waktu_terpakai_periode and renormalizes weights when TA period is absent (Decision C1)', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();

    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create([
        'status_bimbingan' => 'aktif',
        'periode_mulai'   => null,
        'periode_selesai' => null,
    ]);

    $service = app(RiskScoringService::class);
    $result = $service->calculateForBimbingan($bimbingan, now());

    $signalNames = collect($result['sinyal'])->pluck('nama')->toArray();
    expect($signalNames)->not->toContain('waktu_terpakai_periode')
        ->and(count($signalNames))->toBe(5);

    $sumWeights = collect($result['sinyal'])->sum('bobot');
    expect(round($sumWeights, 2))->toBe(1.0);
});

it('enforces the explainability contract and rejects bare scores or incomplete signal payloads (T-23)', function () {
    $bimbingan = Bimbingan::factory()->create();

    // Bare score without sinyal
    expect(fn () => RisikoSnapshot::create([
        'bimbingan_id'   => $bimbingan->bimbingan_id,
        'skor'           => 45,
        'level'          => 'perlu_perhatian',
        'sinyal'         => [],
        'tanggal_hitung' => now()->toDateString(),
    ]))->toThrow(InvalidArgumentException::class);

    // Missing 'kontribusi' key
    expect(fn () => RisikoSnapshot::create([
        'bimbingan_id'   => $bimbingan->bimbingan_id,
        'skor'           => 45,
        'level'          => 'perlu_perhatian',
        'sinyal'         => [
            ['nama' => 'test', 'nilai' => 10, 'bobot' => 0.2, 'deskripsi' => 'missing kontribusi'],
        ],
        'tanggal_hitung' => now()->toDateString(),
    ]))->toThrow(InvalidArgumentException::class);
});

it('returns risk trend over time for a supervision (T-24)', function () {
    $admin = Admin::factory()->create();
    $bimbingan = Bimbingan::factory()->create(['status_bimbingan' => 'aktif']);

    // Create 3 historical snapshots
    for ($i = 3; $i >= 1; $i--) {
        RisikoSnapshot::create([
            'bimbingan_id'   => $bimbingan->bimbingan_id,
            'skor'           => 30 + ($i * 15),
            'level'          => ($i >= 2) ? 'perlu_perhatian' : 'aman',
            'sinyal'         => [
                [
                    'nama'       => 'hari_sejak_bimbingan_terakhir',
                    'nilai'      => $i * 10,
                    'bobot'      => 0.25,
                    'kontribusi' => 10.0,
                    'deskripsi'  => 'Test signal',
                ],
            ],
            'tanggal_hitung' => now()->subDays($i * 5)->toDateString(),
        ]);
    }

    $response = $this->withHeaders(authHeaders($admin->user))
        ->getJson("/api/v1/admin/analytics/risk-trend/{$bimbingan->bimbingan_id}");

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonCount(3, 'data.trend');
});

it('runs risk:score console command and creates snapshots for all active supervisions (T-22)', function () {
    Bimbingan::factory()->count(3)->create(['status_bimbingan' => 'aktif']);
    Bimbingan::factory()->create(['status_bimbingan' => 'selesai']);

    Artisan::call('risk:score');

    expect(RisikoSnapshot::count())->toBe(3)
        ->and(RisikoSnapshot::whereDate('tanggal_hitung', now())->count())->toBe(3);
});
