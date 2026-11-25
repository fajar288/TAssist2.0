<?php

namespace App\Exports;

use Maatwebsite\Excel\Concerns\FromArray;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMultipleSheets;
use Maatwebsite\Excel\Concerns\WithTitle;

class RiwayatBimbinganExport implements WithMultipleSheets
{
    public function __construct(private array $data)
    {
    }

    public function sheets(): array
    {
        return [
            new RiwayatMeetingsSheet($this->data['meetings'] ?? []),
            new RiwayatDocumentsSheet($this->data['documents'] ?? []),
            new RiwayatProgressSheet(
                $this->data['progress_history'] ?? [],
                $this->data['checklist'] ?? []
            ),
        ];
    }
}

class RiwayatMeetingsSheet implements FromArray, WithHeadings, WithTitle
{
    public function __construct(private array $meetings)
    {
    }

    public function title(): string
    {
        return 'Meetings';
    }

    public function headings(): array
    {
        return ['Tanggal', 'Waktu Mulai', 'Waktu Selesai', 'Mode', 'Status', 'Catatan'];
    }

    public function array(): array
    {
        return array_map(fn ($m) => [
            $m['tanggal'],
            $m['waktu_mulai'],
            $m['waktu_selesai'],
            $m['mode'],
            $m['status_konfirmasi'],
            $m['catatan'],
        ], $this->meetings);
    }
}

class RiwayatDocumentsSheet implements FromArray, WithHeadings, WithTitle
{
    public function __construct(private array $documents)
    {
    }

    public function title(): string
    {
        return 'Documents';
    }

    public function headings(): array
    {
        return ['Judul Dokumen', 'Jenis', 'Versi', 'Status', 'Tanggal Unggah', 'Jumlah Feedback', 'Jumlah Anotasi', 'Catatan Revisi'];
    }

    public function array(): array
    {
        return array_map(fn ($d) => [
            $d['judul_dokumen'],
            $d['jenis_dokumen'],
            'v' . $d['nomor_versi'],
            $d['status_versi'],
            $d['uploaded_at'],
            $d['feedback_count'],
            $d['anotasi_count'],
            $d['catatan_revisi'],
        ], $this->documents);
    }
}

class RiwayatProgressSheet implements FromArray, WithHeadings, WithTitle
{
    public function __construct(
        private array $progressHistory,
        private array $checklist
    ) {
    }

    public function title(): string
    {
        return 'Progress';
    }

    public function headings(): array
    {
        return ['Tipe', 'Item / Status', 'Persentase / Bobot', 'Selesai / Override', 'Tanggal', 'Catatan'];
    }

    public function array(): array
    {
        $rows = [];

        foreach ($this->progressHistory as $p) {
            $rows[] = [
                'Progres',
                $p['status_progress'],
                $p['persentase'] . '%',
                $p['is_override'] ? 'Override Manual' : 'Otomatis',
                $p['updated_at'],
                $p['catatan'],
            ];
        }

        foreach ($this->checklist as $c) {
            $rows[] = [
                'Checklist',
                $c['nama_item'],
                'Bobot ' . $c['bobot'],
                $c['is_selesai'] ? 'Selesai' : 'Belum',
                $c['tanggal_selesai'],
                $c['catatan'],
            ];
        }

        return $rows;
    }
}
