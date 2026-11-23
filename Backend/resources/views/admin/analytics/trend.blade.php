@extends('layout.admin')

@section('title', 'Tren Risiko Bimbingan - TAssist Admin')
@section('page-title', 'Riwayat Tren Skor Risiko')
@section('page-subtitle', 'Analisis perkembangan risiko bimbingan mahasiswa')

@section('content')
<div class="space-y-6">

    {{-- Header Card --}}
    <div class="rounded-2xl p-6 border theme-card flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
            <div class="flex items-center gap-2 mb-1">
                <a href="{{ route('admin.analytics.index') }}" class="text-xs font-semibold text-[var(--color-primary)] hover:underline">&larr; Kembali ke Dashboard Analitik</a>
            </div>
            <h2 class="text-xl font-extrabold theme-text-main">{{ $bimbingan->mahasiswa?->user?->nama }}</h2>
            <p class="text-sm theme-text-muted">NIM: {{ $bimbingan->mahasiswa?->nim }} &bull; Prodi: {{ $bimbingan->mahasiswa?->prodi }} &bull; Dosen: {{ $bimbingan->dosen?->user?->nama }}</p>
            <p class="text-xs theme-text-subtle mt-1 font-medium">Judul TA: "{{ $bimbingan->mahasiswa?->judul_ta ?: 'Belum ditentukan' }}"</p>
        </div>

        @php
            $latest = $snapshots->last();
        @endphp
        @if($latest)
            <div class="flex items-center gap-4 p-4 rounded-xl {{ $latest->skor >= 70 ? 'bg-red-50 border border-red-200' : ($latest->skor >= 40 ? 'bg-amber-50 border border-amber-200' : 'bg-emerald-50 border border-emerald-200') }}">
                <div>
                    <p class="text-xs font-semibold uppercase text-slate-500">Skor Terakhir</p>
                    <p class="text-3xl font-extrabold {{ $latest->skor >= 70 ? 'text-red-700' : ($latest->skor >= 40 ? 'text-amber-700' : 'text-emerald-700') }}">
                        {{ $latest->skor }}
                    </p>
                </div>
                <div>
                    <span class="inline-flex px-3 py-1 rounded-full text-xs font-bold uppercase {{ $latest->skor >= 70 ? 'bg-red-200 text-red-900' : ($latest->skor >= 40 ? 'bg-amber-200 text-amber-900' : 'bg-emerald-200 text-emerald-900') }}">
                        {{ $latest->level }}
                    </span>
                    <p class="text-[11px] text-slate-500 mt-1">{{ $latest->tanggal_hitung?->format('d M Y') }}</p>
                </div>
            </div>
        @endif
    </div>

    {{-- Snapshots Timeline Table --}}
    <div class="rounded-2xl p-6 border theme-card space-y-4">
        <h3 class="text-base font-bold theme-text-main">Catatan Snapshot Harian</h3>

        <div class="overflow-x-auto">
            <table class="w-full text-left text-sm">
                <thead>
                    <tr class="border-b theme-border-soft text-xs uppercase theme-text-muted">
                        <th class="py-3 px-3">Tanggal Hitung</th>
                        <th class="py-3 px-3 text-center">Skor</th>
                        <th class="py-3 px-3 text-center">Status Level</th>
                        <th class="py-3 px-3">Rincian Sinyal & Kontribusi (Explainability)</th>
                    </tr>
                </thead>
                <tbody class="divide-y theme-border-soft">
                    @forelse($snapshots->reverse() as $snap)
                        <tr class="hover:bg-slate-50/50 transition">
                            <td class="py-3 px-3 font-semibold theme-text-main whitespace-nowrap">
                                {{ $snap->tanggal_hitung?->format('d F Y') }}
                            </td>
                            <td class="py-3 px-3 text-center">
                                <span class="text-base font-extrabold {{ $snap->skor >= 70 ? 'text-red-600' : ($snap->skor >= 40 ? 'text-amber-600' : 'text-emerald-600') }}">
                                    {{ $snap->skor }}
                                </span>
                            </td>
                            <td class="py-3 px-3 text-center">
                                @if($snap->level === 'berisiko')
                                    <span class="px-2 py-0.5 rounded text-xs font-bold bg-red-100 text-red-800">Berisiko</span>
                                @elseif($snap->level === 'perlu_perhatian')
                                    <span class="px-2 py-0.5 rounded text-xs font-bold bg-amber-100 text-amber-800">Perhatian</span>
                                @else
                                    <span class="px-2 py-0.5 rounded text-xs font-bold bg-emerald-100 text-emerald-800">Aman</span>
                                @endif
                            </td>
                            <td class="py-3 px-3">
                                <div class="grid grid-cols-1 md:grid-cols-2 gap-2">
                                    @foreach($snap->sinyal as $sig)
                                        <div class="p-2 rounded bg-slate-50 border border-slate-100 text-xs">
                                            <div class="flex justify-between items-center font-semibold text-slate-700">
                                                <span>{{ $sig['deskripsi'] }}</span>
                                                <span class="text-indigo-600 font-bold ml-2">+{{ $sig['kontribusi'] }}</span>
                                            </div>
                                            <div class="text-[10px] text-slate-400 mt-0.5">
                                                Bobot: {{ round($sig['bobot'] * 100) }}% &bull; Nilai: {{ $sig['nilai'] }}
                                            </div>
                                        </div>
                                    @endforeach
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="4" class="py-8 text-center theme-text-muted">
                                Belum ada rekaman snapshot risiko untuk bimbingan ini.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

</div>
@endsection
