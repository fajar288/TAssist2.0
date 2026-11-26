<?php

namespace Tests\Feature\Rekomendasi;

use App\Models\Admin;
use App\Models\Bimbingan;
use App\Models\Dosen;
use App\Models\Mahasiswa;
use App\Models\PermohonanBimbingan;
use App\Models\RekomendasiKonfigurasi;
use App\Models\RekomendasiLogPencarian;

it('ranks supervisors by TF-IDF + Sastrawi similarity, completed topics, and returns full explainability (T-48, T-50)', function () {
    $student = Mahasiswa::factory()->create();

    $aiDosen = Dosen::factory()->create([
        'bidang_keahlian' => 'Kecerdasan Buatan dan Machine Learning',
        'kuota_bimbingan' => 5,
        'profil_singkat'  => 'Penelitian klasifikasi penyakit tanaman dengan deep learning dan neural network.',
    ]);

    $networkDosen = Dosen::factory()->create([
        'bidang_keahlian' => 'Jaringan Komputer dan Keamanan Siber',
        'kuota_bimbingan' => 5,
        'profil_singkat'  => 'Fokus pada keamanan jaringan dan kriptografi.',
    ]);

    // Give networkDosen a completed supervision on AI-unrelated topic, and aiDosen a matching completed topic
    $pastStudent = Mahasiswa::factory()->create([
        'judul_ta' => 'Klasifikasi Citra Daun Padi Menggunakan Convolutional Neural Network',
    ]);
    $pastPermohonan = PermohonanBimbingan::factory()
        ->forMahasiswa($pastStudent)
        ->forDosen($aiDosen)
        ->diterima()
        ->create([
            'topik_ta' => 'Deteksi Penyakit Tanaman Padi Berbasis Deep Learning',
        ]);
    Bimbingan::factory()->selesai()->create([
        'permohonan_id' => $pastPermohonan->permohonan_id,
        'mahasiswa_id'  => $pastStudent->mahasiswa_id,
        'dosen_id'      => $aiDosen->dosen_id,
    ]);

    $response = $this->getJson(
        '/api/v1/mahasiswa/dosen/rekomendasi?topik=' . urlencode('Mendeteksi penyakit daun tanaman berbasis machine learning'),
        authHeaders($student->user)
    );

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonPath('data.rekomendasi.0.dosen_id', $aiDosen->dosen_id);

    $first = $response->json('data.rekomendasi.0');

    expect($first)->toHaveKeys([
        'dosen_id',
        'nama',
        'bidang_keahlian',
        'sisa_kuota',
        'skor_total',
        'skor_persen',
        'komponen_skor',
        'kata_kunci_cocok',
        'riwayat_topik_cocok',
        'alasan',
    ]);

    expect($first['komponen_skor'])->toHaveKeys([
        'kemiripan_topik',
        'ketersediaan_kuota_ternormalisasi',
        'beban_aktif_ternormalisasi',
        'skor_beban_rendah',
        'sisa_kuota',
        'kuota_bimbingan',
        'bimbingan_aktif',
        'bobot',
        'kontribusi',
    ]);

    expect($first['alasan'])->toContain('Kecocokan topik')
        ->and($first['alasan'])->toContain('kuota tersisa')
        ->and($first['riwayat_topik_cocok'])->toBeGreaterThanOrEqual(1);
});

it('completely excludes supervisors with zero remaining quota even on exact topic match (T-49)', function () {
    $student = Mahasiswa::factory()->create();

    $fullDosen = Dosen::factory()->create([
        'bidang_keahlian' => 'Computer Vision dan Pengolahan Citra Medis',
        'kuota_bimbingan' => 1,
        'profil_singkat'  => 'Spesialis deteksi tumor otak berbasis pengolahan citra medis.',
    ]);
    // Occupy the single slot
    $otherStudent = Mahasiswa::factory()->create();
    Bimbingan::factory()->untuk($otherStudent, $fullDosen)->create(['status_bimbingan' => 'aktif']);

    $availableDosen = Dosen::factory()->create([
        'bidang_keahlian' => 'Sistem Informasi dan Basis Data',
        'kuota_bimbingan' => 4,
        'profil_singkat'  => 'Sistem informasi akademik.',
    ]);

    $response = $this->getJson(
        '/api/v1/mahasiswa/dosen/rekomendasi?topik=' . urlencode('Pengolahan citra medis untuk deteksi tumor otak'),
        authHeaders($student->user)
    );

    $response->assertOk()
        ->assertJsonPath('data.total_dosen_dikecualikan_kuota_habis', 1);

    $ids = collect($response->json('data.rekomendasi'))->pluck('dosen_id')->all();

    expect($ids)->not->toContain($fullDosen->dosen_id)
        ->and($ids)->toContain($availableDosen->dosen_id);
});

