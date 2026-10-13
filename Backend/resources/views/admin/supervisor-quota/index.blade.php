@extends('layout.admin')

@section('title', 'Supervisor Quota - TAssist Admin')
@section('page-title', 'Supervisor Quota')
@section('page-subtitle', 'Kelola kuota bimbingan dosen')

@section('content')
@php
    $inputClass = 'w-full px-4 py-3 rounded-2xl border theme-input outline-none transition-all duration-200';
    $labelClass = 'block theme-text-muted text-sm font-medium mb-2';
    $secondaryButtonClass = 'flex-1 py-3 rounded-2xl border theme-border theme-text-muted text-base hover:bg-[var(--color-hover)] transition';
    $modalOverlayClass = 'hidden fixed inset-0 z-50 bg-[rgba(0,0,0,0.72)] flex items-center justify-center p-4';
    $modalPanelClass = 'w-full rounded-[28px] p-8 border theme-card';
@endphp

<div class="space-y-5">

    {{-- Summary Cards --}}
    <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">

        <div class="rounded-2xl p-5 flex items-center gap-4 border theme-card border-l-4" style="border-left-color: var(--color-primary);">
            <div class="w-12 h-12 rounded-2xl bg-[var(--color-primary-soft)] flex items-center justify-center text-[var(--color-primary)] text-2xl font-bold flex-shrink-0">
                {{ $totalLecturers }}
            </div>

            <div>
                <p class="theme-text-main font-semibold text-lg">{{ $totalLecturers }}</p>
                <p class="theme-text-muted text-sm">Total Dosen</p>
            </div>
        </div>

        <div class="rounded-2xl p-5 flex items-center gap-4 border theme-card border-l-4" style="border-left-color: var(--color-accent);">
            <div class="w-12 h-12 rounded-2xl bg-[var(--color-primary-soft)] flex items-center justify-center text-[var(--color-accent)] text-2xl font-bold flex-shrink-0">
                {{ $totalSlots }}
            </div>

            <div>
                <p class="theme-text-main font-semibold text-lg">{{ $totalSlots }}</p>
                <p class="theme-text-muted text-sm">Total Kuota</p>
            </div>
        </div>

        <div class="rounded-2xl p-5 flex items-center gap-4 border theme-card border-l-4 border-l-[#FFB900]">
            <div class="w-12 h-12 rounded-2xl bg-[rgba(255,185,0,0.15)] flex items-center justify-center text-[#FFB900] text-2xl font-bold flex-shrink-0">
                {{ $usedSlots }}
            </div>

            <div>
                <p class="theme-text-main font-semibold text-lg">{{ $usedSlots }}</p>
                <p class="theme-text-muted text-sm">Terisi</p>
            </div>
        </div>

        <div class="rounded-2xl p-5 flex items-center gap-4 border theme-card border-l-4 border-l-[#3DDC97]">
            <div class="w-12 h-12 rounded-2xl bg-[rgba(61,220,151,0.15)] flex items-center justify-center text-[#3DDC97] text-2xl font-bold flex-shrink-0">
                {{ $availableSlots }}
            </div>

            <div>
                <p class="theme-text-main font-semibold text-lg">{{ $availableSlots }}</p>
                <p class="theme-text-muted text-sm">Sisa Tersedia</p>
            </div>
        </div>
    </div>

    {{-- Overall Progress --}}
    <div class="rounded-[24px] p-5 border theme-card">
        <div class="flex items-center justify-between mb-4">
            <h3 class="theme-text-main text-lg font-bold">Utilisasi Kuota Keseluruhan</h3>
            <span class="text-[var(--color-accent)] text-lg font-semibold">{{ $usedPercent }}% terpakai</span>
        </div>

        <div class="h-4 rounded-full overflow-hidden bg-[var(--color-border)]">
            <div
                class="quota-progress-fill h-full rounded-full transition-all duration-500 bg-[linear-gradient(90deg,var(--color-primary),var(--color-accent))]"
                data-progress="{{ $usedPercent }}"
            ></div>
        </div>

        <div class="flex items-center justify-between mt-3 text-sm theme-text-muted">
            <span>{{ $usedSlots }} terisi</span>
            <span>{{ $availableSlots }} tersisa dari {{ $totalSlots }} total</span>
        </div>
    </div>

    {{-- Search --}}
    <form method="GET" action="{{ route('admin.supervisor-quota.index') }}">
        <div class="relative max-w-xl">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 absolute left-4 top-1/2 -translate-y-1/2 theme-text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-4.35-4.35m1.85-5.15a7 7 0 11-14 0 7 7 0 0114 0z"/>
            </svg>

            <input
                type="text"
                name="search"
                value="{{ request('search') }}"
                placeholder="Cari nama dosen atau bidang keahlian..."
                onchange="this.form.submit()"
                class="w-full pl-11 pr-4 py-3 rounded-2xl border theme-input text-sm outline-none transition-all duration-200"
            >
        </div>
    </form>

    {{-- Table --}}
    <div class="rounded-[24px] overflow-hidden border theme-border theme-card">
        <div class="overflow-x-auto">
            <table class="w-full border-collapse">
                <thead>
                    <tr class="theme-bg-card">
                        <th class="px-4 py-5 text-left text-xs font-semibold theme-text-muted border-b theme-border">Nama Dosen</th>
                        <th class="px-4 py-5 text-left text-xs font-semibold theme-text-muted border-b theme-border">Bidang Keahlian</th>
                        <th class="px-4 py-5 text-left text-xs font-semibold theme-text-muted border-b theme-border">Max Kuota</th>
                        <th class="px-4 py-5 text-left text-xs font-semibold theme-text-muted border-b theme-border">Bimbingan Aktif</th>
                        <th class="px-4 py-5 text-left text-xs font-semibold theme-text-muted border-b theme-border">Sisa Slot</th>
                        <th class="px-4 py-5 text-left text-xs font-semibold theme-text-muted border-b theme-border">Progress Kuota</th>
                        <th class="px-4 py-5 text-left text-xs font-semibold theme-text-muted border-b theme-border">Status</th>
                        <th class="px-4 py-5 text-left text-xs font-semibold theme-text-muted border-b theme-border">Aksi</th>
                    </tr>
                </thead>

                <tbody>
                    @forelse($dosen as $index => $d)
                        @php
                            $bimbinganAktif = $d->bimbinganAktif()->count();
                            $kuota = $d->kuota_bimbingan;
                            $sisa = max(0, $kuota - $bimbinganAktif);
                            $pct = $kuota > 0 ? round(($bimbinganAktif / $kuota) * 100) : 0;
                            $isFull = $sisa <= 0;
                            $isWarning = $pct > 70 && !$isFull;

                            $progressClass = $isFull
                                ? 'bg-[var(--color-error-text)]'
                                : ($isWarning ? 'bg-[#FFB900]' : 'bg-[#3DDC97]');

                            $progressTextClass = $isFull
                                ? 'text-[var(--color-error-text)]'
                                : ($isWarning ? 'text-[#FFB900]' : 'text-[#3DDC97]');

                            $statusClass = $isFull
                                ? 'bg-[var(--color-error-bg)] text-[var(--color-error-text)]'
                                : 'bg-[var(--color-success-bg)] text-[var(--color-success-text)]';

                            $statusText = $isFull ? 'Penuh' : "{$sisa} tersedia";

                            $sisaClass = $sisa === 0
                                ? 'text-[var(--color-error-text)]'
                                : ($sisa <= 1 ? 'text-[#FFB900]' : 'text-[#3DDC97]');
                        @endphp

                        <tr
                            class="{{ $index % 2 === 0 ? 'theme-bg-main' : 'theme-bg-card' }} border-b theme-border"
                            data-id="{{ $d->dosen_id }}"
                            data-nama="{{ $d->user->nama }}"
                            data-kuota="{{ $kuota }}"
                            data-bimbingan-aktif="{{ $bimbinganAktif }}"
                            data-sisa="{{ $sisa }}"
                            data-url-kuota="{{ route('admin.supervisor-quota.update', $d->dosen_id) }}"
                        >
                            {{-- Nama Dosen --}}
                            <td class="px-4 py-4">
                                <div class="flex items-center gap-3">
                                    <div class="w-10 h-10 rounded-full theme-logo-bg flex items-center justify-center text-white text-sm font-bold flex-shrink-0">
                                        {{ strtoupper(substr($d->user->nama, 0, 1)) }}
                                    </div>

                                    <div>
                                        <p class="theme-text-main text-sm font-medium">{{ $d->user->nama }}</p>
                                        <p class="text-xs theme-text-muted">{{ $d->nid }}</p>
                                    </div>
                                </div>
                            </td>

                            {{-- Bidang Keahlian --}}
                            <td class="px-4 py-4 text-sm theme-text-muted">
                                {{ $d->bidang_keahlian ?? '-' }}
                            </td>

                            {{-- Max Kuota --}}
                            <td class="px-4 py-4 theme-text-main text-sm font-semibold">
                                {{ $kuota }}
                            </td>

                            {{-- Bimbingan Aktif --}}
                            <td class="px-4 py-4 theme-text-main text-sm font-medium">
                                {{ $bimbinganAktif }}
                            </td>

                            {{-- Sisa Slot --}}
                            <td class="px-4 py-4">
                                <span class="text-sm font-semibold {{ $sisaClass }}">
                                    {{ $sisa }}
                                </span>
                            </td>

                            {{-- Progress Bar --}}
                            <td class="px-4 py-4 min-w-[180px]">
                                <div class="flex items-center justify-between text-xs theme-text-muted mb-2">
                                    <span>{{ $pct }}%</span>
                                    <span class="{{ $progressTextClass }}">{{ $bimbinganAktif }}/{{ $kuota }}</span>
                                </div>

                                <div class="h-2.5 rounded-full overflow-hidden bg-[var(--color-border)]">
                                    <div
                                        class="quota-progress-fill h-full rounded-full transition-all duration-300 {{ $progressClass }}"
                                        data-progress="{{ $pct }}"
                                    ></div>
                                </div>
                            </td>

                            {{-- Status --}}
                            <td class="px-4 py-4">
                                <span class="px-3 py-1.5 rounded-full text-xs font-medium whitespace-nowrap {{ $statusClass }}">
                                    {{ $statusText }}
                                </span>
                            </td>

                            {{-- Action --}}
                            <td class="px-4 py-4">
                                <button
                                    type="button"
                                    onclick="openEditQuotaModal(this.closest('tr'))"
                                    class="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-medium text-[var(--color-accent)] bg-[var(--color-primary-soft)] border border-[rgba(77,163,255,0.25)] hover:opacity-90 transition"
                                >
                                    <svg xmlns="http://www.w3.org/2000/svg" class="w-[13px] h-[13px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M11 4h4a2 2 0 012 2v4m-9.586 9.586L3 21l1.414-4.414L14 7l3 3-9.586 9.586z"/>
                                    </svg>
                                    Edit Kuota
                                </button>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="8" class="px-4 py-12 text-center theme-text-muted text-sm theme-bg-main">
                                Tidak ada data dosen ditemukan.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        {{-- Pagination --}}
        @if($dosen->hasPages())
            <div class="flex items-center justify-between px-5 py-4 theme-bg-card border-t theme-border">
                <p class="text-sm theme-text-muted">
                    Menampilkan {{ $dosen->firstItem() }}–{{ $dosen->lastItem() }}
                    dari {{ $dosen->total() }} dosen
                </p>

                <div class="flex items-center gap-2">
                    @if($dosen->onFirstPage())
                        <span class="text-[var(--color-border)]">
                            <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7"/>
                            </svg>
                        </span>
                    @else
                        <a href="{{ $dosen->previousPageUrl() }}" class="theme-text-muted hover:text-[var(--color-text-main)] transition">
                            <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7"/>
                            </svg>
                        </a>
                    @endif

                    @foreach($dosen->getUrlRange(1, $dosen->lastPage()) as $page => $url)
                        <a href="{{ $url }}"
                           class="w-9 h-9 rounded-xl text-sm flex items-center justify-center transition
                           {{ $page == $dosen->currentPage()
                               ? 'theme-primary-btn font-semibold'
                               : 'theme-text-muted hover:bg-[var(--color-hover)] hover:text-[var(--color-text-main)]' }}">
                            {{ $page }}
                        </a>
                    @endforeach

                    @if($dosen->hasMorePages())
                        <a href="{{ $dosen->nextPageUrl() }}" class="theme-text-muted hover:text-[var(--color-text-main)] transition">
                            <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
                            </svg>
                        </a>
                    @else
                        <span class="text-[var(--color-border)]">
                            <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
                            </svg>
                        </span>
                    @endif
                </div>
            </div>
        @endif
    </div>
