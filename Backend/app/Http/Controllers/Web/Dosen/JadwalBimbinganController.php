<?php
// app/Http/Controllers/Web/Dosen/JadwalBimbinganController.php

namespace App\Http\Controllers\Web\Dosen;

use App\Http\Controllers\Controller;
use App\Models\Bimbingan;
use App\Models\JadwalBimbingan;
use App\Services\NotifikasiService;
use Illuminate\Http\Request;

class JadwalBimbinganController extends Controller
{
    public function index(Request $request)
    {
        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];

        $status = $request->query('status');
        $search = trim((string) $request->query('search'));

        $query = JadwalBimbingan::with([
                'bimbingan.mahasiswa.user',
                'pengaju',
            ])
            ->whereHas('bimbingan', function ($q) use ($dosenId) {
                $q->where('dosen_id', $dosenId);
            });

        if ($status && in_array($status, ['menunggu', 'dikonfirmasi', 'ditolak'])) {
            $query->where('status_konfirmasi', $status);
        }

        if ($search !== '') {
            $query->where(function ($q) use ($search) {
                $q->where('catatan', 'like', "%{$search}%")
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

        $jadwal = $query
            ->orderByRaw("FIELD(status_konfirmasi, 'menunggu', 'dikonfirmasi', 'ditolak')")
            ->orderByDesc('tanggal')
            ->orderByDesc('waktu_mulai')
            ->paginate(10)
            ->withQueryString();

        $stats = [
            'semua' => JadwalBimbingan::whereHas('bimbingan', fn($q) => $q->where('dosen_id', $dosenId))->count(),
            'menunggu' => JadwalBimbingan::whereHas('bimbingan', fn($q) => $q->where('dosen_id', $dosenId))
                ->where('status_konfirmasi', 'menunggu')
                ->count(),
            'dikonfirmasi' => JadwalBimbingan::whereHas('bimbingan', fn($q) => $q->where('dosen_id', $dosenId))
                ->where('status_konfirmasi', 'dikonfirmasi')
                ->count(),
            'ditolak' => JadwalBimbingan::whereHas('bimbingan', fn($q) => $q->where('dosen_id', $dosenId))
                ->where('status_konfirmasi', 'ditolak')
                ->count(),
        ];

        return view('dosen.jadwal.index', compact(
            'jadwal',
            'status',
            'search',
            'stats'
        ));
    }

    public function create(Request $request)
    {
        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];

        $selectedBimbinganId = $request->query('bimbingan_id');

        $bimbinganAktif = Bimbingan::with(['mahasiswa.user'])
            ->where('dosen_id', $dosenId)
            ->where('status_bimbingan', 'aktif')
            ->orderByDesc('tanggal_mulai')
            ->get();

        return view('dosen.jadwal.create', compact(
            'bimbinganAktif',
            'selectedBimbinganId'
        ));
    }

    public function store(Request $request)
    {
        $request->validate([
            'bimbingan_id'  => 'required|integer|exists:bimbingan,bimbingan_id',
            'tanggal'       => 'required|date|after_or_equal:today',
            'waktu_mulai'   => 'required|date_format:H:i',
            'waktu_selesai' => 'required|date_format:H:i|after:waktu_mulai',
            'mode'          => 'required|in:online,offline',
            'catatan'       => 'nullable|string|max:1000',
        ], [
            'bimbingan_id.required'  => 'Mahasiswa bimbingan wajib dipilih.',
            'bimbingan_id.exists'    => 'Data bimbingan tidak ditemukan.',
            'tanggal.required'       => 'Tanggal wajib diisi.',
            'tanggal.after_or_equal' => 'Tanggal tidak boleh di masa lampau.',
            'waktu_mulai.required'   => 'Waktu mulai wajib diisi.',
            'waktu_selesai.required' => 'Waktu selesai wajib diisi.',
            'waktu_selesai.after'    => 'Waktu selesai harus setelah waktu mulai.',
            'mode.required'          => 'Mode bimbingan wajib dipilih.',
            'mode.in'                => 'Mode harus online atau offline.',
        ]);

        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];
        $userId = $dosenSession['user_id'];

        $bimbingan = Bimbingan::with(['mahasiswa.user'])
            ->where('bimbingan_id', $request->bimbingan_id)
            ->where('dosen_id', $dosenId)
            ->where('status_bimbingan', 'aktif')
            ->first();

        if (!$bimbingan) {
            return back()
                ->withInput()
                ->with('error', 'Bimbingan tidak ditemukan atau tidak aktif.');
        }

        $jadwal = JadwalBimbingan::create([
            'bimbingan_id'      => $bimbingan->bimbingan_id,
            'pengaju_user_id'   => $userId,
            'tanggal'           => $request->tanggal,
            'waktu_mulai'       => $request->waktu_mulai,
            'waktu_selesai'     => $request->waktu_selesai,
            'mode'              => $request->mode,
            'status_konfirmasi' => 'menunggu',
            'catatan'           => $request->catatan,
        ]);

        NotifikasiService::kirim(
            userId   : $bimbingan->mahasiswa->user_id,
            tipe     : 'jadwal_bimbingan',
            judul    : 'Jadwal Bimbingan Baru dari Dosen',
            pesan    : "Dosen {$dosenSession['nama']} mengajukan jadwal bimbingan pada {$jadwal->tanggal->format('Y-m-d')} pukul {$jadwal->waktu_mulai}. Mohon konfirmasi.",
            refTabel : 'jadwal_bimbingan',
            refId    : $jadwal->jadwal_id
        );

        return redirect()
            ->route('dosen.jadwal.show', $jadwal->jadwal_id)
            ->with('success', 'Jadwal bimbingan berhasil dibuat.');
    }

