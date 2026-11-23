@extends('layout.admin')

@section('title', 'Analitik Chatbot - TAssist Admin')
@section('page-title', 'Analitik Chatbot TA')
@section('page-subtitle', 'Monitoring penggunaan, topik paling sering ditanyakan, dan daftar pertanyaan belum terjawab')

@section('content')
<div class="space-y-6">

    {{-- Usage & Circuit Breaker Stats --}}
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {{-- Hari Ini vs Cap --}}
        <div class="theme-card rounded-2xl border p-5 border-l-4" style="border-left-color: var(--color-primary);">
            <p class="text-xs font-semibold theme-text-muted uppercase tracking-wider">Pesan Hari Ini</p>
            <div class="flex items-baseline gap-2 mt-2">
                <span class="text-3xl font-extrabold theme-text-main">{{ $totalPesanHariIni }}</span>
                <span class="text-xs text-slate-400">/ {{ $systemLimit }} cap</span>
            </div>
            <p class="text-xs text-emerald-600 font-medium mt-1">Tersisa {{ $sisaLimit }} kuota sistem</p>
        </div>

        {{-- Total Percakapan --}}
        <div class="theme-card rounded-2xl border p-5 border-l-4 border-indigo-500">
            <p class="text-xs font-semibold theme-text-muted uppercase tracking-wider">Total Percakapan</p>
            <p class="text-3xl font-extrabold theme-text-main mt-2">{{ $totalPercakapan }}</p>
            <p class="text-xs text-slate-400 mt-1">Semua thread pengguna</p>
        </div>

        {{-- Total Pesan --}}
        <div class="theme-card rounded-2xl border p-5 border-l-4 border-cyan-500">
            <p class="text-xs font-semibold theme-text-muted uppercase tracking-wider">Total Interaksi</p>
            <p class="text-3xl font-extrabold theme-text-main mt-2">{{ $totalPesan }}</p>
            <p class="text-xs text-slate-400 mt-1">Pesan mahasiswa & asisten</p>
        </div>

        {{-- Permintaan Ditolak (Refused) --}}
        <div class="theme-card rounded-2xl border p-5 border-l-4 border-amber-500">
            <p class="text-xs font-semibold theme-text-muted uppercase tracking-wider">Scope Refusals (F-BOT-02)</p>
            <p class="text-3xl font-extrabold text-amber-600 mt-2">{{ $totalRefused }}</p>
            <p class="text-xs text-slate-400 mt-1">Permintaan di luar cakupan</p>
        </div>
    </div>

    {{-- Main Grid: Top Topics & Unanswered Questions --}}
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">

        {{-- Top Topics Asked --}}
        <div class="theme-card rounded-2xl border p-6 flex flex-col">
            <div class="flex items-center justify-between mb-4">
                <div>
                    <h3 class="text-base font-bold text-slate-800">Topik Paling Sering Ditanyakan</h3>
                    <p class="text-xs text-slate-500">Berdasarkan ekstraksi kata kunci & stemmer 60 hari terakhir</p>
                </div>
            </div>

            <div class="overflow-y-auto max-h-96 divide-y divide-slate-100">
                @forelse($topTopics as $topic => $count)
                    <div class="py-3 flex items-center justify-between">
                        <div class="flex items-center gap-3">
                            <span class="w-6 h-6 rounded-full bg-slate-100 text-slate-600 text-xs font-bold flex items-center justify-center">
                                {{ $loop->iteration }}
                            </span>
                            <span class="text-sm font-semibold text-slate-800 capitalize">{{ $topic }}</span>
                        </div>
                        <span class="px-2.5 py-1 text-xs font-bold rounded-lg bg-[var(--color-primary-soft)] text-[var(--color-primary)]">
                            {{ $count }} kali
                        </span>
                    </div>
                @empty
                    <div class="py-8 text-center text-slate-400 text-sm">Belum ada data pertanyaan.</div>
                @endforelse
            </div>
        </div>

        {{-- Unanswered Questions Backlog --}}
        <div class="theme-card rounded-2xl border p-6 flex flex-col">
            <div class="flex items-center justify-between mb-4">
                <div>
                    <h3 class="text-base font-bold text-slate-800">Log Pertanyaan Belum Terjawab</h3>
                    <p class="text-xs text-slate-500">Sumber tidak ditemukan; backlog prioritas untuk Basis Pengetahuan</p>
                </div>
                <a href="{{ route('admin.basis-pengetahuan.create') }}" class="text-xs font-semibold text-[var(--color-primary)] hover:underline">
                    + Tambah Jawaban
                </a>
            </div>

            <div class="overflow-y-auto max-h-96 divide-y divide-slate-100">
                @forelse($unansweredList as $unanswered)
                    <div class="py-3">
                        <div class="text-sm font-medium text-slate-800">"{{ $unanswered['pertanyaan'] }}"</div>
                        <div class="flex items-center gap-3 text-xs text-slate-400 mt-1">
                            <span>Waktu: {{ \Carbon\Carbon::parse($unanswered['waktu'])->diffForHumans() }}</span>
                            <span>Percakapan #{{ $unanswered['percakapan_id'] }}</span>
                        </div>
                    </div>
                @empty
                    <div class="py-8 text-center text-slate-400 text-sm">
                        Tidak ada log pertanyaan belum terjawab.
                    </div>
                @endforelse
            </div>
        </div>

    </div>
</div>
@endsection
