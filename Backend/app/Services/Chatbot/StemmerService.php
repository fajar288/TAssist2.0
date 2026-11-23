<?php

namespace App\Services\Chatbot;

use Sastrawi\Dictionary\ArrayDictionary;
use Sastrawi\Stemmer\Cache\ArrayCache;
use Sastrawi\Stemmer\CachedStemmer;
use Sastrawi\Stemmer\Stemmer;

class StemmerService
{
    protected ?object $stemmer = null;

    /**
     * Common Indonesian stopwords for search normalization.
     */
    protected array $stopwords = [
        'yang', 'untuk', 'pada', 'ke', 'para', 'namun', 'menurut', 'antara', 'dia', 'dua',
        'ia', 'seperti', 'jika', 'sehingga', 'kembali', 'dan', 'ini', 'karena', 'oleh',
        'saat', 'harus', 'sementara', 'setelah', 'belum', 'kami', 'sekitar', 'bagi', 'serta',
        'di', 'dari', 'telah', 'sebagai', 'masih', 'hal', 'ketika', 'adalah', 'itu', 'dalam',
        'bisa', 'bahwa', 'atau', 'hanya', 'kita', 'dengan', 'akan', 'juga', 'ada', 'mereka',
        'sudah', 'saya', 'anda', 'kamu', 'apa', 'siapa', 'kapan', 'di mana', 'dimana', 'kenapa',
        'mengapa', 'bagaimana', 'berapa', 'tolong', 'mohon', 'hai', 'halo', 'terima', 'kasih'
    ];

    public function __construct()
    {
        $this->initializeStemmer();
    }

    /**
     * Safely initialize Sastrawi stemmer with normalized dictionary path.
     */
    protected function initializeStemmer(): void
    {
        if (!class_exists(Stemmer::class) || !class_exists(ArrayDictionary::class)) {
            return;
        }

        $possiblePaths = [
            function_exists('base_path') ? base_path('vendor/sastrawi/sastrawi/data/kata-dasar.txt') : null,
            __DIR__ . '/../../../vendor/sastrawi/sastrawi/data/kata-dasar.txt',
            __DIR__ . '/../../../../vendor/sastrawi/sastrawi/data/kata-dasar.txt',
            dirname(__DIR__, 3) . '/vendor/sastrawi/sastrawi/data/kata-dasar.txt',
        ];

        $dictFile = null;
        foreach ($possiblePaths as $path) {
            if ($path && file_exists($path)) {
                $dictFile = $path;
                break;
            }
        }

        if ($dictFile && ($content = @file_get_contents($dictFile)) !== false) {
            $words = explode("\n", $content);
            $words = array_map('trim', $words);
            $dictionary = new ArrayDictionary($words);
            $rawStemmer = new Stemmer($dictionary);
            $this->stemmer = new CachedStemmer(new ArrayCache(), $rawStemmer);
        }
    }

    /**
     * Stem a text using Sastrawi stemmer or rule-based fallback.
     */
    public function stem(string $text): string
    {
        $normalized = mb_strtolower(trim($text), 'UTF-8');
        $clean = preg_replace('/[^\p{L}\p{N}\s]/u', ' ', $normalized);
        $clean = preg_replace('/\s+/', ' ', $clean);
        $clean = trim($clean);

        if (empty($clean)) {
            return '';
        }

        if ($this->stemmer) {
            try {
                return $this->stemmer->stem($clean);
            } catch (\Throwable $e) {
                // Fall back to rule-based stemmer
            }
        }

        return $this->fallbackStem($clean);
    }

    /**
     * Basic Indonesian rule-based affix removal fallback if dictionary is unavailable.
     */
    protected function fallbackStem(string $text): string
    {
        $words = explode(' ', $text);
        $stemmedWords = array_map(function ($w) {
            $len = mb_strlen($w);
            if ($len <= 4) {
                return $w;
            }

            // Remove prefixes
            $prefixes = ['meng', 'meny', 'men', 'mem', 'me', 'peng', 'peny', 'pen', 'pem', 'per', 'pe', 'di', 'ter', 'ke', 'ber', 'se'];
            foreach ($prefixes as $p) {
                if (str_starts_with($w, $p) && mb_strlen($w) - mb_strlen($p) >= 3) {
                    $w = mb_substr($w, mb_strlen($p));
                    break;
                }
            }

            // Remove suffixes
            $suffixes = ['kan', 'an', 'nya', 'lah', 'kah', 'i'];
            foreach ($suffixes as $s) {
                if (str_ends_with($w, $s) && mb_strlen($w) - mb_strlen($s) >= 3) {
                    $w = mb_substr($w, 0, mb_strlen($w) - mb_strlen($s));
                    break;
                }
            }

            return $w;
        }, $words);

        return implode(' ', $stemmedWords);
    }

    /**
     * Tokenize text, filter stopwords, and return array of stemmed root words.
     *
     * @param string $text
     * @param bool $removeStopwords
     * @return array<string>
     */
    public function tokenizeAndStem(string $text, bool $removeStopwords = true): array
    {
        $stemmed = $this->stem($text);
        if (empty($stemmed)) {
            return [];
        }

        $tokens = preg_split('/\s+/', $stemmed, -1, PREG_SPLIT_NO_EMPTY);

        if ($removeStopwords) {
            $tokens = array_filter($tokens, function ($token) {
                return !in_array($token, $this->stopwords, true) && mb_strlen($token) > 1;
            });
        }

        return array_values(array_unique($tokens));
    }
}
