<?php
// tests/Feature/Schema/SchemaGapTest.php
//
// T-80 — guards the four schema gaps every later wave assumes (C1, C2, C3).
// Assertions read the real schema, not only the model, so a later migration
// that silently drops a column fails here instead of in Wave 3.

use App\Models\Bimbingan;
use App\Models\PeriodeLibur;
use App\Models\ProgresTA;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Schema::getColumns() keyed by column name.
 *
 * @return \Illuminate\Support\Collection<string, array<string, mixed>>
 */
function schemaColumns(string $table): Illuminate\Support\Collection
{
    return collect(Schema::getColumns($table))->keyBy('name');
}

it('adds the completion date and TA period columns to bimbingan', function () {
    $columns = schemaColumns('bimbingan');

    expect($columns->keys()->all())->toContain('tanggal_selesai', 'periode_mulai', 'periode_selesai');

    foreach (['tanggal_selesai', 'periode_mulai', 'periode_selesai'] as $column) {
        expect($columns[$column]['nullable'])->toBeTrue("{$column} must be nullable")
            ->and($columns[$column]['type_name'])->toBeIn(['date', 'date_text']);
    }

    // The idle-nudge / retention queries filter on tanggal_selesai.
    $indexes = collect(Schema::getIndexes('bimbingan'))->pluck('name');

    expect($indexes)->toContain('bimbingan_tanggal_selesai_index');
});

it('casts the new bimbingan dates and answers the status helpers', function () {
    $bimbingan = Bimbingan::factory()->create();

    expect($bimbingan->tanggal_selesai)->toBeNull()
        ->and($bimbingan->periode_mulai)->toBeNull()
        ->and($bimbingan->periode_selesai)->toBeNull()
        ->and($bimbingan->hasPeriode())->toBeFalse()
        ->and($bimbingan->isAktif())->toBeTrue()
        ->and($bimbingan->isSelesai())->toBeFalse()
        ->and($bimbingan->isDibatalkan())->toBeFalse();

    $bimbingan->update([
        'status_bimbingan' => 'selesai',
        'tanggal_selesai'  => '2026-11-20',
        'periode_mulai'    => '2026-08-01',
        'periode_selesai'  => '2026-12-31',
    ]);
    $bimbingan->refresh();

    expect($bimbingan->isSelesai())->toBeTrue()
        ->and($bimbingan->isDibatalkan())->toBeFalse()
        ->and($bimbingan->tanggal_selesai)->toBeInstanceOf(Carbon::class)
        ->and($bimbingan->tanggal_selesai->toDateString())->toBe('2026-11-20')
        ->and($bimbingan->periode_mulai->toDateString())->toBe('2026-08-01')
        ->and($bimbingan->periode_selesai->toDateString())->toBe('2026-12-31')
        ->and($bimbingan->hasPeriode())->toBeTrue();

    // A half-filled period is "not set" (C1): the signal reports inactive.
    $bimbingan->update(['periode_selesai' => null]);

    expect($bimbingan->fresh()->hasPeriode())->toBeFalse();
});

it('defaults progres_ta.is_override to false and casts it to boolean', function () {
    $column = schemaColumns('progres_ta')['is_override'];

    expect($column['nullable'])->toBeFalse()
        ->and(trim((string) $column['default'], "'"))->toBe('0');

    $progres = ProgresTA::factory()->create();
    $progres->refresh();

    expect($progres->is_override)->toBeFalse();

    // DB-level default applies to inserts that omit the column entirely.
    DB::table('progres_ta')->insert([
        'bimbingan_id'     => $progres->bimbingan_id,
        'persentase'       => 10,
        'status_progress'  => 'berjalan',
        'updated_dosen_id' => null,
        'catatan'          => null,
        'created_at'       => now(),
        'updated_at'       => now(),
    ]);

    $raw = DB::table('progres_ta')->where('progress_id', '!=', $progres->progress_id)->value('is_override');

    expect((int) $raw)->toBe(0);

    $override = ProgresTA::factory()->forBimbingan($progres->bimbingan)->create(['is_override' => true]);

    expect($override->fresh()->is_override)->toBeTrue();
});

