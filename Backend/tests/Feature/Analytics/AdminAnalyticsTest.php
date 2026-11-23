<?php

namespace Tests\Feature\Analytics;

use App\Models\Admin;
use App\Models\AnotasiDokumen;
use App\Models\Bimbingan;
use App\Models\Dosen;
use App\Models\Mahasiswa;
use App\Models\PermohonanBimbingan;
use App\Models\RisikoSnapshot;
use App\Models\VersiDokumen;
use Database\Seeders\RisikoKonfigurasiSeeder;

beforeEach(function () {
    $this->seed(RisikoKonfigurasiSeeder::class);
});

it('returns risk distribution per study program (prodi)', function () {
    $admin = Admin::factory()->create();

    $mhs1 = Mahasiswa::factory()->create(['prodi' => 'Teknik Informatika']);
    $b1 = Bimbingan::factory()->create(['mahasiswa_id' => $mhs1->mahasiswa_id, 'status_bimbingan' => 'aktif']);
    RisikoSnapshot::factory()->create([
        'bimbingan_id' => $b1->bimbingan_id,
        'level'        => 'aman',
    ]);

    $mhs2 = Mahasiswa::factory()->create(['prodi' => 'Sistem Informasi']);
    $b2 = Bimbingan::factory()->create(['mahasiswa_id' => $mhs2->mahasiswa_id, 'status_bimbingan' => 'aktif']);
    RisikoSnapshot::factory()->berisiko()->create([
        'bimbingan_id' => $b2->bimbingan_id,
        'skor'         => 80,
    ]);

    $response = $this->withHeaders(authHeaders($admin->user))
        ->getJson('/api/v1/admin/analytics/risk-distribution');

    $response->assertOk()
        ->assertJsonPath('success', true);

    $data = collect($response->json('data'));
    $ti = $data->firstWhere('prodi', 'Teknik Informatika');
    $si = $data->firstWhere('prodi', 'Sistem Informasi');

    expect($ti['aman'])->toBe(1)
        ->and($si['berisiko'])->toBe(1);
});

it('returns average revision-cycle duration per supervisor', function () {
    $admin = Admin::factory()->create();
    $dosen = Dosen::factory()->create();
    $versi = VersiDokumen::factory()->create();

    // Create 2 resolved annotations for this dosen
    AnotasiDokumen::factory()->create([
        'dosen_id'   => $dosen->dosen_id,
        'versi_id'   => $versi->versi_id,
        'status'     => 'resolved',
        'created_at' => now()->subDays(4),
        'updated_at' => now()->subDays(2), // 2 days = 48 hours
    ]);

    AnotasiDokumen::factory()->create([
        'dosen_id'   => $dosen->dosen_id,
        'versi_id'   => $versi->versi_id,
        'status'     => 'resolved',
        'created_at' => now()->subDays(6),
        'updated_at' => now()->subDays(2), // 4 days = 96 hours
    ]);

    $response = $this->withHeaders(authHeaders($admin->user))
        ->getJson('/api/v1/admin/analytics/revision-cycle');

    $response->assertOk()
        ->assertJsonPath('success', true);

    $entry = collect($response->json('data'))->firstWhere('dosen_id', $dosen->dosen_id);
    expect($entry['jumlah_anotasi_selesai'])->toBe(2)
        ->and($entry['rata_rata_hari'])->toEqual(3.0);
});

it('returns supervision funnel metrics', function () {
    $admin = Admin::factory()->create();

    PermohonanBimbingan::factory()->create(['status' => 'menunggu']);
    $pDiterima = PermohonanBimbingan::factory()->create(['status' => 'diterima']);
    $bAktif = Bimbingan::factory()->create(['permohonan_id' => $pDiterima->permohonan_id, 'status_bimbingan' => 'aktif']);
    Bimbingan::factory()->create(['status_bimbingan' => 'selesai']);

    RisikoSnapshot::factory()->berisiko()->create([
        'bimbingan_id' => $bAktif->bimbingan_id,
        'level'        => 'berisiko',
    ]);

    $response = $this->withHeaders(authHeaders($admin->user))
        ->getJson('/api/v1/admin/analytics/supervision-funnel');

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonPath('data.aktif', 1)
        ->assertJsonPath('data.berisiko', 1)
        ->assertJsonPath('data.selesai', 1);
});

it('returns at-risk supervisions sorted by risk score descending with explainability breakdown', function () {
    $admin = Admin::factory()->create();

    $b1 = Bimbingan::factory()->create(['status_bimbingan' => 'aktif']);
    RisikoSnapshot::factory()->create([
        'bimbingan_id' => $b1->bimbingan_id,
        'skor'         => 55,
        'level'        => 'perlu_perhatian',
    ]);

    $b2 = Bimbingan::factory()->create(['status_bimbingan' => 'aktif']);
    RisikoSnapshot::factory()->create([
        'bimbingan_id' => $b2->bimbingan_id,
        'skor'         => 85,
        'level'        => 'berisiko',
    ]);

    $response = $this->withHeaders(authHeaders($admin->user))
        ->getJson('/api/v1/admin/analytics/at-risk');

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonCount(2, 'data');

    $data = $response->json('data');
    expect($data[0]['skor'])->toBe(85)
        ->and($data[1]['skor'])->toBe(55)
        ->and($data[0]['sinyal'])->not->toBeEmpty();
});

it('renders admin web analytics and risk configuration Blade pages (T-77)', function () {
    $this->withoutVite();

    $admin = Admin::factory()->create();
    $bimbingan = Bimbingan::factory()->create(['status_bimbingan' => 'aktif']);
    RisikoSnapshot::factory()->create(['bimbingan_id' => $bimbingan->bimbingan_id]);

    $session = [
        'admin_logged_in' => true,
        'admin_id'        => $admin->admin_id,
        'admin_user'      => [
            'user_id' => $admin->user_id,
            'nama'    => $admin->user->nama,
            'email'   => $admin->user->email,
            'role'    => 'admin',
        ],
    ];

    // 1. Analytics Dashboard
    $this->withSession($session)
        ->get('/admin/analytics')
        ->assertOk()
        ->assertSee('Dashboard Analitik')
        ->assertSee('Supervision Funnel');

    // 2. Risk Configuration Page
    $this->withSession($session)
        ->get('/admin/risiko/konfigurasi')
        ->assertOk()
        ->assertSee('Konfigurasi Scoring Engine Risiko')
        ->assertSee('hari_sejak_bimbingan_terakhir');

    // 3. Risk Trend Page
    $this->withSession($session)
        ->get("/admin/analytics/trend/{$bimbingan->bimbingan_id}")
        ->assertOk()
        ->assertSee('Riwayat Tren Skor Risiko');
});
