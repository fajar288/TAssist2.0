<?php
// app/Http/Controllers/Web/Dosen/ProgressChecklistController.php

namespace App\Http\Controllers\Web\Dosen;

use App\Http\Controllers\Controller;
use App\Models\Bimbingan;
use App\Models\ChecklistProgress;
use App\Models\ProgresTA;
use App\Services\NotifikasiService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProgressChecklistController extends Controller
{
    public function index(Request $request)
    {
        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];

        $search = trim((string) $request->query('search'));
        $status = $request->query('status');

        $query = Bimbingan::with([
                'mahasiswa.user',
                'permohonan',
                'progresAktif.checklistProgress',
            ])
            ->where('dosen_id', $dosenId);

        if ($status && in_array($status, ['aktif', 'selesai', 'nonaktif'])) {
            $query->where('status_bimbingan', $status);
        }

        if ($search !== '') {
            $query->where(function ($q) use ($search) {
                $q->whereHas('mahasiswa.user', function ($userQuery) use ($search) {
                    $userQuery->where('nama', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%");
                })
                ->orWhereHas('mahasiswa', function ($mahasiswaQuery) use ($search) {
                    $mahasiswaQuery->where('nim', 'like', "%{$search}%")
                        ->orWhere('prodi', 'like', "%{$search}%")
                        ->orWhere('judul_ta', 'like', "%{$search}%")
                        ->orWhere('topik_ta', 'like', "%{$search}%");
                })
                ->orWhereHas('permohonan', function ($permohonanQuery) use ($search) {
                    $permohonanQuery->where('topik_ta', 'like', "%{$search}%");
                });
            });
        }

        $bimbingan = $query
            ->orderByRaw("FIELD(status_bimbingan, 'aktif', 'selesai', 'nonaktif')")
            ->orderByDesc('tanggal_mulai')
            ->paginate(10)
            ->withQueryString();

        $totalBimbingan = Bimbingan::where('dosen_id', $dosenId)->count();

        $avgProgress = DB::table('progres_ta')
            ->join('bimbingan', 'progres_ta.bimbingan_id', '=', 'bimbingan.bimbingan_id')
            ->where('bimbingan.dosen_id', $dosenId)
            ->whereIn('progres_ta.progress_id', function ($subQuery) {
                $subQuery->selectRaw('MAX(progress_id)')
                    ->from('progres_ta')
                    ->groupBy('bimbingan_id');
            })
            ->avg('progres_ta.persentase');

        $stats = [
            'total_bimbingan' => $totalBimbingan,
            'aktif' => Bimbingan::where('dosen_id', $dosenId)
                ->where('status_bimbingan', 'aktif')
                ->count(),
            'rata_progress' => round((float) $avgProgress, 1),
            'total_checklist' => ChecklistProgress::whereHas(
                'progresTA.bimbingan',
                fn($q) => $q->where('dosen_id', $dosenId)
            )->count(),
        ];

        return view('dosen.progress-checklist.index', compact(
            'bimbingan',
            'search',
            'status',
            'stats'
        ));
    }

    public function show(int $bimbinganId)
    {
        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];

        $bimbingan = Bimbingan::with([
                'mahasiswa.user',
                'dosen.user',
                'permohonan',
                'progresTA.checklistProgress',
                'progresTA.updatedDosen.user',
            ])
            ->where('bimbingan_id', $bimbinganId)
            ->where('dosen_id', $dosenId)
            ->firstOrFail();

        $progressHistory = $bimbingan->progresTA
            ->sortByDesc(fn($p) => (($p->updated_at?->timestamp ?? 0) * 1000000) + (int) $p->progress_id)
            ->values();

        $latestProgress = $progressHistory->first();

        $latestChecklist = $latestProgress
            ? $latestProgress->checklistProgress
                ->sortBy('tgl_selesai')
                ->sortByDesc('created_at')
                ->values()
            : collect();

        $checklistSummary = [
            'total' => $latestChecklist->count(),
            'selesai' => $latestChecklist->where('tgl_selesai', true)->count(),
        ];

        return view('dosen.progress-checklist.show', compact(
            'bimbingan',
            'progressHistory',
            'latestProgress',
            'latestChecklist',
            'checklistSummary'
        ));
    }

    public function storeProgress(Request $request, int $bimbinganId)
    {
        $request->validate([
            'persentase'      => 'required|numeric|min:0|max:100',
            'status_progress' => 'required|string|max:100',
            'catatan'         => 'nullable|string|max:1000',
        ], [
            'persentase.required'      => 'Persentase wajib diisi.',
            'persentase.numeric'       => 'Persentase harus berupa angka.',
            'persentase.min'           => 'Persentase minimal 0.',
            'persentase.max'           => 'Persentase maksimal 100.',
            'status_progress.required' => 'Status progress wajib diisi.',
            'status_progress.max'      => 'Status progress maksimal 100 karakter.',
            'catatan.max'              => 'Catatan maksimal 1000 karakter.',
        ]);

        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];

        $bimbingan = Bimbingan::with(['mahasiswa.user'])
            ->where('bimbingan_id', $bimbinganId)
            ->where('dosen_id', $dosenId)
            ->first();

        if (!$bimbingan) {
            return back()->with('error', 'Bimbingan tidak ditemukan atau bukan milik Anda.');
        }

        if (!$bimbingan->isAktif()) {
            return back()->with('error', 'Tidak dapat mengupdate progres bimbingan yang tidak aktif.');
        }

        $progres = ProgresTA::create([
            'bimbingan_id'     => $bimbingan->bimbingan_id,
            'persentase'       => $request->persentase,
            'status_progress'  => $request->status_progress,
            'updated_dosen_id' => $dosenId,
            'catatan'          => $request->catatan,
        ]);

        NotifikasiService::kirim(
            userId   : $bimbingan->mahasiswa->user_id,
            tipe     : 'update_progres',
            judul    : 'Progres TA Diperbarui',
            pesan    : "Dosen {$dosenSession['nama']} memperbarui progres TA Anda menjadi {$request->persentase}% - {$request->status_progress}",
            refTabel : 'progres_ta',
            refId    : $progres->progress_id
        );

        return redirect()
            ->route('dosen.progress-checklist.show', $bimbingan->bimbingan_id)
            ->with('success', 'Progress TA berhasil diperbarui.');
    }

    public function storeChecklist(Request $request, int $bimbinganId)
    {
        $request->validate([
            'nama_item'       => 'required|string|max:255',
            'tgl_selesai'     => 'nullable|boolean',
            'tanggal_selesai' => 'nullable|date',
            'catatan'         => 'nullable|string|max:500',
        ], [
            'nama_item.required' => 'Nama item checklist wajib diisi.',
            'nama_item.max'      => 'Nama item checklist maksimal 255 karakter.',
            'catatan.max'        => 'Catatan maksimal 500 karakter.',
        ]);

        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];

        $bimbingan = Bimbingan::with(['mahasiswa.user'])
            ->where('bimbingan_id', $bimbinganId)
            ->where('dosen_id', $dosenId)
            ->first();

        if (!$bimbingan) {
            return back()->with('error', 'Bimbingan tidak ditemukan atau bukan milik Anda.');
        }

        if (!$bimbingan->isAktif()) {
            return back()->with('error', 'Tidak dapat menambahkan checklist pada bimbingan yang tidak aktif.');
        }

        $latestProgress = $this->getLatestProgress($bimbingan);

        if (!$latestProgress) {
            $latestProgress = ProgresTA::create([
                'bimbingan_id'     => $bimbingan->bimbingan_id,
                'persentase'       => 0,
                'status_progress'  => 'Target awal bimbingan',
                'updated_dosen_id' => $dosenId,
                'catatan'          => 'Progress awal dibuat otomatis untuk checklist target mahasiswa.',
            ]);
        }

        $isDone = $request->boolean('tgl_selesai');

        $checklist = ChecklistProgress::create([
            'progress_id'     => $latestProgress->progress_id,
            'nama_item'       => $request->nama_item,
            'tgl_selesai'     => $isDone,
            'tanggal_selesai' => $isDone
                ? ($request->tanggal_selesai ?? now()->toDateString())
                : null,
            'catatan'         => $request->catatan,
        ]);

        NotifikasiService::kirim(
            userId   : $bimbingan->mahasiswa->user_id,
            tipe     : 'checklist_baru',
            judul    : 'Item Checklist Baru Ditambahkan',
            pesan    : "Dosen menambahkan item checklist: {$request->nama_item}",
            refTabel : 'checklist_progress',
            refId    : $checklist->checklist_id
        );

        return redirect()
            ->route('dosen.progress-checklist.show', $bimbingan->bimbingan_id)
            ->with('success', 'Checklist berhasil ditambahkan.');
    }

    public function updateChecklist(Request $request, int $id)
    {
        $request->validate([
            'nama_item'       => 'required|string|max:255',
            'tgl_selesai'     => 'nullable|boolean',
            'tanggal_selesai' => 'nullable|date',
            'catatan'         => 'nullable|string|max:500',
        ], [
            'nama_item.required' => 'Nama item checklist wajib diisi.',
            'nama_item.max'      => 'Nama item checklist maksimal 255 karakter.',
            'catatan.max'        => 'Catatan maksimal 500 karakter.',
        ]);

        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];

        $checklist = ChecklistProgress::with(['progresTA.bimbingan.mahasiswa.user'])
            ->whereHas('progresTA.bimbingan', fn($q) => $q->where('dosen_id', $dosenId))
            ->where('checklist_id', $id)
            ->first();

        if (!$checklist) {
            return back()->with('error', 'Checklist tidak ditemukan atau bukan milik bimbingan Anda.');
        }

        $wasDone = (bool) $checklist->tgl_selesai;
        $isDone = $request->boolean('tgl_selesai');

        $checklist->update([
            'nama_item'       => $request->nama_item,
            'tgl_selesai'     => $isDone,
            'tanggal_selesai' => $isDone
                ? ($request->tanggal_selesai ?? $checklist->tanggal_selesai ?? now()->toDateString())
                : null,
            'catatan'         => $request->catatan,
        ]);

        $checklist->refresh();

        if (!$wasDone && $checklist->tgl_selesai) {
            $mahasiswaUserId = $checklist->progresTA->bimbingan->mahasiswa->user_id;

            NotifikasiService::kirim(
                userId   : $mahasiswaUserId,
                tipe     : 'checklist_selesai',
                judul    : 'Item Checklist Selesai',
                pesan    : "Item checklist \"{$checklist->nama_item}\" telah ditandai selesai oleh dosen.",
                refTabel : 'checklist_progress',
                refId    : $checklist->checklist_id
            );
        }

        return redirect()
            ->route('dosen.progress-checklist.show', $checklist->progresTA->bimbingan_id)
            ->with('success', 'Checklist berhasil diperbarui.');
    }

    public function destroyChecklist(int $id)
    {
        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];

        $checklist = ChecklistProgress::with(['progresTA'])
            ->whereHas('progresTA.bimbingan', fn($q) => $q->where('dosen_id', $dosenId))
            ->where('checklist_id', $id)
            ->first();

        if (!$checklist) {
            return back()->with('error', 'Checklist tidak ditemukan atau bukan milik bimbingan Anda.');
        }

        $bimbinganId = $checklist->progresTA->bimbingan_id;
        $namaItem = $checklist->nama_item;

        $checklist->delete();

        return redirect()
            ->route('dosen.progress-checklist.show', $bimbinganId)
            ->with('success', "Checklist \"{$namaItem}\" berhasil dihapus.");
    }

    private function getLatestProgress(Bimbingan $bimbingan): ?ProgresTA
    {
        return $bimbingan->progresTA()
            ->orderByDesc('updated_at')
            ->orderByDesc('progress_id')
            ->first();
    }
}