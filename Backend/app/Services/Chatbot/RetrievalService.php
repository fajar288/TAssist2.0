<?php

namespace App\Services\Chatbot;

use App\Models\BasisPengetahuanTA;
use App\Models\InformasiTA;
use App\Models\User;
use Carbon\Carbon;

class RetrievalService
{
    public function __construct(
        protected StemmerService $stemmer
    ) {}

    /**
     * Retrieve matching sources from knowledge base, announcements, and user context.
     *
     * @param string $query
     * @param User|null $user
     * @param float $minScore
     * @return array<array{judul: string, tipe: string, konten: string, label: string, score: float}>
     */
    public function retrieve(string $query, ?User $user = null, float $minScore = 0.15): array
    {
        $queryTokens = $this->stemmer->tokenizeAndStem($query);
        if (empty($queryTokens)) {
            return [];
        }

        $results = [];

        // 1. Check user personal context (progres, bimbingan, dosen) if user is Mahasiswa
        if ($user && $user->isMahasiswa()) {
            $contextSource = $this->matchUserContext($queryTokens, $user);
            if ($contextSource) {
                $results[] = $contextSource;
            }
        }

        // 2. Search Informasi TA (announcements - published only)
        $announcements = InformasiTA::query()
            ->whereNotNull('published_at')
            ->where('published_at', '<=', Carbon::now())
            ->get();

        foreach ($announcements as $info) {
            $content = $info->konten_or_file ?? $info->konten ?? '';
            $score = $this->calculateRelevance($queryTokens, ($info->judul ?? '') . ' ' . $content);
            if ($score >= $minScore) {
                $results[] = [
                    'id' => $info->info_id ?? $info->informasi_id ?? $info->id,
                    'judul' => $info->judul,
                    'tipe' => 'pengumuman',
                    'konten' => $content,
                    'label' => '[Sumber: Pengumuman TA - "' . $info->judul . '"]',
                    'score' => $score + 0.1, // Slight priority for recent announcements
                ];
            }
        }

        // 3. Search Basis Pengetahuan TA (curated guides/faq)
        $knowledgeItems = BasisPengetahuanTA::active()->get();
        foreach ($knowledgeItems as $item) {
            // Use pre-stemmed content if available
            $targetText = !empty($item->stemmed_konten)
                ? $item->stemmed_konten
                : ($item->judul . ' ' . $item->konten . ' ' . (is_array($item->tags) ? implode(' ', $item->tags) : ''));

            $score = $this->calculateRelevance($queryTokens, $targetText, !empty($item->stemmed_konten));
            if ($score >= $minScore) {
                $results[] = [
                    'id' => $item->id,
                    'judul' => $item->judul,
                    'tipe' => 'panduan',
                    'kategori' => $item->kategori,
                    'konten' => $item->konten,
                    'label' => '[Sumber: Panduan TA - "' . $item->judul . '"]',
                    'score' => $score,
                ];
            }
        }

        // Sort descending by score
        usort($results, fn($a, $b) => $b['score'] <=> $a['score']);

        return array_slice($results, 0, 3);
    }

    /**
     * Match personal context keywords (progres, checklist, bimbingan, dosen, jadwal).
     */
    protected function matchUserContext(array $queryTokens, User $user): ?array
    {
        $contextKeywords = ['progres', 'persen', 'kemajuan', 'checklist', 'status', 'dosen', 'pembimbing', 'jadwal', 'sidang'];
        $intersection = array_intersect($queryTokens, $contextKeywords);

        if (empty($intersection)) {
            return null;
        }

        $mahasiswa = $user->mahasiswa;
        if (!$mahasiswa) {
            return null;
        }

        $bimbingan = $mahasiswa->bimbinganAktif;
        $progres = $bimbingan ? $bimbingan->progresAktif : null;
        $dosen = $bimbingan?->dosen?->user?->nama ?? $bimbingan?->dosen?->nama ?? 'belum ditentukan';
        $persen = $progres?->persentase ?? 0;
        $statusBimbingan = $bimbingan?->status_bimbingan ?? 'belum aktif';

        $summary = "Nama: {$user->nama}. Dosen Pembimbing: {$dosen}. Status Bimbingan: {$statusBimbingan}. ";
        $summary .= "Progres Tugas Akhir saat ini: {$persen}%.";

        if ($progres && $progres->catatan) {
            $summary .= " Catatan progres: {$progres->catatan}.";
        }

        return [
            'id' => 'personal_context',
            'judul' => 'Progres TA & Profil Bimbingan',
            'tipe' => 'data_pribadi',
            'konten' => $summary,
            'label' => '[Sumber: Data pribadi - Progres TA]',
            'score' => 0.85, // High relevance when context is explicitly queried
        ];
    }

    /**
     * Compute token match score (Jaccard + keyword frequency).
     */
    protected function calculateRelevance(array $queryTokens, string $targetText, bool $isAlreadyStemmed = false): float
    {
        if (empty($queryTokens) || empty($targetText)) {
            return 0.0;
        }

        $targetTokens = $isAlreadyStemmed
            ? preg_split('/\s+/', mb_strtolower($targetText, 'UTF-8'), -1, PREG_SPLIT_NO_EMPTY)
            : $this->stemmer->tokenizeAndStem($targetText);

        if (empty($targetTokens)) {
            return 0.0;
        }

        $targetTokenSet = array_flip($targetTokens);
        $matches = 0;

        foreach ($queryTokens as $qToken) {
            if (isset($targetTokenSet[$qToken])) {
                $matches++;
            }
        }

        if ($matches === 0) {
            return 0.0;
        }

        // Relative to query length (how many of user query terms matched)
        $queryCoverage = $matches / count($queryTokens);
        // Overlap relative to total unique tokens
        $jaccard = $matches / count(array_unique(array_merge($queryTokens, $targetTokens)));

        return (0.7 * $queryCoverage) + (0.3 * $jaccard);
    }
}
