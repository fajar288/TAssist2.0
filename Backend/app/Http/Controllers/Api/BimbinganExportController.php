<?php

namespace App\Http\Controllers\Api;

use App\Exports\RiwayatBimbinganExport;
use App\Http\Controllers\Controller;
use App\Models\Bimbingan;
use App\Services\BimbinganExportService;
use App\Traits\ApiResponse;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Maatwebsite\Excel\Facades\Excel;

class BimbinganExportController extends Controller
{
    use ApiResponse;

    public function __construct(private BimbinganExportService $exportService)
    {
    }

    /**
     * GET /api/v1/{mahasiswa|dosen}/bimbingan/{id}/export?format={pdf|excel}
     */
    public function export(Request $request, int $id)
    {
        $format = strtolower((string) $request->query('format', 'pdf'));

        if (! in_array($format, ['pdf', 'excel', 'xlsx'], true)) {
            return $this->errorResponse('Format export harus pdf atau excel.', [
                'format' => ['Format export tidak valid. Gunakan pdf atau excel.'],
            ], 422);
        }

        $bimbingan = Bimbingan::findOrFail($id);

        Gate::authorize('view', $bimbingan);

        $data = $this->exportService->buildData($bimbingan);

        if ($format === 'pdf') {
            $pdf = Pdf::loadView('exports.riwayat-bimbingan-pdf', ['data' => $data])
                ->setPaper('a4', 'portrait');

            return $pdf->download("riwayat-bimbingan-{$bimbingan->bimbingan_id}.pdf");
        }

        $binary = Excel::raw(
            new RiwayatBimbinganExport($data),
            \Maatwebsite\Excel\Excel::XLSX
        );

        return response($binary, 200, [
            'Content-Type'        => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'Content-Disposition' => "attachment; filename=\"riwayat-bimbingan-{$bimbingan->bimbingan_id}.xlsx\"",
        ]);
    }
}
