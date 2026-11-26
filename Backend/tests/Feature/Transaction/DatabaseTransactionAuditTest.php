<?php

use App\Models\Admin;
use App\Models\BeritaAcara;
use App\Models\Bimbingan;
use App\Models\ChecklistProgress;
use App\Models\DeviceToken;
use App\Models\InformasiTA;
use App\Models\Notifikasi;
use App\Models\ProgresTA;
use App\Models\User;
use App\Services\BeritaAcaraService;
use App\Services\ProgresCalculatorService;

it('rolls back auto-created ProgresTA if checklist recalculation fails in web storeChecklist (T-53)', function () {
    $bimbingan = Bimbingan::factory()->create([
        'status_bimbingan' => 'aktif',
    ]);
    $dosen = $bimbingan->dosen;
    $dosenUser = $dosen->user;

    expect(ProgresTA::where('bimbingan_id', $bimbingan->bimbingan_id)->count())->toBe(0);

    $mock = Mockery::mock(ProgresCalculatorService::class);
    $mock->shouldReceive('recalculate')
        ->once()
        ->andThrow(new RuntimeException('Simulated recalculation failure'));
    $this->app->instance(ProgresCalculatorService::class, $mock);

    $response = $this->withSession([
        'dosen_user' => [
            'user_id'  => $dosenUser->user_id,
            'dosen_id' => $dosen->dosen_id,
            'nama'     => $dosenUser->nama,
            'role'     => 'dosen',
        ],
    ])->post(route('dosen.progress-checklist.checklist.store', $bimbingan->bimbingan_id), [
        'nama_item'  => 'Bab 1 Pendahuluan',
        'is_selesai' => true,
        'bobot'      => 2.0,
    ]);

    $response->assertStatus(500);

    // Neither ProgresTA nor ChecklistProgress should survive the rollback.
    expect(ProgresTA::where('bimbingan_id', $bimbingan->bimbingan_id)->count())->toBe(0)
        ->and(ChecklistProgress::count())->toBe(0)
        ->and(Notifikasi::where('ref_tabel', 'checklist_progress')->count())->toBe(0);
});

it('atomically creates initial ProgresTA and ChecklistProgress in web storeChecklist (T-53)', function () {
    $bimbingan = Bimbingan::factory()->create([
        'status_bimbingan' => 'aktif',
    ]);
    $dosen = $bimbingan->dosen;
    $dosenUser = $dosen->user;

    $response = $this->withSession([
        'dosen_user' => [
            'user_id'  => $dosenUser->user_id,
            'dosen_id' => $dosen->dosen_id,
            'nama'     => $dosenUser->nama,
            'role'     => 'dosen',
        ],
    ])->post(route('dosen.progress-checklist.checklist.store', $bimbingan->bimbingan_id), [
        'nama_item'  => 'Bab 1 Pendahuluan',
        'is_selesai' => true,
        'bobot'      => 2.0,
    ]);

    $response->assertRedirect(route('dosen.progress-checklist.show', $bimbingan->bimbingan_id));

    $progres = ProgresTA::where('bimbingan_id', $bimbingan->bimbingan_id)->first();
    expect($progres)->not->toBeNull()
        ->and((float) $progres->persentase)->toBe(100.0)
        ->and(ChecklistProgress::where('progress_id', $progres->progress_id)->count())->toBe(1);
});

it('rolls back notification deletion if api InformasiTA destroy fails mid-transaction (T-53)', function () {
    $admin = Admin::factory()->create();
    $adminUser = $admin->user;

    $info = InformasiTA::create([
        'admin_id'       => $admin->admin_id,
        'kategori'       => 'pengumuman',
        'judul'          => 'Jadwal Seminar Proposal',
        'konten_or_file' => 'Detail jadwal seminar.',
        'published_at'   => now(),
    ]);

    $notif = Notifikasi::factory()->create([
        'user_id'         => User::factory()->create()->user_id,
        'tipe_notifikasi' => 'informasi_ta',
        'ref_tabel'       => 'informasi_ta',
        'ref_id'          => $info->info_id,
    ]);

    InformasiTA::deleting(function () {
        throw new RuntimeException('Simulated delete failure');
    });

    try {
        $this->actingAs($adminUser, 'sanctum')
            ->deleteJson("/api/v1/admin/informasi-ta/{$info->info_id}")
            ->assertStatus(500);
    } finally {
        InformasiTA::flushEventListeners();
    }

    expect(InformasiTA::find($info->info_id))->not->toBeNull()
        ->and(Notifikasi::find($notif->notifikasi_id))->not->toBeNull();
});

