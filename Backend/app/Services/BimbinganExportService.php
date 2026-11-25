<?php

namespace App\Services;

use App\Models\Bimbingan;
use Carbon\Carbon;

/**
 * Aggregates supervision history for PDF and Excel exports (T-41 / F-DOC-07).
 */
class BimbinganExportService
{
    public function buildData(Bimbingan $bimbingan): array
    {
        $bimbingan->loadMissing([
            'mahasiswa.user',
            'dosen.user',
            'permohonan',
            'jadwalBimbingan' => fn ($q) => $q->orderBy('tanggal')->orderBy('waktu_mulai'),
            'dokumenTA.versiDokumen' => fn ($q) => $q->withCount(['feedbackDokumen', 'anotasiDokumen'])->orderBy('nomor_versi'),
            'progresTA' => fn ($q) => $q->with('checklistProgress')->orderByDesc('updated_at')->orderByDesc('progress_id'),
        ]);

        $meetings = $bimbingan->jadwalBimbingan->map(fn ($j) => [
            'jadwal_id'         => $j->jadwal_id,
            'tanggal'           => $j->tanggal?->format('Y-m-d') ?? '-',
            'waktu_mulai'       => substr((string) $j->waktu_mulai, 0, 5),
            'waktu_selesai'     => substr((string) $j->waktu_selesai, 0, 5),
            'mode'              => $j->mode,
            'status_konfirmasi' => $j->status_konfirmasi,
            'catatan'           => $j->catatan ?? '-',
        ])->values()->toArray();

        $documents = [];
        foreach ($bimbingan->dokumenTA as $dok) {
            foreach ($dok->versiDokumen as $v) {
                $documents[] = [
                    'judul_dokumen'   => $dok->judul_dokumen,
                    'jenis_dokumen'   => $dok->jenis_dokumen,
                    'nomor_versi'     => $v->nomor_versi,
                    'status_versi'    => $v->status_versi,
                    'uploaded_at'     => $v->uploaded_at ? Carbon::parse($v->uploaded_at)->format('Y-m-d H:i') : '-',
                    'catatan_revisi'  => $v->catatan_revisi ?? '-',
                    'feedback_count'  => (int) ($v->feedback_dokumen_count ?? 0),
                    'anotasi_count'   => (int) ($v->anotasi_dokumen_count ?? 0),
                ];
            }
        }

        $latestProgress = $bimbingan->progresTA->first();
        $progressHistory = $bimbingan->progresTA->map(fn ($p) => [
            'progress_id'     => $p->progress_id,
            'persentase'      => (float) $p->persentase,
            'status_progress' => $p->status_progress,
            'is_override'     => (bool) $p->is_override,
            'catatan'         => $p->catatan ?? '-',
            'updated_at'      => $p->updated_at?->format('Y-m-d H:i') ?? '-',
        ])->values()->toArray();

        $checklist = $latestProgress
            ? $latestProgress->checklistProgress->map(fn ($c) => [
                'nama_item'       => $c->nama_item,
                'bobot'           => (float) ($c->bobot ?? 1.0),
                'is_selesai'      => (bool) $c->is_selesai,
                'tanggal_selesai' => $c->tanggal_selesai?->format('Y-m-d') ?? '-',
                'catatan'         => $c->catatan ?? '-',
            ])->values()->toArray()
            : [];

        return [
            'bimbingan' => [
                'bimbingan_id'     => $bimbingan->bimbingan_id,
                'status_bimbingan' => $bimbingan->status_bimbingan,
                'tanggal_mulai'    => $bimbingan->tanggal_mulai?->format('Y-m-d') ?? '-',
                'tanggal_selesai'  => $bimbingan->tanggal_selesai?->format('Y-m-d') ?? '-',
                'topik_ta'         => $bimbingan->mahasiswa?->judul_ta
                    ?: ($bimbingan->permohonan?->topik_ta ?: ($bimbingan->mahasiswa?->topik_ta ?? '-')),
            ],
            'mahasiswa' => [
                'nama'  => $bimbingan->mahasiswa?->user?->nama ?? '-',
                'nim'   => $bimbingan->mahasiswa?->nim ?? '-',
                'prodi' => $bimbingan->mahasiswa?->prodi ?? '-',
            ],
            'dosen' => [
                'nama' => $bimbingan->dosen?->user?->nama ?? '-',
                'nid'  => $bimbingan->dosen?->nid ?? '-',
            ],
            'meetings'         => $meetings,
            'documents'        => $documents,
            'latest_progress'  => $latestProgress ? [
                'persentase'      => (float) $latestProgress->persentase,
                'status_progress' => $latestProgress->status_progress,
                'is_override'     => (bool) $latestProgress->is_override,
            ] : ['persentase' => 0.0, 'status_progress' => '-', 'is_override' => false],
            'progress_history' => $progressHistory,
            'checklist'        => $checklist,
            'generated_at'     => now()->format('Y-m-d H:i:s'),
        ];
    }
}
