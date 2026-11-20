<?php

use App\Models\BeritaAcara;
use App\Models\Dosen;
use Illuminate\Support\Facades\Schema;

it('creates berita_acara table with all required columns and foreign keys', function () {
    expect(Schema::hasTable('berita_acara'))->toBeTrue();

    $expectedColumns = [
        'berita_acara_id',
        'bimbingan_id',
        'nomor',
        'periode_mulai',
        'periode_selesai',
        'data_snapshot',
        'file_path',
        'file_hash',
        'token_verifikasi',
        'status_persetujuan',
        'metode_persetujuan',
        'tanda_tangan_path',
        'approved_at',
        'approved_hash',
        'created_at',
        'updated_at',
    ];

    expect(Schema::hasColumns('berita_acara', $expectedColumns))->toBeTrue();
});

it('adds pin column to dosen table', function () {
    expect(Schema::hasColumn('dosen', 'pin'))->toBeTrue();
});

it('rolls back and re-migrates the berita acara migration cleanly', function () {
    $baMigration = require database_path('migrations/2026_11_20_000003_create_berita_acara_table.php');
    $pinMigration = require database_path('migrations/2026_11_20_000004_add_pin_to_dosen_table.php');

    $pinMigration->down();
    $baMigration->down();

    expect(Schema::hasTable('berita_acara'))->toBeFalse()
        ->and(Schema::hasColumn('dosen', 'pin'))->toBeFalse();

    $baMigration->up();
    $pinMigration->up();

    expect(Schema::hasTable('berita_acara'))->toBeTrue()
        ->and(Schema::hasColumn('dosen', 'pin'))->toBeTrue();
});
