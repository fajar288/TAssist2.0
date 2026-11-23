<?php

namespace Tests\Feature\Chatbot;

use App\Models\Mahasiswa;
use App\Models\User;
use App\Services\Chatbot\Drivers\FakeChatbotDriver;
use App\Services\Chatbot\ChatbotService;

beforeEach(function () {
    app(ChatbotService::class)->setDriver(new FakeChatbotDriver());
});

it('refuses writing thesis content while allowing procedural writing inquiries (F-BOT-02 Category 1)', function () {
    $mahasiswa = Mahasiswa::factory()->create();
    $headers = authHeaders($mahasiswa->user);

    // Out-of-scope: asking bot to write/draft thesis content
    $response = $this->withHeaders($headers)->postJson('/api/v1/chatbot/pesan', [
        'pesan' => 'Buatkan abstrak untuk tugas akhir saya tentang machine learning',
    ]);

    $response->assertStatus(200);
    $response->assertJsonPath('data.pesan_asisten.is_refused', true);
    expect($response->json('data.pesan_asisten.pesan'))->toContain('tidak dapat menulis atau menyusun bagian dari tugas akhir');

    // In-scope: asking procedural format about thesis
    $procedural = $this->withHeaders($headers)->postJson('/api/v1/chatbot/pesan', [
        'pesan' => 'Bagaimana format penulisan abstrak yang benar menurut panduan TA?',
    ]);

    $procedural->assertStatus(200);
    $procedural->assertJsonPath('data.pesan_asisten.is_refused', false);
});

it('refuses rewriting/improving thesis text (F-BOT-02 Category 2)', function () {
    $mahasiswa = Mahasiswa::factory()->create();
    $headers = authHeaders($mahasiswa->user);

    $response = $this->withHeaders($headers)->postJson('/api/v1/chatbot/pesan', [
        'pesan' => 'Perbaiki paragraf ini agar lebih akademis: hasil penelitian ini menunjukkan bahwa model bekerja dengan sangat cepat dan mantap.',
    ]);

    $response->assertStatus(200);
    $response->assertJsonPath('data.pesan_asisten.is_refused', true);
    expect($response->json('data.pesan_asisten.pesan'))->toContain('tidak dapat mengedit atau memperbaiki tulisan');
});

it('refuses summarizing thesis chapters or documents (F-BOT-02 Category 3)', function () {
    $mahasiswa = Mahasiswa::factory()->create();
    $headers = authHeaders($mahasiswa->user);

    $response = $this->withHeaders($headers)->postJson('/api/v1/chatbot/pesan', [
        'pesan' => 'Rangkum bab 2 literature review saya berikut ini',
    ]);

    $response->assertStatus(200);
    $response->assertJsonPath('data.pesan_asisten.is_refused', true);
    expect($response->json('data.pesan_asisten.pesan'))->toContain('tidak dapat merangkum konten tugas akhir');
});

it('refuses generating literature reviews or paper searches (F-BOT-02 Category 4)', function () {
    $mahasiswa = Mahasiswa::factory()->create();
    $headers = authHeaders($mahasiswa->user);

    $response = $this->withHeaders($headers)->postJson('/api/v1/chatbot/pesan', [
        'pesan' => 'Carikan referensi tentang deep learning untuk NLP yang terbit tahun 2026',
    ]);

    $response->assertStatus(200);
    $response->assertJsonPath('data.pesan_asisten.is_refused', true);
    expect($response->json('data.pesan_asisten.pesan'))->toContain('pencarian literatur dan penyusunan tinjauan pustaka di luar cakupan');
});

it('refuses generating or picking research methodology (F-BOT-02 Category 5)', function () {
    $mahasiswa = Mahasiswa::factory()->create();
    $headers = authHeaders($mahasiswa->user);

    $response = $this->withHeaders($headers)->postJson('/api/v1/chatbot/pesan', [
        'pesan' => 'Jelaskan metodologi yang cocok untuk penelitian saya tentang deteksi intrusi',
    ]);

    $response->assertStatus(200);
    $response->assertJsonPath('data.pesan_asisten.is_refused', true);
    expect($response->json('data.pesan_asisten.pesan'))->toContain('pemilihan dan penjelasan metodologi penelitian adalah bagian dari proses bimbingan');
});

it('refuses generating bibliography or citation lists (F-BOT-02 Category 6)', function () {
    $mahasiswa = Mahasiswa::factory()->create();
    $headers = authHeaders($mahasiswa->user);

    $response = $this->withHeaders($headers)->postJson('/api/v1/chatbot/pesan', [
        'pesan' => 'Buatkan daftar pustaka dalam format APA untuk buku Machine Learning karya Mitchell',
    ]);

    $response->assertStatus(200);
    $response->assertJsonPath('data.pesan_asisten.is_refused', true);
    expect($response->json('data.pesan_asisten.pesan'))->toContain('tidak dapat membuat kutipan atau daftar pustaka');
});

it('refuses evaluating or grading student work quality (F-BOT-02 Category 7)', function () {
    $mahasiswa = Mahasiswa::factory()->create();
    $headers = authHeaders($mahasiswa->user);

    $response = $this->withHeaders($headers)->postJson('/api/v1/chatbot/pesan', [
        'pesan' => 'Apakah bab 3 saya sudah bagus dan layak disetujui dosen?',
    ]);

    $response->assertStatus(200);
    $response->assertJsonPath('data.pesan_asisten.is_refused', true);
    expect($response->json('data.pesan_asisten.pesan'))->toContain('evaluasi kualitas tugas akhir hanya dapat dilakukan oleh dosen pembimbing');
});

it('refuses substituting supervisor academic judgment on topic selection (F-BOT-02 Category 8)', function () {
    $mahasiswa = Mahasiswa::factory()->create();
    $headers = authHeaders($mahasiswa->user);

    $response = $this->withHeaders($headers)->postJson('/api/v1/chatbot/pesan', [
        'pesan' => 'Menurut kamu, topik TA mana yang lebih baik: Klasifikasi Penyakit Daun atau Chatbot Kampus?',
    ]);

    $response->assertStatus(200);
    $response->assertJsonPath('data.pesan_asisten.is_refused', true);
    expect($response->json('data.pesan_asisten.pesan'))->toContain('tidak dapat memberikan rekomendasi akademis');
});
