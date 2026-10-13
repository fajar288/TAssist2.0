@extends('layout.dosen')

@section('content')
    <div class="tassist-page-header rounded-[2rem] border p-6 sm:p-8 mb-6">
        <div class="flex flex-col xl:flex-row xl:items-start xl:justify-between gap-5">
            <div>
                <a
                    href="{{ route('dosen.permohonan.index') }}"
                    class="inline-flex items-center gap-2 text-sm theme-text-muted font-bold mb-4"
                >
                    ← Kembali ke daftar permohonan
                </a>

                <div class="tassist-page-kicker mb-4">
                    <span>●</span>
                    Detail Permohonan
                </div>

                <h1 class="text-3xl font-black tracking-tight theme-text-main">
                    Detail Permohonan Bimbingan
                </h1>

                <p class="theme-text-muted mt-2 max-w-2xl">
                    Review data mahasiswa dan topik TA sebelum menerima atau menolak permohonan bimbingan.
                </p>
            </div>

            <div>
                @if($permohonan->status === 'menunggu')
                    <span class="px-4 py-2 rounded-full text-xs font-black theme-badge-primary">
                        Menunggu
                    </span>
                @elseif($permohonan->status === 'diterima')
                    <span class="px-4 py-2 rounded-full text-xs font-black theme-alert-success">
                        Diterima
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
                <div class="flex items-center justify-between gap-4 mb-6">
                    <div>
                        <h2 class="font-black text-xl theme-text-main">
                            Informasi Permohonan
                        </h2>
                        <p class="text-sm theme-text-muted mt-1">
                            Data utama permohonan yang diajukan mahasiswa.
                        </p>
                    </div>
                </div>

                <div class="space-y-4">
                    <div class="rounded-2xl border tassist-mini-card p-5">
                        <p class="text-xs uppercase tracking-wide theme-text-muted font-black">
                            Topik TA
                        </p>
                        <p class="mt-2 theme-text-main font-bold leading-relaxed">
                            {{ $permohonan->topik_ta ?? '-' }}
                        </p>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div class="rounded-2xl border tassist-mini-card p-5">
                            <p class="text-xs uppercase tracking-wide theme-text-muted font-black">
                                Tanggal Pengajuan
                            </p>
                            <p class="mt-2 theme-text-main font-bold">
                                {{ optional($permohonan->tanggal_pengajuan)->format('d M Y') ?? '-' }}
                            </p>
                        </div>

                        <div class="rounded-2xl border tassist-mini-card p-5">
                            <p class="text-xs uppercase tracking-wide theme-text-muted font-black">
                                Status
                            </p>
                            <p class="mt-2 theme-text-main font-bold">
                                {{ ucfirst($permohonan->status) }}
                            </p>
                        </div>
                    </div>

                    @if($permohonan->catatan_respons)
                        <div class="rounded-2xl border tassist-mini-card p-5">
                            <p class="text-xs uppercase tracking-wide theme-text-muted font-black">
                                Catatan Respons
                            </p>
                            <p class="mt-2 theme-text-main leading-relaxed">
                                {{ $permohonan->catatan_respons }}
                            </p>
                        </div>
                    @endif

                    @if($permohonan->bimbingan)
                        <div class="rounded-2xl border theme-alert-success p-5">
                            <p class="text-xs uppercase tracking-wide font-black">
                                Data Bimbingan
                            </p>
                            <p class="mt-2 font-bold">
                                Bimbingan aktif sejak
                                {{ optional($permohonan->bimbingan->tanggal_mulai)->format('d M Y') ?? '-' }}
                            </p>
                        </div>
                    @endif
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
                        {{ strtoupper(substr($permohonan->mahasiswa->user->nama ?? 'M', 0, 1)) }}
                    </div>

                    <div class="min-w-0">
                        <p class="font-black theme-text-main truncate">
                            {{ $permohonan->mahasiswa->user->nama ?? '-' }}
                        </p>
                        <p class="text-sm theme-text-muted truncate">
                            {{ $permohonan->mahasiswa->user->email ?? '-' }}
                        </p>
                    </div>
                </div>

                <div class="space-y-3">
                    <div class="rounded-2xl border tassist-mini-card p-4">
                        <p class="text-xs theme-text-muted font-black uppercase tracking-wide">NIM</p>
                        <p class="font-bold theme-text-main mt-1">{{ $permohonan->mahasiswa->nim ?? '-' }}</p>
                    </div>

                    <div class="rounded-2xl border tassist-mini-card p-4">
                        <p class="text-xs theme-text-muted font-black uppercase tracking-wide">Program Studi</p>
                        <p class="font-bold theme-text-main mt-1">{{ $permohonan->mahasiswa->prodi ?? '-' }}</p>
                    </div>

                    <div class="rounded-2xl border tassist-mini-card p-4">
                        <p class="text-xs theme-text-muted font-black uppercase tracking-wide">Angkatan</p>
                        <p class="font-bold theme-text-main mt-1">{{ $permohonan->mahasiswa->angkatan ?? '-' }}</p>
                    </div>
                </div>
            </div>

            @if($permohonan->status === 'menunggu')
                <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                    <h2 class="font-black text-xl theme-text-main mb-2">
                        Aksi Permohonan
                    </h2>
                    <p class="text-sm theme-text-muted mb-5">
                        Terima untuk membuat bimbingan aktif, atau tolak dengan alasan yang jelas.
                    </p>

                    <form
                        method="POST"
                        action="{{ route('dosen.permohonan.terima', $permohonan->permohonan_id) }}"
                        onsubmit="return confirm('Terima permohonan bimbingan ini?')"
                        class="mb-4"
                    >
                        @csrf
                        @method('PUT')

                        <button
                            type="submit"
                            class="w-full px-4 py-3 rounded-2xl theme-primary-btn text-sm font-black"
                        >
                            Terima Permohonan
                        </button>
                    </form>

                    <div class="rounded-2xl border tassist-mini-card p-4">
                        <p class="font-black theme-text-main mb-3">
                            Tolak Permohonan
                        </p>

                        <form
                            method="POST"
                            action="{{ route('dosen.permohonan.tolak', $permohonan->permohonan_id) }}"
                            class="space-y-3"
                        >
                            @csrf
                            @method('PUT')

                            <textarea
                                name="catatan_respons"
                                rows="4"
                                required
                                placeholder="Tulis alasan penolakan..."
                                class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
                            ></textarea>

                            <button
                                type="submit"
                                class="w-full px-4 py-3 rounded-2xl border tassist-danger-btn text-sm font-black"
                            >
                                Tolak Permohonan
                            </button>
                        </form>
                    </div>
                </div>
            @else
                <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                    <h2 class="font-black text-xl theme-text-main mb-2">
                        Status Aksi
                    </h2>
                    <p class="text-sm theme-text-muted">
                        Permohonan ini sudah diproses, sehingga tidak tersedia aksi lanjutan.
                    </p>
                </div>
            @endif
        </div>
    </div>
@endsection