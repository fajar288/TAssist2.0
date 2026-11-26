<?php

namespace App\Services;

use App\Models\Dosen;
use App\Models\RekomendasiKonfigurasi;
use App\Models\RekomendasiLogPencarian;
use App\Services\Chatbot\StemmerService;
use Illuminate\Support\Facades\Storage;

/**
 * Topic-based supervisor recommendation engine (Wave 6: T-47..T-50, T-52; PRD F-SUP-06).
 *
 * Uses TF-IDF + cosine similarity tokenized via the shared Sastrawi StemmerService (T-28),
 * excludes supervisors with zero remaining quota (T-49), and returns full score
 * explainability per candidate (T-50).
 */
class SupervisorRecommendationService
{
    public function __construct(
        protected StemmerService $stemmer
    ) {}

    /**
     * Rank eligible supervisors for a proposed TA topic.
     *
     * @param string $topic
     * @param bool $logLowScore Whether to anonymously log low-score searches (T-52)
     * @param int|null $limit Optional max results to return
     * @return array<string, mixed>
     */
    public function recommend(string $topic, bool $logLowScore = true, ?int $limit = null): array
    {
        $cleanTopic = trim($topic);
        $config = RekomendasiKonfigurasi::current();
        $weights = $config->normalizedWeights();

        $queryTerms = $this->stemmer->tokenizeTerms($cleanTopic);
        $uniqueQueryTerms = array_values(array_unique($queryTerms));
        $isTopikSingkat = mb_strlen($cleanTopic) < 10 || count($uniqueQueryTerms) < 2;

        $activeDosen = Dosen::query()
            ->with([
                'user',
                'bimbinganAktif',
                'bimbinganSelesai.permohonan',
                'bimbinganSelesai.mahasiswa',
            ])
            ->whereHas('user', fn ($q) => $q->where('status_akun', 'aktif'))
            ->get();

        $allDocs = [];
        $eligibleDocs = [];

        foreach ($activeDosen as $dosen) {
            $completedTopics = $this->extractCompletedTopics($dosen);
            $bidang = trim((string) ($dosen->bidang_keahlian ?? ''));
            $profil = trim((string) ($dosen->profil_singkat ?? ''));

            // Repeat bidang_keahlian twice so core expertise carries natural priority in TF-IDF.
            $corpusText = trim($bidang . ' ' . $bidang . ' ' . $profil . ' ' . implode(' ', $completedTopics));
            $docTerms = $this->stemmer->tokenizeTerms($corpusText);
            $termCounts = array_count_values($docTerms);

            $bimbinganAktifCount = $dosen->bimbinganAktif->count();
            $kuotaBimbingan = max(0, (int) $dosen->kuota_bimbingan);
            $sisaKuota = max(0, $kuotaBimbingan - $bimbinganAktifCount);

            $docRecord = [
                'dosen'            => $dosen,
                'term_counts'      => $termCounts,
                'completed_topics' => $completedTopics,
                'bimbingan_aktif'  => $bimbinganAktifCount,
                'kuota_bimbingan'  => $kuotaBimbingan,
                'sisa_kuota'       => $sisaKuota,
            ];

            $allDocs[] = $docRecord;

            // T-49: Exclude supervisors with sisaKuota() == 0 before ranking.
            if ($sisaKuota > 0) {
                $eligibleDocs[] = $docRecord;
            }
        }

        // Compute smoothed IDF across all active supervisors.
        $totalDocs = count($allDocs);
        $documentFrequency = [];
        foreach ($allDocs as $doc) {
            foreach (array_keys($doc['term_counts']) as $term) {
                $documentFrequency[$term] = ($documentFrequency[$term] ?? 0) + 1;
            }
        }

        $idf = function (string $term) use ($totalDocs, $documentFrequency): float {
            $df = $documentFrequency[$term] ?? 0;
            return log(($totalDocs + 1) / ($df + 1)) + 1.0;
        };

        $queryTermCounts = array_count_values($queryTerms);
        $queryVector = $this->buildTfIdfVector($queryTermCounts, $idf);
        $queryNorm = $this->vectorNorm($queryVector);

        $maxSisaKuota = 1;
        foreach ($eligibleDocs as $doc) {
            if ($doc['sisa_kuota'] > $maxSisaKuota) {
                $maxSisaKuota = $doc['sisa_kuota'];
            }
        }

        $ranked = [];

        foreach ($eligibleDocs as $doc) {
            $dosen = $doc['dosen'];
            $docVector = $this->buildTfIdfVector($doc['term_counts'], $idf);
            $docNorm = $this->vectorNorm($docVector);

            $kemiripanTopik = $this->cosineSimilarity($queryVector, $queryNorm, $docVector, $docNorm);

            $ketersediaanKuota = min(1.0, max(0.0, $doc['sisa_kuota'] / $maxSisaKuota));
            $bebanAktif = $doc['kuota_bimbingan'] > 0
                ? min(1.0, max(0.0, $doc['bimbingan_aktif'] / $doc['kuota_bimbingan']))
                : 1.0;
            $skorBebanRendah = max(0.0, 1.0 - $bebanAktif);

            $kontribusiKemiripan = $weights['alpha'] * $kemiripanTopik;
            $kontribusiKuota = $weights['beta'] * $ketersediaanKuota;
            $kontribusiBeban = $weights['gamma'] * $skorBebanRendah;

            $skorTotal = min(1.0, max(0.0, $kontribusiKemiripan + $kontribusiKuota + $kontribusiBeban));

            $matchedKeywords = array_values(array_intersect($uniqueQueryTerms, array_keys($doc['term_counts'])));
            $matchedHistoryCount = $this->countMatchingCompletedTopics($uniqueQueryTerms, $doc['completed_topics']);

            $alasan = $this->buildExplanation(
                kemiripanTopik: $kemiripanTopik,
                matchedKeywords: $matchedKeywords,
                sisaKuota: $doc['sisa_kuota'],
                kuotaBimbingan: $doc['kuota_bimbingan'],
                bimbinganAktif: $doc['bimbingan_aktif'],
                bebanAktif: $bebanAktif,
                matchedHistoryCount: $matchedHistoryCount,
            );

            $ranked[] = [
                'dosen_id'        => $dosen->dosen_id,
                'nama'            => $dosen->user->nama ?? '-',
                'email'           => $dosen->user->email ?? null,
                'avatar'          => $dosen->user?->avatar ? Storage::url($dosen->user->avatar) : null,
                'nid'             => $dosen->nid,
                'bidang_keahlian' => $dosen->bidang_keahlian,
                'kuota_bimbingan' => $doc['kuota_bimbingan'],
                'sisa_kuota'      => $doc['sisa_kuota'],
                'bimbingan_aktif' => $doc['bimbingan_aktif'],
                'profil_singkat'  => $dosen->profil_singkat,
                'skor_total'      => round($skorTotal, 4),
                'skor_persen'     => round($skorTotal * 100, 1),
                'kata_kunci_cocok'    => $matchedKeywords,
                'riwayat_topik_cocok' => $matchedHistoryCount,
                'komponen_skor'   => [
                    'kemiripan_topik'                  => round($kemiripanTopik, 4),
                    'ketersediaan_kuota_ternormalisasi' => round($ketersediaanKuota, 4),
                    'beban_aktif_ternormalisasi'       => round($bebanAktif, 4),
                    'skor_beban_rendah'                => round($skorBebanRendah, 4),
                    'sisa_kuota'                       => $doc['sisa_kuota'],
                    'kuota_bimbingan'                  => $doc['kuota_bimbingan'],
                    'bimbingan_aktif'                  => $doc['bimbingan_aktif'],
                    'bobot'                            => $weights,
                    'kontribusi'                       => [
                        'kemiripan' => round($kontribusiKemiripan, 4),
                        'kuota'     => round($kontribusiKuota, 4),
                        'beban'     => round($kontribusiBeban, 4),
                    ],
                ],
                'alasan' => $alasan,
            ];
        }

        usort($ranked, function (array $a, array $b) {
            $cmpScore = $b['skor_total'] <=> $a['skor_total'];
            if ($cmpScore !== 0) {
                return $cmpScore;
            }

            $cmpSim = $b['komponen_skor']['kemiripan_topik'] <=> $a['komponen_skor']['kemiripan_topik'];
            if ($cmpSim !== 0) {
                return $cmpSim;
            }

            $cmpQuota = $b['sisa_kuota'] <=> $a['sisa_kuota'];
            if ($cmpQuota !== 0) {
                return $cmpQuota;
            }

            return strcmp((string) $a['nama'], (string) $b['nama']);
        });

        $maxSimilarity = 0.0;
        foreach ($ranked as $item) {
            $sim = (float) ($item['komponen_skor']['kemiripan_topik'] ?? 0.0);
            if ($sim > $maxSimilarity) {
                $maxSimilarity = $sim;
            }
        }

        // T-52: Anonymized low-score search log (no user_id / mahasiswa_id stored).
        if ($logLowScore && !empty($uniqueQueryTerms) && (empty($ranked) || $maxSimilarity < (float) $config->ambang_skor_rendah)) {
            RekomendasiLogPencarian::create([
                'topik_kueri'        => mb_substr($cleanTopic, 0, 255),
                'kata_kunci_stemmed' => $uniqueQueryTerms,
                'skor_tertinggi'     => round($maxSimilarity, 4),
                'jumlah_kandidat'    => count($ranked),
                'created_at'         => now(),
            ]);
        }

        if ($limit !== null && $limit > 0) {
            $ranked = array_slice($ranked, 0, $limit);
        }

        return [
            'topik'                                => $cleanTopic,
            'kata_kunci_stemmed'                   => $uniqueQueryTerms,
            'is_topik_singkat'                     => $isTopikSingkat,
            'catatan_kueri'                        => $isTopikSingkat
                ? 'Topik masih singkat atau umum. Berikan deskripsi topik yang lebih detail untuk meningkatkan akurasi pencocokan keahlian dosen.'
                : null,
            'bobot_aktif'                          => $weights,
            'total_kandidat'                       => count($ranked),
            'total_dosen_dikecualikan_kuota_habis' => count($allDocs) - count($eligibleDocs),
            'rekomendasi'                          => $ranked,
        ];
    }

