<?php
// tests/Feature/InformasiTA/MahasiswaInformasiTATest.php

use App\Models\Admin;
use App\Models\InformasiTA;
use App\Models\Mahasiswa;

it('allows mahasiswa to view published TA announcements (published_at <= now)', function () {
    $admin = Admin::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();

    // Published announcement
    InformasiTA::create([
        'admin_id'       => $admin->admin_id,
        'kategori'       => 'Pengumuman',
        'judul'          => 'Jadwal Pendaftaran Sidang TA Semester Ganjil',
        'konten_or_file' => 'Pendaftaran dibuka tanggal 1 sampai 15 Desember.',
        'published_at'   => now()->subDay(),
    ]);

    // Unpublished future announcement
    InformasiTA::create([
        'admin_id'       => $admin->admin_id,
        'kategori'       => 'Pengumuman',
        'judul'          => 'Jadwal Masa Depan',
        'konten_or_file' => 'Belum boleh dilihat.',
        'published_at'   => now()->addDays(5),
    ]);

    // Draft / null published_at announcement
    InformasiTA::create([
        'admin_id'       => $admin->admin_id,
        'kategori'       => 'Draft',
        'judul'          => 'Draft Informasi',
        'konten_or_file' => 'Draft saja.',
        'published_at'   => null,
    ]);

    $response = $this->withHeaders(authHeaders($mahasiswa->user))
        ->getJson('/api/v1/mahasiswa/informasi-ta');

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonCount(1, 'data.data')
        ->assertJsonPath('data.data.0.judul', 'Jadwal Pendaftaran Sidang TA Semester Ganjil');
});

it('allows mahasiswa to view detail of a published TA announcement', function () {
    $admin = Admin::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();

    $info = InformasiTA::create([
        'admin_id'       => $admin->admin_id,
        'kategori'       => 'Panduan',
        'judul'          => 'Panduan Format Penulisan Laporan TA 2026',
        'konten_or_file' => 'Gunakan template LaTeX atau Word resmi.',
        'published_at'   => now()->subHours(2),
    ]);

    $response = $this->withHeaders(authHeaders($mahasiswa->user))
        ->getJson("/api/v1/mahasiswa/informasi-ta/{$info->info_id}");

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonPath('data.judul', 'Panduan Format Penulisan Laporan TA 2026');
});
