@extends('layout.admin')

@section('title', 'Dashboard Analitik - TAssist Admin')
@section('page-title', 'Dashboard Analitik & Early Warning')
@section('page-subtitle', 'Monitoring risiko keterlambatan bimbingan tugas akhir dan metrik performa')

@section('content')
<div class="space-y-6">

    {{-- Stats Cards --}}
    <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        {{-- Total Aktif --}}
        <div class="rounded-2xl p-5 border theme-card flex items-start gap-4 border-l-4" style="border-left-color: var(--color-primary);">
            <div class="w-12 h-12 rounded-xl flex items-center justify-center bg-[var(--color-primary-soft)] flex-shrink-0">
                <svg class="w-6 h-6 text-[var(--color-primary)]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                </svg>
            </div>
            <div>
                <p class="text-sm font-medium theme-text-muted">Bimbingan Aktif</p>
                <p class="theme-text-main text-2xl font-extrabold">{{ $totalAktif }}</p>
                <p class="text-xs theme-text-subtle mt-1">{{ $totalSelesai }} bimbingan selesai</p>
            </div>
        </div>

        {{-- Berisiko --}}
        <div class="rounded-2xl p-5 border theme-card flex items-start gap-4 border-l-4 border-red-500 bg-red-50/20">
            <div class="w-12 h-12 rounded-xl flex items-center justify-center bg-red-100 flex-shrink-0">
                <svg class="w-6 h-6 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
            </div>
            <div>
                <p class="text-sm font-medium text-red-800">Status Berisiko</p>
                <p class="text-red-900 text-2xl font-extrabold">{{ $atRiskCount }}</p>
                <p class="text-xs text-red-600 mt-1">Skor &ge; 70 (Perlu Intervensi)</p>
            </div>
        </div>

        {{-- Perlu Perhatian --}}
        <div class="rounded-2xl p-5 border theme-card flex items-start gap-4 border-l-4 border-amber-500 bg-amber-50/20">
            <div class="w-12 h-12 rounded-xl flex items-center justify-center bg-amber-100 flex-shrink-0">
                <svg class="w-6 h-6 text-amber-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
            </div>
            <div>
                <p class="text-sm font-medium text-amber-800">Perlu Perhatian</p>
                <p class="text-amber-900 text-2xl font-extrabold">{{ $perluPerhatianCount }}</p>
                <p class="text-xs text-amber-600 mt-1">Skor 40 &ndash; 69 (Waspada)</p>
            </div>
        </div>

        {{-- Aman --}}
        <div class="rounded-2xl p-5 border theme-card flex items-start gap-4 border-l-4 border-emerald-500 bg-emerald-50/20">
            <div class="w-12 h-12 rounded-xl flex items-center justify-center bg-emerald-100 flex-shrink-0">
                <svg class="w-6 h-6 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
            </div>
            <div>
                <p class="text-sm font-medium text-emerald-800">Status Aman</p>
                <p class="text-emerald-900 text-2xl font-extrabold">{{ $amanCount }}</p>
                <p class="text-xs text-emerald-600 mt-1">Skor 0 &ndash; 39 (Sesuai Jadwal)</p>
            </div>
        </div>
    </div>

    {{-- Supervision Funnel --}}
    <div class="rounded-2xl p-5 border theme-card space-y-4">
        <h3 class="text-base font-bold theme-text-main">Supervision Funnel</h3>
        <div class="grid grid-cols-2 md:grid-cols-5 gap-3">
            <div class="p-4 rounded-xl bg-slate-50 border theme-border-soft text-center">
                <p class="text-xs theme-text-muted font-semibold uppercase">Permohonan</p>
                <p class="text-xl font-bold theme-text-main mt-1">{{ $totalPermohonan }}</p>
            </div>
            <div class="p-4 rounded-xl bg-blue-50/50 border border-blue-100 text-center">
                <p class="text-xs text-blue-600 font-semibold uppercase">Diterima</p>
                <p class="text-xl font-bold text-blue-900 mt-1">{{ $totalDiterima }}</p>
            </div>
            <div class="p-4 rounded-xl bg-indigo-50/50 border border-indigo-100 text-center">
                <p class="text-xs text-indigo-600 font-semibold uppercase">Bimbingan Aktif</p>
                <p class="text-xl font-bold text-indigo-900 mt-1">{{ $totalAktif }}</p>
            </div>
            <div class="p-4 rounded-xl bg-red-50/50 border border-red-100 text-center">
                <p class="text-xs text-red-600 font-semibold uppercase">Sedang Berisiko</p>
                <p class="text-xl font-bold text-red-900 mt-1">{{ $atRiskCount }}</p>
            </div>
            <div class="p-4 rounded-xl bg-emerald-50/50 border border-emerald-100 text-center">
                <p class="text-xs text-emerald-600 font-semibold uppercase">Tuntas / Selesai</p>
                <p class="text-xl font-bold text-emerald-900 mt-1">{{ $totalSelesai }}</p>
            </div>
        </div>
    </div>

    {{-- 2 Columns: Risk Distribution per Prodi & Revision Cycle --}}
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {{-- Distribusi Risiko per Prodi --}}
        <div class="rounded-2xl p-5 border theme-card space-y-4">
            <h3 class="text-base font-bold theme-text-main">Distribusi Tingkat Risiko per Program Studi</h3>
            <div class="overflow-x-auto">
                <table class="w-full text-left text-sm">
                    <thead>
                        <tr class="border-b theme-border-soft text-xs uppercase theme-text-muted">
                            <th class="py-2.5 px-3">Program Studi</th>
                            <th class="py-2.5 px-3 text-center text-emerald-600">Aman</th>
                            <th class="py-2.5 px-3 text-center text-amber-600">Perhatian</th>
                            <th class="py-2.5 px-3 text-center text-red-600">Berisiko</th>
                            <th class="py-2.5 px-3 text-right">Total</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y theme-border-soft">
                        @forelse($distribution as $prodiName => $counts)
                            <tr class="hover:bg-slate-50/50 transition">
                                <td class="py-2.5 px-3 font-medium theme-text-main">{{ $prodiName }}</td>
                                <td class="py-2.5 px-3 text-center font-bold text-emerald-700">{{ $counts['aman'] }}</td>
                                <td class="py-2.5 px-3 text-center font-bold text-amber-700">{{ $counts['perlu_perhatian'] }}</td>
                                <td class="py-2.5 px-3 text-center font-bold text-red-700">{{ $counts['berisiko'] }}</td>
                                <td class="py-2.5 px-3 text-right font-bold theme-text-main">{{ $counts['total'] }}</td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="5" class="py-4 text-center theme-text-muted">Belum ada data distribusi prodi</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>

        {{-- Rata-rata Siklus Revisi Dosen --}}
        <div class="rounded-2xl p-5 border theme-card space-y-4">
            <h3 class="text-base font-bold theme-text-main">Rata-rata Siklus Revisi per Dosen Pembimbing</h3>
            <div class="overflow-x-auto max-h-72 overflow-y-auto">
                <table class="w-full text-left text-sm">
                    <thead>
                        <tr class="border-b theme-border-soft text-xs uppercase theme-text-muted sticky top-0 bg-white">
                            <th class="py-2.5 px-3">Dosen</th>
                            <th class="py-2.5 px-3 text-center">Anotasi Selesai</th>
                            <th class="py-2.5 px-3 text-right">Rata-rata Durasi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y theme-border-soft">
                        @forelse($revisionCycles as $item)
                            <tr class="hover:bg-slate-50/50 transition">
                                <td class="py-2.5 px-3">
                                    <p class="font-medium theme-text-main">{{ $item['nama'] }}</p>
                                    <p class="text-xs theme-text-subtle">NID: {{ $item['nid'] ?: '-' }}</p>
                                </td>
                                <td class="py-2.5 px-3 text-center font-bold">{{ $item['resolved'] }}</td>
                                <td class="py-2.5 px-3 text-right">
                                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold {{ $item['avg_days'] > 7 ? 'bg-amber-100 text-amber-800' : 'bg-slate-100 text-slate-800' }}">
                                        {{ $item['avg_days'] }} hari
                                    </span>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="3" class="py-4 text-center theme-text-muted">Belum ada catatan revisi anotasi selesai</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    {{-- Daftar Mahasiswa Berisiko (Explainable Breakdown) --}}
    <div class="rounded-2xl p-5 border theme-card space-y-4">
        <div class="flex items-center justify-between">
            <div>
                <h3 class="text-base font-bold theme-text-main">Daftar Bimbingan Berisiko & Perlu Perhatian</h3>
                <p class="text-xs theme-text-muted">Diurutkan berdasarkan skor risiko tertinggi (Explainability Breakdown)</p>
            </div>
            <a href="{{ route('admin.risiko.index') }}" class="text-xs font-semibold text-[var(--color-primary)] hover:underline flex items-center gap-1">
                Kelola Ambang Batas & Bobot Sinyal &rarr;
            </a>
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-left text-sm">
                <thead>
                    <tr class="border-b theme-border-soft text-xs uppercase theme-text-muted">
                        <th class="py-3 px-3">Mahasiswa</th>
                        <th class="py-3 px-3">Dosen Pembimbing</th>
                        <th class="py-3 px-3 text-center">Skor Risiko</th>
                        <th class="py-3 px-3 text-center">Status</th>
                        <th class="py-3 px-3">Sinyal Pemicu Terbesar</th>
                        <th class="py-3 px-3 text-right">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y theme-border-soft">
                    @forelse($atRiskList as $row)
                        @php
                            $signals = is_string($row->sinyal) ? json_decode($row->sinyal, true) : $row->sinyal;
                            $topSignal = collect($signals)->sortByDesc('kontribusi')->first();
                        @endphp
                        <tr class="hover:bg-slate-50/50 transition">
                            <td class="py-3 px-3">
                                <p class="font-bold theme-text-main">{{ $row->nama_mahasiswa }}</p>
                                <p class="text-xs theme-text-muted">{{ $row->nim }} &bull; {{ $row->prodi }}</p>
                            </td>
                            <td class="py-3 px-3">
                                <p class="font-medium theme-text-main">{{ $row->nama_dosen }}</p>
                            </td>
                            <td class="py-3 px-3 text-center">
                                <span class="text-lg font-extrabold {{ $row->skor >= 70 ? 'text-red-600' : 'text-amber-600' }}">
                                    {{ $row->skor }}
                                </span>
                                <span class="text-[10px] text-slate-400 block">/ 100</span>
                            </td>
                            <td class="py-3 px-3 text-center">
                                @if($row->level === 'berisiko')
                                    <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-red-100 text-red-800">
                                        Berisiko
                                    </span>
                                @else
                                    <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-800">
                                        Perlu Perhatian
                                    </span>
                                @endif
                            </td>
                            <td class="py-3 px-3">
                                @if($topSignal)
                                    <p class="text-xs font-semibold theme-text-main">{{ $topSignal['deskripsi'] }}</p>
                                    <p class="text-[11px] text-slate-500">Kontribusi: +{{ $topSignal['kontribusi'] }} poin (bobot {{ round($topSignal['bobot'] * 100) }}%)</p>
                                @else
                                    <span class="text-xs text-slate-400">-</span>
                                @endif
                            </td>
                            <td class="py-3 px-3 text-right">
                                <a href="{{ route('admin.analytics.trend', $row->bimbingan_id) }}"
                                   class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border theme-border-soft text-xs font-semibold theme-text-main hover:bg-slate-100 transition">
                                    <svg class="w-3.5 h-3.5 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                                    </svg>
                                    Riwayat Tren
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="py-8 text-center theme-text-muted">
                                Tidak ada bimbingan aktif dengan status berisiko atau perlu perhatian saat ini.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

</div>
@endsection
