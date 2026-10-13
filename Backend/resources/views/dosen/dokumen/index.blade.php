@extends('layout.dosen')

@section('content')
    <div class="tassist-page-header rounded-[2rem] border p-6 sm:p-8 mb-6">
        <div class="flex flex-col xl:flex-row xl:items-end xl:justify-between gap-5">
            <div>
                <div class="tassist-page-kicker mb-4">
                    <span>●</span>
                    Dokumen
                </div>

                <h1 class="text-3xl font-black tracking-tight theme-text-main">
                    Dokumen & Feedback
                </h1>

                <p class="theme-text-muted mt-2 max-w-2xl">
                    Review dokumen tugas akhir mahasiswa bimbingan, buka versi terbaru, dan berikan feedback pada versi dokumen.
                </p>
            </div>
        </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-4 gap-5 mb-6">
        <div class="tassist-stat-card rounded-[1.6rem] border p-5">
            <div class="relative z-10">
                <p class="text-sm theme-text-muted font-bold">Total Dokumen</p>
                <h2 class="text-4xl font-black mt-3">{{ $stats['total_dokumen'] }}</h2>
                <p class="text-xs theme-text-subtle mt-3">Dokumen mahasiswa</p>
            </div>
        </div>

        <div class="tassist-stat-card rounded-[1.6rem] border p-5">
            <div class="relative z-10">
                <p class="text-sm theme-text-muted font-bold">Total Versi</p>
                <h2 class="text-4xl font-black mt-3">{{ $stats['total_versi'] }}</h2>
                <p class="text-xs theme-text-subtle mt-3">Riwayat upload versi</p>
            </div>
        </div>

        <div class="tassist-stat-card rounded-[1.6rem] border p-5">
            <div class="relative z-10">
                <p class="text-sm theme-text-muted font-bold">Feedback Saya</p>
                <h2 class="text-4xl font-black mt-3">{{ $stats['feedback_saya'] }}</h2>
                <p class="text-xs theme-text-subtle mt-3">Komentar yang diberikan</p>
            </div>
        </div>

        <div class="tassist-stat-card rounded-[1.6rem] border p-5">
            <div class="relative z-10">
                <p class="text-sm theme-text-muted font-bold">Belum Feedback</p>
                <h2 class="text-4xl font-black mt-3">{{ $stats['dokumen_belum_feedback'] }}</h2>
                <p class="text-xs theme-text-subtle mt-3">Perlu direview</p>
            </div>
        </div>
    </div>

    <div class="rounded-[1.6rem] border tassist-filter-card p-5 mb-6">
        <form method="GET" action="{{ route('dosen.dokumen.index') }}" class="flex flex-col xl:flex-row gap-3">
            <input
                type="text"
                name="search"
                value="{{ $search }}"
                placeholder="Cari judul dokumen, jenis, nama, NIM, prodi..."
                class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
            >

            <select
                name="bimbingan_id"
                class="px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
            >
                <option value="">Semua Mahasiswa</option>

                @foreach($bimbinganList as $bimbingan)
                    @php
                        $mahasiswa = $bimbingan->mahasiswa;
                        $user = $mahasiswa?->user;
                    @endphp

                    <option
                        value="{{ $bimbingan->bimbingan_id }}"
                        {{ (string) $bimbinganId === (string) $bimbingan->bimbingan_id ? 'selected' : '' }}
                    >
                        {{ $user->nama ?? '-' }} • {{ $mahasiswa->nim ?? '-' }}
                    </option>
                @endforeach
            </select>

            <button
                type="submit"
                class="px-5 py-3 rounded-2xl theme-primary-btn text-sm font-extrabold"
            >
                Filter
            </button>

            @if($search || $bimbinganId)
                <a
                    href="{{ route('dosen.dokumen.index') }}"
                    class="px-5 py-3 rounded-2xl border tassist-secondary-btn text-sm font-extrabold text-center"
                >
                    Reset
                </a>
            @endif
        </form>
    </div>

    <div class="rounded-[1.6rem] border tassist-list-shell overflow-hidden">
        <div class="p-5 sm:p-6 border-b tassist-divider">
            <h2 class="font-black text-xl theme-text-main">
                Daftar Dokumen
            </h2>
            <p class="text-sm theme-text-muted mt-1">
                Dokumen yang diupload oleh mahasiswa bimbingan Anda.
            </p>
        </div>

        <div class="p-4 sm:p-5 space-y-4">
            @forelse($dokumen as $item)
                @php
                    $bimbingan = $item->bimbingan;
                    $mahasiswa = $bimbingan?->mahasiswa;
                    $user = $mahasiswa?->user;
                    $versiTerbaru = $item->versiTerbaru;
                    $totalVersi = $item->versiDokumen->count();
                    $totalFeedback = $item->versiDokumen->sum(fn($v) => $v->feedbackDokumen->count());
                    $feedbackSaya = $item->versiDokumen->sum(fn($v) => $v->feedbackDokumen->where('dosen_id', session('dosen_user.dosen_id'))->count());
                @endphp

                <div class="tassist-list-item rounded-2xl border p-5">
                    <div class="flex flex-col xl:flex-row xl:items-start xl:justify-between gap-5">
                        <div class="flex items-start gap-4 flex-1 min-w-0">
                            <div class="w-12 h-12 rounded-2xl theme-logo-bg text-white flex items-center justify-center font-black flex-shrink-0">
                                {{ strtoupper(substr($item->jenis_dokumen ?? 'D', 0, 1)) }}
                            </div>

                            <div class="min-w-0 flex-1">
                                <div class="flex flex-wrap items-center gap-2">
                                    <h3 class="font-black theme-text-main">
                                        {{ $item->judul_dokumen ?? '-' }}
                                    </h3>

                                    <span class="px-3 py-1 rounded-full text-xs font-bold theme-badge-primary">
                                        {{ $item->jenis_dokumen ?? '-' }}
                                    </span>
                                </div>

                                <p class="text-sm theme-text-muted mt-1">
                                    {{ $user->nama ?? '-' }}
                                    • {{ $mahasiswa->nim ?? '-' }}
                                    • {{ $mahasiswa->prodi ?? '-' }}
                                </p>

                                @if($item->deskripsi)
                                    <p class="text-sm theme-text-muted mt-3 line-clamp-2">
                                        {{ $item->deskripsi }}
                                    </p>
                                @endif

                                <div class="mt-4 grid grid-cols-1 md:grid-cols-3 gap-3">
                                    <div class="rounded-2xl border tassist-mini-card p-4">
                                        <p class="text-xs theme-text-muted font-black uppercase tracking-wide">Total Versi</p>
                                        <p class="text-sm font-bold mt-1 theme-text-main">{{ $totalVersi }}</p>
                                    </div>

                                    <div class="rounded-2xl border tassist-mini-card p-4">
                                        <p class="text-xs theme-text-muted font-black uppercase tracking-wide">Total Feedback</p>
                                        <p class="text-sm font-bold mt-1 theme-text-main">{{ $totalFeedback }}</p>
                                    </div>

                                    <div class="rounded-2xl border tassist-mini-card p-4">
                                        <p class="text-xs theme-text-muted font-black uppercase tracking-wide">Feedback Saya</p>
                                        <p class="text-sm font-bold mt-1 theme-text-main">{{ $feedbackSaya }}</p>
                                    </div>
                                </div>

                                @if($versiTerbaru)
                                    <p class="text-xs theme-text-muted mt-3">
                                        Versi terbaru: v{{ $versiTerbaru->nomor_versi }}
                                        • {{ optional($versiTerbaru->uploaded_at)->format('d M Y H:i') ?? '-' }}
                                        • Status: {{ ucfirst($versiTerbaru->status_versi ?? '-') }}
                                    </p>
                                @else
                                    <p class="text-xs theme-text-muted mt-3">
                                        Belum ada versi dokumen.
                                    </p>
                                @endif
                            </div>
                        </div>

                        <div class="xl:w-52 flex flex-col gap-2">
                            <a
                                href="{{ route('dosen.dokumen.show', $item->dokumen_id) }}"
                                class="px-4 py-2.5 rounded-2xl theme-primary-btn text-sm font-extrabold text-center"
                            >
                                Review Dokumen
                            </a>

                            @if($versiTerbaru)
                                <a
                                    href="{{ \Illuminate\Support\Facades\Storage::url($versiTerbaru->file_url_or_path) }}"
                                    target="_blank"
                                    class="px-4 py-2.5 rounded-2xl border tassist-secondary-btn text-sm font-extrabold text-center"
                                >
                                    Buka File Terbaru
                                </a>
                            @endif
                        </div>
                    </div>
                </div>
            @empty
                <div class="tassist-empty-state rounded-2xl border p-10 text-center">
                    <p class="font-black theme-text-main">
                        Belum ada dokumen.
                    </p>
                    <p class="text-sm theme-text-muted mt-2">
                        Dokumen yang diupload mahasiswa bimbingan akan muncul di halaman ini.
                    </p>
                </div>
            @endforelse
        </div>

        @if($dokumen->hasPages())
            <div class="p-5 border-t tassist-divider">
                {{ $dokumen->links() }}
            </div>
        @endif
    </div>
@endsection