    /**
     * Collect completed-supervision topics from permohonan.topik_ta and mahasiswa.judul_ta.
     *
     * @return array<string>
     */
    protected function extractCompletedTopics(Dosen $dosen): array
    {
        $topics = [];

        foreach ($dosen->bimbinganSelesai as $bimbingan) {
            $topikTa = trim((string) ($bimbingan->permohonan?->topik_ta ?? ''));
            $judulTa = trim((string) ($bimbingan->mahasiswa?->judul_ta ?? ''));

            if ($topikTa !== '') {
                $topics[] = $topikTa;
            }
            if ($judulTa !== '' && mb_strtolower($judulTa) !== mb_strtolower($topikTa)) {
                $topics[] = $judulTa;
            }
        }

        return $topics;
    }

    /**
     * @param array<string, int> $termCounts
     * @param callable(string): float $idf
     * @return array<string, float>
     */
    protected function buildTfIdfVector(array $termCounts, callable $idf): array
    {
        $vector = [];

        foreach ($termCounts as $term => $count) {
            if ($count <= 0) {
                continue;
            }

            $tf = 1.0 + log($count);
            $vector[$term] = $tf * $idf((string) $term);
        }

        return $vector;
    }

    /**
     * @param array<string, float> $vector
     */
    protected function vectorNorm(array $vector): float
    {
        if (empty($vector)) {
            return 0.0;
        }

        $sumSq = 0.0;
        foreach ($vector as $weight) {
            $sumSq += $weight * $weight;
        }

        return sqrt($sumSq);
    }