it('creates periode_libur rows and treats both window boundaries as inside', function () {
    $libur = PeriodeLibur::factory()->rentang('2026-12-20', '2027-01-05')->create();

    expect($libur->periode_libur_id)->toBeInt()
        ->and($libur->mulai)->toBeInstanceOf(Carbon::class)
        ->and($libur->mulai->toDateString())->toBe('2026-12-20')
        ->and($libur->selesai->toDateString())->toBe('2027-01-05')
        ->and($libur->keterangan)->toBe('Libur semester')
        ->and($libur->isBerlangsung('2026-12-19'))->toBeFalse()
        ->and($libur->isBerlangsung('2026-12-20'))->toBeTrue()   // inclusive start
        ->and($libur->isBerlangsung('2026-12-28'))->toBeTrue()
        ->and($libur->isBerlangsung('2027-01-05'))->toBeTrue()   // inclusive end
        ->and($libur->isBerlangsung('2027-01-06'))->toBeFalse()
        ->and($libur->isBerlangsung(Carbon::parse('2026-12-31 23:59:59')))->toBeTrue();
});

it('filters break windows with scopeAktif', function () {
    $aktif = PeriodeLibur::factory()->rentang('2026-12-20', '2027-01-05')->create();
    PeriodeLibur::factory()->rentang('2026-06-01', '2026-06-30')->create();

    expect(PeriodeLibur::aktif('2026-12-25')->pluck('periode_libur_id')->all())
        ->toBe([$aktif->periode_libur_id])
        ->and(PeriodeLibur::aktif('2027-01-05')->count())->toBe(1)
        ->and(PeriodeLibur::aktif('2026-07-01')->count())->toBe(0);
});

it('matches today with the default factory window and scopeAktif()', function () {
    $libur = PeriodeLibur::factory()->create();

    expect($libur->isBerlangsung())->toBeTrue()
        ->and(PeriodeLibur::aktif()->count())->toBe(1);
});

it('rolls the T-80 migration back to the previous schema and forward again', function () {
    /** @var \Illuminate\Database\Migrations\Migration $migration */
    $migration = require database_path('migrations/2026_11_20_000001_add_schema_gaps_for_analytics.php');

    expect(Schema::hasColumns('bimbingan', ['tanggal_selesai', 'periode_mulai', 'periode_selesai']))->toBeTrue()
        ->and(Schema::hasColumn('progres_ta', 'is_override'))->toBeTrue()
        ->and(Schema::hasTable('periode_libur'))->toBeTrue();

    $migration->down();

    expect(Schema::hasColumns('bimbingan', ['tanggal_selesai', 'periode_mulai', 'periode_selesai']))->toBeFalse()
        ->and(Schema::hasColumn('progres_ta', 'is_override'))->toBeFalse()
        ->and(Schema::hasTable('periode_libur'))->toBeFalse()
        // Untouched by T-80; T-40/T-44 later renames tgl_selesai -> is_selesai and adds bobot.
        ->and(Schema::hasColumns('checklist_progress', ['progress_id', 'is_selesai', 'bobot']))->toBeTrue();

    expect(collect(Schema::getIndexes('bimbingan'))->pluck('name')->all())
        ->not->toContain('bimbingan_tanggal_selesai_index');

    $migration->up();

    expect(Schema::hasColumns('bimbingan', ['tanggal_selesai', 'periode_mulai', 'periode_selesai']))->toBeTrue()
        ->and(Schema::hasColumn('progres_ta', 'is_override'))->toBeTrue()
        ->and(Schema::hasTable('periode_libur'))->toBeTrue();

    expect(collect(Schema::getIndexes('bimbingan'))->pluck('name')->all())
        ->toContain('bimbingan_tanggal_selesai_index');
});
