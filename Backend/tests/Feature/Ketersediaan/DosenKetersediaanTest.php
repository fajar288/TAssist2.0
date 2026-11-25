<?php

use App\Models\Dosen;
use App\Models\DosenKetersediaan;
use App\Models\Mahasiswa;
use Carbon\Carbon;

it('allows dosen to CRUD availability slots and blocks other dosen', function () {
    $dosen = Dosen::factory()->create();
    $otherDosen = Dosen::factory()->create();

    $create = $this->actingAs($dosen->user, 'sanctum')
        ->postJson('/api/v1/dosen/ketersediaan', [
            'tipe'          => 'mingguan',
            'hari'          => 'senin',
            'waktu_mulai'   => '09:00',
            'waktu_selesai' => '11:00',
            'is_available'  => true,
            'catatan'       => 'Slot pagi',
        ]);

    $create->assertStatus(201)
        ->assertJsonPath('data.hari', 'senin')
        ->assertJsonPath('data.waktu_mulai', '09:00');

    $slotId = $create->json('data.ketersediaan_id');

    $this->actingAs($dosen->user, 'sanctum')
        ->getJson('/api/v1/dosen/ketersediaan')
        ->assertOk()
        ->assertJsonCount(1, 'data');

    // Other dosen cannot update or delete
    $this->actingAs($otherDosen->user, 'sanctum')
        ->putJson("/api/v1/dosen/ketersediaan/{$slotId}", [
            'waktu_selesai' => '12:00',
        ])
        ->assertStatus(403);

    $this->actingAs($otherDosen->user, 'sanctum')
        ->deleteJson("/api/v1/dosen/ketersediaan/{$slotId}")
        ->assertStatus(403);

    // Owner updates and deletes
    $this->actingAs($dosen->user, 'sanctum')
        ->putJson("/api/v1/dosen/ketersediaan/{$slotId}", [
            'waktu_selesai' => '12:00',
        ])
        ->assertOk()
        ->assertJsonPath('data.waktu_selesai', '12:00');

    $this->actingAs($dosen->user, 'sanctum')
        ->deleteJson("/api/v1/dosen/ketersediaan/{$slotId}")
        ->assertOk();

    expect(DosenKetersediaan::count())->toBe(0);
});

it('validates availability slot time range and required fields', function () {
    $dosen = Dosen::factory()->create();

    $this->actingAs($dosen->user, 'sanctum')
        ->postJson('/api/v1/dosen/ketersediaan', [
            'tipe'          => 'mingguan',
            'waktu_mulai'   => '14:00',
            'waktu_selesai' => '12:00',
        ])
        ->assertStatus(422)
        ->assertJsonValidationErrors(['hari', 'waktu_selesai']);
});

it('resolves weekly availability and overrides blocked exceptions for students (F-SCH-04)', function () {
    $dosen = Dosen::factory()->create();
    $mhs = Mahasiswa::factory()->create();

    // Next Monday
    $nextMonday = Carbon::now()->next(Carbon::MONDAY)->format('Y-m-d');

    DosenKetersediaan::create([
        'dosen_id'      => $dosen->dosen_id,
        'tipe'          => 'mingguan',
        'hari'          => 'senin',
        'waktu_mulai'   => '09:00',
        'waktu_selesai' => '11:00',
        'is_available'  => true,
    ]);

    // Before exception: slot appears
    $this->actingAs($mhs->user, 'sanctum')
        ->getJson("/api/v1/mahasiswa/dosen/{$dosen->dosen_id}/ketersediaan?tanggal={$nextMonday}")
        ->assertOk()
        ->assertJsonCount(1, 'data.slot_efektif');

    // Add blocked exception on that specific Monday
    DosenKetersediaan::create([
        'dosen_id'      => $dosen->dosen_id,
        'tipe'          => 'khusus',
        'tanggal'       => $nextMonday,
        'waktu_mulai'   => '09:00',
        'waktu_selesai' => '11:00',
        'is_available'  => false,
        'catatan'       => 'Rapat jurusan',
    ]);

    // After exception: overridden and empty
    $this->actingAs($mhs->user, 'sanctum')
        ->getJson("/api/v1/mahasiswa/dosen/{$dosen->dosen_id}/ketersediaan?tanggal={$nextMonday}")
        ->assertOk()
        ->assertJsonCount(0, 'data.slot_efektif');
});
