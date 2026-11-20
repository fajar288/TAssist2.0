<?php
// app/Console/Commands/PindahkanDokumenKePrivat.php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;
use Throwable;

/**
 * One-off migration for T-02: documents moved from the public disk
 * (`storage/app/public/dokumen_ta/**`, reachable through the unauthenticated
 * `public/storage` symlink) to the private `dokumen` disk.
 *
 * The relative path is preserved so `versi_dokumen.file_url_or_path` rows stay
 * addressable without a data migration.
 *
 * Idempotent: files already present on the private disk are only cleaned up
 * from the public disk, and a second run reports zero moves.
 */
class PindahkanDokumenKePrivat extends Command
{
    protected $signature = 'dokumen:pindahkan-ke-privat
                            {--dry-run : Tampilkan rencana pemindahan tanpa menyentuh file}';

    protected $description = 'Pindahkan semua file dokumen_ta/** dari disk public ke disk privat "dokumen".';

    public function handle(): int
    {
        $public  = Storage::disk('public');
        $privat  = Storage::disk('dokumen');
        $dryRun  = (bool) $this->option('dry-run');

        $files = $public->allFiles('dokumen_ta');

        if (empty($files)) {
            $this->info('Tidak ada file dokumen_ta di disk public. Tidak ada yang dipindahkan.');

            return self::SUCCESS;
        }

        $dipindah = 0;
        $dilewati = 0;
        $gagal    = 0;

        foreach ($files as $path) {
            if ($privat->exists($path)) {
                $dilewati++;
                $this->line("Lewati (sudah ada di disk privat): {$path}");

                if (! $dryRun) {
                    $public->delete($path);
                }

                continue;
            }

            if ($dryRun) {
                $this->line("[dry-run] Akan dipindahkan: {$path}");
                $dipindah++;

                continue;
            }

            try {
                $stream = $public->readStream($path);

                if ($stream === null) {
                    throw new \RuntimeException('Tidak dapat membaca file sumber.');
                }

                $privat->writeStream($path, $stream);

                if (is_resource($stream)) {
                    fclose($stream);
                }

                if (! $privat->exists($path)) {
                    throw new \RuntimeException('File tujuan tidak terverifikasi setelah ditulis.');
                }

                $public->delete($path);
                $dipindah++;
                $this->line("Dipindahkan: {$path}");
            } catch (Throwable $e) {
                $gagal++;
                $this->error("Gagal memindahkan {$path}: {$e->getMessage()}");
            }
        }

        $this->newLine();
        $this->table(
            ['Status', 'Jumlah'],
            [
                ['Dipindahkan', $dipindah],
                ['Dilewati (sudah privat)', $dilewati],
                ['Gagal', $gagal],
            ]
        );

        if ($dryRun) {
            $this->warn('Mode dry-run: tidak ada file yang diubah.');
        }

        return $gagal > 0 ? self::FAILURE : self::SUCCESS;
    }
}
