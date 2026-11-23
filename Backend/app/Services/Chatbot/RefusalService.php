<?php

namespace App\Services\Chatbot;

class RefusalService
{
    /**
     * Map of refusal rules covering all 8 F-BOT-02 categories.
     * Each entry contains:
     * - 'category': Identifier
     * - 'patterns': Regex patterns matching out-of-scope requests
     * - 'whitelist': Patterns that indicate procedural inquiry (safe to allow)
     * - 'response': Exact PRD response text
     */
    protected array $rules = [
        'write_content' => [
            'category' => 'write_content',
            'patterns' => [
                '/(?:buatkan|tuliskan|susunkan|ciptakan|generate)\s+(?:abstrak|latar\s+belakang|bab\s+\d+|pendahuluan|kesimpulan|rumusan\s+masalah|tujuan\s+penelitian|skripsi|tugas\s+akhir)/i',
                '/(?:tulis|buat|draft)\s+(?:abstrak|laporan\s+ta|bab\s+\d+)\s+(?:untuk|saya)/i',
            ],
            'whitelist' => [
                '/(?:format|aturan|panduan|cara|syarat|ketentuan|kapan|jadwal|berapa)\b/i',
            ],
            'response' => 'Maaf, saya tidak dapat menulis atau menyusun bagian dari tugas akhir Anda. Penulisan tugas akhir adalah tanggung jawab mahasiswa dengan bimbingan dosen pembimbing.',
        ],
        'rewrite_text' => [
            'category' => 'rewrite_text',
            'patterns' => [
                '/(?:perbaiki|koreksi|edit|parafrase|sempurnakan|tulis\s+ulang)\s+(?:paragraf|kalimat|tulisan|teks|draft|bab\s+\d+)/i',
                '/(?:agar|supaya)\s+lebih\s+(?:akademis|bagus|ilmiah|formal):/i',
                '/(?:parafrasekan|paraphrase|perbaiki\s+ini)/i',
            ],
            'whitelist' => [
                '/(?:format|aturan|panduan|cara|syarat|prosedur)\b/i',
            ],
            'response' => 'Maaf, saya tidak dapat mengedit atau memperbaiki tulisan tugas akhir. Silakan konsultasikan dengan dosen pembimbing Anda untuk masukan penulisan.',
        ],
        'summarize_content' => [
            'category' => 'summarize_content',
            'patterns' => [
                '/(?:rangkum|ringkas|simpulkan|summarize)\s+(?:bab\s+\d+|dokumen|jurnal|skripsi|teks|laporan|literature\s+review)/i',
                '/(?:buatkan|berikan)\s+(?:ringkasan|rangkuman)\s+(?:bab\s+\d+|tugas\s+akhir)/i',
            ],
            'whitelist' => [
                '/(?:format|panduan|jadwal|prosedur)\b/i',
            ],
            'response' => 'Maaf, saya tidak dapat merangkum konten tugas akhir. Saya hanya dapat membantu menjawab pertanyaan tentang prosedur dan informasi TA.',
        ],
        'literature_review' => [
            'category' => 'literature_review',
            'patterns' => [
                '/(?:carikan|cari|temukan|berikan)\s+(?:referensi|jurnal|paper|pustaka|studi\s+terkait)\s+(?:tentang|mengenai|untuk)/i',
                '/(?:rekomendasikan|daftar)\s+(?:jurnal|buku|paper|referensi)\s+(?:terbaru|ilmiah)/i',
            ],
            'whitelist' => [
                '/(?:format|panduan|cara\s+unggah|template)\b/i',
            ],
            'response' => 'Maaf, pencarian literatur dan penyusunan tinjauan pustaka di luar cakupan layanan saya. Silakan gunakan Google Scholar atau database akademik lainnya.',
        ],
        'methodology' => [
            'category' => 'methodology',
            'patterns' => [
                '/(?:jelaskan|pilihkan|tentukan|buatkan)\s+metodologi\s+(?:yang\s+cocok|untuk\s+penelitian\s+saya)/i',
                '/(?:metodologi|metode\s+penelitian)\s+apa\s+yang\s+(?:bagus|cocok|harus\s+saya\s+pakai)/i',
            ],
            'whitelist' => [
                '/(?:format|panduan|ketentuan\s+penulisan|template)\b/i',
            ],
            'response' => 'Maaf, pemilihan dan penjelasan metodologi penelitian adalah bagian dari proses bimbingan dengan dosen pembimbing Anda.',
        ],
        'citations' => [
            'category' => 'citations',
            'patterns' => [
                '/(?:buatkan|susunkan|generate)\s+(?:daftar\s+pustaka|kutipan|sitasi|referensi\s+dalam\s+format)/i',
                '/(?:daftar\s+pustaka|sitasi)\s+dalam\s+format\s+(?:apa|ieee|harvard|chicago|mendeley)/i',
            ],
            'whitelist' => [
                '/(?:format|panduan|aturan|ketentuan\s+kampus)\b/i',
            ],
            'response' => 'Maaf, saya tidak dapat membuat kutipan atau daftar pustaka. Gunakan tools seperti Mendeley atau Zotero untuk manajemen referensi.',
        ],
        'evaluate_grade' => [
            'category' => 'evaluate_grade',
            'patterns' => [
                '/(?:apakah|apakah\s+sudah)\s+(?:bab\s+\d+|skripsi|penelitian|tulisan|laporan)(?:\s+saya)?\s+(?:sudah\s+)?(?:bagus|layak|benar|siap\s+sidang|sempurna)/i',
                '/(?:nilai|evaluasi|kualitas)\s+(?:tugas\s+akhir|bab\s+\d+|skripsi\s+saya)/i',
            ],
            'whitelist' => [
                '/(?:syarat|ketentuan|jadwal|tata\s+cara|prosedur)\b/i',
            ],
            'response' => 'Maaf, evaluasi kualitas tugas akhir hanya dapat dilakukan oleh dosen pembimbing. Silakan ajukan untuk review melalui fitur dokumen di TAssist.',
        ],
        'substitute_judgment' => [
            'category' => 'substitute_judgment',
            'patterns' => [
                '/(?:menurut\s+(?:kamu|anda)|pilihkan|mana\s+yang\s+lebih\s+bagus|topik\s+ta\s+mana\s+yang\s+lebih\s+baik)/i',
                '/(?:sebaiknya|enaknya)\s+(?:saya\s+)?(?:ambil|pilih)\s+topik\s+(?:a\s+atau\s+b|yang\s+mana)/i',
            ],
            'whitelist' => [
                '/(?:daftar\s+bidang|kuota|dosen\s+pembimbing|prosedur)\b/i',
            ],
            'response' => 'Maaf, saya tidak dapat memberikan rekomendasi akademis. Keputusan tentang topik dan arah penelitian sebaiknya didiskusikan dengan dosen pembimbing Anda.',
        ],
    ];

