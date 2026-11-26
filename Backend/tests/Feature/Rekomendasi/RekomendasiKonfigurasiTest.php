<?php

namespace Tests\Feature\Rekomendasi;

use App\Models\Admin;
use App\Models\Dosen;
use App\Models\Mahasiswa;
use App\Models\RekomendasiKonfigurasi;
use App\Models\RekomendasiLogPencarian;
use App\Models\User;
use Illuminate\Support\Facades\Schema;

it('seeds default recommendation weights (0.60 / 0.25 / 0.15) and enforces admin authorization (T-47)', function () {
    $config = RekomendasiKonfigurasi::current();

    expect($config->bobot_kemiripan)->toBe(0.6)
        ->and($config->bobot_kuota)->toBe(0.25)
        ->and($config->bobot_beban)->toBe(0.15);

    $mahasiswa = Mahasiswa::factory()->create();
    $dosen = Dosen::factory()->create();
    $admin = Admin::factory()->create();

    $this->getJson('/api/v1/admin/rekomendasi/konfigurasi', authHeaders($mahasiswa->user))
        ->assertForbidden();

    app('auth')->forgetGuards();

    $this->putJson('/api/v1/admin/rekomendasi/konfigurasi', [
        'bobot_kemiripan' => 0.7,
        'bobot_kuota'     => 0.2,
        'bobot_beban'     => 0.1,
    ], authHeaders($dosen->user))
        ->assertForbidden();

    app('auth')->forgetGuards();

    $this->getJson('/api/v1/admin/rekomendasi/konfigurasi', authHeaders($admin->user))
        ->assertOk()
        ->assertJsonPath('data.bobot_kemiripan', 0.6)
        ->assertJsonPath('data.bobot_kuota', 0.25)
        ->assertJsonPath('data.bobot_beban', 0.15);
});

it('allows admin to update recommendation weights and rejects sums != 1.0 (T-47)', function () {
    $admin = Admin::factory()->create();

    $this->putJson('/api/v1/admin/rekomendasi/konfigurasi', [
        'bobot_kemiripan' => 0.50,
        'bobot_kuota'     => 0.30,
        'bobot_beban'     => 0.30,
    ], authHeaders($admin->user))
        ->assertUnprocessable();

    $this->putJson('/api/v1/admin/rekomendasi/konfigurasi', [
        'bobot_kemiripan'    => 0.50,
        'bobot_kuota'        => 0.30,
        'bobot_beban'        => 0.20,
        'ambang_skor_rendah' => 0.25,
    ], authHeaders($admin->user))
        ->assertOk()
        ->assertJsonPath('data.bobot_kemiripan', 0.5)
        ->assertJsonPath('data.bobot_kuota', 0.3)
        ->assertJsonPath('data.bobot_beban', 0.2)
        ->assertJsonPath('data.ambang_skor_rendah', 0.25);
});

it('renders and updates recommendation weights through admin web UI without storing student IDs in logs (T-47, T-52)', function () {
    $this->withoutVite();

    $admin = Admin::factory()->create();

    RekomendasiLogPencarian::create([
        'topik_kueri'        => 'komputasi kuantum blockchain',
        'kata_kunci_stemmed' => ['komputasi', 'kuantum', 'blockchain'],
        'skor_tertinggi'     => 0.0,
        'jumlah_kandidat'    => 2,
        'created_at'         => now(),
    ]);

    expect(Schema::hasColumn('rekomendasi_log_pencarian', 'user_id'))->toBeFalse()
        ->and(Schema::hasColumn('rekomendasi_log_pencarian', 'mahasiswa_id'))->toBeFalse();

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

    $this->withSession($session)
        ->get('/admin/rekomendasi/konfigurasi')
        ->assertOk()
        ->assertSee('komputasi kuantum blockchain');

    $this->withSession($session)
        ->put('/admin/rekomendasi/konfigurasi', [
            'bobot_kemiripan'    => 0.65,
            'bobot_kuota'        => 0.20,
            'bobot_beban'        => 0.15,
            'ambang_skor_rendah' => 0.35,
        ])
        ->assertRedirect('/admin/rekomendasi/konfigurasi');

    expect((float) RekomendasiKonfigurasi::current()->bobot_kemiripan)->toBe(0.65);

    $this->getJson('/api/v1/admin/rekomendasi/log-pencarian', authHeaders($admin->user))
        ->assertOk()
        ->assertJsonPath('data.data.0.topik_kueri', 'komputasi kuantum blockchain');
});
