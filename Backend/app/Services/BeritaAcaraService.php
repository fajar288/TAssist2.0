<?php

namespace App\Services;

use App\Models\AnotasiDokumen;
use App\Models\BeritaAcara;
use App\Models\Bimbingan;
use App\Models\Dosen;
use App\Models\VersiDokumen;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use SimpleSoftwareIO\QrCode\Facades\QrCode;

class BeritaAcaraService
{
    /**
     * Generate sequential number BA/TA/{year}/{seq} with transaction lock (Decision C10).
     */
    public function generateNomor(int $year): string
    {
        return DB::transaction(function () use ($year) {
            $prefix = "BA/TA/{$year}/";
            $lastBa = BeritaAcara::where('nomor', 'LIKE', "{$prefix}%")
                ->lockForUpdate()
                ->orderBy('berita_acara_id', 'desc')
                ->first();

            $seq = 1;
            if ($lastBa && preg_match('/BA\/TA\/\d+\/(\d+)/', $lastBa->nomor, $matches)) {
                $seq = (int)$matches[1] + 1;
            }

            return sprintf("BA/TA/%d/%04d", $year, $seq);
        });
    }

    /**
     * Build JSON snapshot of supervision data for the specified period.
     */
    public function buildSnapshot(Bimbingan $bimbingan, string $periodeMulai, string $periodeSelesai): array
    {
        $bimbingan->loadMissing(['mahasiswa.user', 'dosen.user', 'permohonan']);

        $mhs = $bimbingan->mahasiswa;
        $dsn = $bimbingan->dosen;
        $permohonan = $bimbingan->permohonan;

        // Sesi bimbingan yang terkonfirmasi dalam rentang periode
        $sesiList = $bimbingan->jadwalBimbingan()
            ->whereBetween('tanggal', [$periodeMulai, $periodeSelesai])
            ->where('status_konfirmasi', 'dikonfirmasi')
            ->orderBy('tanggal', 'asc')
            ->orderBy('waktu_mulai', 'asc')
            ->get()
            ->map(fn ($j) => [
                'jadwal_id'      => $j->jadwal_id,
                'tanggal'        => Carbon::parse($j->tanggal)->format('Y-m-d'),
                'waktu_mulai'    => $j->waktu_mulai ? substr((string)$j->waktu_mulai, 0, 5) : null,
                'waktu_selesai'  => $j->waktu_selesai ? substr((string)$j->waktu_selesai, 0, 5) : null,
                'catatan'        => $j->catatan ?: '-',
                'catatan_revisi' => $j->catatan_revisi ?? '-',
            ])
            ->toArray();

        // Dokumen versi yang diunggah dalam rentang periode
        $dokumenList = VersiDokumen::whereHas('dokumen', fn ($q) => $q->where('bimbingan_id', $bimbingan->bimbingan_id))
            ->whereBetween('created_at', [
                Carbon::parse($periodeMulai)->startOfDay(),
                Carbon::parse($periodeSelesai)->endOfDay(),
            ])
            ->orderBy('created_at', 'asc')
            ->get()
            ->map(fn ($v) => [
                'versi_id'      => $v->versi_id,
                'nomor_versi'   => $v->nomor_versi,
                'nama_file'     => basename($v->file_url_or_path ?? 'dokumen.pdf'),
                'catatan'       => $v->catatan_revisi ?: '-',
                'tanggal_unggah'=> $v->created_at->format('Y-m-d H:i'),
            ])
            ->toArray();

        // Anotasi terselesaikan
        $anotasiTotal = AnotasiDokumen::whereHas('versiDokumen.dokumen', fn ($q) => $q->where('bimbingan_id', $bimbingan->bimbingan_id))
            ->whereBetween('created_at', [
                Carbon::parse($periodeMulai)->startOfDay(),
                Carbon::parse($periodeSelesai)->endOfDay(),
            ])
            ->count();

        $anotasiResolved = AnotasiDokumen::whereHas('versiDokumen.dokumen', fn ($q) => $q->where('bimbingan_id', $bimbingan->bimbingan_id))
            ->where('status', 'resolved')
            ->whereBetween('created_at', [
                Carbon::parse($periodeMulai)->startOfDay(),
                Carbon::parse($periodeSelesai)->endOfDay(),
            ])
            ->count();

        // Progres snapshot
        $progresAktif = $bimbingan->progresAktif;
        $persentase = $progresAktif ? (int)$progresAktif->persentase : 0;
        $checklist = [];
        if ($progresAktif) {
            $checklist = $progresAktif->checklistProgress()
                ->get()
                ->map(fn ($c) => [
                    'tugas'      => $c->nama_tugas ?? $c->kegiatan ?? 'Tugas',
                    'is_selesai' => (bool)($c->is_selesai ?? false),
                ])
                ->toArray();
        }

        return [
            'mahasiswa' => [
                'mahasiswa_id' => $mhs?->mahasiswa_id,
                'nama'         => $mhs?->user?->nama ?? 'Mahasiswa',
                'nim'          => $mhs?->nim ?? '-',
                'program_studi'=> $mhs?->program_studi ?? 'Teknik Informatika',
            ],
            'dosen' => [
                'dosen_id'        => $dsn?->dosen_id,
                'nama'            => $dsn?->user?->nama ?? 'Dosen Pembimbing',
                'nid'             => $dsn?->nid ?? '-',
                'bidang_keahlian' => $dsn?->bidang_keahlian ?? '-',
            ],
            'supervisi' => [
                'bimbingan_id'   => $bimbingan->bimbingan_id,
                'judul_ta'       => $permohonan?->judul_ta ?? 'Tugas Akhir',
                'tanggal_mulai'  => $bimbingan->tanggal_mulai?->format('Y-m-d'),
                'tanggal_selesai'=> $bimbingan->tanggal_selesai?->format('Y-m-d'),
                'status'         => $bimbingan->status_bimbingan,
            ],
            'periode' => [
                'mulai'   => $periodeMulai,
                'selesai' => $periodeSelesai,
            ],
            'sesi_bimbingan'     => $sesiList,
            'total_sesi'         => count($sesiList),
            'dokumen_submisi'    => $dokumenList,
            'anotasi'            => [
                'total'    => $anotasiTotal,
                'resolved' => $anotasiResolved,
            ],
            'progres' => [
                'persentase' => $persentase,
                'checklist'  => $checklist,
            ],
            'generated_at' => now()->toIso8601String(),
        ];
    }

