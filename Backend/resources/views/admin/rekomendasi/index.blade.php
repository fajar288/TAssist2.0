@extends('layout.admin')

@section('title', 'Konfigurasi Rekomendasi Dosen - TAssist Admin')
@section('page-title', 'Rekomendasi Dosen Pembimbing')
@section('page-subtitle', 'Pengaturan bobot ranking (α/β/γ) dan log pencarian topik skor rendah (anonim)')

@section('content')
<div class="space-y-6">

    <div>
        <h2 class="text-xl font-extrabold theme-text-main">Konfigurasi Rekomendasi Dosen (F-SUP-06)</h2>
        <p class="text-xs theme-text-muted mt-0.5">
            Formula: <code class="font-mono">skor_total = α·kemiripan_topik + β·ketersediaan_kuota + γ·(1 − beban_aktif)</code>. Dosen dengan sisa kuota 0 otomatis dikecualikan.
        </p>
    </div>

    {{-- Weight Configuration Form (T-47) --}}
    <div class="rounded-2xl p-6 border theme-card" x-data="{
        alpha: {{ old('bobot_kemiripan', $config->bobot_kemiripan) }},
        beta: {{ old('bobot_kuota', $config->bobot_kuota) }},
        gamma: {{ old('bobot_beban', $config->bobot_beban) }},
        threshold: {{ old('ambang_skor_rendah', $config->ambang_skor_rendah) }},
        get total() { return (parseFloat(this.alpha || 0) + parseFloat(this.beta || 0) + parseFloat(this.gamma || 0)).toFixed(2); },
        resetDefaults() {
            this.alpha = 0.60;
            this.beta = 0.25;
            this.gamma = 0.15;
            this.threshold = 0.30;
        }
    }">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b theme-border-soft">
            <div>
                <h3 class="text-base font-bold theme-text-main">Bobot Komponen Rekomendasi</h3>
                <p class="text-xs theme-text-muted mt-0.5">Total α + β + γ wajib bernilai <strong>1.00</strong>. Default: 0.60 / 0.25 / 0.15.</p>
            </div>
            <div class="flex items-center gap-3">
                <span class="px-3 py-1 rounded-lg text-xs font-bold font-mono"
                      :class="Math.abs(parseFloat(total) - 1.0) <= 0.001 ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' : 'bg-rose-50 text-rose-700 border border-rose-200'">
                    Total: <span x-text="total"></span>
                </span>
                <button type="button" @click="resetDefaults()"
                        class="px-3 py-1.5 rounded-lg border theme-border-soft text-xs font-semibold theme-text-main hover:opacity-80 transition">
                    Reset Default
                </button>
            </div>
        </div>

        <form action="{{ route('admin.rekomendasi.update') }}" method="POST" class="pt-5 space-y-5">
            @csrf
            @method('PUT')

            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                <div>
                    <label class="block text-xs font-semibold theme-text-muted mb-1">α · Kemiripan Topik (TF-IDF)</label>
                    <input type="number" step="0.01" min="0" max="1" name="bobot_kemiripan" x-model="alpha" required
                           class="w-full text-sm rounded-xl border theme-border-soft px-3 py-2 bg-white text-slate-900 font-mono focus:outline-none focus:ring-2 focus:ring-indigo-500">
                </div>

                <div>
                    <label class="block text-xs font-semibold theme-text-muted mb-1">β · Ketersediaan Kuota</label>
                    <input type="number" step="0.01" min="0" max="1" name="bobot_kuota" x-model="beta" required
                           class="w-full text-sm rounded-xl border theme-border-soft px-3 py-2 bg-white text-slate-900 font-mono focus:outline-none focus:ring-2 focus:ring-indigo-500">
                </div>

                <div>
                    <label class="block text-xs font-semibold theme-text-muted mb-1">γ · Beban Aktif Rendah</label>
                    <input type="number" step="0.01" min="0" max="1" name="bobot_beban" x-model="gamma" required
                           class="w-full text-sm rounded-xl border theme-border-soft px-3 py-2 bg-white text-slate-900 font-mono focus:outline-none focus:ring-2 focus:ring-indigo-500">
                </div>

                <div>
                    <label class="block text-xs font-semibold theme-text-muted mb-1">Ambang Log Skor Rendah (T-52)</label>
                    <input type="number" step="0.01" min="0" max="1" name="ambang_skor_rendah" x-model="threshold" required
                           class="w-full text-sm rounded-xl border theme-border-soft px-3 py-2 bg-white text-slate-900 font-mono focus:outline-none focus:ring-2 focus:ring-indigo-500">
                </div>
            </div>

            <div class="flex justify-end">
                <button type="submit"
                        class="px-5 py-2.5 rounded-xl bg-[var(--color-primary)] hover:bg-[var(--color-primary-dark)] text-white text-xs font-bold shadow-sm transition">
                    Simpan Konfigurasi Bobot
                </button>
            </div>
        </form>
    </div>

    {{-- Anonymized Low-Score Search Logs (T-52) --}}
    <div class="rounded-2xl p-6 border theme-card">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-4 border-b theme-border-soft">
            <div>
                <h3 class="text-base font-bold theme-text-main">Log Pencarian Topik Skor Rendah (Anonim)</h3>
                <p class="text-xs theme-text-muted mt-0.5">
                    Mencatat pencarian topik dengan kemiripan tertinggi di bawah {{ number_format($config->ambang_skor_rendah * 100, 0) }}% untuk memetakan kesenjangan keahlian dosen. Tidak menyimpan identitas mahasiswa.
                </p>
            </div>
            <span class="text-xs font-semibold px-3 py-1 rounded-lg bg-amber-50 text-amber-700 border border-amber-200">
                Total Log: {{ $logs->total() }}
            </span>
        </div>

        <div class="overflow-x-auto mt-4">
            <table class="w-full text-left text-xs">
                <thead>
                    <tr class="border-b theme-border-soft theme-text-muted uppercase tracking-wider">
                        <th class="py-3 pr-4">Topik Pencarian</th>
                        <th class="py-3 pr-4">Kata Kunci (Stemmed)</th>
                        <th class="py-3 pr-4">Kemiripan Tertinggi</th>
                        <th class="py-3 pr-4">Kandidat</th>
                        <th class="py-3">Waktu</th>
                    </tr>
                </thead>
                <tbody class="divide-y theme-border-soft">
                    @forelse($logs as $log)
                        <tr>
                            <td class="py-3 pr-4 font-semibold theme-text-main max-w-xs">{{ $log->topik_kueri }}</td>
                            <td class="py-3 pr-4">
                                <div class="flex flex-wrap gap-1">
                                    @foreach(($log->kata_kunci_stemmed ?? []) as $kw)
                                        <span class="px-2 py-0.5 rounded bg-slate-100 text-slate-700 font-mono text-[11px]">{{ $kw }}</span>
                                    @endforeach
                                </div>
                            </td>
                            <td class="py-3 pr-4 font-mono font-bold text-amber-600">
                                {{ number_format($log->skor_tertinggi * 100, 1) }}%
                            </td>
                            <td class="py-3 pr-4 font-mono theme-text-main">{{ $log->jumlah_kandidat }}</td>
                            <td class="py-3 theme-text-muted">
                                {{ $log->created_at ? $log->created_at->format('d M Y H:i') : '-' }}
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="py-8 text-center theme-text-muted">
                                Belum ada log pencarian topik dengan skor rendah.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($logs->hasPages())
            <div class="mt-4">
                {{ $logs->links() }}
            </div>
        @endif
    </div>

</div>
@endsection
