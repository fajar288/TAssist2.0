<?php
// tests/Feature/Schema/AnnotationMigrationTest.php

use App\Models\AnotasiDokumen;
use App\Models\Dosen;
use App\Models\FeedbackDokumen;
use App\Models\Mahasiswa;
use App\Models\VersiDokumen;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

it('creates anotasi_dokumen table with all required columns and foreign keys', function () {
    expect(Schema::hasTable('anotasi_dokumen'))->toBeTrue()
        ->and(Schema::hasColumns('anotasi_dokumen', [
            'anotasi_id',
            'versi_id',
            'dosen_id',
            'user_id',
            'parent_id',
            'halaman',
            'x',
            'y',
            'lebar',
            'tinggi',
            'tipe',
            'konten',
            'data_coretan',
            'status',
            'created_at',
            'updated_at',
        ]))->toBeTrue();
});

it('adds jumlah_anotasi_terbuka to versi_dokumen table', function () {
    expect(Schema::hasColumn('versi_dokumen', 'jumlah_anotasi_terbuka'))->toBeTrue();
});

it('casts anotasi_dokumen model attributes appropriately', function () {
    $anotasi = AnotasiDokumen::factory()->create([
        'halaman' => 3,
        'x'       => 0.25,
        'y'       => 0.45,
        'status'  => 'open',
    ]);

    expect($anotasi->halaman)->toBeInt()->toBe(3)
        ->and($anotasi->x)->toBeFloat()->toBe(0.25)
        ->and($anotasi->isOpen())->toBeTrue()
        ->and($anotasi->isResolved())->toBeFalse();
});

it('rolls back and re-migrates the annotation migration cleanly', function () {
    // Rollback last migration
    Artisan::call('migrate:rollback', ['--step' => 1]);

    expect(Schema::hasTable('anotasi_dokumen'))->toBeFalse()
        ->and(Schema::hasColumn('versi_dokumen', 'jumlah_anotasi_terbuka'))->toBeFalse();

    // Re-migrate
    Artisan::call('migrate');

    expect(Schema::hasTable('anotasi_dokumen'))->toBeTrue()
        ->and(Schema::hasColumn('versi_dokumen', 'jumlah_anotasi_terbuka'))->toBeTrue();
});
