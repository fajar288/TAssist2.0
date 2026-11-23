@extends('layout.admin')

@section('title', 'Konfigurasi Sinyal Risiko - TAssist Admin')
@section('page-title', 'Konfigurasi Scoring Engine Risiko')
@section('page-subtitle', 'Pengaturan bobot dan ambang batas sinyal deteksi dini (Early Warning System)')

@section('content')
<div class="space-y-6">

    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
            <h2 class="text-xl font-extrabold theme-text-main">Konfigurasi Scoring Engine Risiko</h2>
            <p class="text-xs theme-text-muted mt-0.5">Pengaturan bobot dan ambang batas sinyal deteksi dini (Early Warning System)</p>
        </div>
    </div>

    @if(session('success'))
        <div class="p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-sm font-semibold flex items-center justify-between">
            <span>{{ session('success') }}</span>
        </div>
    @endif

    {{-- Top Action & Notice Card --}}
    <div class="rounded-2xl p-6 border theme-card flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div>
            <h3 class="text-base font-bold theme-text-main">Aturan Penilaian & Normalisasi Bobot</h3>
            <p class="text-xs theme-text-muted mt-1 leading-relaxed max-w-2xl">
                Sistem menghitung skor 0&ndash;100 berdasarkan bobot aktif. Jika suatu sinyal dinonaktifkan atau periode TA mahasiswa belum diset, total bobot akan secara otomatis <strong>diter-normalisasi ulang</strong> di antara sinyal yang aktif agar proporsi tetap 100%.
            </p>
        </div>
        <form action="{{ route('admin.risiko.recalculate') }}" method="POST">
            @csrf
            <button type="submit"
                    class="px-4 py-2.5 rounded-xl bg-[var(--color-primary)] hover:bg-[var(--color-primary-dark)] text-white text-xs font-bold shadow-sm transition flex items-center gap-2">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
                Hitung Ulang Skor Sekarang
            </button>
        </form>
    </div>

    {{-- Signal Configuration Cards / Table --}}
    <div class="space-y-4">
        @foreach($signals as $signal)
            @php
                $normalized = $renormalized->get($signal->konfigurasi_id)?->bobot_ternormalisasi ?? 0.0;
            @endphp
            <div class="rounded-2xl p-5 border theme-card {{ ! $signal->is_active ? 'opacity-60 bg-slate-50/50' : '' }}">
                <form action="{{ route('admin.risiko.update', $signal->konfigurasi_id) }}" method="POST">
                    @csrf
                    @method('PUT')

                    <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 pb-4 border-b theme-border-soft">
                        <div class="flex items-center gap-3">
                            <span class="w-8 h-8 rounded-lg bg-indigo-50 text-indigo-700 font-extrabold flex items-center justify-center text-xs">
                                #{{ $signal->konfigurasi_id }}
                            </span>
                            <div>
                                <h4 class="text-sm font-bold theme-text-main font-mono">{{ $signal->nama_sinyal }}</h4>
                                <p class="text-xs theme-text-muted mt-0.5">{{ $signal->deskripsi }}</p>
                            </div>
                        </div>

                        <div class="flex items-center gap-4">
                            <label class="inline-flex items-center gap-2 cursor-pointer">
                                <input type="checkbox" name="is_active" value="1" {{ $signal->is_active ? 'checked' : '' }} class="rounded border-slate-300 text-indigo-600 focus:ring-indigo-500">
                                <span class="text-xs font-semibold theme-text-main">Aktif</span>
                            </label>
                            <button type="submit" class="px-3.5 py-1.5 rounded-lg bg-slate-900 text-white text-xs font-semibold hover:bg-slate-800 transition">
                                Simpan Perubahan
                            </button>
                        </div>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 pt-4">
                        {{-- Deskripsi --}}
                        <div>
                            <label class="block text-xs font-semibold theme-text-muted mb-1">Keterangan Sinyal</label>
                            <input type="text" name="deskripsi" value="{{ $signal->deskripsi }}" required
                                   class="w-full text-xs rounded-lg border theme-border-soft px-3 py-2 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500">
                        </div>

                        {{-- Bobot --}}
                        <div>
                            <div class="flex justify-between items-center mb-1">
                                <label class="text-xs font-semibold theme-text-muted">Bobot Dasar (0.00 - 1.00)</label>
                                @if($signal->bobot > 0 && $signal->is_active)
                                    <span class="text-[11px] text-indigo-600 font-bold">Ternormalisasi: {{ round($normalized * 100, 1) }}%</span>
                                @endif
                            </div>
                            <input type="number" step="0.01" min="0" max="1" name="bobot" value="{{ $signal->bobot }}" required
                                   class="w-full text-xs rounded-lg border theme-border-soft px-3 py-2 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500 font-mono">
                        </div>

                        {{-- Ambang Batas --}}
                        <div>
                            <label class="block text-xs font-semibold theme-text-muted mb-1">Ambang Batas (Thresholds)</label>
                            <div class="grid grid-cols-2 gap-2">
                                @foreach($signal->ambang_batas as $key => $val)
                                    <div>
                                        <span class="text-[10px] uppercase font-bold text-slate-400 block">{{ $key }}</span>
                                        <input type="text" name="ambang_batas[{{ $key }}]" value="{{ $val }}" required
                                               class="w-full text-xs rounded-lg border theme-border-soft px-2.5 py-1.5 bg-white focus:outline-none focus:ring-1 focus:ring-indigo-500 font-mono">
                                    </div>
                                @endforeach
                            </div>
                        </div>
                    </div>
                </form>
            </div>
        @endforeach
    </div>

</div>
@endsection