    /**
     * Check if the prompt should be refused under F-BOT-02.
     *
     * @param string $prompt
     * @return array{refused: bool, category: ?string, response: ?string}
     */
    public function checkRefusal(string $prompt): array
    {
        $normalized = trim($prompt);

        foreach ($this->rules as $rule) {
            $matchedPattern = false;
            foreach ($rule['patterns'] as $pattern) {
                if (preg_match($pattern, $normalized)) {
                    $matchedPattern = true;
                    break;
                }
            }

            if ($matchedPattern) {
                // Check if this is an allowed procedural question (e.g. asking about the format guidelines)
                $isWhitelisted = false;
                if (!empty($rule['whitelist'])) {
                    // If prompt explicitly contains procedural words without command words like "buatkan", "tuliskan"
                    $isProceduralInquiry = preg_match('/(?:bagaimana|apa|kapan|apakah\s+ada)\s+(?:format|aturan|panduan|syarat|ketentuan)/i', $normalized);
                    $hasDirectAuthoringCommand = preg_match('/(?:buatkan|tuliskan|perbaiki|rangkum|susunkan|ciptakan|generate)/i', $normalized);

                    if ($isProceduralInquiry && !$hasDirectAuthoringCommand) {
                        $isWhitelisted = true;
                    }
                }

                if (!$isWhitelisted) {
                    return [
                        'refused' => true,
                        'category' => $rule['category'],
                        'response' => $rule['response'],
                    ];
                }
            }
        }

        return [
            'refused' => false,
            'category' => null,
            'response' => null,
        ];
    }
}
