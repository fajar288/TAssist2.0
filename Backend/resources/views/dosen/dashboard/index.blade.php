@extends('layout.dosen')

@section('content')
    <div class="tassist-hero rounded-[2rem] border p-6 sm:p-8 mb-8">
        <div class="flex flex-col xl:flex-row xl:items-end xl:justify-between gap-6">
            <div>
                <div class="tassist-page-kicker mb-4">
                    <span>●</span>
                    Dashboard Dosen
                </div>

                <h1 class="text-3xl sm:text-4xl font-black tracking-tight theme-text-main">
                    Selamat datang, {{ session('dosen_user.nama') }}.
                </h1>

                <p class="theme-text-muted mt-3 max-w-2xl leading-relaxed">
                    Pantau permohonan, jadwal, dokumen, feedback, dan progress mahasiswa bimbingan dari satu portal.
                </p>
            </div>

            <div class="flex flex-col sm:flex-row gap-3">
                <a
                    href="{{ route('dosen.permohonan.index') }}"
                    class="px-5 py-3 rounded-2xl theme-primary-btn text-sm font-extrabold text-center"
                >
                    Kelola Permohonan
                </a>

                <a
                    href="{{ route('dosen.progress-checklist.index') }}"
                    class="px-5 py-3 rounded-2xl border theme-soft-card text-sm font-extrabold text-center"
                >
                    Lihat Progress
                </a>
            </div>
        </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5 mb-8">
        <a href="{{ route('dosen.permohonan.index', ['status' => 'menunggu']) }}" class="tassist-stat-card rounded-[1.6rem] border p-5 block">
            <div class="relative z-10">
                <div class="flex items-start justify-between gap-4">
                    <div>
                        <p class="text-sm theme-text-muted font-bold">Permohonan Menunggu</p>
                        <h2 class="text-4xl font-black mt-3">{{ $permohonanMenunggu }}</h2>
                    </div>

                    <div class="tassist-stat-icon w-12 h-12 rounded-2xl flex items-center justify-center">
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 6.75h12M8.25 12h12M8.25 17.25h12M3.75 6.75h.008v.008H3.75V6.75zM3.75 12h.008v.008H3.75V12zM3.75 17.25h.008v.008H3.75v-.008z" />
                        </svg>
                    </div>
                </div>

                <p class="text-xs theme-text-subtle mt-4">
                    Review permohonan baru dari mahasiswa.
                </p>
            </div>
        </a>

        <a href="{{ route('dosen.mahasiswa-bimbingan.index', ['status' => 'aktif']) }}" class="tassist-stat-card rounded-[1.6rem] border p-5 block">
            <div class="relative z-10">
                <div class="flex items-start justify-between gap-4">
                    <div>
                        <p class="text-sm theme-text-muted font-bold">Mahasiswa Aktif</p>
                        <h2 class="text-4xl font-black mt-3">{{ $mahasiswaAktif }}</h2>
                    </div>

                    <div class="tassist-stat-icon w-12 h-12 rounded-2xl flex items-center justify-center">
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.5 20.25a8.25 8.25 0 0115 0" />
                        </svg>
                    </div>
                </div>

                <p class="text-xs theme-text-subtle mt-4">
                    Mahasiswa yang sedang dibimbing.
                </p>
            </div>
        </a>

        <a href="{{ route('dosen.jadwal.index', ['status' => 'menunggu']) }}" class="tassist-stat-card rounded-[1.6rem] border p-5 block">
            <div class="relative z-10">
                <div class="flex items-start justify-between gap-4">
                    <div>
                        <p class="text-sm theme-text-muted font-bold">Jadwal Menunggu</p>
                        <h2 class="text-4xl font-black mt-3">{{ $jadwalMenunggu }}</h2>
                    </div>

                    <div class="tassist-stat-icon w-12 h-12 rounded-2xl flex items-center justify-center">
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3.75 8.25h16.5M5.25 5.25h13.5A1.5 1.5 0 0120.25 6.75v12A1.5 1.5 0 0118.75 20.25H5.25A1.5 1.5 0 013.75 18.75v-12A1.5 1.5 0 015.25 5.25z" />
                        </svg>
                    </div>
                </div>

                <p class="text-xs theme-text-subtle mt-4">
                    Jadwal yang perlu dikonfirmasi.
                </p>
            </div>
        </a>

        <div class="tassist-stat-card rounded-[1.6rem] border p-5">
            <div class="relative z-10">
                <div class="flex items-start justify-between gap-4">
                    <div>
                        <p class="text-sm theme-text-muted font-bold">Notifikasi Baru</p>
                        <h2 class="text-4xl font-black mt-3">{{ $notifikasiBelumDibaca }}</h2>
                    </div>

                    <div class="tassist-stat-icon w-12 h-12 rounded-2xl flex items-center justify-center">
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022 23.848 23.848 0 005.455 1.31m5.714 0a3 3 0 11-5.714 0" />
                        </svg>
                    </div>
                </div>

                <p class="text-xs theme-text-subtle mt-4">
                    Update terbaru dari aktivitas sistem.
                </p>
            </div>
        </div>
    </div>

    <div class="grid grid-cols-1 xl:grid-cols-2 gap-6">
        <div class="rounded-[1.6rem] border theme-panel p-5 sm:p-6">
            <div class="flex items-center justify-between gap-4 mb-5">
                <div>
                    <h2 class="font-black text-xl theme-text-main">Permohonan Terbaru</h2>
                    <p class="text-sm theme-text-muted mt-1">Aktivitas permohonan bimbingan terbaru.</p>
                </div>

                <a
                    href="{{ route('dosen.permohonan.index') }}"
                    class="text-sm font-extrabold theme-text-muted hover:theme-text-main"
                >
                    Lihat semua
                </a>
            </div>

            <div class="space-y-3">
                @forelse($recentPermohonan as $permohonan)
                    @php
                        $status = strtolower($permohonan->status ?? '');
                    @endphp

                    <a
                        href="{{ route('dosen.permohonan.show', $permohonan->permohonan_id) }}"
                        class="tassist-list-item block rounded-2xl border p-4"
                    >
                        <div class="flex items-start justify-between gap-4">
                            <div class="min-w-0">
                                <p class="font-extrabold theme-text-main truncate">
                                    {{ $permohonan->mahasiswa->user->nama ?? '-' }}
                                </p>

                                <p class="text-sm theme-text-muted mt-1 line-clamp-2">
                                    {{ $permohonan->topik_ta ?? '-' }}
                                </p>
                            </div>

                            @if($status === 'diterima')
                                <span class="px-3 py-1 rounded-full text-xs font-bold theme-alert-success">
                                    Diterima
                                </span>
                            @elseif($status === 'ditolak')
                                <span class="px-3 py-1 rounded-full text-xs font-bold theme-alert-error">
                                    Ditolak
                                </span>
                            @else
                                <span class="px-3 py-1 rounded-full text-xs font-bold theme-badge-primary">
                                    Menunggu
                                </span>
                            @endif
                        </div>
                    </a>
                @empty
                    <div class="rounded-2xl border theme-soft-card p-5 text-center">
                        <p class="text-sm theme-text-muted">
                            Belum ada permohonan terbaru.
                        </p>
                    </div>
                @endforelse
            </div>
        </div>

        <div class="rounded-[1.6rem] border theme-panel p-5 sm:p-6">
            <div class="flex items-center justify-between gap-4 mb-5">
                <div>
                    <h2 class="font-black text-xl theme-text-main">Jadwal Terbaru</h2>
                    <p class="text-sm theme-text-muted mt-1">Agenda bimbingan terbaru dengan mahasiswa.</p>
                </div>

                <a
                    href="{{ route('dosen.jadwal.index') }}"
                    class="text-sm font-extrabold theme-text-muted hover:theme-text-main"
                >
                    Lihat semua
                </a>
            </div>

            <div class="space-y-3">
                @forelse($recentJadwal as $jadwal)
                    @php
                        $status = strtolower($jadwal->status_konfirmasi ?? '');
                    @endphp

                    <a
                        href="{{ route('dosen.jadwal.show', $jadwal->jadwal_id) }}"
                        class="tassist-list-item block rounded-2xl border p-4"
                    >
                        <div class="flex items-start justify-between gap-4">
                            <div class="min-w-0">
                                <p class="font-extrabold theme-text-main truncate">
                                    {{ $jadwal->bimbingan->mahasiswa->user->nama ?? '-' }}
                                </p>

                                <p class="text-sm theme-text-muted mt-1">
                                    {{ optional($jadwal->tanggal)->format('d M Y') ?? '-' }}
                                    • {{ substr($jadwal->waktu_mulai, 0, 5) }} - {{ substr($jadwal->waktu_selesai, 0, 5) }}
                                </p>

                                <p class="text-xs theme-text-muted mt-1">
                                    Mode: {{ ucfirst($jadwal->mode) }}
                                </p>
                            </div>

                            @if($status === 'dikonfirmasi')
                                <span class="px-3 py-1 rounded-full text-xs font-bold theme-alert-success">
                                    Dikonfirmasi
                                </span>
                            @elseif($status === 'ditolak')
                                <span class="px-3 py-1 rounded-full text-xs font-bold theme-alert-error">
                                    Ditolak
                                </span>
                            @else
                                <span class="px-3 py-1 rounded-full text-xs font-bold theme-badge-primary">
                                    Menunggu
                                </span>
                            @endif
                        </div>
                    </a>
                @empty
                    <div class="rounded-2xl border theme-soft-card p-5 text-center">
                        <p class="text-sm theme-text-muted">
                            Belum ada jadwal terbaru.
                        </p>
                    </div>
                @endforelse
            </div>
        </div>
    </div>
@endsection