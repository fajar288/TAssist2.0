<?php

use App\Models\Bimbingan;
use App\Models\ChecklistProgress;
use App\Models\ProgresTA;
use Illuminate\Support\Facades\Schema;

it('renames tgl_selesai to is_selesai and adds bobot column on checklist_progress (T-40, T-44)', function () {
    expect(Schema::hasColumn('checklist_progress', 'is_selesai'))->toBeTrue()
        ->and(Schema::hasColumn('checklist_progress', 'bobot'))->toBeTrue()
        ->and(Schema::hasColumn('checklist_progress', 'tgl_selesai'))->toBeFalse();
});

it('auto-calculates weighted progress when checklist items change (F-PRG-04)', function () {
    $bimbingan = Bimbingan::factory()->create();
    $progres = ProgresTA::factory()->forBimbingan($bimbingan)->create([
        'persentase'  => 0,
        'is_override' => false,
    ]);

    $dosenUser = $bimbingan->dosen->user;

    // 3 items: weights 1.0, 2.0, 1.0 -> first two completed => (1 + 2) / 4 * 100 = 75%
    $r1 = $this->actingAs($dosenUser, 'sanctum')
        ->postJson("/api/v1/dosen/progres/{$progres->progress_id}/checklist", [
            'nama_item'  => 'Bab 1',
            'bobot'      => 1.0,
            'is_selesai' => true,
        ]);
    $r1->assertStatus(201)->assertJsonPath('data.progres_persentase', 100);

    $r2 = $this->actingAs($dosenUser, 'sanctum')
        ->postJson("/api/v1/dosen/progres/{$progres->progress_id}/checklist", [
            'nama_item'  => 'Bab 2',
            'bobot'      => 2.0,
            'is_selesai' => false,
        ]);
    $r2->assertStatus(201);

    $r3 = $this->actingAs($dosenUser, 'sanctum')
        ->postJson("/api/v1/dosen/progres/{$progres->progress_id}/checklist", [
            'nama_item'  => 'Bab 3',
            'bobot'      => 1.0,
            'is_selesai' => false,
        ]);
    $r3->assertStatus(201);

    $bab2Id = $r2->json('data.checklist_id');

    $toggle = $this->actingAs($dosenUser, 'sanctum')
        ->putJson("/api/v1/dosen/checklist/{$bab2Id}", [
            'nama_item'  => 'Bab 2',
            'bobot'      => 2.0,
            'is_selesai' => true,
        ]);

    $toggle->assertOk()
        ->assertJsonPath('data.is_selesai', true)
        ->assertJsonPath('data.progres_persentase', 75);

    expect((float) $progres->fresh()->persentase)->toBe(75.0);
});

it('requires catatan on manual override and resumes auto-calculation when cleared (F-PRG-04)', function () {
    $bimbingan = Bimbingan::factory()->create();
    $progres = ProgresTA::factory()->forBimbingan($bimbingan)->create(['persentase' => 0]);
    $dosenUser = $bimbingan->dosen->user;

    $c1 = ChecklistProgress::factory()->create([
        'progress_id' => $progres->progress_id,
        'nama_item'   => 'Bab 1',
        'bobot'       => 1.0,
        'is_selesai'  => true,
    ]);
    $c2 = ChecklistProgress::factory()->create([
        'progress_id' => $progres->progress_id,
        'nama_item'   => 'Bab 2',
        'bobot'       => 1.0,
        'is_selesai'  => false,
    ]);

    // Missing catatan when is_override = true -> 422
    $this->actingAs($dosenUser, 'sanctum')
        ->putJson("/api/v1/dosen/progres/{$bimbingan->bimbingan_id}", [
            'persentase'      => 50,
            'status_progress' => 'Revisi Bab 2',
            'is_override'     => true,
        ])
        ->assertStatus(422)
        ->assertJsonValidationErrors(['catatan']);

    // Valid manual override to 50%
    $this->actingAs($dosenUser, 'sanctum')
        ->putJson("/api/v1/dosen/progres/{$bimbingan->bimbingan_id}", [
            'persentase'      => 50,
            'status_progress' => 'Revisi Bab 2',
            'is_override'     => true,
            'catatan'         => 'Student needs to redo Chapter 2',
        ])
        ->assertOk()
        ->assertJsonPath('data.persentase', 50)
        ->assertJsonPath('data.is_override', true);

    // Completing c2 while override is active keeps 50%
    $this->actingAs($dosenUser, 'sanctum')
        ->putJson("/api/v1/dosen/checklist/{$c2->checklist_id}", [
            'nama_item'  => 'Bab 2',
            'is_selesai' => true,
        ])
        ->assertOk()
        ->assertJsonPath('data.progres_persentase', 50)
        ->assertJsonPath('data.is_override', true);

    // Clearing override (is_override = false) resumes auto-calculation -> 100%
    $this->actingAs($dosenUser, 'sanctum')
        ->putJson("/api/v1/dosen/progres/{$bimbingan->bimbingan_id}", [
            'status_progress' => 'Siap Seminar',
            'is_override'     => false,
            'catatan'         => 'Override dicabut',
        ])
        ->assertOk()
        ->assertJsonPath('data.persentase', 100)
        ->assertJsonPath('data.is_override', false);

    // Unchecking c1 now recalculates to 50%
    $this->actingAs($dosenUser, 'sanctum')
        ->putJson("/api/v1/dosen/checklist/{$c1->checklist_id}", [
            'nama_item'  => 'Bab 1',
            'is_selesai' => false,
        ])
        ->assertOk()
        ->assertJsonPath('data.progres_persentase', 50);
});
