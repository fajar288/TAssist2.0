<?php

namespace Tests\Feature\Rekomendasi;

use App\Models\Bimbingan;
use App\Models\Dosen;
use App\Models\Mahasiswa;
use App\Models\PermohonanBimbingan;
use App\Services\SupervisorRecommendationService;

it('achieves >= 70% Precision@3 and strong MRR across 18 judged evaluation topics (T-81, PRD S16.7)', function () {
    // 5 realistic supervisor profiles matching DosenSeeder + completed supervisions
    $budi = Dosen::factory()->create([
        'nid'             => 'EVAL001',
        'bidang_keahlian' => 'Kecerdasan Buatan dan Machine Learning',
        'kuota_bimbingan' => 5,
        'profil_singkat'  => 'Dosen berpengalaman di bidang AI, klasifikasi teks, NLP, dan machine learning.',
    ]);

    $sari = Dosen::factory()->create([
        'nid'             => 'EVAL002',
        'bidang_keahlian' => 'Rekayasa Perangkat Lunak',
        'kuota_bimbingan' => 5,
        'profil_singkat'  => 'Ahli rekayasa perangkat lunak, pengujian otomatis, arsitektur microservices, dan metodologi Agile.',
    ]);

    $ahmad = Dosen::factory()->create([
        'nid'             => 'EVAL003',
        'bidang_keahlian' => 'Jaringan Komputer dan Keamanan Siber',
        'kuota_bimbingan' => 5,
        'profil_singkat'  => 'Profesor dengan keahlian keamanan jaringan, kriptografi, firewall, dan deteksi intrusi.',
    ]);

    $rina = Dosen::factory()->create([
        'nid'             => 'EVAL004',
        'bidang_keahlian' => 'Sistem Informasi dan Basis Data',
        'kuota_bimbingan' => 5,
        'profil_singkat'  => 'Spesialis sistem informasi enterprise, optimasi query basis data, ERP, dan data warehouse.',
    ]);

    $hendra = Dosen::factory()->create([
        'nid'             => 'EVAL005',
        'bidang_keahlian' => 'Computer Vision dan Pengolahan Citra',
        'kuota_bimbingan' => 5,
        'profil_singkat'  => 'Peneliti aktif di bidang computer vision, deteksi objek citra medis, dan segmentasi gambar.',
    ]);

    // Seed 1 completed supervision per professor to verify corpus enrichment
    $seedCompleted = function (Dosen $dosen, string $topik) {
        $mhs = Mahasiswa::factory()->create(['judul_ta' => $topik]);
        $perm = PermohonanBimbingan::factory()->forMahasiswa($mhs)->forDosen($dosen)->diterima()->create([
            'topik_ta' => $topik,
        ]);
        Bimbingan::factory()->selesai()->create([
            'permohonan_id' => $perm->permohonan_id,
            'mahasiswa_id'  => $mhs->mahasiswa_id,
            'dosen_id'      => $dosen->dosen_id,
        ]);
    };

    $seedCompleted($budi, 'Analisis Sentimen Ulasan Pengguna Menggunakan Naive Bayes dan Support Vector Machine');
    $seedCompleted($sari, 'Otomasi Pengujian Perangkat Lunak Web Menggunakan CI/CD Pipeline');
    $seedCompleted($ahmad, 'Deteksi Serangan DDoS pada Jaringan Kampus Menggunakan Intrusion Detection System');
    $seedCompleted($rina, 'Perancangan Data Warehouse Akademik untuk Pelaporan Eksekutif');
    $seedCompleted($hendra, 'Deteksi Penyakit Retina Mata pada Citra Fundus Menggunakan Segmentasi');

    // 18 judged sample topics -> expected relevant supervisor ID(s)
    $judgedTopics = [
        ['topic' => 'Klasifikasi sentimen komentar media sosial dengan machine learning', 'expected' => [$budi->dosen_id]],
        ['topic' => 'Prediksi kelulusan mahasiswa menggunakan algoritma pembelajaran mesin', 'expected' => [$budi->dosen_id]],
        ['topic' => 'Pembangunan chatbot pemrosesan bahasa alami NLP akademik', 'expected' => [$budi->dosen_id]],
        ['topic' => 'Implementasi kecerdasan buatan untuk rekomendasi mata kuliah', 'expected' => [$budi->dosen_id]],
        ['topic' => 'Penerapan metodologi Agile Scrum pada pengembangan aplikasi web', 'expected' => [$sari->dosen_id]],
        ['topic' => 'Otomasi pengujian unit dan integrasi pada arsitektur microservices', 'expected' => [$sari->dosen_id]],
        ['topic' => 'Desain rekayasa perangkat lunak sistem reservasi kampus berbasis Flutter', 'expected' => [$sari->dosen_id]],
        ['topic' => 'Evaluasi kualitas perangkat lunak menggunakan CI/CD pipeline', 'expected' => [$sari->dosen_id]],
        ['topic' => 'Implementasi kriptografi AES untuk pengamanan komunikasi jaringan', 'expected' => [$ahmad->dosen_id]],
        ['topic' => 'Sistem deteksi intrusi serangan DDoS pada jaringan komputer', 'expected' => [$ahmad->dosen_id]],
        ['topic' => 'Audit keamanan siber dan konfigurasi firewall server kampus', 'expected' => [$ahmad->dosen_id]],
        ['topic' => 'Optimasi query SQL dan indeks basis data sistem informasi akademik', 'expected' => [$rina->dosen_id]],
        ['topic' => 'Perancangan data warehouse dan sistem informasi enterprise ERP', 'expected' => [$rina->dosen_id]],
        ['topic' => 'Pengembangan sistem informasi manajemen inventaris berbasis basis data relasional', 'expected' => [$rina->dosen_id]],
        ['topic' => 'Deteksi objek kendaraan pada video lalu lintas dengan computer vision', 'expected' => [$hendra->dosen_id]],
        ['topic' => 'Segmentasi citra medis retina untuk deteksi penyakit berbasis pengolahan citra', 'expected' => [$hendra->dosen_id]],
        ['topic' => 'Pengenalan wajah mahasiswa menggunakan pengolahan citra digital', 'expected' => [$hendra->dosen_id]],
        ['topic' => 'Klasifikasi kualitas buah kopi menggunakan computer vision dan pengolahan citra', 'expected' => [$hendra->dosen_id]],
    ];

    /** @var SupervisorRecommendationService $service */
    $service = app(SupervisorRecommendationService::class);

    $top3Hits = 0;
    $reciprocalRanks = [];

    foreach ($judgedTopics as $case) {
        $result = $service->recommend($case['topic'], logLowScore: false);
        $rankedIds = collect($result['rekomendasi'])->pluck('dosen_id')->all();
        $top3 = array_slice($rankedIds, 0, 3);

        $hitInTop3 = count(array_intersect($top3, $case['expected'])) > 0;
        if ($hitInTop3) {
            $top3Hits++;
        }

        $rr = 0.0;
        foreach ($rankedIds as $idx => $dosenId) {
            if (in_array($dosenId, $case['expected'], true)) {
                $rr = 1.0 / ($idx + 1);
                break;
            }
        }
        $reciprocalRanks[] = $rr;
    }

    $totalCases = count($judgedTopics);
    $precisionAt3 = $top3Hits / $totalCases;
    $mrr = array_sum($reciprocalRanks) / $totalCases;

    // PRD §2 & §16.7 target: >= 70% top-3 accuracy
    expect($totalCases)->toBeGreaterThanOrEqual(15)
        ->and($precisionAt3)->toBeGreaterThanOrEqual(0.70)
        ->and($mrr)->toBeGreaterThanOrEqual(0.70);
});