    /**
     * Render and store the PDF file for a Berita Acara record.
     * Returns ['file_path' => string, 'file_hash' => string].
     */
    public function renderAndStorePdf(BeritaAcara $ba): array
    {
        $verificationUrl = url("/verifikasi/{$ba->token_verifikasi}");

        // Generate QR code base64 SVG
        $qrCodeSvg = QrCode::format('svg')
            ->size(110)
            ->margin(1)
            ->generate($verificationUrl);

        $qrCodeBase64 = 'data:image/svg+xml;base64,' . base64_encode($qrCodeSvg);

        // Signature image base64 if available
        $signatureBase64 = null;
        if ($ba->tanda_tangan_path && Storage::exists($ba->tanda_tangan_path)) {
            $rawImg = Storage::get($ba->tanda_tangan_path);
            $mime = 'image/png';
            $signatureBase64 = 'data:' . $mime . ';base64,' . base64_encode($rawImg);
        }

        $pdf = Pdf::loadView('pdf.berita_acara', [
            'ba'              => $ba,
            'snapshot'        => $ba->data_snapshot,
            'verificationUrl' => $verificationUrl,
            'qrCodeBase64'    => $qrCodeBase64,
            'signatureBase64' => $signatureBase64,
        ])->setPaper('a4', 'portrait');

        $pdfContent = $pdf->output();

        $safeNomor = str_replace(['/', '\\'], '_', $ba->nomor);
        $relativePath = "berita_acara/{$safeNomor}_{$ba->token_verifikasi}.pdf";

        Storage::put($relativePath, $pdfContent);

        $hash = hash('sha256', $pdfContent);

        return [
            'file_path' => $relativePath,
            'file_hash' => $hash,
        ];
    }