    public function show(int $id)
    {
        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];
        $userId = $dosenSession['user_id'];

        $jadwal = JadwalBimbingan::with([
                'bimbingan.mahasiswa.user',
                'bimbingan.permohonan',
                'pengaju',
            ])
            ->whereHas('bimbingan', fn($q) => $q->where('dosen_id', $dosenId))
            ->where('jadwal_id', $id)
            ->firstOrFail();

        $canKonfirmasi = $jadwal->status_konfirmasi === 'menunggu'
            && (int) $jadwal->pengaju_user_id !== (int) $userId;

        return view('dosen.jadwal.show', compact(
            'jadwal',
            'canKonfirmasi'
        ));
    }

    public function konfirmasi(Request $request, int $id)
    {
        $request->validate([
            'mode'    => 'required|in:online,offline',
            'catatan' => 'nullable|string|max:500',
        ], [
            'mode.required' => 'Mode bimbingan wajib dipilih sebelum mengkonfirmasi jadwal.',
            'mode.in'       => 'Mode harus online atau offline.',
            'catatan.max'   => 'Catatan maksimal 500 karakter.',
        ]);

        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];
        $userId = $dosenSession['user_id'];

        $jadwal = JadwalBimbingan::with(['bimbingan.mahasiswa.user'])
            ->whereHas('bimbingan', fn($q) => $q->where('dosen_id', $dosenId))
            ->where('jadwal_id', $id)
            ->first();

        if (!$jadwal) {
            return back()->with('error', 'Jadwal tidak ditemukan atau bukan milik Anda.');
        }

        if ($jadwal->status_konfirmasi !== 'menunggu') {
            return back()->with('error', 'Jadwal ini sudah diproses sebelumnya.');
        }

        if ((int) $jadwal->pengaju_user_id === (int) $userId) {
            return back()->with('error', 'Anda tidak dapat mengkonfirmasi jadwal yang Anda ajukan sendiri.');
        }

        $jadwal->update([
            'status_konfirmasi' => 'dikonfirmasi',
            'mode'              => $request->mode,
            'catatan'           => $request->catatan ?? $jadwal->catatan,
        ]);

        $mahasiswa = $jadwal->bimbingan->mahasiswa;

        NotifikasiService::kirim(
            userId   : $mahasiswa->user_id,
            tipe     : 'konfirmasi_jadwal',
            judul    : 'Update Status Jadwal Bimbingan',
            pesan    : "Jadwal bimbingan Anda pada {$jadwal->tanggal->format('Y-m-d')} pukul {$jadwal->waktu_mulai} telah dikonfirmasi oleh dosen. Mode bimbingan: {$jadwal->mode}.",
            refTabel : 'jadwal_bimbingan',
            refId    : $jadwal->jadwal_id
        );

        return redirect()
            ->route('dosen.jadwal.show', $jadwal->jadwal_id)
            ->with('success', 'Jadwal berhasil dikonfirmasi.');
    }

    public function tolak(Request $request, int $id)
    {
        $request->validate([
            'catatan' => 'required|string|max:500',
        ], [
            'catatan.required' => 'Catatan penolakan wajib diisi.',
            'catatan.max'      => 'Catatan maksimal 500 karakter.',
        ]);

        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];
        $userId = $dosenSession['user_id'];

        $jadwal = JadwalBimbingan::with(['bimbingan.mahasiswa.user'])
            ->whereHas('bimbingan', fn($q) => $q->where('dosen_id', $dosenId))
            ->where('jadwal_id', $id)
            ->first();

        if (!$jadwal) {
            return back()->with('error', 'Jadwal tidak ditemukan atau bukan milik Anda.');
        }

        if ($jadwal->status_konfirmasi !== 'menunggu') {
            return back()->with('error', 'Jadwal ini sudah diproses sebelumnya.');
        }

        if ((int) $jadwal->pengaju_user_id === (int) $userId) {
            return back()->with('error', 'Anda tidak dapat menolak jadwal yang Anda ajukan sendiri.');
        }

        $jadwal->update([
            'status_konfirmasi' => 'ditolak',
            'catatan'           => $request->catatan,
        ]);

        $mahasiswa = $jadwal->bimbingan->mahasiswa;

        NotifikasiService::kirim(
            userId   : $mahasiswa->user_id,
            tipe     : 'konfirmasi_jadwal',
            judul    : 'Update Status Jadwal Bimbingan',
            pesan    : "Jadwal bimbingan Anda pada {$jadwal->tanggal->format('Y-m-d')} pukul {$jadwal->waktu_mulai} telah ditolak oleh dosen. Catatan: {$request->catatan}",
            refTabel : 'jadwal_bimbingan',
            refId    : $jadwal->jadwal_id
        );

        return redirect()
            ->route('dosen.jadwal.show', $jadwal->jadwal_id)
            ->with('success', 'Jadwal berhasil ditolak.');
    }
}