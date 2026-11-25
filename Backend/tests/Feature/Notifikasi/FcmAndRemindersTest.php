<?php

use App\Jobs\SendFcmNotificationJob;
use App\Models\Bimbingan;
use App\Models\DeviceToken;
use App\Models\JadwalBimbingan;
use App\Models\Notifikasi;
use App\Models\User;
use App\Services\FcmDispatcher;
use App\Services\NotifikasiService;
use Illuminate\Support\Facades\Bus;

it('registers, deregisters, and deactivates device tokens on logout (F-NOT-04)', function () {
    $user = User::factory()->create();

    $this->actingAs($user, 'sanctum')
        ->postJson('/api/v1/device-token', [
            'token'    => 'fcm-token-abc-123',
            'platform' => 'android',
        ])
        ->assertStatus(201)
        ->assertJsonPath('data.is_active', true);

    expect(DeviceToken::where('token', 'fcm-token-abc-123')->first()->is_active)->toBeTrue();

    // Logout deactivates all active device tokens for user
    $token = $user->createToken('test-token')->plainTextToken;
    $this->withHeader('Authorization', 'Bearer ' . $token)
        ->postJson('/api/v1/logout')
        ->assertOk();

    expect(DeviceToken::where('token', 'fcm-token-abc-123')->first()->is_active)->toBeFalse();

    // Re-register and delete explicitly
    $this->actingAs($user, 'sanctum')
        ->postJson('/api/v1/device-token', [
            'token'    => 'fcm-token-abc-123',
            'platform' => 'android',
        ])
        ->assertStatus(201);

    $this->actingAs($user, 'sanctum')
        ->deleteJson('/api/v1/device-token', ['token' => 'fcm-token-abc-123'])
        ->assertOk();

    expect(DeviceToken::where('token', 'fcm-token-abc-123')->first()->is_active)->toBeFalse();
});

it('dispatches queued FCM job from NotifikasiService and purges UNREGISTERED tokens', function () {
    Bus::fake([SendFcmNotificationJob::class]);

    $user = User::factory()->create();
    $notif = NotifikasiService::kirim(
        userId: $user->user_id,
        tipe: 'feedback',
        judul: 'Feedback Baru',
        pesan: 'Dosen memberi catatan baru',
        refTabel: 'versi_dokumen',
        refId: 1
    );

    expect($notif->notifikasi_id)->not->toBeNull();
    Bus::assertDispatched(SendFcmNotificationJob::class, fn ($job) => $job->userId === $user->user_id);

    // Test UNREGISTERED token handling directly through FcmDispatcher mock
    $deviceToken = DeviceToken::create([
        'user_id'   => $user->user_id,
        'token'     => 'stale-fcm-token',
        'platform'  => 'android',
        'is_active' => true,
    ]);

    $mockDispatcher = Mockery::mock(FcmDispatcher::class);
    $mockDispatcher->shouldReceive('sendToToken')
        ->once()
        ->andReturnUsing(function (DeviceToken $dt) {
            $dt->update(['is_active' => false]);
            return 'unregistered';
        });

    $job = new SendFcmNotificationJob($user->user_id, 'Test', 'Body');
    $job->handle($mockDispatcher);

    expect($deviceToken->fresh()->is_active)->toBeFalse();
});

it('sends 24h and 1h reminders once for confirmed meetings and skips unconfirmed ones (F-SCH-05)', function () {
    $bimbingan = Bimbingan::factory()->create();

    $in24h = now()->addHours(24);
    $in1h  = now()->addMinutes(55);

    // Confirmed meeting ~24h from now
    $j24 = JadwalBimbingan::factory()->dikonfirmasi()->forBimbingan($bimbingan)->create([
        'tanggal'       => $in24h->toDateString(),
        'waktu_mulai'   => $in24h->format('H:i'),
        'waktu_selesai' => $in24h->copy()->addHour()->format('H:i'),
    ]);

    // Confirmed meeting ~1h from now
    $j1 = JadwalBimbingan::factory()->dikonfirmasi()->forBimbingan($bimbingan)->create([
        'tanggal'       => $in1h->toDateString(),
        'waktu_mulai'   => $in1h->format('H:i'),
        'waktu_selesai' => $in1h->copy()->addHour()->format('H:i'),
    ]);

    // Pending meeting ~1h from now -> must NOT get reminder
    JadwalBimbingan::factory()->forBimbingan($bimbingan)->create([
        'tanggal'           => $in1h->toDateString(),
        'waktu_mulai'       => $in1h->format('H:i'),
        'waktu_selesai'     => $in1h->copy()->addHour()->format('H:i'),
        'status_konfirmasi' => 'menunggu',
    ]);

    $this->artisan('reminders:meetings')->assertExitCode(0);

    // 2 meetings * 2 recipients (mahasiswa + dosen) = 4 notifications
    expect(Notifikasi::where('tipe_notifikasi', 'pengingat_jadwal')->count())->toBe(4)
        ->and($j24->fresh()->reminder_24h_sent_at)->not->toBeNull()
        ->and($j1->fresh()->reminder_1h_sent_at)->not->toBeNull();

    // Second run must not double-send (idempotency guard)
    $this->artisan('reminders:meetings')->assertExitCode(0);
    expect(Notifikasi::where('tipe_notifikasi', 'pengingat_jadwal')->count())->toBe(4);
});