</div>

{{-- ============================================================ --}}
{{-- MODAL: EDIT QUOTA --}}
{{-- ============================================================ --}}
<div id="editQuotaModal" class="{{ $modalOverlayClass }}">
    <div class="max-w-xl {{ $modalPanelClass }}">
        <div class="flex items-center justify-between mb-8">
            <h2 class="theme-text-main text-2xl font-bold">Edit Kuota</h2>

            <button
                type="button"
                onclick="document.getElementById('editQuotaModal').classList.add('hidden')"
                class="theme-text-muted hover:text-[var(--color-text-main)] transition"
            >
                <svg xmlns="http://www.w3.org/2000/svg" class="w-7 h-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                </svg>
            </button>
        </div>

        {{-- Info Dosen --}}
        <div class="rounded-2xl theme-bg-input border theme-border p-5 mb-5 space-y-3">
            <div class="flex justify-between gap-4 text-sm">
                <span class="theme-text-muted">Dosen</span>
                <span id="modal_nama" class="theme-text-main font-semibold text-right"></span>
            </div>

            <div class="flex justify-between gap-4 text-sm">
                <span class="theme-text-muted">Bimbingan Aktif Saat Ini</span>
                <span id="modal_current" class="theme-text-main font-semibold"></span>
            </div>

            <div class="flex justify-between gap-4 text-sm">
                <span class="theme-text-muted">Sisa Slot</span>
                <span id="modal_sisa" class="text-[#3DDC97] font-semibold"></span>
            </div>
        </div>

        <form id="editQuotaForm" method="POST" action="">
            @csrf
            @method('PUT')

            <div>
                <label class="{{ $labelClass }}">
                    Kuota Maksimal Baru <span class="text-red-400">*</span>
                </label>

                <input
                    type="number"
                    name="kuota_bimbingan"
                    id="modal_kuota_input"
                    min="0"
                    required
                    class="{{ $inputClass }}"
                >

                <p class="theme-text-muted text-xs mt-2">
                    * Kuota tidak bisa dikurangi di bawah jumlah bimbingan aktif saat ini.
                </p>
            </div>

            <div class="flex gap-4 mt-8">
                <button
                    type="button"
                    onclick="document.getElementById('editQuotaModal').classList.add('hidden')"
                    class="{{ $secondaryButtonClass }}"
                >
                    Batal
                </button>

                <button
                    type="submit"
                    class="flex-1 py-3 rounded-2xl theme-primary-btn text-base font-semibold transition"
                >
                    Simpan Perubahan
                </button>
            </div>
        </form>
    </div>
</div>

@endsection

@push('scripts')
<script>
    function applyQuotaProgressBars() {
        document.querySelectorAll('.quota-progress-fill').forEach((bar) => {
            const progress = Number(bar.dataset.progress || 0);
            const safeProgress = Math.max(0, Math.min(progress, 100));

            bar.style.width = `${safeProgress}%`;
        });
    }

    function openEditQuotaModal(row) {
        const d = row.dataset;

        document.getElementById('modal_nama').textContent = d.nama;
        document.getElementById('modal_current').textContent = d.bimbinganAktif;
        document.getElementById('modal_sisa').textContent = d.sisa;
        document.getElementById('modal_kuota_input').value = d.kuota;
        document.getElementById('modal_kuota_input').min = d.bimbinganAktif;

        document.getElementById('editQuotaForm').action = d.urlKuota;

        document.getElementById('editQuotaModal').classList.remove('hidden');
    }

    document.addEventListener('DOMContentLoaded', applyQuotaProgressBars);
</script>
@endpush