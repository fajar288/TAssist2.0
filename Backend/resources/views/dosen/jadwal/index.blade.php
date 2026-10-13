@extends('layout.dosen')

@section('content')
    <div class="tassist-page-header rounded-[2rem] border p-6 sm:p-8 mb-6">
        <div class="flex flex-col xl:flex-row xl:items-end xl:justify-between gap-5">
            <div>
                <div class="tassist-page-kicker mb-4">
                    <span>●</span>
                    Jadwal
                </div>

                <h1 class="text-3xl font-black tracking-tight theme-text-main">
                    Jadwal Bimbingan
                </h1>

                <p class="theme-text-muted mt-2 max-w-2xl">
                    Kelola jadwal bimbingan, konfirmasi pengajuan mahasiswa, atau buat jadwal baru untuk mahasiswa bimbingan aktif.
                </p>
            </div>

            <a
                href="{{ route('dosen.jadwal.create') }}"
                class="px-5 py-3 rounded-2xl theme-primary-btn text-sm font-extrabold text-center"
            >
                + Buat Jadwal
            </a>
        </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-4 gap-5 mb-6">
        <a href="{{ route('dosen.jadwal.index') }}" class="tassist-stat-card rounded-[1.6rem] border p-5 block">
            <div class="relative z-10">
                <p class="text-sm theme-text-muted font-bold">Semua</p>
                <h2 class="text-4xl font-black mt-3">{{ $stats['semua'] }}</h2>
                <p class="text-xs theme-text-subtle mt-3">Total jadwal bimbingan</p>
            </div>
        </a>

        <a href="{{ route('dosen.jadwal.index', ['status' => 'menunggu']) }}" class="tassist-stat-card rounded-[1.6rem] border p-5 block">
            <div class="relative z-10">
                <p class="text-sm theme-text-muted font-bold">Menunggu</p>
                <h2 class="text-4xl font-black mt-3">{{ $stats['menunggu'] }}</h2>
                <p class="text-xs theme-text-subtle mt-3">Perlu konfirmasi</p>
            </div>
        </a>

        <a href="{{ route('dosen.jadwal.index', ['status' => 'dikonfirmasi']) }}" class="tassist-stat-card rounded-[1.6rem] border p-5 block">
            <div class="relative z-10">
                <p class="text-sm theme-text-muted font-bold">Dikonfirmasi</p>
                <h2 class="text-4xl font-black mt-3">{{ $stats['dikonfirmasi'] }}</h2>
                <p class="text-xs theme-text-subtle mt-3">Jadwal disetujui</p>
            </div>
        </a>

        <a href="{{ route('dosen.jadwal.index', ['status' => 'ditolak']) }}" class="tassist-stat-card rounded-[1.6rem] border p-5 block">
            <div class="relative z-10">
                <p class="text-sm theme-text-muted font-bold">Ditolak</p>
                <h2 class="text-4xl font-black mt-3">{{ $stats['ditolak'] }}</h2>
                <p class="text-xs theme-text-subtle mt-3">Jadwal tidak disetujui</p>
            </div>
        </a>
    </div>

    <div class="rounded-[1.6rem] border tassist-filter-card p-5 mb-6">
        <form method="GET" action="{{ route('dosen.jadwal.index') }}" class="flex flex-col xl:flex-row gap-3">
            <input
                type="text"
                name="search"
                value="{{ $search }}"
                placeholder="Cari nama, NIM, prodi, judul TA, atau catatan..."
                class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
            >

            <select
                name="status"
                class="px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
            >
                <option value="">Semua Status</option>
                <option value="menunggu" {{ $status === 'menunggu' ? 'selected' : '' }}>Menunggu</option>
                <option value="dikonfirmasi" {{ $status === 'dikonfirmasi' ? 'selected' : '' }}>Dikonfirmasi</option>
                <option value="ditolak" {{ $status === 'ditolak' ? 'selected' : '' }}>Ditolak</option>
            </select>

            <button
                type="submit"
                class="px-5 py-3 rounded-2xl theme-primary-btn text-sm font-extrabold"
            >
                Filter
            </button>

            @if($search || $status)
                <a
                    href="{{ route('dosen.jadwal.index') }}"
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
                Daftar Jadwal
            </h2>
            <p class="text-sm theme-text-muted mt-1">
                Jadwal bimbingan dari dosen maupun mahasiswa yang membutuhkan konfirmasi.
            </p>
        </div>

        <div class="p-4 sm:p-5 space-y-4">
            @forelse($jadwal as $item)
                @php
                    $mahasiswa = $item->bimbingan?->mahasiswa;
                    $user = $mahasiswa?->user;
                    $canKonfirmasi = $item->status_konfirmasi === 'menunggu'
                        && (int) $item->pengaju_user_id !== (int) session('dosen_user.user_id');
                @endphp

                <div class="tassist-list-item rounded-2xl border p-5">
                    <div class="flex flex-col xl:flex-row xl:items-start xl:justify-between gap-5">
                        <div class="flex items-start gap-4 flex-1 min-w-0">
                            <div class="w-12 h-12 rounded-2xl theme-logo-bg text-white flex items-center justify-center font-black flex-shrink-0">
                                {{ strtoupper(substr($user->nama ?? 'M', 0, 1)) }}
                            </div>

                            <div class="min-w-0 flex-1">
                                <div class="flex flex-wrap items-center gap-2">
                                    <h3 class="font-black theme-text-main">
                                        {{ $user->nama ?? '-' }}
                                    </h3>

                                    @if($item->status_konfirmasi === 'menunggu')
                                        <span class="px-3 py-1 rounded-full text-xs font-bold theme-badge-primary">
                                            Menunggu
                                        </span>
                                    @elseif($item->status_konfirmasi === 'dikonfirmasi')
                                        <span class="px-3 py-1 rounded-full text-xs font-bold theme-alert-success">
                                            Dikonfirmasi
                                        </span>
                                    @else
                                        <span class="px-3 py-1 rounded-full text-xs font-bold theme-alert-error">
                                            Ditolak
                                        </span>
                                    @endif
                                </div>

                                <p class="text-sm theme-text-muted mt-1">
                                    {{ $mahasiswa->nim ?? '-' }}
                                    • {{ $mahasiswa->prodi ?? '-' }}
                                    • Pengaju: {{ $item->pengaju->nama ?? '-' }} ({{ $item->pengaju->role ?? '-' }})
                                </p>

                                <div class="mt-4 grid grid-cols-1 md:grid-cols-3 gap-3">
                                    <div class="rounded-2xl border tassist-mini-card p-4">
                                        <p class="text-xs theme-text-muted font-black uppercase tracking-wide">Tanggal</p>
                                        <p class="text-sm font-bold mt-1 theme-text-main">
                                            {{ optional($item->tanggal)->format('d M Y') ?? '-' }}
                                        </p>
                                    </div>

                                    <div class="rounded-2xl border tassist-mini-card p-4">
                                        <p class="text-xs theme-text-muted font-black uppercase tracking-wide">Waktu</p>
                                        <p class="text-sm font-bold mt-1 theme-text-main">
                                            {{ substr($item->waktu_mulai, 0, 5) }} - {{ substr($item->waktu_selesai, 0, 5) }}
                                        </p>
                                    </div>

                                    <div class="rounded-2xl border tassist-mini-card p-4">
                                        <p class="text-xs theme-text-muted font-black uppercase tracking-wide">Mode</p>
                                        <p class="text-sm font-bold mt-1 theme-text-main">
                                            {{ ucfirst($item->mode) }}
                                        </p>
                                    </div>
                                </div>

                                @if($item->catatan)
                                    <div class="mt-4 rounded-2xl border tassist-mini-card p-4">
                                        <p class="text-xs uppercase tracking-wide theme-text-muted font-black">
                                            Catatan
                                        </p>
                                        <p class="text-sm theme-text-main mt-1 leading-relaxed">
                                            {{ $item->catatan }}
                                        </p>
                                    </div>
                                @endif
                            </div>
                        </div>

                        <div class="xl:w-52 flex flex-col gap-2">
                            <a
                                href="{{ route('dosen.jadwal.show', $item->jadwal_id) }}"
                                class="px-4 py-2.5 rounded-2xl border tassist-secondary-btn text-sm font-extrabold text-center"
                            >
                                Detail
                            </a>

                            @if($canKonfirmasi)
                                <details class="rounded-2xl border tassist-secondary-btn">
                                    <summary class="cursor-pointer px-4 py-2.5 text-sm font-extrabold">
                                        Konfirmasi
                                    </summary>

                                    <form
                                        method="POST"
                                        action="{{ route('dosen.jadwal.konfirmasi', $item->jadwal_id) }}"
                                        class="p-3 pt-1 space-y-3"
                                    >
                                        @csrf
                                        @method('PUT')

                                        <select
                                            name="mode"
                                            required
                                            class="w-full px-3 py-2 rounded-xl border theme-input text-sm outline-none"
                                        >
                                            <option value="">Pilih Mode</option>
                                            <option value="online" {{ $item->mode === 'online' ? 'selected' : '' }}>Online</option>
                                            <option value="offline" {{ $item->mode === 'offline' ? 'selected' : '' }}>Offline</option>
                                        </select>

                                        <textarea
                                            name="catatan"
                                            rows="2"
                                            placeholder="Catatan opsional..."
                                            class="w-full px-3 py-2 rounded-xl border theme-input text-sm outline-none"
                                        ></textarea>

                                        <button
                                            type="submit"
                                            class="w-full px-4 py-2.5 rounded-xl theme-primary-btn text-sm font-extrabold"
                                        >
                                            Terima
                                        </button>
                                    </form>
                                </details>

                                <details class="rounded-2xl border tassist-secondary-btn">
                                    <summary class="cursor-pointer px-4 py-2.5 text-sm font-extrabold">
                                        Tolak
                                    </summary>

                                    <form
                                        method="POST"
                                        action="{{ route('dosen.jadwal.tolak', $item->jadwal_id) }}"
                                        class="p-3 pt-1 space-y-3"
                                    >
                                        @csrf
                                        @method('PUT')

                                        <textarea
                                            name="catatan"
                                            rows="3"
                                            required
                                            placeholder="Tulis alasan penolakan..."
                                            class="w-full px-3 py-2 rounded-xl border theme-input text-sm outline-none"
                                        ></textarea>

                                        <button
                                            type="submit"
                                            class="w-full px-4 py-2.5 rounded-xl border tassist-danger-btn text-sm font-extrabold"
                                        >
                                            Kirim Penolakan
                                        </button>
                                    </form>
                                </details>
                            @endif
                        </div>
                    </div>
                </div>
            @empty
                <div class="tassist-empty-state rounded-2xl border p-10 text-center">
                    <p class="font-black theme-text-main">
                        Belum ada jadwal bimbingan.
                    </p>
                    <p class="text-sm theme-text-muted mt-2">
                        Jadwal yang dibuat dosen atau diajukan mahasiswa akan muncul di sini.
                    </p>
                </div>
            @endforelse
        </div>

        @if($jadwal->hasPages())
            <div class="p-5 border-t tassist-divider">
                {{ $jadwal->links() }}
            </div>
        @endif
    </div>
@endsection