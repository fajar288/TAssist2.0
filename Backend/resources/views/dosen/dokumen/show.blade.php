@extends('layout.dosen')

@section('content')
    @php
        $bimbingan = $dokumen->bimbingan;
        $mahasiswa = $bimbingan?->mahasiswa;
        $user = $mahasiswa?->user;
        $taTitle = $mahasiswa?->judul_ta ?: ($bimbingan?->permohonan?->topik_ta ?: $mahasiswa?->topik_ta);
    @endphp

    <div class="tassist-page-header rounded-[2rem] border p-6 sm:p-8 mb-6">
        <div class="flex flex-col xl:flex-row xl:items-start xl:justify-between gap-5">
            <div>
                <a
                    href="{{ route('dosen.dokumen.index') }}"
                    class="inline-flex items-center gap-2 text-sm theme-text-muted font-bold mb-4"
                >
                    ← Kembali ke daftar dokumen
                </a>

                <div class="tassist-page-kicker mb-4">
                    <span>●</span>
                    Detail Dokumen
                </div>

                <h1 class="text-3xl font-black tracking-tight theme-text-main">
                    Detail Dokumen
                </h1>

                <p class="theme-text-muted mt-2 max-w-2xl">
                    Lihat riwayat versi dokumen, buka file, dan berikan feedback untuk mahasiswa.
                </p>
            </div>

            <span class="px-4 py-2 rounded-full text-xs font-black theme-badge-primary">
                {{ $dokumen->jenis_dokumen ?? '-' }}
            </span>
        </div>
    </div>

    <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <div class="xl:col-span-2 space-y-6">

            <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                <h2 class="font-black text-xl theme-text-main mb-5">
                    Informasi Dokumen
                </h2>

                <div class="space-y-4">
                    <div class="rounded-2xl border tassist-mini-card p-5">
                        <p class="text-xs uppercase tracking-wide theme-text-muted font-black">
                            Judul Dokumen
                        </p>
                        <p class="mt-2 text-lg font-black theme-text-main leading-relaxed">
                            {{ $dokumen->judul_dokumen ?? '-' }}
                        </p>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div class="rounded-2xl border tassist-mini-card p-5">
                            <p class="text-xs uppercase tracking-wide theme-text-muted font-black">
                                Jenis Dokumen
                            </p>
                            <p class="mt-2 theme-text-main font-bold">
                                {{ $dokumen->jenis_dokumen ?? '-' }}
                            </p>
                        </div>

                        <div class="rounded-2xl border tassist-mini-card p-5">
                            <p class="text-xs uppercase tracking-wide theme-text-muted font-black">
                                Tanggal Dibuat
                            </p>
                            <p class="mt-2 theme-text-main font-bold">
                                {{ optional($dokumen->created_at)->format('d M Y H:i') ?? '-' }}
                            </p>
                        </div>
                    </div>

                    @if($dokumen->deskripsi)
                        <div class="rounded-2xl border tassist-mini-card p-5">
                            <p class="text-xs uppercase tracking-wide theme-text-muted font-black">
                                Deskripsi
                            </p>
                            <p class="mt-2 theme-text-main leading-relaxed">
                                {{ $dokumen->deskripsi }}
                            </p>
                        </div>
                    @endif
                </div>
            </div>

            <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                <div class="flex flex-col md:flex-row md:items-start md:justify-between gap-4 mb-5">
                    <div>
                        <h2 class="font-black text-xl theme-text-main">
                            Riwayat Versi Dokumen
                        </h2>
                        <p class="text-sm theme-text-muted mt-1">
                            Versi terbaru berada di urutan paling atas.
                        </p>
                    </div>
                </div>

                <div class="space-y-5">
                    @forelse($dokumen->versiDokumen as $versi)
                        @php
                            $fileUrl = \Illuminate\Support\Facades\Storage::url($versi->file_url_or_path);
                            $feedbackList = $versi->feedbackDokumen->sortByDesc('created_at');
                        @endphp

                        <div class="rounded-[1.4rem] border tassist-mini-card p-5">
                            <div class="flex flex-col xl:flex-row xl:items-start xl:justify-between gap-4">
                                <div class="min-w-0">
                                    <div class="flex flex-wrap items-center gap-2">
                                        <h3 class="font-black theme-text-main">
                                            Versi {{ $versi->nomor_versi }}
                                        </h3>

                                        <span class="px-3 py-1 rounded-full text-xs font-bold theme-badge-primary">
                                            {{ ucfirst($versi->status_versi ?? '-') }}
                                        </span>
                                    </div>

                                    <p class="text-sm theme-text-muted mt-1">
                                        Diupload oleh {{ $versi->uploader->nama ?? '-' }}
                                        • {{ optional($versi->uploaded_at)->format('d M Y H:i') ?? '-' }}
                                    </p>

                                    @if($versi->catatan_revisi)
                                        <div class="mt-4 p-4 rounded-2xl border tassist-mini-card">
                                            <p class="text-xs uppercase tracking-wide theme-text-muted font-black">
                                                Catatan Revisi
                                            </p>
                                            <p class="mt-2 text-sm theme-text-main leading-relaxed">
                                                {{ $versi->catatan_revisi }}
                                            </p>
                                        </div>
                                    @endif
                                </div>

                                <a
                                    href="{{ $fileUrl }}"
                                    target="_blank"
                                    class="px-4 py-2.5 rounded-2xl theme-primary-btn text-sm font-black text-center"
                                >
                                    Buka File
                                </a>
                            </div>

                            <div class="mt-6">
                                <h4 class="font-black theme-text-main mb-3">
                                    Feedback
                                </h4>

                                <div class="space-y-3">
                                    @forelse($feedbackList as $feedback)
                                        <div class="p-4 rounded-2xl border tassist-mini-card">
                                            <div class="flex flex-col md:flex-row md:items-start md:justify-between gap-2">
                                                <div>
                                                    <p class="font-bold theme-text-main">
                                                        {{ $feedback->dosen->user->nama ?? 'Dosen' }}
                                                    </p>

                                                    <p class="text-xs theme-text-muted mt-1">
                                                        {{ optional($feedback->created_at)->format('d M Y H:i') ?? '-' }}
                                                        @if($feedback->halaman)
                                                            • Halaman {{ $feedback->halaman }}
                                                        @endif
                                                        @if($feedback->posisi_anotasi)
                                                            • {{ $feedback->posisi_anotasi }}
                                                        @endif
                                                    </p>
                                                </div>

                                                @if((int) $feedback->dosen_id === (int) session('dosen_user.dosen_id'))
                                                    <span class="px-3 py-1 rounded-full text-xs font-bold theme-alert-success">
                                                        Feedback Saya
                                                    </span>
                                                @endif
                                            </div>

                                            <p class="text-sm theme-text-main mt-3 leading-relaxed">
                                                {{ $feedback->komentar }}
                                            </p>
                                        </div>
                                    @empty
                                        <div class="rounded-2xl border tassist-empty-state p-5 text-center">
                                            <p class="text-sm theme-text-muted">
                                                Belum ada feedback untuk versi ini.
                                            </p>
                                        </div>
                                    @endforelse
                                </div>
                            </div>

                            <details class="mt-5 rounded-2xl border tassist-secondary-btn">
                                <summary class="cursor-pointer px-4 py-3 text-sm font-black">
                                    + Beri Feedback pada Versi {{ $versi->nomor_versi }}
                                </summary>

                                <form
                                    method="POST"
                                    action="{{ route('dosen.dokumen.feedback.store') }}"
                                    class="p-4 pt-2 space-y-4"
                                >
                                    @csrf

                                    <input type="hidden" name="versi_id" value="{{ $versi->versi_id }}">

                                    <div>
                                        <label class="block text-sm mb-2 theme-text-muted font-black">
                                            Komentar Feedback
                                        </label>

                                        <textarea
                                            name="komentar"
                                            rows="4"
                                            required
                                            placeholder="Tulis feedback untuk mahasiswa..."
                                            class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
                                        >{{ old('versi_id') == $versi->versi_id ? old('komentar') : '' }}</textarea>
                                    </div>

                                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                        <div>
                                            <label class="block text-sm mb-2 theme-text-muted font-black">
                                                Halaman
                                            </label>

                                            <input
                                                type="number"
                                                min="1"
                                                name="halaman"
                                                value="{{ old('versi_id') == $versi->versi_id ? old('halaman') : '' }}"
                                                placeholder="Opsional"
                                                class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
                                            >
                                        </div>

                                        <div>
                                            <label class="block text-sm mb-2 theme-text-muted font-black">
                                                Posisi Anotasi
                                            </label>

                                            <input
                                                type="text"
                                                name="posisi_anotasi"
                                                value="{{ old('versi_id') == $versi->versi_id ? old('posisi_anotasi') : '' }}"
                                                placeholder="Contoh: paragraf 2 / gambar 1"
                                                class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
                                            >
                                        </div>
                                    </div>

                                    <button
                                        type="submit"
                                        class="px-5 py-3 rounded-2xl theme-primary-btn text-sm font-black"
                                    >
                                        Kirim Feedback
                                    </button>
                                </form>
                            </details>
                        </div>
                    @empty
                        <div class="tassist-empty-state rounded-2xl border p-8 text-center">
                            <p class="font-black theme-text-main">
                                Belum ada versi dokumen.
                            </p>
                            <p class="text-sm theme-text-muted mt-2">
                                Versi dokumen akan muncul setelah mahasiswa melakukan upload file.
                            </p>
                        </div>
                    @endforelse
                </div>
            </div>
        </div>

        <div class="space-y-6">
            <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                <h2 class="font-black text-xl theme-text-main mb-5">
                    Data Mahasiswa
                </h2>

                <div class="flex items-center gap-4 mb-6">
                    <div class="w-14 h-14 rounded-2xl theme-logo-bg text-white flex items-center justify-center font-black text-lg">
                        {{ strtoupper(substr($user->nama ?? 'M', 0, 1)) }}
                    </div>

                    <div class="min-w-0">
                        <p class="font-black theme-text-main truncate">
                            {{ $user->nama ?? '-' }}
                        </p>
                        <p class="text-sm theme-text-muted truncate">
                            {{ $user->email ?? '-' }}
                        </p>
                    </div>
                </div>

                <div class="space-y-3">
                    <div class="rounded-2xl border tassist-mini-card p-4">
                        <p class="text-xs theme-text-muted font-black uppercase tracking-wide">NIM</p>
                        <p class="font-bold theme-text-main mt-1">{{ $mahasiswa->nim ?? '-' }}</p>
                    </div>

                    <div class="rounded-2xl border tassist-mini-card p-4">
                        <p class="text-xs theme-text-muted font-black uppercase tracking-wide">Program Studi</p>
                        <p class="font-bold theme-text-main mt-1">{{ $mahasiswa->prodi ?? '-' }}</p>
                    </div>

                    <div class="rounded-2xl border tassist-mini-card p-4">
                        <p class="text-xs theme-text-muted font-black uppercase tracking-wide">Angkatan</p>
                        <p class="font-bold theme-text-main mt-1">{{ $mahasiswa->angkatan ?? '-' }}</p>
                    </div>

                    <div class="rounded-2xl border tassist-mini-card p-4">
                        <p class="text-xs theme-text-muted font-black uppercase tracking-wide">Judul / Topik TA</p>
                        <p class="font-bold theme-text-main mt-1 leading-relaxed">
                            {{ $taTitle ?: '-' }}
                        </p>
                    </div>
                </div>

                <div class="mt-6">
                    <a
                        href="{{ route('dosen.mahasiswa-bimbingan.show', $bimbingan->bimbingan_id) }}"
                        class="block px-4 py-3 rounded-2xl border tassist-secondary-btn text-sm font-black text-center"
                    >
                        Lihat Detail Mahasiswa
                    </a>
                </div>
            </div>

            <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                <h2 class="font-black text-xl theme-text-main mb-5">
                    Ringkasan Dokumen
                </h2>

                <div class="space-y-4">
                    <div class="rounded-2xl border tassist-mini-card p-5">
                        <p class="text-sm theme-text-muted">Total Versi</p>
                        <h3 class="text-3xl font-black mt-1 theme-text-main">
                            {{ $dokumen->versiDokumen->count() }}
                        </h3>
                    </div>

                    <div class="rounded-2xl border tassist-mini-card p-5">
                        <p class="text-sm theme-text-muted">Total Feedback</p>
                        <h3 class="text-3xl font-black mt-1 theme-text-main">
                            {{ $dokumen->versiDokumen->sum(fn($v) => $v->feedbackDokumen->count()) }}
                        </h3>
                    </div>

                    <div class="rounded-2xl border tassist-mini-card p-5">
                        <p class="text-sm theme-text-muted">Feedback Saya</p>
                        <h3 class="text-3xl font-black mt-1 theme-text-main">
                            {{ $dokumen->versiDokumen->sum(fn($v) => $v->feedbackDokumen->where('dosen_id', session('dosen_user.dosen_id'))->count()) }}
                        </h3>
                    </div>
                </div>
            </div>
        </div>
    </div>
@endsection