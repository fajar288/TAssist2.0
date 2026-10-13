@extends('layout.dosen')

@section('content')
    <div class="tassist-page-header rounded-[2rem] border p-6 sm:p-8 mb-6">
        <div class="flex flex-col xl:flex-row xl:items-end xl:justify-between gap-5">
            <div>
                <div class="tassist-page-kicker mb-4">
                    <span>●</span>
                    Mahasiswa
                </div>

                <h1 class="text-3xl font-black tracking-tight theme-text-main">
                    Mahasiswa Bimbingan
                </h1>

                <p class="theme-text-muted mt-2 max-w-2xl">
                    Lihat seluruh mahasiswa bimbingan, pantau progress terbaru, dan akses detail bimbingan dengan cepat.
                </p>
            </div>
        </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-5 mb-6">
        <div class="tassist-stat-card rounded-[1.6rem] border p-5">
            <div class="relative z-10">
                <p class="text-sm theme-text-muted font-bold">Total Bimbingan</p>
                <h2 class="text-4xl font-black mt-3">{{ $stats['semua'] }}</h2>
                <p class="text-xs theme-text-subtle mt-3">Semua mahasiswa bimbingan</p>
            </div>
        </div>

        <a href="{{ route('dosen.mahasiswa-bimbingan.index', ['status' => 'aktif']) }}" class="tassist-stat-card rounded-[1.6rem] border p-5 block">
            <div class="relative z-10">
                <p class="text-sm theme-text-muted font-bold">Bimbingan Aktif</p>
                <h2 class="text-4xl font-black mt-3">{{ $stats['aktif'] }}</h2>
                <p class="text-xs theme-text-subtle mt-3">Sedang berjalan</p>
            </div>
        </a>

        <div class="tassist-stat-card rounded-[1.6rem] border p-5">
            <div class="relative z-10">
                <p class="text-sm theme-text-muted font-bold">Rata-rata Progress</p>
                <h2 class="text-4xl font-black mt-3">{{ $stats['rata_progress'] }}%</h2>
                <p class="text-xs theme-text-subtle mt-3">Dari progress terbaru</p>
            </div>
        </div>
    </div>

    <div class="rounded-[1.6rem] border tassist-filter-card p-5 mb-6">
        <form method="GET" action="{{ route('dosen.mahasiswa-bimbingan.index') }}" class="flex flex-col xl:flex-row gap-3">
            <input
                type="text"
                name="search"
                value="{{ $search }}"
                placeholder="Cari nama, NIM, prodi, judul TA, atau topik..."
                class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
            >

            <select
                name="status"
                class="px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
            >
                <option value="">Semua Status</option>
                <option value="aktif" {{ $status === 'aktif' ? 'selected' : '' }}>Aktif</option>
                <option value="selesai" {{ $status === 'selesai' ? 'selected' : '' }}>Selesai</option>
                <option value="nonaktif" {{ $status === 'nonaktif' ? 'selected' : '' }}>Nonaktif</option>
            </select>

            <button
                type="submit"
                class="px-5 py-3 rounded-2xl theme-primary-btn text-sm font-extrabold"
            >
                Cari
            </button>

            @if($search || $status)
                <a
                    href="{{ route('dosen.mahasiswa-bimbingan.index') }}"
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
                Daftar Mahasiswa
            </h2>
            <p class="text-sm theme-text-muted mt-1">
                Klik detail untuk melihat ringkasan bimbingan, jadwal, dokumen, dan progress mahasiswa.
            </p>
        </div>

        <div class="p-4 sm:p-5 space-y-4">
            @forelse($bimbingan as $item)
                @php
                    $mahasiswa = $item->mahasiswa;
                    $user = $mahasiswa?->user;
                    $progress = $item->progresAktif;
                    $progressValue = $progress ? (float) $progress->persentase : 0;
                    $taTitle = $mahasiswa?->judul_ta ?: ($item->permohonan?->topik_ta ?: $mahasiswa?->topik_ta);
                @endphp

                <div class="tassist-list-item rounded-2xl border p-5">
                    <div class="flex flex-col xl:flex-row xl:items-center xl:justify-between gap-5">
                        <div class="flex items-start gap-4 flex-1 min-w-0">
                            <div class="w-12 h-12 rounded-2xl theme-logo-bg text-white flex items-center justify-center font-black flex-shrink-0">
                                {{ strtoupper(substr($user->nama ?? 'M', 0, 1)) }}
                            </div>

                            <div class="min-w-0 flex-1">
                                <div class="flex flex-wrap items-center gap-2">
                                    <h3 class="font-black theme-text-main">
                                        {{ $user->nama ?? '-' }}
                                    </h3>

                                    @if($item->status_bimbingan === 'aktif')
                                        <span class="px-3 py-1 rounded-full text-xs font-bold theme-alert-success">
                                            Aktif
                                        </span>
                                    @else
                                        <span class="px-3 py-1 rounded-full text-xs font-bold theme-badge-primary">
                                            {{ ucfirst($item->status_bimbingan) }}
                                        </span>
                                    @endif
                                </div>

                                <p class="text-sm theme-text-muted mt-1">
                                    {{ $mahasiswa->nim ?? '-' }}
                                    • {{ $mahasiswa->prodi ?? '-' }}
                                    • Angkatan {{ $mahasiswa->angkatan ?? '-' }}
                                </p>

                                <div class="mt-4 rounded-2xl border tassist-mini-card p-4">
                                    <p class="text-xs uppercase tracking-wide theme-text-muted font-black">
                                        Judul / Topik TA
                                    </p>
                                    <p class="mt-1 theme-text-main font-semibold line-clamp-2">
                                        {{ $taTitle ?: '-' }}
                                    </p>
                                </div>

                                <p class="text-xs theme-text-muted mt-3">
                                    Mulai bimbingan: {{ optional($item->tanggal_mulai)->format('d M Y') ?? '-' }}
                                </p>
                            </div>
                        </div>

                        <div class="xl:w-72">
                            <div class="rounded-2xl border tassist-mini-card p-4 mb-3">
                                <div class="flex items-center justify-between text-xs mb-2">
                                    <span class="theme-text-muted font-bold">Progress</span>
                                    <span class="font-black theme-text-main">{{ $progressValue }}%</span>
                                </div>

                                <div class="w-full h-2.5 rounded-full overflow-hidden tassist-progress-track">
                                    <div
                                        class="h-full tassist-progress-fill rounded-full"
                                        style="width: {{ min(100, max(0, $progressValue)) }}%"
                                    ></div>
                                </div>

                                <p class="text-xs theme-text-muted mt-2">
                                    {{ $progress->status_progress ?? 'Belum ada progress' }}
                                </p>
                            </div>

                            <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-1 gap-2">
                                <a
                                    href="{{ route('dosen.mahasiswa-bimbingan.show', $item->bimbingan_id) }}"
                                    class="block px-4 py-2.5 rounded-2xl theme-primary-btn text-sm font-extrabold text-center"
                                >
                                    Detail Mahasiswa
                                </a>

                                <a
                                    href="{{ route('dosen.progress-checklist.show', $item->bimbingan_id) }}"
                                    class="block px-4 py-2.5 rounded-2xl border tassist-secondary-btn text-sm font-extrabold text-center"
                                >
                                    Kelola Progress
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            @empty
                <div class="tassist-empty-state rounded-2xl border p-10 text-center">
                    <p class="font-black theme-text-main">
                        Belum ada mahasiswa bimbingan.
                    </p>
                    <p class="text-sm theme-text-muted mt-2">
                        Mahasiswa akan muncul setelah permohonan bimbingan diterima.
                    </p>
                </div>
            @endforelse
        </div>

        @if($bimbingan->hasPages())
            <div class="p-5 border-t tassist-divider">
                {{ $bimbingan->links() }}
            </div>
        @endif
    </div>
@endsection