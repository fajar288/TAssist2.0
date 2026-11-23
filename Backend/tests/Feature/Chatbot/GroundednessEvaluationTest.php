<?php

namespace Tests\Feature\Chatbot;

use App\Models\BasisPengetahuanTA;
use App\Models\Bimbingan;
use App\Models\Dosen;
use App\Models\InformasiTA;
use App\Models\Mahasiswa;
use App\Models\ProgresTA;
use App\Services\Chatbot\Drivers\FakeChatbotDriver;
use App\Services\Chatbot\ChatbotService;

beforeEach(function () {
    app(ChatbotService::class)->setDriver(new FakeChatbotDriver());
});

it('passes groundedness evaluation with >= 90% citations across 50 in-scope queries (T-73, PRD S16.6)', function () {
    $dosen = Dosen::factory()->create();
    $mahasiswa = Mahasiswa::factory()->create();
    $admin = \App\Models\Admin::factory()->create();
    $user = $mahasiswa->user;

    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create([
        'status_bimbingan' => 'aktif',
    ]);
    ProgresTA::factory()->create([
        'bimbingan_id' => $bimbingan->bimbingan_id,
        'persentase'   => 45,
        'catatan'      => 'Revisi bab 3 sedang berlangsung',
    ]);

    // Seed Knowledge Base and Announcements
    InformasiTA::create([
        'admin_id' => $admin->admin_id,
        'kategori' => 'akademik',
        'judul' => 'Jadwal Batas Akhir Pengumpulan Laporan TA Semester Genap 2026',
        'konten_or_file' => 'Batas akhir pengumpulan laporan akhir tugas akhir adalah 30 Juni 2026 pukul 23:59 WIB.',
        'published_at' => now()->subDay(),
    ]);

    InformasiTA::create([
        'admin_id' => $admin->admin_id,
        'kategori' => 'akademik',
        'judul' => 'Jadwal Sidang Skripsi Periode Juli 2026',
        'konten_or_file' => 'Pendaftaran sidang skripsi dibuka mulai 1 Juli sampai 7 Juli 2026 melalui portal akademik.',
        'published_at' => now()->subDay(),
    ]);

    InformasiTA::create([
        'admin_id' => $admin->admin_id,
        'kategori' => 'akademik',
        'judul' => 'Sosialisasi Tata Cara Seminar Proposal TA',
        'konten_or_file' => 'Seminar proposal wajib dihadiri oleh minimal 5 mahasiswa sebagai audiens dan dosen pembimbing.',
        'published_at' => now()->subDay(),
    ]);

    BasisPengetahuanTA::create([
        'kategori' => 'format',
        'judul' => 'Panduan Format Penulisan Judul dan Huruf Sampul TA',
        'konten' => 'Sampul dokumen tugas akhir wajib menggunakan huruf Times New Roman 14pt tebal dengan margin kiri 4cm, kanan 3cm, atas 4cm, bawah 3cm.',
        'tags' => ['format', 'sampul', 'margin', 'font'],
    ]);

    BasisPengetahuanTA::create([
        'kategori' => 'format',
        'judul' => 'Ketentuan Format Spasi dan Penomoran Halaman',
        'konten' => 'Penulisan naskah menggunakan spasi 1.5. Halaman awal menggunakan angka romawi kecil, bagian isi menggunakan angka arab di pojok kanan atas.',
        'tags' => ['spasi', 'penomoran', 'halaman', 'romawi'],
    ]);

    BasisPengetahuanTA::create([
        'kategori' => 'prosedur',
        'judul' => 'Syarat dan Prosedur Pendaftaran Sidang Tugas Akhir',
        'konten' => 'Syarat pendaftaran sidang: telah menyelesaikan minimal 8 kali bimbingan, naskah disetujui dosen pembimbing, dan bebas tanggungan perpustakaan.',
        'tags' => ['sidang', 'syarat', 'bimbingan', 'perpustakaan'],
    ]);

    BasisPengetahuanTA::create([
        'kategori' => 'prosedur',
        'judul' => 'Tata Cara Pengajuan Permohonan Dosen Pembimbing',
        'konten' => 'Mahasiswa mengajukan permohonan dengan memilih dosen yang memiliki kuota tersedia dan mengunggah draf usulan topik.',
        'tags' => ['permohonan', 'kuota', 'pembimbing', 'topik'],
    ]);

    BasisPengetahuanTA::create([
        'kategori' => 'prosedur',
        'judul' => 'Ketentuan Jumlah Bimbingan Minimal Sebelum Ujian',
        'konten' => 'Mahasiswa wajib melaksanakan minimal 8 kali sesi bimbingan tatap muka atau daring yang tercatat resmi di sistem TAssist.',
        'tags' => ['jumlah', 'minimal', 'sesi', 'bimbingan'],
    ]);

    BasisPengetahuanTA::create([
        'kategori' => 'faq',
        'judul' => 'Prosedur Perpanjangan Periode Tugas Akhir',
        'konten' => 'Jika belum selesai dalam 1 semester, perpanjangan dapat diajukan dengan rekomendasi dosen pembimbing ke koordinator TA.',
        'tags' => ['perpanjangan', 'semester', 'koordinator'],
    ]);

    BasisPengetahuanTA::create([
        'kategori' => 'faq',
        'judul' => 'Ketentuan Uji Bebas Plagiasi Turnitin',
        'konten' => 'Batas maksimal similarity index Turnitin adalah 20 persen tanpa menyertakan daftar pustaka.',
        'tags' => ['turnitin', 'plagiasi', 'similarity'],
    ]);

    // 50 realistic in-scope questions
    $evaluationQuestions = [
        'Kapan batas akhir pengumpulan laporan TA?',
        'Kapan jadwal sidang skripsi dibuka?',
        'Berapa persen progres saya sekarang?',
        'Bagaimana status bimbingan saya saat ini?',
        'Siapa dosen pembimbing saya?',
        'Berapa batas margin untuk penulisan sampul TA?',
        'Jenis huruf apa yang digunakan untuk sampul laporan?',
        'Berapa spasi yang harus digunakan dalam penulisan naskah TA?',
        'Bagaimana aturan penomoran halaman untuk bab isi?',
        'Berapa kali bimbingan minimal sebelum daftar sidang?',
        'Apa saja syarat pendaftaran sidang tugas akhir?',
        'Apakah harus bebas tanggungan perpustakaan untuk sidang?',
        'Bagaimana cara mengajukan permohonan pembimbing?',
        'Apakah ada syarat kuota dosen pembimbing?',
        'Berapa batas maksimal similarity Turnitin?',
        'Bagaimana prosedur jika ingin perpanjangan periode TA?',
        'Apakah perlu rekomendasi dosen untuk perpanjangan semester TA?',
        'Berapa audiens mahasiswa minimal untuk seminar proposal?',
        'Apakah seminar proposal wajib dihadiri dosen pembimbing?',
        'Kapan pendaftaran sidang periode Juli ditutup?',
        'Bagaimana format halaman awal tugas akhir?',
        'Di mana letak penomoran angka romawi kecil?',
        'Apakah penulisan judul sampul menggunakan Times New Roman?',
        'Berapa ukuran font judul sampul naskah?',
        'Berapa margin kiri penulisan tugas akhir?',
        'Berapa margin atas dan bawah penulisan naskah?',
        'Apakah laporan akhir dikumpulkan sebelum 30 Juni?',
        'Jam berapa batas akhir pengumpulan laporan di portal?',
        'Kapan pendaftaran sidang skripsi mulai dibuka?',
        'Apakah sidang skripsi dibuka pada bulan Juli?',
        'Bagaimana catatan progres tugas akhir saya?',
        'Berapa persen progres tugas akhir saya yang tercatat?',
        'Apakah progres bimbingan saya sudah mencapai 40 persen?',
        'Apakah saya memiliki dosen pembimbing aktif?',
        'Apa saja ketentuan bimbingan di TAssist?',
        'Bagaimana cara mendaftar sidang di portal akademik?',
        'Apakah ada uji plagiasi sebelum mengumpulkan draft?',
        'Apakah daftar pustaka diikutsertakan dalam cek similarity Turnitin?',
        'Berapa persen ambang batas toleransi plagiasi?',
        'Kepada siapa perpanjangan tugas akhir diajukan?',
        'Berapa kali sesi bimbingan yang harus tercatat di sistem?',
        'Apakah bimbingan daring dihitung dalam jumlah minimal?',
        'Apa syarat naskah sebelum mendaftar ujian sidang?',
        'Bagaimana cara memilih dosen pembimbing yang kuotanya masih ada?',
        'Apakah draf usulan topik harus diunggah saat mengajukan?',
        'Kapan sosialisasi tata cara seminar proposal diadakan?',
        'Apakah audiens seminar proposal harus minimal 5 orang?',
        'Bagaimana aturan spasi 1.5 pada naskah?',
        'Bagaimana format penomoran di pojok kanan atas?',
        'Berapa batas akhir submit laporan genap 2026?',
    ];

    expect(count($evaluationQuestions))->toBe(50);

    $citedCount = 0;

    $headers = authHeaders($user);

    foreach ($evaluationQuestions as $question) {
        $response = $this->withHeaders($headers)->postJson('/api/v1/chatbot/pesan', [
            'pesan' => $question,
        ]);

        $response->assertStatus(200);
        $assistantMsg = $response->json('data.pesan_asisten');

        if (!empty($assistantMsg['sumber']) && is_array($assistantMsg['sumber']) && count($assistantMsg['sumber']) > 0) {
            $citedCount++;
        }
    }

    $citationRate = ($citedCount / count($evaluationQuestions)) * 100;
    // PRD S16.6 Pass criterion: >= 90% of answers carry a correct citation
    expect($citationRate)->toBeGreaterThanOrEqual(90.0);
});
