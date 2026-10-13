@extends('layout.dosen')

@section('content')
    @php
        $bimbingan = $jadwal->bimbingan;
        $mahasiswa = $bimbingan?->mahasiswa;
        $user = $mahasiswa?->user;
        $taTitle = $mahasiswa?->judul_ta ?: ($bimbingan?->permohonan?->topik_ta ?: $mahasiswa?->topik_ta);
    @endphp

    <div class="tassist-page-header rounded-[2rem] border p-6 sm:p-8 mb-6">
        <div class="flex flex-col xl:flex-row xl:items-start xl:justify-between gap-5">
            <div>
                <a
                    href="{{ route('dosen.jadwal.index') }}"
                    class="inline-flex items-center gap-2 text-sm theme-text-muted font-bold mb-4"
                >
                    ← Kembali ke daftar jadwal
                </a>

                <div class="tassist-page-kicker mb-4">
                    <span>●</span>
                    Detail Jadwal
                </div>

                <h1 class="text-3xl font-black tracking-tight theme-text-main">
                    Detail Jadwal Bimbingan
                </h1>

                <p class="theme-text-muted mt-2 max-w-2xl">
                    Lihat detail jadwal, data mahasiswa, dan lakukan konfirmasi jika jadwal diajukan oleh mahasiswa.
                </p>
            </div>

            <div>
                @if($jadwal->status_konfirmasi === 'menunggu')
                    <span class="px-4 py-2 rounded-full text-xs font-black theme-badge-primary">
                        Menunggu
                    </span>
                @elseif($jadwal->status_konfirmasi === 'dikonfirmasi')
                    <span class="px-4 py-2 rounded-full text-xs font-black theme-alert-success">
                        Dikonfirmasi
                    </span>
                @else
                    <span class="px-4 py-2 rounded-full text-xs font-black theme-alert-error">
                        Ditolak
                    </span>
                @endif
            </div>
        </div>
    </div>

    <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <div class="xl:col-span-2 space-y-6">
            <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                <h2 class="font-black text-xl theme-text-main mb-5">
                    Informasi Jadwal
                </h2>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div class="rounded-2xl border tassist-mini-card p-5">
                        <p class="text-xs uppercase tracking-wide theme-text-muted font-black">Tanggal</p>
                        <p class="mt-2 font-bold theme-text-main">
                            {{ optional($jadwal->tanggal)->format('d M Y') ?? '-' }}
                        </p>
                    </div>

                    <div class="rounded-2xl border tassist-mini-card p-5">
                        <p class="text-xs uppercase tracking-wide theme-text-muted font-black">Waktu</p>
                        <p class="mt-2 font-bold theme-text-main">
                            {{ substr($jadwal->waktu_mulai, 0, 5) }} - {{ substr($jadwal->waktu_selesai, 0, 5) }}
                        </p>
                    </div>

                    <div class="rounded-2xl border tassist-mini-card p-5">
                        <p class="text-xs uppercase tracking-wide theme-text-muted font-black">Mode</p>
                        <p class="mt-2 font-bold theme-text-main">
                            {{ ucfirst($jadwal->mode) }}
                        </p>
                    </div>

                    <div class="rounded-2xl border tassist-mini-card p-5">
                        <p class="text-xs uppercase tracking-wide theme-text-muted font-black">Pengaju</p>
                        <p class="mt-2 font-bold theme-text-main">
                            {{ $jadwal->pengaju->nama ?? '-' }}
                            <span class="theme-text-muted">
                                ({{ $jadwal->pengaju->role ?? '-' }})
                            </span>
                        </p>
                    </div>
                </div>

                @if($jadwal->catatan)
                    <div class="mt-5 rounded-2xl border tassist-mini-card p-5">
                        <p class="text-xs uppercase tracking-wide theme-text-muted font-black">Catatan</p>
                        <p class="mt-2 theme-text-main leading-relaxed">
                            {{ $jadwal->catatan }}
                        </p>
                    </div>
                @endif
            </div>

            <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                <h2 class="font-black text-xl theme-text-main mb-5">
                    Data Mahasiswa
                </h2>

                <div class="flex items-start gap-4">
                    <div class="w-14 h-14 rounded-2xl theme-logo-bg text-white flex items-center justify-center font-black text-lg flex-shrink-0">
                        {{ strtoupper(substr($user->nama ?? 'M', 0, 1)) }}
                    </div>

                    <div class="min-w-0">
                        <p class="font-black theme-text-main text-lg">
                            {{ $user->nama ?? '-' }}
                        </p>

                        <p class="text-sm theme-text-muted mt-1">
                            {{ $user->email ?? '-' }}
                        </p>

                        <p class="text-sm theme-text-muted mt-2">
                            {{ $mahasiswa->nim ?? '-' }}
                            • {{ $mahasiswa->prodi ?? '-' }}
                            • Angkatan {{ $mahasiswa->angkatan ?? '-' }}
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

                <div class="mt-6">
                    <a
                        href="{{ route('dosen.mahasiswa-bimbingan.show', $bimbingan->bimbingan_id) }}"
                        class="inline-block px-4 py-2.5 rounded-2xl border tassist-secondary-btn text-sm font-black"
                    >
                        Lihat Detail Mahasiswa
                    </a>
                </div>
            </div>
        </div>

        <div class="space-y-6">
            @if($canKonfirmasi)
                <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                    <h2 class="font-black text-xl theme-text-main mb-2">
                        Konfirmasi Jadwal
                    </h2>
                    <p class="text-sm theme-text-muted mb-5">
                        Pilih mode final dan tambahkan catatan bila diperlukan.
                    </p>

                    <form
                        method="POST"
                        action="{{ route('dosen.jadwal.konfirmasi', $jadwal->jadwal_id) }}"
                        class="space-y-4"
                    >
                        @csrf
                        @method('PUT')

                        <div>
                            <label class="block text-sm mb-2 theme-text-muted font-black">
                                Pilih Mode
                            </label>

                            <select
                                name="mode"
                                required
                                class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
                            >
                                <option value="">Pilih mode</option>
                                <option value="online" {{ $jadwal->mode === 'online' ? 'selected' : '' }}>Online</option>
                                <option value="offline" {{ $jadwal->mode === 'offline' ? 'selected' : '' }}>Offline</option>
                            </select>
                        </div>

                        <div>
                            <label class="block text-sm mb-2 theme-text-muted font-black">
                                Catatan Opsional
                            </label>

                            <textarea
                                name="catatan"
                                rows="3"
                                placeholder="Catatan tambahan..."
                                class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
                            ></textarea>
                        </div>

                        <button
                            type="submit"
                            class="w-full px-4 py-3 rounded-2xl theme-primary-btn text-sm font-black"
                        >
                            Konfirmasi Jadwal
                        </button>
                    </form>
                </div>

                <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                    <h2 class="font-black text-xl theme-text-main mb-2">
                        Tolak Jadwal
                    </h2>
                    <p class="text-sm theme-text-muted mb-5">
                        Berikan alasan penolakan agar mahasiswa memahami revisi jadwal.
                    </p>

                    <form
                        method="POST"
                        action="{{ route('dosen.jadwal.tolak', $jadwal->jadwal_id) }}"
                        class="space-y-4"
                    >
                        @csrf
                        @method('PUT')

                        <textarea
                            name="catatan"
                            rows="4"
                            required
                            placeholder="Tulis alasan penolakan..."
                            class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
                        ></textarea>

                        <button
                            type="submit"
                            class="w-full px-4 py-3 rounded-2xl border tassist-danger-btn text-sm font-black"
                        >
                            Tolak Jadwal
                        </button>
                    </form>
                </div>
            @else
                <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                    <h2 class="font-black text-xl theme-text-main mb-3">
                        Status Aksi
                    </h2>

                    @if($jadwal->status_konfirmasi !== 'menunggu')
                        <p class="text-sm theme-text-muted leading-relaxed">
                            Jadwal ini sudah diproses, sehingga tidak bisa dikonfirmasi ulang.
                        </p>
                    @elseif((int) $jadwal->pengaju_user_id === (int) session('dosen_user.user_id'))
                        <p class="text-sm theme-text-muted leading-relaxed">
                            Jadwal ini diajukan oleh Anda. Sesuai aturan sistem, dosen tidak dapat mengkonfirmasi jadwal yang diajukan sendiri.
                        </p>
                    @else
                        <p class="text-sm theme-text-muted leading-relaxed">
                            Tidak ada aksi tersedia untuk jadwal ini.
                        </p>
                    @endif
                </div>
            @endif

            <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                <h2 class="font-black text-xl theme-text-main mb-4">
                    Aksi Cepat
                </h2>

                <div class="space-y-3">
                    <a
                        href="{{ route('dosen.jadwal.create', ['bimbingan_id' => $bimbingan->bimbingan_id]) }}"
                        class="block w-full px-4 py-3 rounded-2xl theme-primary-btn text-sm font-black text-center"
                    >
                        + Jadwal Baru untuk Mahasiswa Ini
                    </a>

                    <a
                        href="{{ route('dosen.progress-checklist.show', $bimbingan->bimbingan_id) }}"
                        class="block w-full px-4 py-3 rounded-2xl border tassist-secondary-btn text-sm font-black text-center"
                    >
                        Kelola Progress
                    </a>

                    <a
                        href="{{ route('dosen.dokumen.index', ['bimbingan_id' => $bimbingan->bimbingan_id]) }}"
                        class="block w-full px-4 py-3 rounded-2xl border tassist-secondary-btn text-sm font-black text-center"
                    >
                        Dokumen & Feedback
                    </a>
                </div>
            </div>
        </div>
    </div>
@endsection