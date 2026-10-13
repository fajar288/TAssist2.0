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
                    href="{{ route('dosen.progress-checklist.index') }}"
                    class="inline-flex items-center gap-2 text-sm theme-text-muted font-bold mb-4"
                >
                    ← Kembali ke Progress & Checklist
                </a>

                <div class="tassist-page-kicker mb-4">
                    <span>●</span>
                    Detail Progress
                </div>

                <h1 class="text-3xl font-black tracking-tight theme-text-main">
                    Progress & Checklist
                </h1>

                <p class="theme-text-muted mt-2 max-w-2xl">
                    Update progress tugas akhir, kelola checklist target, dan pantau riwayat perkembangan mahasiswa.
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
                            Progress terbaru ditampilkan berdasarkan update terakhir dosen.
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

                <div class="w-full h-3 rounded-full overflow-hidden tassist-progress-track">
                    <div
                        class="h-full tassist-progress-fill rounded-full"
                        style="width: {{ min(100, max(0, $progressValue)) }}%"
                    ></div>
                </div>

                @if($latestProgress?->catatan)
                    <div class="mt-5 rounded-2xl border tassist-mini-card p-5">
                        <p class="text-xs uppercase tracking-wide theme-text-muted font-black">
                            Catatan Progress
                        </p>
                        <p class="text-sm theme-text-main mt-2 leading-relaxed">
                            {{ $latestProgress->catatan }}
                        </p>
                    </div>
                @endif

                @if($latestProgress)
                    <p class="text-xs theme-text-muted mt-3">
                        Update terakhir:
                        {{ optional($latestProgress->updated_at)->format('d M Y H:i') ?? '-' }}
                    </p>
                @endif
            </div>

            <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                <h2 class="font-black text-xl theme-text-main mb-2">
                    Update Progress Baru
                </h2>
                <p class="text-sm theme-text-muted mb-5">
                    Setiap update akan membuat record progress baru dan mengirim notifikasi ke mahasiswa.
                </p>

                <form
                    method="POST"
                    action="{{ route('dosen.progress-checklist.progress.store', $bimbingan->bimbingan_id) }}"
                    class="space-y-5"
                >
                    @csrf

                    <div>
                        <label class="block text-sm mb-2 theme-text-muted font-black">
                            Persentase Progress
                        </label>

                        <input
                            type="number"
                            step="0.1"
                            min="0"
                            max="100"
                            name="persentase"
                            value="{{ old('persentase', $progressValue) }}"
                            required
                            class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
                        >
                    </div>

                    <div>
                        <label class="block text-sm mb-2 theme-text-muted font-black">
                            Status Progress
                        </label>

                        <input
                            type="text"
                            name="status_progress"
                            value="{{ old('status_progress') }}"
                            placeholder="Contoh: Bab 2 selesai / Revisi proposal / Persiapan sidang"
                            required
                            class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
                        >
                    </div>

                    <div>
                        <label class="block text-sm mb-2 theme-text-muted font-black">
                            Catatan
                        </label>

                        <textarea
                            name="catatan"
                            rows="4"
                            placeholder="Catatan tambahan untuk mahasiswa..."
                            class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
                        >{{ old('catatan') }}</textarea>
                    </div>

                    <button
                        type="submit"
                        class="px-5 py-3 rounded-2xl theme-primary-btn text-sm font-black"
                    >
                        Simpan Progress Baru
                    </button>
                </form>
            </div>

            <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                <div class="flex flex-col md:flex-row md:items-start md:justify-between gap-4 mb-5">
                    <div>
                        <h2 class="font-black text-xl theme-text-main">
                            Checklist Progress Terbaru
                        </h2>
                        <p class="text-sm theme-text-muted mt-1">
                            Checklist ini terhubung ke progress terbaru mahasiswa.
                        </p>
                    </div>

                    <div class="text-left md:text-right">
                        <p class="text-3xl font-black theme-text-main">
                            {{ $checklistSummary['selesai'] }}/{{ $checklistSummary['total'] }}
                        </p>
                        <p class="text-xs theme-text-muted">
                            Selesai
                        </p>
                    </div>
                </div>

                <form
                    method="POST"
                    action="{{ route('dosen.progress-checklist.checklist.store', $bimbingan->bimbingan_id) }}"
                    class="p-5 rounded-2xl border tassist-mini-card space-y-4 mb-6"
                >
                    @csrf

                    <h3 class="font-black theme-text-main">
                        Tambah Checklist Baru
                    </h3>

                    <div>
                        <label class="block text-sm mb-2 theme-text-muted font-black">
                            Nama Item
                        </label>

                        <input
                            type="text"
                            name="nama_item"
                            value="{{ old('nama_item') }}"
                            placeholder="Contoh: Revisi latar belakang / Lengkapi daftar pustaka"
                            required
                            class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
                        >
                    </div>

                    <div>
                        <label class="block text-sm mb-2 theme-text-muted font-black">
                            Catatan
                        </label>

                        <textarea
                            name="catatan"
                            rows="3"
                            placeholder="Catatan opsional..."
                            class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
                        >{{ old('catatan') }}</textarea>
                    </div>

                    <label class="flex items-center gap-2 text-sm theme-text-main font-bold">
                        <input type="hidden" name="tgl_selesai" value="0">
                        <input type="checkbox" name="tgl_selesai" value="1">
                        Tandai langsung sebagai selesai
                    </label>

                    <button
                        type="submit"
                        class="px-5 py-3 rounded-2xl theme-primary-btn text-sm font-black"
                    >
                        Tambah Checklist
                    </button>
                </form>

                <div class="space-y-4">
                    @forelse($latestChecklist as $checklist)
                        <div class="rounded-2xl border tassist-mini-card p-5">
                            <form
                                method="POST"
                                action="{{ route('dosen.progress-checklist.checklist.update', $checklist->checklist_id) }}"
                                class="space-y-4"
                            >
                                @csrf
                                @method('PUT')

                                <div class="flex flex-col xl:flex-row xl:items-start xl:justify-between gap-4">
                                    <div class="flex-1">
                                        <label class="block text-sm mb-2 theme-text-muted font-black">
                                            Nama Item
                                        </label>

                                        <input
                                            type="text"
                                            name="nama_item"
                                            value="{{ $checklist->nama_item }}"
                                            required
                                            class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
                                        >
                                    </div>

                                    <div class="xl:w-52">
                                        <label class="block text-sm mb-2 theme-text-muted font-black">
                                            Status
                                        </label>

                                        <label class="flex items-center gap-2 px-4 py-3 rounded-2xl border tassist-secondary-btn text-sm font-bold">
                                            <input type="hidden" name="tgl_selesai" value="0">
                                            <input
                                                type="checkbox"
                                                name="tgl_selesai"
                                                value="1"
                                                {{ $checklist->tgl_selesai ? 'checked' : '' }}
                                            >
                                            Selesai
                                        </label>
                                    </div>
                                </div>

                                <div>
                                    <label class="block text-sm mb-2 theme-text-muted font-black">
                                        Catatan
                                    </label>

                                    <textarea
                                        name="catatan"
                                        rows="3"
                                        class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
                                    >{{ $checklist->catatan }}</textarea>
                                </div>

                                @if($checklist->tgl_selesai)
                                    <p class="text-xs theme-text-muted">
                                        Selesai pada:
                                        {{ optional($checklist->tanggal_selesai)->format('d M Y') ?? '-' }}
                                    </p>
                                @endif

                                <button
                                    type="submit"
                                    class="px-5 py-3 rounded-2xl theme-primary-btn text-sm font-black"
                                >
                                    Simpan Checklist
                                </button>
                            </form>

                            <form
                                method="POST"
                                action="{{ route('dosen.progress-checklist.checklist.destroy', $checklist->checklist_id) }}"
                                onsubmit="return confirm('Hapus checklist ini?')"
                                class="mt-3"
                            >
                                @csrf
                                @method('DELETE')

                                <button
                                    type="submit"
                                    class="px-5 py-3 rounded-2xl border tassist-danger-btn text-sm font-black"
                                >
                                    Hapus Checklist
                                </button>
                            </form>
                        </div>
                    @empty
                        <div class="tassist-empty-state rounded-2xl border p-8 text-center">
                            <p class="font-black theme-text-main">
                                Belum ada checklist.
                            </p>
                            <p class="text-sm theme-text-muted mt-2">
                                Tambahkan checklist target untuk progress terbaru mahasiswa.
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
                        <p class="text-sm theme-text-muted">Progress Terbaru</p>
                        <h3 class="text-3xl font-black mt-1 theme-text-main">
                            {{ $progressValue }}%
                        </h3>
                    </div>

                    <div class="rounded-2xl border tassist-mini-card p-5">
                        <p class="text-sm theme-text-muted">Total Checklist</p>
                        <h3 class="text-3xl font-black mt-1 theme-text-main">
                            {{ $checklistSummary['total'] }}
                        </h3>
                    </div>

                    <div class="rounded-2xl border tassist-mini-card p-5">
                        <p class="text-sm theme-text-muted">Checklist Selesai</p>
                        <h3 class="text-3xl font-black mt-1 theme-text-main">
                            {{ $checklistSummary['selesai'] }}
                        </h3>
                    </div>

                    <div class="rounded-2xl border tassist-mini-card p-5">
                        <p class="text-sm theme-text-muted">Riwayat Progress</p>
                        <h3 class="text-3xl font-black mt-1 theme-text-main">
                            {{ $progressHistory->count() }}
                        </h3>
                    </div>
                </div>
            </div>

            <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                <h2 class="font-black text-xl theme-text-main mb-5">
                    Riwayat Progress
                </h2>

                <div class="space-y-3">
                    @forelse($progressHistory as $progress)
                        <div class="p-4 rounded-2xl border tassist-mini-card">
                            <div class="flex items-start justify-between gap-3">
                                <div class="min-w-0">
                                    <p class="font-bold theme-text-main">
                                        {{ $progress->status_progress }}
                                    </p>

                                    <p class="text-xs theme-text-muted mt-1">
                                        {{ optional($progress->updated_at)->format('d M Y H:i') ?? '-' }}
                                    </p>
                                </div>

                                <span class="font-black theme-text-main">
                                    {{ (float) $progress->persentase }}%
                                </span>
                            </div>

                            @if($progress->catatan)
                                <p class="text-sm theme-text-muted mt-3 leading-relaxed">
                                    {{ $progress->catatan }}
                                </p>
                            @endif

                            <p class="text-xs theme-text-muted mt-3">
                                Checklist:
                                {{ $progress->checklistProgress->where('tgl_selesai', true)->count() }}/{{ $progress->checklistProgress->count() }}
                                selesai
                            </p>
                        </div>
                    @empty
                        <div class="tassist-empty-state rounded-2xl border p-6 text-center">
                            <p class="text-sm theme-text-muted">
                                Belum ada riwayat progress.
                            </p>
                        </div>
                    @endforelse
                </div>
            </div>

            <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                <h2 class="font-black text-xl theme-text-main mb-4">
                    Akses Cepat
                </h2>

                <div class="space-y-3">
                    <a
                        href="{{ route('dosen.mahasiswa-bimbingan.show', $bimbingan->bimbingan_id) }}"
                        class="block px-4 py-3 rounded-2xl border tassist-secondary-btn text-sm font-black text-center"
                    >
                        Detail Mahasiswa
                    </a>

                    <a
                        href="{{ route('dosen.jadwal.create', ['bimbingan_id' => $bimbingan->bimbingan_id]) }}"
                        class="block px-4 py-3 rounded-2xl theme-primary-btn text-sm font-black text-center"
                    >
                        + Buat Jadwal
                    </a>

                    <a
                        href="{{ route('dosen.dokumen.index', ['bimbingan_id' => $bimbingan->bimbingan_id]) }}"
                        class="block px-4 py-3 rounded-2xl border tassist-secondary-btn text-sm font-black text-center"
                    >
                        Dokumen & Feedback
                    </a>
                </div>
            </div>
        </div>
    </div>
@endsection