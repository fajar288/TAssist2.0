<?php
// app/Http/Controllers/Web/Admin/InformasiTAController.php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\Admin;
use App\Models\InformasiTA;
use App\Models\Notifikasi;
use App\Models\User;
use App\Services\NotifikasiService;
use Illuminate\Http\Request;

class InformasiTAController extends Controller
{
    // ==================== Helper ambil admin dari session ====================
    private function getAdminFromSession(): ?Admin
    {
        $adminData = session('admin_user');
        if (!$adminData) return null;

        return Admin::find($adminData['admin_id']);
    }

    // ==================== INDEX ====================
    public function index(Request $request)
    {
        $query = InformasiTA::with('admin.user')
            ->when($request->filled('search'), fn($q) =>
                $q->where('judul', 'like', '%'.$request->search.'%')
                  ->orWhere('konten_or_file', 'like', '%'.$request->search.'%')
            )
            ->when($request->filled('status'), function ($q) use ($request) {
                if ($request->status === 'published') {
                    $q->whereNotNull('published_at')
                      ->where('published_at', '<=', now());
                } elseif ($request->status === 'draft') {
                    $q->where(function ($q2) {
                        $q2->whereNull('published_at')
                           ->orWhere('published_at', '>', now());
                    });
                }
            })
            ->when($request->filled('kategori'), fn($q) =>
                $q->where('kategori', $request->kategori)
            )
            ->orderByDesc('created_at');

        $totalInfo = InformasiTA::count();
        $published = InformasiTA::whereNotNull('published_at')
            ->where('published_at', '<=', now())
            ->count();

        $drafts = $totalInfo - $published;

        $infos = $query->paginate(15)->withQueryString();

        $kategoriList = InformasiTA::whereNotNull('kategori')
            ->distinct()
            ->pluck('kategori')
            ->sort()
            ->values();

        return view('admin.informasi-ta.index', compact(
            'infos',
            'totalInfo',
            'published',
            'drafts',
            'kategoriList'
        ));
    }

    // ==================== STORE ====================
    public function store(Request $request)
    {
        $request->validate([
            'judul'          => 'required|string|max:255',
            'kategori'       => 'required|string|max:100',
            'konten_or_file' => 'required|string',
            'published_at'   => 'nullable|date',
        ], [
            'judul.required'          => 'Judul wajib diisi.',
            'kategori.required'       => 'Kategori wajib diisi.',
            'konten_or_file.required' => 'Konten wajib diisi.',
        ]);

        $admin = $this->getAdminFromSession();

        if (!$admin) {
            return back()
                ->with('error', 'Sesi admin tidak ditemukan. Silakan login ulang.')
                ->withInput();
        }

        // Draft harus benar-benar draft.
        // Jadi published_at hanya diisi kalau admin memilih publish.
        $publishedAt = null;

        if ($request->boolean('is_published')) {
            $publishedAt = $request->filled('published_at')
                ? $request->published_at
                : now()->toDateTimeString();
        }

        $info = InformasiTA::create([
            'admin_id'       => $admin->admin_id,
            'kategori'       => $request->kategori,
            'judul'          => $request->judul,
            'konten_or_file' => $request->konten_or_file,
            'published_at'   => $publishedAt,
        ]);

        $info->refresh();

        // Kirim notifikasi hanya kalau statusnya benar-benar published sekarang.
        if ($this->isPublishedNow($info)) {
            $this->kirimNotifikasiInformasiTA($info);
        }

        return redirect()->route('admin.informasi-ta.index')
            ->with('success', 'Informasi TA berhasil ditambahkan.');
    }

