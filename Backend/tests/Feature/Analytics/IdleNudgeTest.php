<?php

namespace Tests\Feature\Analytics;

use App\Models\Bimbingan;
use App\Models\Dosen;
use App\Models\JadwalBimbingan;
use App\Models\Mahasiswa;
use App\Models\Notifikasi;
use App\Models\PeriodeLibur;
use Database\Seeders\RisikoKonfigurasiSeeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Artisan;

beforeEach(function () {
    $this->seed(RisikoKonfigurasiSeeder::class);
});

it('sends nudge notification to student and supervisor when idle threshold is crossed (T-27, F-ANL-05 AC 1)', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();

    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create([
        'status_bimbingan' => 'aktif',
    ]);

    // Meeting was 21 days ago
    JadwalBimbingan::factory()->create([
        'bimbingan_id'      => $bimbingan->bimbingan_id,
        'tanggal'           => now()->subDays(21)->toDateString(),
        'status_konfirmasi' => 'dikonfirmasi',
    ]);

    Artisan::call('nudge:idle-supervisions');

    // Both student and dosen should have received a notification
    $notifMhs = Notifikasi::where('user_id', $mahasiswa->user_id)
        ->where('tipe_notifikasi', 'peringatan_bimbingan')
        ->first();

    $notifDsn = Notifikasi::where('user_id', $dosen->user_id)
        ->where('tipe_notifikasi', 'peringatan_bimbingan')
        ->first();

    expect($notifMhs)->not->toBeNull()
        ->and($notifDsn)->not->toBeNull()
        ->and($notifMhs->pesan)->toContain($mahasiswa->user->nama)
        ->and($notifMhs->pesan)->toContain('21 hari');

    // Bimbingan last_nudge_at should be recorded
    $bimbingan->refresh();
    expect($bimbingan->last_nudge_at)->not->toBeNull();
});

it('does not send duplicate nudge on subsequent days if threshold was already crossed (F-ANL-05 AC 2)', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();

    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create([
        'status_bimbingan' => 'aktif',
    ]);

    JadwalBimbingan::factory()->create([
        'bimbingan_id'      => $bimbingan->bimbingan_id,
        'tanggal'           => now()->subDays(21)->toDateString(),
        'status_konfirmasi' => 'dikonfirmasi',
    ]);

    // Run first day (day 21)
    Artisan::call('nudge:idle-supervisions');
    expect(Notifikasi::where('tipe_notifikasi', 'peringatan_bimbingan')->count())->toBe(2);

    // Run next day (day 22)
    Artisan::call('nudge:idle-supervisions', ['--date' => now()->addDay()->toDateString()]);

    // Count should still be 2 (no duplicate nudge sent)
    expect(Notifikasi::where('tipe_notifikasi', 'peringatan_bimbingan')->count())->toBe(2);
});

it('suppresses idle supervision nudges during official academic break windows (C2, F-ANL-05)', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();

    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create([
        'status_bimbingan' => 'aktif',
    ]);

    JadwalBimbingan::factory()->create([
        'bimbingan_id'      => $bimbingan->bimbingan_id,
        'tanggal'           => now()->subDays(25)->toDateString(),
        'status_konfirmasi' => 'dikonfirmasi',
    ]);

    // Create academic break covering today
    PeriodeLibur::create([
        'mulai'      => now()->subDays(2)->toDateString(),
        'selesai'    => now()->addDays(5)->toDateString(),
        'keterangan' => 'Libur Semester Ganjil',
    ]);

    Artisan::call('nudge:idle-supervisions');

    // No notifications sent because today is in an academic break
    expect(Notifikasi::where('tipe_notifikasi', 'peringatan_bimbingan')->count())->toBe(0);
});