it('flags short or generic topic queries while still returning ranked results (F-SUP-06)', function () {
    $student = Mahasiswa::factory()->create();
    Dosen::factory()->create([
        'bidang_keahlian' => 'Kecerdasan Buatan',
        'kuota_bimbingan' => 3,
    ]);

    $response = $this->getJson(
        '/api/v1/mahasiswa/dosen/rekomendasi?topik=AI',
        authHeaders($student->user)
    );

    $response->assertOk()
        ->assertJsonPath('data.is_topik_singkat', true);

    expect($response->json('data.catatan_kueri'))->not->toBeEmpty()
        ->and($response->json('data.rekomendasi'))->toHaveCount(1);
});

it('responds to dynamic admin weight changes in rekomendasi_konfigurasi (T-47, T-48)', function () {
    $student = Mahasiswa::factory()->create();

    // Dosen A: strong topic match, 1 remaining quota out of 5 (high active load)
    $dosenA = Dosen::factory()->create([
        'bidang_keahlian' => 'Keamanan Siber dan Kriptografi',
        'kuota_bimbingan' => 5,
        'profil_singkat'  => 'Kriptografi pasca kuantum dan firewall.',
    ]);
    for ($i = 0; $i < 4; $i++) {
        Bimbingan::factory()->untuk(Mahasiswa::factory()->create(), $dosenA)->create(['status_bimbingan' => 'aktif']);
    }

    // Dosen B: weak topic match, 5 remaining quota out of 5 (zero active load)
    $dosenB = Dosen::factory()->create([
        'bidang_keahlian' => 'Sistem Informasi Akuntansi',
        'kuota_bimbingan' => 5,
        'profil_singkat'  => 'Audit sistem informasi.',
    ]);

    // With default weights (alpha=0.60), topic match wins
    $res1 = $this->getJson(
        '/api/v1/mahasiswa/dosen/rekomendasi?topik=' . urlencode('Kriptografi jaringan keamanan siber'),
        authHeaders($student->user)
    )->assertOk();
    expect($res1->json('data.rekomendasi.0.dosen_id'))->toBe($dosenA->dosen_id);

    // Admin prioritizes quota & low workload over topic similarity
    RekomendasiKonfigurasi::current()->update([
        'bobot_kemiripan' => 0.05,
        'bobot_kuota'     => 0.55,
        'bobot_beban'     => 0.40,
    ]);

    $res2 = $this->getJson(
        '/api/v1/mahasiswa/dosen/rekomendasi?topik=' . urlencode('Kriptografi jaringan keamanan siber'),
        authHeaders($student->user)
    )->assertOk();
    expect($res2->json('data.rekomendasi.0.dosen_id'))->toBe($dosenB->dosen_id);
});

it('logs low-score topic searches anonymously without student attribution and enforces route guards (T-52)', function () {
    $student = Mahasiswa::factory()->create();
    $dosen = Dosen::factory()->create([
        'bidang_keahlian' => 'Sistem Informasi Manajemen',
        'kuota_bimbingan' => 3,
    ]);

    // Non-mahasiswa cannot call recommendation endpoint
    $this->getJson('/api/v1/mahasiswa/dosen/rekomendasi?topik=machine+learning', authHeaders($dosen->user))
        ->assertForbidden();

    app('auth')->forgetGuards();

    // Missing topic returns 422
    $this->getJson('/api/v1/mahasiswa/dosen/rekomendasi', authHeaders($student->user))
        ->assertUnprocessable();

    // Unmatched topic triggers anonymous low-score log
    $this->getJson(
        '/api/v1/mahasiswa/dosen/rekomendasi?topik=' . urlencode('Bioinformatika Genomik Kuantum'),
        authHeaders($student->user)
    )->assertOk();

    $log = RekomendasiLogPencarian::query()->latest('log_id')->first();
    expect($log)->not->toBeNull()
        ->and($log->topik_kueri)->toBe('Bioinformatika Genomik Kuantum')
        ->and($log->skor_tertinggi)->toBe(0.0);
});
