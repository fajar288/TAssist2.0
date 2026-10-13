@extends('layout.dosen')

@section('content')
    <div class="tassist-page-header rounded-[2rem] border p-6 sm:p-8 mb-6">
        <div class="flex flex-col xl:flex-row xl:items-end xl:justify-between gap-5">
            <div>
                <a
                    href="{{ route('dosen.jadwal.index') }}"
                    class="inline-flex items-center gap-2 text-sm theme-text-muted font-bold mb-4"
                >
                    ← Kembali ke daftar jadwal
                </a>

                <div class="tassist-page-kicker mb-4">
                    <span>●</span>
                    Buat Jadwal
                </div>

                <h1 class="text-3xl font-black tracking-tight theme-text-main">
                    Buat Jadwal Bimbingan
                </h1>

                <p class="theme-text-muted mt-2 max-w-2xl">
                    Ajukan jadwal bimbingan baru kepada mahasiswa bimbingan aktif. Mahasiswa akan mendapatkan notifikasi untuk konfirmasi.
                </p>
            </div>
        </div>
    </div>

    <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <div class="xl:col-span-2">
            <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                @if($bimbinganAktif->isEmpty())
                    <div class="tassist-empty-state rounded-2xl border p-8 text-center">
                        <p class="font-black theme-text-main">
                            Belum ada mahasiswa bimbingan aktif.
                        </p>
                        <p class="text-sm theme-text-muted mt-2">
                            Jadwal hanya bisa dibuat jika dosen memiliki mahasiswa bimbingan aktif.
                        </p>
                    </div>
                @else
                    <div class="mb-6">
                        <h2 class="font-black text-xl theme-text-main">
                            Form Jadwal Bimbingan
                        </h2>
                        <p class="text-sm theme-text-muted mt-1">
                            Lengkapi data jadwal, waktu, mode, dan catatan bimbingan.
                        </p>
                    </div>

                    <form method="POST" action="{{ route('dosen.jadwal.store') }}" class="space-y-5">
                        @csrf

                        <div>
                            <label class="block text-sm mb-2 theme-text-muted font-black">
                                Mahasiswa Bimbingan
                            </label>

                            <select
                                name="bimbingan_id"
                                required
                                class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
                            >
                                <option value="">Pilih mahasiswa bimbingan</option>

                                @foreach($bimbinganAktif as $bimbingan)
                                    @php
                                        $mahasiswa = $bimbingan->mahasiswa;
                                        $user = $mahasiswa?->user;
                                        $label = ($user->nama ?? '-')
                                            . ' • '
                                            . ($mahasiswa->nim ?? '-')
                                            . ' • '
                                            . ($mahasiswa->prodi ?? '-');
                                    @endphp

                                    <option
                                        value="{{ $bimbingan->bimbingan_id }}"
                                        {{ (string) old('bimbingan_id', $selectedBimbinganId) === (string) $bimbingan->bimbingan_id ? 'selected' : '' }}
                                    >
                                        {{ $label }}
                                    </option>
                                @endforeach
                            </select>
                        </div>

                        <div>
                            <label class="block text-sm mb-2 theme-text-muted font-black">
                                Tanggal
                            </label>

                            <input
                                type="date"
                                name="tanggal"
                                value="{{ old('tanggal') }}"
                                required
                                class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
                            >
                        </div>

                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <label class="block text-sm mb-2 theme-text-muted font-black">
                                    Waktu Mulai
                                </label>

                                <input
                                    type="time"
                                    name="waktu_mulai"
                                    value="{{ old('waktu_mulai') }}"
                                    required
                                    class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
                                >
                            </div>

                            <div>
                                <label class="block text-sm mb-2 theme-text-muted font-black">
                                    Waktu Selesai
                                </label>

                                <input
                                    type="time"
                                    name="waktu_selesai"
                                    value="{{ old('waktu_selesai') }}"
                                    required
                                    class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
                                >
                            </div>
                        </div>

                        <div>
                            <label class="block text-sm mb-2 theme-text-muted font-black">
                                Mode Bimbingan
                            </label>

                            <select
                                name="mode"
                                required
                                class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
                            >
                                <option value="">Pilih mode</option>
                                <option value="online" {{ old('mode') === 'online' ? 'selected' : '' }}>Online</option>
                                <option value="offline" {{ old('mode') === 'offline' ? 'selected' : '' }}>Offline</option>
                            </select>
                        </div>

                        <div>
                            <label class="block text-sm mb-2 theme-text-muted font-black">
                                Catatan
                            </label>

                            <textarea
                                name="catatan"
                                rows="4"
                                placeholder="Contoh: Bahas revisi Bab 2 / bawa dokumen terbaru..."
                                class="w-full px-4 py-3 rounded-2xl border theme-input text-sm outline-none"
                            >{{ old('catatan') }}</textarea>
                        </div>

                        <div class="flex flex-col sm:flex-row gap-3 pt-2">
                            <button
                                type="submit"
                                class="px-5 py-3 rounded-2xl theme-primary-btn text-sm font-black"
                            >
                                Simpan Jadwal
                            </button>

                            <a
                                href="{{ route('dosen.jadwal.index') }}"
                                class="px-5 py-3 rounded-2xl border tassist-secondary-btn text-sm font-black text-center"
                            >
                                Batal
                            </a>
                        </div>
                    </form>
                @endif
            </div>
        </div>

        <div class="space-y-6">
            <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                <h2 class="font-black text-xl theme-text-main mb-5">
                    Ringkasan
                </h2>

                <div class="space-y-4">
                    <div class="rounded-2xl border tassist-mini-card p-4">
                        <p class="text-sm theme-text-muted">Mahasiswa Aktif</p>
                        <h3 class="text-3xl font-black theme-text-main mt-1">
                            {{ $bimbinganAktif->count() }}
                        </h3>
                    </div>

                    <div class="rounded-2xl border tassist-mini-card p-4">
                        <p class="text-sm theme-text-muted">Status Jadwal Baru</p>
                        <p class="font-bold theme-text-main mt-1">
                            Menunggu konfirmasi mahasiswa
                        </p>
                    </div>
                </div>
            </div>

            <div class="rounded-[1.6rem] border tassist-list-shell p-6">
                <h2 class="font-black text-xl theme-text-main mb-3">
                    Catatan Penggunaan
                </h2>

                <div class="space-y-3 text-sm theme-text-muted leading-relaxed">
                    <p>
                        Jadwal yang dibuat dosen akan masuk sebagai jadwal dengan status menunggu.
                    </p>
                    <p>
                        Mahasiswa akan mendapatkan notifikasi dan dapat melihat jadwal tersebut dari aplikasi Mobile.
                    </p>
                    <p>
                        Gunakan catatan untuk menjelaskan agenda bimbingan secara singkat.
                    </p>
                </div>
            </div>
        </div>
    </div>
@endsection