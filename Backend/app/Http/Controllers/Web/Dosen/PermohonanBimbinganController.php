<?php
// app/Http/Controllers/Web/Dosen/PermohonanBimbinganController.php

namespace App\Http\Controllers\Web\Dosen;

use App\Http\Controllers\Controller;
use App\Models\Bimbingan;
use App\Models\PermohonanBimbingan;
use App\Services\NotifikasiService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PermohonanBimbinganController extends Controller
{
    public function index(Request $request)
    {
        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];

        $status = $request->query('status');

        $query = PermohonanBimbingan::with(['mahasiswa.user', 'dosen.user'])
            ->where('dosen_id', $dosenId);

        if ($status && in_array($status, ['menunggu', 'diterima', 'ditolak'])) {
            $query->where('status', $status);
        }

        $permohonan = $query
            ->orderByRaw("FIELD(status, 'menunggu', 'diterima', 'ditolak')")
            ->orderByDesc('tanggal_pengajuan')
            ->paginate(10)
            ->withQueryString();

        $stats = [
            'semua' => PermohonanBimbingan::where('dosen_id', $dosenId)->count(),
            'menunggu' => PermohonanBimbingan::where('dosen_id', $dosenId)->where('status', 'menunggu')->count(),
            'diterima' => PermohonanBimbingan::where('dosen_id', $dosenId)->where('status', 'diterima')->count(),
            'ditolak' => PermohonanBimbingan::where('dosen_id', $dosenId)->where('status', 'ditolak')->count(),
        ];

        return view('dosen.permohonan.index', compact(
            'permohonan',
            'status',
            'stats'
        ));
    }

    public function show(int $id)
    {
        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];

        $permohonan = PermohonanBimbingan::with(['mahasiswa.user', 'dosen.user', 'bimbingan'])
            ->where('permohonan_id', $id)
            ->where('dosen_id', $dosenId)
            ->firstOrFail();

        return view('dosen.permohonan.show', compact('permohonan'));
    }

    public function terima(int $id)
    {
        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];

        $permohonan = PermohonanBimbingan::with(['mahasiswa.user', 'dosen.user'])
            ->where('permohonan_id', $id)
            ->where('dosen_id', $dosenId)
            ->first();

        if (!$permohonan) {
            return back()->with('error', 'Permohonan tidak ditemukan atau bukan milik Anda.');
        }

        if (!$permohonan->isMenunggu()) {
            return back()->with('error', 'Permohonan ini sudah diproses sebelumnya.');
        }

        $dosen = $permohonan->dosen;
        $dosen->refresh();

        if (!$dosen->masihAdaKuota()) {
            return back()->with('error', 'Kuota bimbingan Anda sudah penuh. Tidak dapat menerima permohonan.');
        }

        $mahasiswa = $permohonan->mahasiswa;

        if ($mahasiswa->bimbinganAktif()->exists()) {
            return back()->with('error', 'Mahasiswa ini sudah memiliki bimbingan aktif.');
        }

        DB::beginTransaction();

        try {
            $permohonan->update([
                'status' => 'diterima',
            ]);

            $bimbingan = Bimbingan::create([
                'permohonan_id'    => $permohonan->permohonan_id,
                'mahasiswa_id'     => $permohonan->mahasiswa_id,
                'dosen_id'         => $dosenId,
                'tanggal_mulai'    => now()->toDateString(),
                'status_bimbingan' => 'aktif',
            ]);

            $bimbingan->progresTA()->create([
                'bimbingan_id'     => $bimbingan->bimbingan_id,
                'persentase'       => 0,
                'status_progress'  => 'baru dimulai',
                'updated_dosen_id' => $dosenId,
                'catatan'          => 'Bimbingan dimulai.',
            ]);

            DB::commit();

            NotifikasiService::kirim(
                userId   : $mahasiswa->user_id,
                tipe     : 'permohonan_diterima',
                judul    : 'Permohonan Bimbingan Diterima',
                pesan    : "Selamat! Permohonan bimbingan Anda telah diterima oleh Dosen {$dosenSession['nama']}. Bimbingan Anda telah dimulai.",
                refTabel : 'bimbingan',
                refId    : $bimbingan->bimbingan_id
            );

            return redirect()
                ->route('dosen.permohonan.index')
                ->with('success', 'Permohonan berhasil diterima dan bimbingan aktif berhasil dibuat.');

        } catch (\Exception $e) {
            DB::rollBack();

            return back()->with('error', 'Gagal menerima permohonan: ' . $e->getMessage());
        }
    }

    public function tolak(Request $request, int $id)
    {
        $request->validate([
            'catatan_respons' => 'required|string|max:1000',
        ], [
            'catatan_respons.required' => 'Alasan penolakan wajib diisi.',
            'catatan_respons.max' => 'Alasan penolakan maksimal 1000 karakter.',
        ]);

        $dosenSession = session('dosen_user');
        $dosenId = $dosenSession['dosen_id'];

        $permohonan = PermohonanBimbingan::with(['mahasiswa.user'])
            ->where('permohonan_id', $id)
            ->where('dosen_id', $dosenId)
            ->first();

        if (!$permohonan) {
            return back()->with('error', 'Permohonan tidak ditemukan atau bukan milik Anda.');
        }

        if (!$permohonan->isMenunggu()) {
            return back()->with('error', 'Permohonan ini sudah diproses sebelumnya.');
        }

        $permohonan->update([
            'status'          => 'ditolak',
            'catatan_respons' => $request->catatan_respons,
        ]);

        NotifikasiService::kirim(
            userId   : $permohonan->mahasiswa->user_id,
            tipe     : 'permohonan_ditolak',
            judul    : 'Permohonan Bimbingan Ditolak',
            pesan    : "Permohonan bimbingan Anda ditolak oleh Dosen {$dosenSession['nama']}. Alasan: {$request->catatan_respons}",
            refTabel : 'permohonan_bimbingan',
            refId    : $permohonan->permohonan_id
        );

        return redirect()
            ->route('dosen.permohonan.index')
            ->with('success', 'Permohonan berhasil ditolak.');
    }
}