    /**
     * @param array<string, float> $vecA
     * @param array<string, float> $vecB
     */
    protected function cosineSimilarity(array $vecA, float $normA, array $vecB, float $normB): float
    {
        if ($normA <= 0.0 || $normB <= 0.0 || empty($vecA) || empty($vecB)) {
            return 0.0;
        }

        $dot = 0.0;
        foreach ($vecA as $term => $weightA) {
            if (isset($vecB[$term])) {
                $dot += $weightA * $vecB[$term];
            }
        }

        $similarity = $dot / ($normA * $normB);

        return min(1.0, max(0.0, $similarity));
    }

    /**
     * @param array<string> $uniqueQueryTerms
     * @param array<string> $completedTopics
     */
    protected function countMatchingCompletedTopics(array $uniqueQueryTerms, array $completedTopics): int
    {
        if (empty($uniqueQueryTerms) || empty($completedTopics)) {
            return 0;
        }

        $querySet = array_flip($uniqueQueryTerms);
        $matches = 0;

        foreach ($completedTopics as $topic) {
            $terms = $this->stemmer->tokenizeAndStem($topic);
            foreach ($terms as $term) {
                if (isset($querySet[$term])) {
                    $matches++;
                    break;
                }
            }
        }

        return $matches;
    }

    /**
     * T-50: Produce a concise 1-line human-readable explanation of all 3 score components.
     *
     * @param array<string> $matchedKeywords
     */
    protected function buildExplanation(
        float $kemiripanTopik,
        array $matchedKeywords,
        int $sisaKuota,
        int $kuotaBimbingan,
        int $bimbinganAktif,
        float $bebanAktif,
        int $matchedHistoryCount,
    ): string {
        $topicPct = (int) round($kemiripanTopik * 100);

        if ($topicPct > 0 && !empty($matchedKeywords)) {
            $previewKeywords = implode(', ', array_slice($matchedKeywords, 0, 3));
            $topicPart = "Kecocokan topik {$topicPct}% ({$previewKeywords})";
        } elseif ($topicPct > 0) {
            $topicPart = "Kecocokan topik {$topicPct}%";
        } else {
            $topicPart = 'Kecocokan topik rendah (0%)';
        }

        $loadLabel = match (true) {
            $bebanAktif <= 0.35 => 'rendah',
            $bebanAktif <= 0.70 => 'sedang',
            default              => 'tinggi',
        };

        $quotaPart = "kuota tersisa {$sisaKuota} dari {$kuotaBimbingan}";
        $loadPart = "beban bimbingan aktif {$loadLabel} ({$bimbinganAktif}/{$kuotaBimbingan})";

        $parts = [$topicPart, $quotaPart, $loadPart];

        if ($matchedHistoryCount > 0) {
            $parts[] = "{$matchedHistoryCount} riwayat bimbingan relevan";
        }

        return implode(', ', $parts) . '.';
    }
}
