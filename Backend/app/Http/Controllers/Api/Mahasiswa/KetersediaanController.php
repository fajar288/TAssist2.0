<?php

namespace App\Http\Controllers\Api\Mahasiswa;

use App\Http\Controllers\Controller;
use App\Models\Dosen;
use App\Models\DosenKetersediaan;
use App\Traits\ApiResponse;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class KetersediaanController extends Controller
{
    use ApiResponse;

    private const HARI_MAP = [
        Carbon::MONDAY    => 'senin',
        Carbon::TUESDAY   => 'selasa',
        Carbon::WEDNESDAY => 'rabu',
        Carbon::THURSDAY  => 'kamis',
        Carbon::FRIDAY    => 'jumat',
        Carbon::SATURDAY  => 'sabtu',
        Carbon::SUNDAY    => 'minggu',
    ];

    /**
     * GET /api/v1/mahasiswa/dosen/{id}/ketersediaan
     *
     * Supports optional `?tanggal=YYYY-MM-DD` to resolve effective slots for a specific date
     * (one-off exceptions with `is_available = false` block overlapping weekly slots).
     */
    public function index(Request $request, int $id): JsonResponse
    {
        $dosen = Dosen::with('user')->findOrFail($id);

        $allSlots = DosenKetersediaan::where('dosen_id', $dosen->dosen_id)
            ->orderByRaw("CASE WHEN tipe = 'mingguan' THEN 0 ELSE 1 END")
            ->orderBy('tanggal')
            ->orderBy('waktu_mulai')
            ->get();

        $mingguan = $allSlots->where('tipe', 'mingguan')->values()->map(fn ($s) => $this->formatSlot($s));
        $khusus = $allSlots->where('tipe', 'khusus')->values()->map(fn ($s) => $this->formatSlot($s));

        $payload = [
            'dosen' => [
                'dosen_id' => $dosen->dosen_id,
                'nama'     => $dosen->user?->nama,
            ],
            'mingguan' => $mingguan,
            'khusus'   => $khusus,
        ];

        if ($request->filled('tanggal')) {
            $date = Carbon::parse($request->query('tanggal'));
            $hari = self::HARI_MAP[$date->dayOfWeek] ?? null;

            $weeklyForDay = $allSlots->filter(
                fn ($s) => $s->tipe === 'mingguan' && $s->hari === $hari && $s->is_available
            );
            $exceptionsForDate = $allSlots->filter(
                fn ($s) => $s->tipe === 'khusus' && $s->tanggal?->format('Y-m-d') === $date->format('Y-m-d')
            );

            $blockedRanges = $exceptionsForDate->where('is_available', false);
            $effective = collect();

            foreach ($weeklyForDay as $slot) {
                $slotStart = substr((string) $slot->waktu_mulai, 0, 5);
                $slotEnd   = substr((string) $slot->waktu_selesai, 0, 5);

                $isBlocked = $blockedRanges->contains(function ($ex) use ($slotStart, $slotEnd) {
                    $exStart = substr((string) $ex->waktu_mulai, 0, 5);
                    $exEnd   = substr((string) $ex->waktu_selesai, 0, 5);
                    return $slotStart < $exEnd && $slotEnd > $exStart;
                });

                if (! $isBlocked) {
                    $effective->push($this->formatSlot($slot));
                }
            }

            foreach ($exceptionsForDate->where('is_available', true) as $extra) {
                $effective->push($this->formatSlot($extra));
            }

            $payload['tanggal'] = $date->format('Y-m-d');
            $payload['hari'] = $hari;
            $payload['slot_efektif'] = $effective->values();
        }

        return $this->successResponse('Ketersediaan dosen berhasil diambil', $payload);
    }

    private function formatSlot(DosenKetersediaan $slot): array
    {
        return [
            'ketersediaan_id' => $slot->ketersediaan_id,
            'tipe'            => $slot->tipe,
            'hari'            => $slot->hari,
            'tanggal'         => $slot->tanggal?->format('Y-m-d'),
            'waktu_mulai'     => substr((string) $slot->waktu_mulai, 0, 5),
            'waktu_selesai'   => substr((string) $slot->waktu_selesai, 0, 5),
            'is_available'    => (bool) $slot->is_available,
            'catatan'         => $slot->catatan,
        ];
    }
}