it('atomically deletes InformasiTA and its notifications on web destroy (T-53)', function () {
    $admin = Admin::factory()->create();
    $adminUser = $admin->user;

    $info = InformasiTA::create([
        'admin_id'       => $admin->admin_id,
        'kategori'       => 'pengumuman',
        'judul'          => 'Info Dihapus',
        'konten_or_file' => 'Konten',
        'published_at'   => now(),
    ]);

    Notifikasi::factory()->create([
        'user_id'         => User::factory()->create()->user_id,
        'tipe_notifikasi' => 'informasi_ta',
        'ref_tabel'       => 'informasi_ta',
        'ref_id'          => $info->info_id,
    ]);

    $response = $this->withSession([
        'admin_user' => [
            'user_id'  => $adminUser->user_id,
            'admin_id' => $admin->admin_id,
            'nama'     => $adminUser->nama,
            'role'     => 'admin',
        ],
    ])->delete(route('admin.informasi-ta.destroy', $info->info_id));

    $response->assertRedirect(route('admin.informasi-ta.index'));

    expect(InformasiTA::find($info->info_id))->toBeNull()
        ->and(Notifikasi::where('ref_tabel', 'informasi_ta')->where('ref_id', $info->info_id)->count())->toBe(0);
});

it('atomically unpublishes InformasiTA and removes related notifications in web togglePublish (T-53)', function () {
    $admin = Admin::factory()->create();
    $adminUser = $admin->user;

    $info = InformasiTA::create([
        'admin_id'       => $admin->admin_id,
        'kategori'       => 'pengumuman',
        'judul'          => 'Info Published',
        'konten_or_file' => 'Konten',
        'published_at'   => now()->subMinute(),
    ]);

    Notifikasi::factory()->create([
        'user_id'         => User::factory()->create()->user_id,
        'tipe_notifikasi' => 'informasi_ta',
        'ref_tabel'       => 'informasi_ta',
        'ref_id'          => $info->info_id,
    ]);

    $response = $this->withSession([
        'admin_user' => [
            'user_id'  => $adminUser->user_id,
            'admin_id' => $admin->admin_id,
            'nama'     => $adminUser->nama,
            'role'     => 'admin',
        ],
    ])->post(route('admin.informasi-ta.toggle', $info->info_id));

    $response->assertRedirect();

    $info->refresh();
    expect($info->published_at)->toBeNull()
        ->and(Notifikasi::where('ref_tabel', 'informasi_ta')->where('ref_id', $info->info_id)->count())->toBe(0);
});

it('atomically deactivates device tokens and revokes token on logout (T-53)', function () {
    $user = User::factory()->create();
    $token = $user->createToken('auth_token', ['*'], now()->addHour());

    $deviceToken = DeviceToken::create([
        'user_id'   => $user->user_id,
        'token'     => 'fcm-test-token-123',
        'platform'  => 'android',
        'is_active' => true,
    ]);

    $this->withHeader('Authorization', 'Bearer ' . $token->plainTextToken)
        ->postJson('/api/v1/logout')
        ->assertOk();

    $deviceToken->refresh();
    expect($deviceToken->is_active)->toBeFalse()
        ->and($user->tokens()->count())->toBe(0);
});

it('rolls back pending BeritaAcara row if PDF rendering fails in createDraft (T-53)', function () {
    $bimbingan = Bimbingan::factory()->create([
        'status_bimbingan' => 'selesai',
        'tanggal_selesai'  => now()->toDateString(),
    ]);

    $service = new class extends BeritaAcaraService {
        public function renderAndStorePdf(BeritaAcara $ba): array
        {
            throw new RuntimeException('Simulated PDF render failure');
        }
    };

    expect(fn () => $service->createDraft(
        $bimbingan,
        now()->subMonth()->toDateString(),
        now()->toDateString()
    ))->toThrow(RuntimeException::class, 'Simulated PDF render failure');

    expect(BeritaAcara::where('bimbingan_id', $bimbingan->bimbingan_id)->count())->toBe(0);
});