    // ==================== UPDATE ====================
    public function update(Request $request, int $id)
    {
        $request->validate([
            'judul'          => 'required|string|max:255',
            'kategori'       => 'required|string|max:100',
            'konten_or_file' => 'required|string',
            'published_at'   => 'nullable|date',
        ]);

        $info = InformasiTA::findOrFail($id);
        $wasPublished = $this->isPublishedNow($info);

        // Kalau checkbox publish tidak aktif, anggap draft/unpublished.
        $publishedAt = null;

        if ($request->boolean('is_published')) {
            $publishedAt = $request->filled('published_at')
                ? $request->published_at
                : now()->toDateTimeString();
        }

        $info->update([
            'kategori'       => $request->kategori,
            'judul'          => $request->judul,
            'konten_or_file' => $request->konten_or_file,
            'published_at'   => $publishedAt,
        ]);

        $info->refresh();
        $nowPublished = $this->isPublishedNow($info);

        if (!$wasPublished && $nowPublished) {
            // Draft -> Published: kirim notifikasi sekali.
            $this->kirimNotifikasiInformasiTA($info);
        } elseif ($wasPublished && !$nowPublished) {
            // Published -> Draft: hapus notifikasi agar tidak terekspos lagi.
            $this->hapusNotifikasiInformasiTA($info);
        } elseif ($wasPublished && $nowPublished) {
            // Published -> Published: update isi notifikasi lama, jangan buat dobel.
            $this->updateNotifikasiInformasiTA($info);
        }

        return redirect()->route('admin.informasi-ta.index')
            ->with('success', 'Informasi TA berhasil diperbarui.');
    }

    // ==================== DESTROY ====================
    public function destroy(int $id)
    {
        $info = InformasiTA::findOrFail($id);
        $judul = $info->judul;

        $this->hapusNotifikasiInformasiTA($info);

        $info->delete();

        return redirect()->route('admin.informasi-ta.index')
            ->with('success', "Informasi \"{$judul}\" berhasil dihapus.");
    }

    // ==================== TOGGLE PUBLISH ====================
    public function togglePublish(int $id)
    {
        $info = InformasiTA::findOrFail($id);
        $isPublished = $this->isPublishedNow($info);

        if ($isPublished) {
            $info->update(['published_at' => null]);
            $info->refresh();

            // Saat unpublish, notifikasi terkait ikut dihapus.
            $this->hapusNotifikasiInformasiTA($info);

            return back()->with('success', "Informasi \"{$info->judul}\" berhasil di-unpublish.");
        }

        $info->update(['published_at' => now()]);
        $info->refresh();

        // Saat publish, hapus notifikasi lama untuk ref yang sama lalu kirim sekali.
        $this->kirimNotifikasiInformasiTA($info);

        return back()->with('success', "Informasi \"{$info->judul}\" berhasil dipublish.");
    }

    // ==================== HELPER NOTIFIKASI ====================

    private function isPublishedNow(InformasiTA $info): bool
    {
        return $info->published_at !== null && $info->published_at->lte(now());
    }

    private function hapusNotifikasiInformasiTA(InformasiTA $info): void
    {
        Notifikasi::where('ref_tabel', 'informasi_ta')
            ->where('ref_id', $info->info_id)
            ->delete();
    }

    private function buildPesanInformasiTA(InformasiTA $info): string
    {
        $konten = trim((string) $info->konten_or_file);

        if ($konten !== '') {
            return $konten;
        }

        return "Informasi TA kategori {$info->kategori} telah dipublikasikan.";
    }

    private function kirimNotifikasiInformasiTA(InformasiTA $info): void
    {
        // Cegah notifikasi dobel untuk informasi TA yang sama.
        $this->hapusNotifikasiInformasiTA($info);

        $userIds = User::whereIn('role', ['mahasiswa', 'dosen'])
            ->where('status_akun', 'aktif')
            ->pluck('user_id')
            ->toArray();

        if (empty($userIds)) {
            return;
        }

        NotifikasiService::kirimKeBanyak(
            userIds: $userIds,
            tipe: 'informasi_ta',
            judul: 'Informasi TA: ' . $info->judul,
            pesan: $this->buildPesanInformasiTA($info),
            refTabel: 'informasi_ta',
            refId: $info->info_id
        );
    }

    private function updateNotifikasiInformasiTA(InformasiTA $info): void
    {
        Notifikasi::where('ref_tabel', 'informasi_ta')
            ->where('ref_id', $info->info_id)
            ->update([
                'tipe_notifikasi' => 'informasi_ta',
                'judul'           => 'Informasi TA: ' . $info->judul,
                'pesan'           => $this->buildPesanInformasiTA($info),
            ]);
    }
}