    /**
     * Create draft Berita Acara for a supervision.
     */
    public function createDraft(Bimbingan $bimbingan, string $periodeMulai, string $periodeSelesai): BeritaAcara
    {
        if ($bimbingan->isDibatalkan()) {
            throw ValidationException::withMessages([
                'bimbingan' => 'Tidak dapat membuat Berita Acara untuk bimbingan yang telah dibatalkan.',
            ]);
        }

        if (Carbon::parse($periodeMulai)->isAfter(Carbon::parse($periodeSelesai))) {
            throw ValidationException::withMessages([
                'periode_mulai' => 'Tanggal mulai periode tidak boleh melebihi tanggal selesai.',
            ]);
        }

        $snapshot = $this->buildSnapshot($bimbingan, $periodeMulai, $periodeSelesai);
        $year = Carbon::parse($periodeSelesai)->year;
        $token = Str::random(40);

        return DB::transaction(function () use ($bimbingan, $year, $periodeMulai, $periodeSelesai, $snapshot, $token) {
            $nomor = $this->generateNomor($year);

            $ba = new BeritaAcara([
                'bimbingan_id'       => $bimbingan->bimbingan_id,
                'nomor'              => $nomor,
                'periode_mulai'      => $periodeMulai,
                'periode_selesai'    => $periodeSelesai,
                'data_snapshot'      => $snapshot,
                'file_path'          => 'pending',
                'file_hash'          => str_repeat('0', 64),
                'token_verifikasi'   => $token,
                'status_persetujuan' => 'draft',
            ]);

            $ba->save();

            // Render PDF initial draft
            $renderResult = $this->renderAndStorePdf($ba);
            $ba->file_path = $renderResult['file_path'];
            $ba->file_hash = $renderResult['file_hash'];
            $ba->save();

            return $ba;
        });
    }

    /**
     * Approve Berita Acara via PIN or signature image.
     */
    public function approve(
        BeritaAcara $ba,
        Dosen $dosen,
        string $metode,
        ?string $pin = null,
        ?UploadedFile $signatureFile = null
    ): BeritaAcara {
        if ($ba->isDisetujui()) {
            throw ValidationException::withMessages([
                'berita_acara' => 'Berita Acara ini telah disetujui sebelumnya.',
            ]);
        }

        if ($metode === 'pin') {
            if (empty($pin)) {
                throw ValidationException::withMessages([
                    'pin' => 'PIN dosen wajib diisi.',
                ]);
            }
            if (!$dosen->verifyPin($pin)) {
                throw ValidationException::withMessages([
                    'pin' => 'PIN dosen yang Anda masukkan tidak valid.',
                ]);
            }
        } elseif ($metode === 'tanda_tangan') {
            if (!$signatureFile) {
                throw ValidationException::withMessages([
                    'tanda_tangan' => 'File gambar tanda tangan wajib diunggah.',
                ]);
            }

            $sigName = 'sig_' . $ba->berita_acara_id . '_' . Str::random(12) . '.' . $signatureFile->getClientOriginalExtension();
            $path = $signatureFile->storeAs('signatures', $sigName);
            $ba->tanda_tangan_path = $path;
        } else {
            throw ValidationException::withMessages([
                'metode' => 'Metode persetujuan harus pin atau tanda_tangan.',
            ]);
        }

        $ba->status_persetujuan = 'disetujui';
        $ba->metode_persetujuan = $metode;
        $ba->approved_at = now();

        // Re-render PDF with approval metadata embedded and re-hash
        $renderResult = $this->renderAndStorePdf($ba);
        $ba->file_path = $renderResult['file_path'];
        $ba->approved_hash = $renderResult['file_hash'];
        $ba->save();

        // Notifikasi ke mahasiswa
        $mhsUserId = $ba->bimbingan?->mahasiswa?->user_id;
        if ($mhsUserId) {
            NotifikasiService::kirim(
                $mhsUserId,
                'berita_acara_disetujui',
                'Berita Acara Bimbingan Disetujui',
                "Berita Acara nomor {$ba->nomor} telah disetujui oleh dosen pembimbing.",
                'berita_acara',
                $ba->berita_acara_id
            );
        }

        return $ba;
    }
}
