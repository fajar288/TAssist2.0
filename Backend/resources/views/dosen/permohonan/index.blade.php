@extends('layout.dosen')

@section('content')
    <div class="tassist-page-header rounded-[2rem] border p-6 sm:p-8 mb-6">
        <div class="flex flex-col xl:flex-row xl:items-end xl:justify-between gap-5">
            <div>
                <div class="tassist-page-kicker mb-4">
                    <span>●</span>
                    Permohonan
                </div>

                <h1 class="text-3xl font-black tracking-tight theme-text-main">
                    Permohonan Bimbingan
                </h1>

                <p class="theme-text-muted mt-2 max-w-2xl">
                    Kelola permohonan bimbingan tugas akhir dari mahasiswa. Terima permohonan yang sesuai atau berikan alasan penolakan.
                </p>
            </div>

            <form method="GET" action="{{ route('dosen.permohonan.index') }}" class="flex flex-col sm:flex-row gap-3">
                <select
                    name="status"
                    class="px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
                >
                    <option value="">Semua Status</option>
                    <option value="menunggu" {{ $status === 'menunggu' ? 'selected' : '' }}>Menunggu</option>
                    <option value="diterima" {{ $status === 'diterima' ? 'selected' : '' }}>Diterima</option>
                    <option value="ditolak" {{ $status === 'ditolak' ? 'selected' : '' }}>Ditolak</option>
                </select>

                <button
                    type="submit"
                    class="px-5 py-3 rounded-2xl theme-primary-btn text-sm font-extrabold"
                >
                    Filter
                </button>

                @if($status)
                    <a
                        href="{{ route('dosen.permohonan.index') }}"
                        class="px-5 py-3 rounded-2xl border tassist-secondary-btn text-sm font-extrabold text-center"
                    >
                        Reset
                    </a>
                @endif
            </form>
        </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-4 gap-5 mb-6">
        <a href="{{ route('dosen.permohonan.index') }}" class="tassist-stat-card rounded-[1.6rem] border p-5 block">
            <div class="relative z-10">
                <p class="text-sm theme-text-muted font-bold">Semua</p>
                <h2 class="text-4xl font-black mt-3">{{ $stats['semua'] }}</h2>
                <p class="text-xs theme-text-subtle mt-3">Total permohonan masuk</p>
            </div>
        </a>

        <a href="{{ route('dosen.permohonan.index', ['status' => 'menunggu']) }}" class="tassist-stat-card rounded-[1.6rem] border p-5 block">
            <div class="relative z-10">
                <p class="text-sm theme-text-muted font-bold">Menunggu</p>
                <h2 class="text-4xl font-black mt-3">{{ $stats['menunggu'] }}</h2>
                <p class="text-xs theme-text-subtle mt-3">Perlu diproses</p>
            </div>
        </a>

        <a href="{{ route('dosen.permohonan.index', ['status' => 'diterima']) }}" class="tassist-stat-card rounded-[1.6rem] border p-5 block">
            <div class="relative z-10">
                <p class="text-sm theme-text-muted font-bold">Diterima</p>
                <h2 class="text-4xl font-black mt-3">{{ $stats['diterima'] }}</h2>
                <p class="text-xs theme-text-subtle mt-3">Sudah menjadi bimbingan</p>
            </div>
        </a>

        <a href="{{ route('dosen.permohonan.index', ['status' => 'ditolak']) }}" class="tassist-stat-card rounded-[1.6rem] border p-5 block">
            <div class="relative z-10">
                <p class="text-sm theme-text-muted font-bold">Ditolak</p>
                <h2 class="text-4xl font-black mt-3">{{ $stats['ditolak'] }}</h2>
                <p class="text-xs theme-text-subtle mt-3">Tidak disetujui</p>
            </div>
        </a>
    </div>

    <div class="rounded-[1.6rem] border tassist-list-shell overflow-hidden">
        <div class="p-5 sm:p-6 border-b tassist-divider">
            <h2 class="font-black text-xl theme-text-main">
                Daftar Permohonan
            </h2>
            <p class="text-sm theme-text-muted mt-1">
                Data permohonan bimbingan berdasarkan dosen yang sedang login.
            </p>
        </div>

        <div class="p-4 sm:p-5 space-y-4">
            @forelse($permohonan as $item)
                <div class="tassist-list-item rounded-2xl border p-5">
                    <div class="flex flex-col xl:flex-row xl:items-start xl:justify-between gap-5">
                        <div class="flex items-start gap-4 flex-1 min-w-0">
                            <div class="w-12 h-12 rounded-2xl theme-logo-bg text-white flex items-center justify-center font-black flex-shrink-0">
                                {{ strtoupper(substr($item->mahasiswa->user->nama ?? 'M', 0, 1)) }}
                            </div>

                            <div class="min-w-0 flex-1">
                                <div class="flex flex-wrap items-center gap-2">
                                    <h3 class="font-black theme-text-main">
                                        {{ $item->mahasiswa->user->nama ?? '-' }}
                                    </h3>

                                    @if($item->status === 'menunggu')
                                        <span class="px-3 py-1 rounded-full text-xs font-bold theme-badge-primary">
                                            Menunggu
                                        </span>
                                    @elseif($item->status === 'diterima')
                                        <span class="px-3 py-1 rounded-full text-xs font-bold theme-alert-success">
                                            Diterima
                                        </span>
                                    @else
                                        <span class="px-3 py-1 rounded-full text-xs font-bold theme-alert-error">
                                            Ditolak
                                        </span>
                                    @endif
                                </div>

                                <p class="text-sm theme-text-muted mt-1">
                                    {{ $item->mahasiswa->nim ?? '-' }}
                                    • {{ $item->mahasiswa->prodi ?? '-' }}
                                    • Angkatan {{ $item->mahasiswa->angkatan ?? '-' }}
                                </p>

                                <div class="mt-4 rounded-2xl border tassist-mini-card p-4">
                                    <p class="text-xs uppercase tracking-wide theme-text-muted font-black">
                                        Topik TA
                                    </p>
                                    <p class="mt-1 theme-text-main font-semibold leading-relaxed">
                                        {{ $item->topik_ta ?? '-' }}
                                    </p>
                                </div>

                                <p class="text-xs theme-text-muted mt-3">
                                    Diajukan pada {{ optional($item->tanggal_pengajuan)->format('d M Y') ?? '-' }}
                                </p>

                                @if($item->catatan_respons)
                                    <div class="mt-4 p-4 rounded-2xl border tassist-mini-card">
                                        <p class="text-xs uppercase tracking-wide theme-text-muted font-black">
                                            Catatan Respons
                                        </p>
                                        <p class="text-sm mt-1 theme-text-main leading-relaxed">
                                            {{ $item->catatan_respons }}
                                        </p>
                                    </div>
                                @endif
                            </div>
                        </div>

                        <div class="flex flex-col sm:flex-row xl:flex-col gap-2 xl:w-48">
                            <a
                                href="{{ route('dosen.permohonan.show', $item->permohonan_id) }}"
                                class="px-4 py-2.5 rounded-2xl border tassist-secondary-btn text-sm font-extrabold text-center"
                            >
                                Detail
                            </a>

                            @if($item->status === 'menunggu')
                                <form
                                    method="POST"
                                    action="{{ route('dosen.permohonan.terima', $item->permohonan_id) }}"
                                    onsubmit="return confirm('Terima permohonan bimbingan ini?')"
                                >
                                    @csrf
                                    @method('PUT')

                                    <button
                                        type="submit"
                                        class="w-full px-4 py-2.5 rounded-2xl theme-primary-btn text-sm font-extrabold"
                                    >
                                        Terima
                                    </button>
                                </form>

                                <details class="rounded-2xl border tassist-secondary-btn">
                                    <summary class="cursor-pointer px-4 py-2.5 text-sm font-extrabold">
                                        Tolak
                                    </summary>

                                    <form
                                        method="POST"
                                        action="{{ route('dosen.permohonan.tolak', $item->permohonan_id) }}"
                                        class="p-3 pt-1 space-y-3"
                                    >
                                        @csrf
                                        @method('PUT')

                                        <textarea
                                            name="catatan_respons"
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
                        Belum ada permohonan bimbingan.
                    </p>
                    <p class="text-sm theme-text-muted mt-2">
                        Permohonan dari mahasiswa akan muncul di halaman ini.
                    </p>
                </div>
            @endforelse
        </div>

        @if($permohonan->hasPages())
            <div class="p-5 border-t tassist-divider">
                {{ $permohonan->links() }}
            </div>
        @endif
    </div>
@endsection