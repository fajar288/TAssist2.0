<?php
// app/Http/Controllers/Web/Dosen/DokumenFeedbackController.php

namespace App\Http\Controllers\Web\Dosen;

use App\Http\Controllers\Controller;
use App\Models\Bimbingan;
use App\Models\DokumenTA;
use App\Models\FeedbackDokumen;
use App\Models\VersiDokumen;
use App\Services\NotifikasiService;
use Illuminate\Http\Request;

class DokumenFeedbackController extends Controller
{
    public function index(Request $request)
    {
        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];

        $search = trim((string) $request->query('search'));
        $bimbinganId = $request->query('bimbingan_id');

        $bimbinganList = Bimbingan::with(['mahasiswa.user'])
            ->where('dosen_id', $dosenId)
            ->where('status_bimbingan', 'aktif')
            ->orderByDesc('tanggal_mulai')
            ->get();

        $query = DokumenTA::with([
                'bimbingan.mahasiswa.user',
                'bimbingan.permohonan',
                'versiTerbaru',
                'versiDokumen.feedbackDokumen',
            ])
            ->whereHas('bimbingan', function ($q) use ($dosenId) {
                $q->where('dosen_id', $dosenId);
            });

        if ($bimbinganId) {
            $query->where('bimbingan_id', $bimbinganId);
        }

        if ($search !== '') {
            $query->where(function ($q) use ($search) {
                $q->where('judul_dokumen', 'like', "%{$search}%")
                    ->orWhere('jenis_dokumen', 'like', "%{$search}%")
                    ->orWhere('deskripsi', 'like', "%{$search}%")
                    ->orWhereHas('bimbingan.mahasiswa.user', function ($userQuery) use ($search) {
                        $userQuery->where('nama', 'like', "%{$search}%")
                            ->orWhere('email', 'like', "%{$search}%");
                    })
                    ->orWhereHas('bimbingan.mahasiswa', function ($mahasiswaQuery) use ($search) {
                        $mahasiswaQuery->where('nim', 'like', "%{$search}%")
                            ->orWhere('prodi', 'like', "%{$search}%")
                            ->orWhere('judul_ta', 'like', "%{$search}%")
                            ->orWhere('topik_ta', 'like', "%{$search}%");
                    });
            });
        }

        $dokumen = $query
            ->orderByDesc('updated_at')
            ->orderByDesc('created_at')
            ->paginate(10)
            ->withQueryString();

        $stats = [
            'total_dokumen' => DokumenTA::whereHas('bimbingan', fn($q) => $q->where('dosen_id', $dosenId))->count(),

            'total_versi' => VersiDokumen::whereHas('dokumen.bimbingan', fn($q) => $q->where('dosen_id', $dosenId))->count(),

            'feedback_saya' => FeedbackDokumen::where('dosen_id', $dosenId)->count(),

            'dokumen_belum_feedback' => DokumenTA::whereHas('bimbingan', fn($q) => $q->where('dosen_id', $dosenId))
                ->whereHas('versiDokumen')
                ->whereDoesntHave('versiDokumen.feedbackDokumen', fn($q) => $q->where('dosen_id', $dosenId))
                ->count(),
        ];

        return view('dosen.dokumen.index', compact(
            'dokumen',
            'bimbinganList',
            'search',
            'bimbinganId',
            'stats'
        ));
    }

    public function show(int $id)
    {
        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];

        $dokumen = DokumenTA::with([
                'bimbingan.mahasiswa.user',
                'bimbingan.permohonan',
                'versiDokumen' => function ($q) {
                    $q->orderByDesc('nomor_versi');
                },
                'versiDokumen.uploader',
                'versiDokumen.feedbackDokumen.dosen.user',
            ])
            ->whereHas('bimbingan', function ($q) use ($dosenId) {
                $q->where('dosen_id', $dosenId);
            })
            ->where('dokumen_id', $id)
            ->firstOrFail();

        return view('dosen.dokumen.show', compact('dokumen'));
    }

    public function storeFeedback(Request $request)
    {
        $request->validate([
            'versi_id'       => 'required|integer|exists:versi_dokumen,versi_id',
            'komentar'       => 'required|string|max:2000',
            'halaman'        => 'nullable|integer|min:1',
            'posisi_anotasi' => 'nullable|string|max:255',
        ], [
            'versi_id.required' => 'Versi dokumen wajib dipilih.',
            'versi_id.exists'   => 'Versi dokumen tidak ditemukan.',
            'komentar.required' => 'Komentar feedback wajib diisi.',
            'komentar.max'      => 'Komentar maksimal 2000 karakter.',
            'halaman.integer'   => 'Halaman harus berupa angka.',
            'halaman.min'       => 'Halaman minimal 1.',
        ]);

        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];

        $versi = VersiDokumen::with([
                'dokumen.bimbingan.mahasiswa.user',
            ])
            ->where('versi_id', $request->versi_id)
            ->firstOrFail();

        $bimbingan = $versi->dokumen->bimbingan;

        if ((int) $bimbingan->dosen_id !== (int) $dosenId) {
            return back()->with('error', 'Anda hanya dapat memberi feedback pada dokumen mahasiswa bimbingan Anda.');
        }

        $feedback = FeedbackDokumen::create([
            'versi_id'       => $versi->versi_id,
            'dosen_id'       => $dosenId,
            'komentar'       => $request->komentar,
            'halaman'        => $request->halaman,
            'posisi_anotasi' => $request->posisi_anotasi,
        ]);

        $mahasiswa = $bimbingan->mahasiswa;

        NotifikasiService::kirim(
            userId   : $mahasiswa->user_id,
            tipe     : 'feedback_dokumen',
            judul    : 'Feedback Dokumen Baru',
            pesan    : "Dosen {$dosenSession['nama']} memberikan feedback pada dokumen: {$versi->dokumen->judul_dokumen} (Versi {$versi->nomor_versi})",
            refTabel : 'feedback_dokumen',
            refId    : $feedback->feedback_id
        );

        return redirect()
            ->route('dosen.dokumen.show', $versi->dokumen_id)
            ->with('success', 'Feedback berhasil dikirim.');
    }
}