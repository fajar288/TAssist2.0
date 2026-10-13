@extends('layout.dosen')

@section('content')
    @php
        $mahasiswa = $bimbingan->mahasiswa;
        $user = $mahasiswa?->user;
        $taTitle = $mahasiswa?->judul_ta ?: ($bimbingan->permohonan?->topik_ta ?: $mahasiswa?->topik_ta);
        $progressValue = $latestProgress ? (float) $latestProgress->persentase : 0;
    @endphp

    <div class="tassist-page-header rounded-[2rem] border p-6 sm:p-8 mb-6">
        <div class="flex flex-col xl:flex-row xl:items-start xl:justify-between gap-5">
            <div>
                <a
                    href="{{ route('dosen.mahasiswa-bimbingan.index') }}"
                    class="inline-flex items-center gap-2 text-sm theme-text-muted font-bold mb-4"
                >
                    ← Kembali ke mahasiswa bimbingan
                </a>

                <div class="tassist-page-kicker mb-4">
                    <span>●</span>
                    Detail Mahasiswa
                </div>

                <h1 class="text-3xl font-black tracking-tight theme-text-main">
                    Detail Mahasiswa Bimbingan
                </h1>

                <p class="theme-text-muted mt-2 max-w-2xl">
                    Ringkasan data mahasiswa, progress terbaru, jadwal, dokumen, dan akses cepat pengelolaan bimbingan.
                </p>
            </div>

            <div>
                @if($bimbingan->status_bimbingan === 'aktif')
                    <span class="px-4 py-2 rounded-full text-xs font-black theme-alert-success">
                        Bimbingan Aktif
                    </span>
                @else
                    <span class="px-4 py-2 rounded-full text-xs font-black theme-badge-primary">
                        {{ ucfirst($bimbingan->status_bimbingan) }}
                    </span>
                @endif
            </div>
        </div>
    </div>

    <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <div class="xl:col-span-2 space-y-6">

            <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                <div class="flex items-start gap-4">
                    <div class="w-16 h-16 rounded-2xl theme-logo-bg text-white flex items-center justify-center font-black text-xl flex-shrink-0">
                        {{ strtoupper(substr($user->nama ?? 'M', 0, 1)) }}
                    </div>

                    <div class="min-w-0">
                        <h2 class="text-2xl font-black theme-text-main">
                            {{ $user->nama ?? '-' }}
                        </h2>

                        <p class="theme-text-muted mt-1">
                            {{ $user->email ?? '-' }}
                        </p>

                        <p class="text-sm theme-text-muted mt-2">
                            {{ $mahasiswa->nim ?? '-' }}
                            • {{ $mahasiswa->prodi ?? '-' }}
                            • Angkatan {{ $mahasiswa->angkatan ?? '-' }}
                        </p>
                    </div>
                </div>

                <div class="mt-6 grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div class="rounded-2xl border tassist-mini-card p-5">
                        <p class="text-xs uppercase tracking-wide theme-text-muted font-black">
                            Mulai Bimbingan
                        </p>
                        <p class="mt-2 font-bold theme-text-main">
                            {{ optional($bimbingan->tanggal_mulai)->format('d M Y') ?? '-' }}
                        </p>
                    </div>

                    <div class="rounded-2xl border tassist-mini-card p-5">
                        <p class="text-xs uppercase tracking-wide theme-text-muted font-black">
                            Status Bimbingan
                        </p>
                        <p class="mt-2 font-bold theme-text-main">
                            {{ ucfirst($bimbingan->status_bimbingan) }}
                        </p>
                    </div>
                </div>

                <div class="mt-6 rounded-2xl border tassist-mini-card p-5">
                    <p class="text-xs uppercase tracking-wide theme-text-muted font-black">
                        Judul / Topik TA
                    </p>
                    <p class="mt-2 theme-text-main font-bold leading-relaxed">
                        {{ $taTitle ?: '-' }}
                    </p>
                </div>
            </div>

            <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                <div class="flex flex-col md:flex-row md:items-start md:justify-between gap-4 mb-5">
                    <div>
                        <h2 class="font-black text-xl theme-text-main">
                            Progress Terbaru
                        </h2>
                        <p class="text-sm theme-text-muted mt-1">
                            Update progress terakhir dari bimbingan mahasiswa.
                        </p>
                    </div>

                    <div class="text-left md:text-right">
                        <p class="text-4xl font-black theme-text-main">
                            {{ $progressValue }}%
                        </p>
                        <p class="text-xs theme-text-muted">
                            {{ $latestProgress->status_progress ?? 'Belum ada progress' }}
                        </p>
                    </div>
                </div>

                @if($latestProgress)
                    <div class="w-full h-3 rounded-full overflow-hidden tassist-progress-track">
                        <div
                            class="h-full tassist-progress-fill rounded-full"
                            style="width: {{ min(100, max(0, $progressValue)) }}%"
                        ></div>
                    </div>

                    @if($latestProgress->catatan)
                        <div class="mt-5 rounded-2xl border tassist-mini-card p-5">
                            <p class="text-xs uppercase tracking-wide theme-text-muted font-black">
                                Catatan Progress
                            </p>
                            <p class="mt-2 text-sm theme-text-main leading-relaxed">
                                {{ $latestProgress->catatan }}
                            </p>
                        </div>
                    @endif

                    <p class="mt-3 text-xs theme-text-muted">
                        Update terakhir:
                        {{ optional($latestProgress->updated_at)->format('d M Y H:i') ?? '-' }}
                    </p>

                    <div class="mt-6">
                        <div class="flex items-center justify-between gap-4 mb-3">
                            <h3 class="font-black theme-text-main">
                                Checklist Terbaru
                            </h3>

                            <a
                                href="{{ route('dosen.progress-checklist.show', $bimbingan->bimbingan_id) }}"
                                class="text-sm font-black theme-text-muted"
                            >
                                Kelola
                            </a>
                        </div>

                        <div class="space-y-3">
                            @forelse($latestChecklist as $checklist)
                                <div class="flex items-start gap-3 p-4 rounded-2xl border tassist-mini-card">
                                    <div class="mt-0.5">
                                        @if($checklist->tgl_selesai)
                                            ✅
                                        @else
                                            ⏳
                                        @endif
                                    </div>

                                    <div class="min-w-0">
                                        <p class="font-bold theme-text-main">
                                            {{ $checklist->nama_item }}
                                        </p>

                                        @if($checklist->catatan)
                                            <p class="text-sm theme-text-muted mt-1 leading-relaxed">
                                                {{ $checklist->catatan }}
                                            </p>
                                        @endif
                                    </div>
                                </div>
                            @empty
                                <div class="rounded-2xl border tassist-empty-state p-6 text-center">
                                    <p class="text-sm theme-text-muted">
                                        Belum ada checklist pada progress terbaru.
                                    </p>
                                </div>
                            @endforelse
                        </div>
                    </div>
                @else
                    <div class="tassist-empty-state rounded-2xl border p-8 text-center">
                        <p class="font-black theme-text-main">
                            Belum ada data progress.
                        </p>
                        <p class="text-sm theme-text-muted mt-2">
                            Progress akan muncul setelah dosen membuat update progress.
                        </p>
                    </div>
                @endif
            </div>

            <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                <div class="flex items-center justify-between gap-4 mb-5">
                    <div>
                        <h2 class="font-black text-xl theme-text-main">
                            Jadwal Terbaru
                        </h2>
                        <p class="text-sm theme-text-muted mt-1">
                            Beberapa jadwal bimbingan terbaru mahasiswa ini.
                        </p>
                    </div>
                </div>

                <div class="space-y-3">
                    @forelse($recentJadwal as $jadwal)
                        <div class="p-4 rounded-2xl border tassist-mini-card">
                            <div class="flex items-start justify-between gap-3">
                                <div>
                                    <p class="font-bold theme-text-main">
                                        {{ optional($jadwal->tanggal)->format('d M Y') ?? $jadwal->tanggal }}
                                    </p>
                                    <p class="text-sm theme-text-muted mt-1">
                                        {{ substr($jadwal->waktu_mulai, 0, 5) }} - {{ substr($jadwal->waktu_selesai, 0, 5) }}
                                        • {{ ucfirst($jadwal->mode) }}
                                    </p>
                                </div>

                                @if($jadwal->status_konfirmasi === 'dikonfirmasi')
                                    <span class="px-3 py-1 rounded-full text-xs font-bold theme-alert-success">
                                        Dikonfirmasi
                                    </span>
                                @elseif($jadwal->status_konfirmasi === 'ditolak')
                                    <span class="px-3 py-1 rounded-full text-xs font-bold theme-alert-error">
                                        Ditolak
                                    </span>
                                @else
                                    <span class="px-3 py-1 rounded-full text-xs font-bold theme-badge-primary">
                                        Menunggu
                                    </span>
                                @endif
                            </div>

                            @if($jadwal->catatan)
                                <p class="text-sm theme-text-muted mt-3 leading-relaxed">
                                    {{ $jadwal->catatan }}
                                </p>
                            @endif
                        </div>
                    @empty
                        <div class="tassist-empty-state rounded-2xl border p-8 text-center">
                            <p class="text-sm theme-text-muted">
                                Belum ada jadwal bimbingan.
                            </p>
                        </div>
                    @endforelse
                </div>
            </div>
        </div>

        <div class="space-y-6">
            <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                <h2 class="font-black text-xl theme-text-main mb-5">
                    Ringkasan
                </h2>

                <div class="space-y-4">
                    <div class="rounded-2xl border tassist-mini-card p-5">
                        <p class="text-sm theme-text-muted">Total Jadwal</p>
                        <h3 class="text-3xl font-black mt-1 theme-text-main">
                            {{ $bimbingan->jadwal_bimbingan_count }}
                        </h3>
                    </div>

                    <div class="rounded-2xl border tassist-mini-card p-5">
                        <p class="text-sm theme-text-muted">Total Dokumen</p>
                        <h3 class="text-3xl font-black mt-1 theme-text-main">
                            {{ $bimbingan->dokumen_t_a_count }}
                        </h3>
                    </div>

                    <div class="rounded-2xl border tassist-mini-card p-5">
                        <p class="text-sm theme-text-muted">Riwayat Progress</p>
                        <h3 class="text-3xl font-black mt-1 theme-text-main">
                            {{ $bimbingan->progres_t_a_count }}
                        </h3>
                    </div>
                </div>
            </div>

            <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                <h2 class="font-black text-xl theme-text-main mb-5">
                    Dokumen Terbaru
                </h2>

                <div class="space-y-3">
                    @forelse($recentDokumen as $dokumen)
                        <a
                            href="{{ route('dosen.dokumen.show', $dokumen->dokumen_id) }}"
                            class="block p-4 rounded-2xl border tassist-mini-card"
                        >
                            <p class="font-bold theme-text-main">
                                {{ $dokumen->judul_dokumen ?? '-' }}
                            </p>

                            <p class="text-sm theme-text-muted mt-1">
                                {{ $dokumen->jenis_dokumen ?? '-' }}
                            </p>
                        </a>
                    @empty
                        <div class="tassist-empty-state rounded-2xl border p-6 text-center">
                            <p class="text-sm theme-text-muted">
                                Belum ada dokumen.
                            </p>
                        </div>
                    @endforelse
                </div>
            </div>

            <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                <h2 class="font-black text-xl theme-text-main mb-4">
                    Aksi Berikutnya
                </h2>

                <div class="space-y-3">
                    <a
                        href="{{ route('dosen.jadwal.create', ['bimbingan_id' => $bimbingan->bimbingan_id]) }}"
                        class="block px-4 py-3 rounded-2xl theme-primary-btn text-sm font-black text-center"
                    >
                        + Buat Jadwal Bimbingan
                    </a>

                    <a
                        href="{{ route('dosen.jadwal.index') }}"
                        class="block px-4 py-3 rounded-2xl border tassist-secondary-btn text-sm font-black text-center"
                    >
                        Lihat Semua Jadwal
                    </a>

                    <a
                        href="{{ route('dosen.dokumen.index', ['bimbingan_id' => $bimbingan->bimbingan_id]) }}"
                        class="block px-4 py-3 rounded-2xl border tassist-secondary-btn text-sm font-black text-center"
                    >
                        Lihat Dokumen & Feedback
                    </a>

                    <a
                        href="{{ route('dosen.progress-checklist.show', $bimbingan->bimbingan_id) }}"
                        class="block px-4 py-3 rounded-2xl border tassist-secondary-btn text-sm font-black text-center"
                    >
                        Kelola Progress & Checklist
                    </a>
                </div>
            </div>
        </div>
    </div>
@endsection