@extends('layout.admin')

@section('title', 'Mahasiswa - TAssist Admin')
@section('page-title', 'Manajemen Mahasiswa')
@section('page-subtitle', 'Kelola data mahasiswa')

@section('content')
@php
    $inputClass = 'w-full px-4 py-3 rounded-2xl border theme-input outline-none transition-all duration-200';
    $selectClass = 'px-4 py-3 rounded-2xl border theme-input outline-none transition-all duration-200';
    $labelClass = 'block theme-text-muted text-sm font-medium mb-2';
    $disabledInputClass = 'w-full px-4 py-3 rounded-2xl border theme-input theme-text-muted outline-none opacity-90 cursor-not-allowed';
    $secondaryButtonClass = 'flex-1 py-3 rounded-2xl border theme-border theme-text-muted text-base hover:bg-[var(--color-hover)] transition';
    $modalOverlayClass = 'hidden fixed inset-0 z-50 bg-[rgba(0,0,0,0.72)] flex items-center justify-center p-4';
    $modalPanelClass = 'w-full rounded-[28px] p-8 border theme-card';
@endphp

<div class="space-y-5">

    {{-- Top Filter --}}
    <form method="GET" action="{{ route('admin.mahasiswa.index') }}" id="filterForm">
        <div class="flex flex-wrap items-center gap-3">

            {{-- Search --}}
            <div class="relative flex-1 min-w-[280px]">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 absolute left-4 top-1/2 -translate-y-1/2 theme-text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-4.35-4.35m1.85-5.15a7 7 0 11-14 0 7 7 0 0114 0z"/>
                </svg>

                <input
                    type="text"
                    name="search"
                    value="{{ request('search') }}"
                    placeholder="Cari nama, NIM, atau email..."
                    onchange="this.form.submit()"
                    class="w-full pl-11 pr-4 py-3 rounded-2xl border theme-input text-sm outline-none transition-all duration-200"
                >
            </div>

            {{-- Filter Prodi --}}
            <select
                name="prodi"
                onchange="this.form.submit()"
                class="min-w-[200px] {{ $selectClass }} text-sm"
            >
                <option value="">Semua Prodi</option>
                <option value="Teknik Informatika" {{ request('prodi') === 'Teknik Informatika' ? 'selected' : '' }}>Teknik Informatika</option>
                <option value="Sistem Informasi" {{ request('prodi') === 'Sistem Informasi' ? 'selected' : '' }}>Sistem Informasi</option>
                <option value="Teknik Elektro" {{ request('prodi') === 'Teknik Elektro' ? 'selected' : '' }}>Teknik Elektro</option>
            </select>

            {{-- Filter Angkatan --}}
            <select
                name="angkatan"
                onchange="this.form.submit()"
                class="min-w-[160px] {{ $selectClass }} text-sm"
            >
                <option value="">Semua Angkatan</option>
                @for($y = date('Y'); $y >= 2018; $y--)
                    <option value="{{ $y }}" {{ request('angkatan') == $y ? 'selected' : '' }}>{{ $y }}</option>
                @endfor
            </select>

            {{-- Tombol Add --}}
            <button
                type="button"
                onclick="document.getElementById('addStudentModal').classList.remove('hidden')"
                class="inline-flex items-center gap-2 px-6 py-3 rounded-2xl theme-primary-btn font-semibold transition"
            >
                <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
                </svg>
                Tambah Mahasiswa
            </button>
        </div>
    </form>

    {{-- Table --}}
    <div class="rounded-[24px] overflow-hidden border theme-border theme-card">
        <div class="overflow-x-auto">
            <table class="w-full border-collapse">
                <thead>
                    <tr class="theme-bg-card">
                        <th class="px-5 py-5 text-left text-xs font-semibold theme-text-muted border-b theme-border">No</th>
                        <th class="px-5 py-5 text-left text-xs font-semibold theme-text-muted border-b theme-border">Nama</th>
                        <th class="px-5 py-5 text-left text-xs font-semibold theme-text-muted border-b theme-border">NIM</th>
                        <th class="px-5 py-5 text-left text-xs font-semibold theme-text-muted border-b theme-border">Prodi</th>
                        <th class="px-5 py-5 text-left text-xs font-semibold theme-text-muted border-b theme-border">Angkatan</th>
                        <th class="px-5 py-5 text-left text-xs font-semibold theme-text-muted border-b theme-border">Status Akun</th>
                        <th class="px-5 py-5 text-left text-xs font-semibold theme-text-muted border-b theme-border">Aksi</th>
                    </tr>
                </thead>

                <tbody>
                    @forelse($mahasiswa as $index => $m)
                        <tr
                            class="{{ $index % 2 === 0 ? 'theme-bg-main' : 'theme-bg-card' }} border-b theme-border"
                            data-id="{{ $m->mahasiswa_id }}"
                            data-nama="{{ $m->user->nama }}"
                            data-email="{{ $m->user->email }}"
                            data-nim="{{ $m->nim }}"
                            data-prodi="{{ $m->prodi }}"
                            data-angkatan="{{ $m->angkatan }}"
                            data-topik="{{ $m->topik_ta ?? '' }}"
                            data-judul="{{ $m->judul_ta ?? '' }}"
                            data-status="{{ $m->user->status_akun }}"
                        >
                            {{-- No --}}
                            <td class="px-5 py-5 text-sm theme-text-muted">
                                {{ $mahasiswa->firstItem() + $index }}
                            </td>

                            {{-- Nama + Email --}}
                            <td class="px-5 py-5">
                                <div class="flex items-center gap-3">
                                    <div class="w-10 h-10 rounded-full theme-logo-bg text-white text-sm font-bold flex items-center justify-center flex-shrink-0">
                                        {{ strtoupper(substr($m->user->nama, 0, 1)) }}
                                    </div>

                                    <div>
                                        <p class="theme-text-main text-sm font-medium">{{ $m->user->nama }}</p>
                                        <p class="text-xs theme-text-muted">{{ $m->user->email }}</p>
                                    </div>
                                </div>
                            </td>

                            {{-- NIM --}}
                            <td class="px-5 py-5 text-sm theme-text-muted">{{ $m->nim }}</td>

                            {{-- Prodi --}}
                            <td class="px-5 py-5 text-sm theme-text-muted">{{ $m->prodi }}</td>

                            {{-- Angkatan --}}
                            <td class="px-5 py-5 text-sm theme-text-muted">{{ $m->angkatan }}</td>

                            {{-- Status --}}
                            <td class="px-5 py-5">
                                <span class="px-3 py-1 rounded-full text-xs font-medium
                                    {{ $m->user->status_akun === 'aktif'
                                        ? 'bg-[var(--color-success-bg)] text-[var(--color-success-text)]'
                                        : 'bg-[var(--color-error-bg)] text-[var(--color-error-text)]' }}">
                                    {{ ucfirst($m->user->status_akun) }}
                                </span>
                            </td>

                            {{-- Aksi --}}
                            <td class="px-5 py-5">
                                <div class="flex items-center gap-3">

                                    {{-- View --}}
                                    <button
                                        type="button"
                                        onclick="openViewModal(this.closest('tr'))"
                                        class="text-[var(--color-accent)] hover:opacity-80 transition"
                                        title="Lihat Detail"
                                    >
                                        <svg xmlns="http://www.w3.org/2000/svg" class="w-[18px] h-[18px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                            <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                                            <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                                        </svg>
                                    </button>

                                    {{-- Edit --}}
                                    <button
                                        type="button"
                                        onclick="openEditModal(this.closest('tr'), '{{ route('admin.mahasiswa.update', $m->mahasiswa_id) }}')"
                                        class="text-[#FFB900] hover:opacity-80 transition"
                                        title="Edit"
                                    >
                                        <svg xmlns="http://www.w3.org/2000/svg" class="w-[18px] h-[18px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                            <path stroke-linecap="round" stroke-linejoin="round" d="M11 4h4a2 2 0 012 2v4m-9.586 9.586L3 21l1.414-4.414L14 7l3 3-9.586 9.586z"/>
                                        </svg>
                                    </button>

                                    {{-- Delete --}}
                                    <button
                                        type="button"
                                        onclick="openDeleteModal(this.closest('tr'), '{{ route('admin.mahasiswa.destroy', $m->mahasiswa_id) }}')"
                                        class="text-[var(--color-error-text)] hover:opacity-80 transition"
                                        title="Hapus"
                                    >
                                        <svg xmlns="http://www.w3.org/2000/svg" class="w-[18px] h-[18px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                            <path stroke-linecap="round" stroke-linejoin="round" d="M6 7h12M9 7V5a1 1 0 011-1h4a1 1 0 011 1v2m-7 0l1 12h6l1-12"/>
                                        </svg>
                                    </button>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="px-5 py-12 text-center theme-text-muted text-sm theme-bg-main">
                                Tidak ada data mahasiswa ditemukan.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        {{-- Pagination --}}
        <div class="flex items-center justify-between px-5 py-4 theme-bg-card border-t theme-border">
            <p class="text-sm theme-text-muted">
                Menampilkan {{ $mahasiswa->firstItem() ?? 0 }}–{{ $mahasiswa->lastItem() ?? 0 }}
                dari {{ $mahasiswa->total() }} mahasiswa
            </p>

            <div class="flex items-center gap-2">
                {{-- Prev --}}
                @if($mahasiswa->onFirstPage())
                    <span class="text-[var(--color-border)]">
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7"/>
                        </svg>
                    </span>
                @else
                    <a href="{{ $mahasiswa->previousPageUrl() }}" class="theme-text-muted hover:text-[var(--color-text-main)] transition">
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7"/>
                        </svg>
                    </a>
                @endif

                {{-- Page Numbers --}}
                @foreach($mahasiswa->getUrlRange(1, $mahasiswa->lastPage()) as $page => $url)
                    <a href="{{ $url }}"
                       class="w-9 h-9 rounded-xl text-sm flex items-center justify-center transition
                       {{ $page == $mahasiswa->currentPage()
                           ? 'theme-primary-btn font-semibold'
                           : 'theme-text-muted hover:bg-[var(--color-hover)] hover:text-[var(--color-text-main)]' }}">
                        {{ $page }}
                    </a>
                @endforeach

                {{-- Next --}}
                @if($mahasiswa->hasMorePages())
                    <a href="{{ $mahasiswa->nextPageUrl() }}" class="theme-text-muted hover:text-[var(--color-text-main)] transition">
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
    </div>
</div>

{{-- ============================================================ --}}
{{-- MODAL: ADD STUDENT --}}
{{-- ============================================================ --}}
<div id="addStudentModal" class="{{ $modalOverlayClass }}">
    <div class="max-w-3xl {{ $modalPanelClass }}">
        <div class="flex items-center justify-between mb-8">
            <h2 class="theme-text-main text-2xl font-bold">Tambah Mahasiswa</h2>

            <button
                type="button"
                onclick="document.getElementById('addStudentModal').classList.add('hidden')"
                class="theme-text-muted hover:text-[var(--color-text-main)] transition"
            >
                <svg xmlns="http://www.w3.org/2000/svg" class="w-7 h-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                </svg>
            </button>
        </div>

        <form method="POST" action="{{ route('admin.mahasiswa.store') }}">
            @csrf

            <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                <div class="md:col-span-2">
                    <label class="{{ $labelClass }}">Nama Lengkap <span class="text-red-400">*</span></label>
                    <input type="text" name="nama" value="{{ old('nama') }}" required class="{{ $inputClass }}">
                </div>

                <div>
                    <label class="{{ $labelClass }}">NIM <span class="text-red-400">*</span></label>
                    <input type="text" name="nim" value="{{ old('nim') }}" required class="{{ $inputClass }}">
                </div>

                <div>
                    <label class="{{ $labelClass }}">Email <span class="text-red-400">*</span></label>
                    <input type="email" name="email" value="{{ old('email') }}" required class="{{ $inputClass }}">
                </div>

                <div>
                    <label class="{{ $labelClass }}">Password <span class="text-red-400">*</span></label>
                    <input type="password" name="password" required minlength="8" class="{{ $inputClass }}">
                </div>

                <div>
                    <label class="{{ $labelClass }}">Angkatan <span class="text-red-400">*</span></label>
                    <input type="number" name="angkatan" value="{{ old('angkatan') }}" min="2000" max="{{ date('Y') }}" required class="{{ $inputClass }}">
                </div>

                <div>
                    <label class="{{ $labelClass }}">Program Studi <span class="text-red-400">*</span></label>
                    <select name="prodi" required class="{{ $inputClass }}">
                        <option value="">Pilih Prodi</option>
                        <option value="Teknik Informatika" {{ old('prodi') === 'Teknik Informatika' ? 'selected' : '' }}>Teknik Informatika</option>
                        <option value="Sistem Informasi" {{ old('prodi') === 'Sistem Informasi' ? 'selected' : '' }}>Sistem Informasi</option>
                        <option value="Teknik Elektro" {{ old('prodi') === 'Teknik Elektro' ? 'selected' : '' }}>Teknik Elektro</option>
                    </select>
                </div>

                <div class="md:col-span-2">
                    <label class="{{ $labelClass }}">Topik TA</label>
                    <input type="text" name="topik_ta" value="{{ old('topik_ta') }}" class="{{ $inputClass }}">
                </div>

                <div class="md:col-span-2">
                    <label class="{{ $labelClass }}">Judul TA</label>
                    <input type="text" name="judul_ta" value="{{ old('judul_ta') }}" class="{{ $inputClass }}">
                </div>
            </div>

            <div class="flex gap-4 mt-8">
                <button
                    type="button"
                    onclick="document.getElementById('addStudentModal').classList.add('hidden')"
                    class="{{ $secondaryButtonClass }}"
                >
                    Batal
                </button>

                <button
                    type="submit"
                    class="flex-1 py-3 rounded-2xl theme-primary-btn text-base font-semibold transition"
                >
                    Tambah Mahasiswa
                </button>
            </div>
        </form>
    </div>
</div>

{{-- ============================================================ --}}
{{-- MODAL: VIEW STUDENT --}}
{{-- ============================================================ --}}
<div id="viewStudentModal" class="{{ $modalOverlayClass }}">
    <div class="max-w-3xl {{ $modalPanelClass }}">
        <div class="flex items-center justify-between mb-8">
            <h2 class="theme-text-main text-2xl font-bold">Detail Mahasiswa</h2>

            <button
                type="button"
                onclick="document.getElementById('viewStudentModal').classList.add('hidden')"
                class="theme-text-muted hover:text-[var(--color-text-main)] transition"
            >
                <svg xmlns="http://www.w3.org/2000/svg" class="w-7 h-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                </svg>
            </button>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div class="md:col-span-2">
                <label class="{{ $labelClass }}">Nama Lengkap</label>
                <input type="text" id="view_nama" disabled class="{{ $disabledInputClass }}">
            </div>

            <div>
                <label class="{{ $labelClass }}">NIM</label>
                <input type="text" id="view_nim" disabled class="{{ $disabledInputClass }}">
            </div>

            <div>
                <label class="{{ $labelClass }}">Email</label>
                <input type="text" id="view_email" disabled class="{{ $disabledInputClass }}">
            </div>

            <div>
                <label class="{{ $labelClass }}">Angkatan</label>
                <input type="text" id="view_angkatan" disabled class="{{ $disabledInputClass }}">
            </div>

            <div>
                <label class="{{ $labelClass }}">Program Studi</label>
                <input type="text" id="view_prodi" disabled class="{{ $disabledInputClass }}">
            </div>

            <div class="md:col-span-2">
                <label class="{{ $labelClass }}">Topik TA</label>
                <input type="text" id="view_topik" disabled class="{{ $disabledInputClass }}">
            </div>

            <div class="md:col-span-2">
                <label class="{{ $labelClass }}">Judul TA</label>
                <input type="text" id="view_judul" disabled class="{{ $disabledInputClass }}">
            </div>

            <div>
                <label class="{{ $labelClass }}">Status Akun</label>
                <input type="text" id="view_status" disabled class="{{ $disabledInputClass }}">
            </div>
        </div>
    </div>
</div>

{{-- ============================================================ --}}
{{-- MODAL: EDIT STUDENT --}}
{{-- ============================================================ --}}
<div id="editStudentModal" class="{{ $modalOverlayClass }}">
    <div class="max-w-3xl {{ $modalPanelClass }}">
        <div class="flex items-center justify-between mb-8">
            <h2 class="theme-text-main text-2xl font-bold">Edit Mahasiswa</h2>

            <button
                type="button"
                onclick="document.getElementById('editStudentModal').classList.add('hidden')"
                class="theme-text-muted hover:text-[var(--color-text-main)] transition"
            >
                <svg xmlns="http://www.w3.org/2000/svg" class="w-7 h-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                </svg>
            </button>
        </div>

        <form id="editForm" method="POST" action="">
            @csrf
            @method('PUT')

            <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                <div class="md:col-span-2">
                    <label class="{{ $labelClass }}">Nama Lengkap <span class="text-red-400">*</span></label>
                    <input type="text" name="nama" id="edit_nama" required class="{{ $inputClass }}">
                </div>

                <div>
                    <label class="{{ $labelClass }}">NIM <span class="text-red-400">*</span></label>
                    <input type="text" name="nim" id="edit_nim" required class="{{ $inputClass }}">
                </div>

                <div>
                    <label class="{{ $labelClass }}">Email <span class="text-red-400">*</span></label>
                    <input type="email" name="email" id="edit_email" required class="{{ $inputClass }}">
                </div>

                <div>
                    <label class="{{ $labelClass }}">Angkatan <span class="text-red-400">*</span></label>
                    <input type="number" name="angkatan" id="edit_angkatan" min="2000" max="{{ date('Y') }}" required class="{{ $inputClass }}">
                </div>

                <div>
                    <label class="{{ $labelClass }}">Program Studi <span class="text-red-400">*</span></label>
                    <select name="prodi" id="edit_prodi" required class="{{ $inputClass }}">
                        <option value="Teknik Informatika">Teknik Informatika</option>
                        <option value="Sistem Informasi">Sistem Informasi</option>
                        <option value="Teknik Elektro">Teknik Elektro</option>
                    </select>
                </div>

                <div>
                    <label class="{{ $labelClass }}">Status Akun <span class="text-red-400">*</span></label>
                    <select name="status_akun" id="edit_status_akun" required class="{{ $inputClass }}">
                        <option value="aktif">Aktif</option>
                        <option value="nonaktif">Nonaktif</option>
                    </select>
                </div>

                <div class="md:col-span-2">
                    <label class="{{ $labelClass }}">Topik TA</label>
                    <input type="text" name="topik_ta" id="edit_topik_ta" class="{{ $inputClass }}">
                </div>

                <div class="md:col-span-2">
                    <label class="{{ $labelClass }}">Judul TA</label>
                    <input type="text" name="judul_ta" id="edit_judul_ta" class="{{ $inputClass }}">
                </div>
            </div>

            <div class="flex gap-4 mt-8">
                <button
                    type="button"
                    onclick="document.getElementById('editStudentModal').classList.add('hidden')"
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

{{-- ============================================================ --}}
{{-- MODAL: DELETE STUDENT --}}
{{-- ============================================================ --}}
<div id="deleteStudentModal" class="{{ $modalOverlayClass }}">
    <div class="max-w-xl {{ $modalPanelClass }}">
        <h2 class="theme-text-main text-2xl font-bold mb-4">Konfirmasi Hapus</h2>

        <p class="theme-text-muted text-base leading-7 mb-2">
            Apakah Anda yakin ingin menghapus mahasiswa
            <span id="delete_nama" class="theme-text-main font-semibold"></span>?
        </p>

        <p class="text-[var(--color-error-text)] text-sm mb-8">Tindakan ini tidak dapat dibatalkan.</p>

        <form id="deleteForm" method="POST" action="">
            @csrf
            @method('DELETE')

            <div class="flex gap-4">
                <button
                    type="button"
                    onclick="document.getElementById('deleteStudentModal').classList.add('hidden')"
                    class="{{ $secondaryButtonClass }}"
                >
                    Batal
                </button>

                <button
                    type="submit"
                    class="flex-1 py-3 rounded-2xl bg-[var(--color-error-text)] text-white text-base font-semibold hover:opacity-90 transition"
                >
                    Hapus
                </button>
            </div>
        </form>
    </div>
</div>

@endsection

@push('scripts')
<script>
    // ==================== VIEW MODAL ====================
    function openViewModal(row) {
        const d = row.dataset;

        document.getElementById('view_nama').value     = d.nama;
        document.getElementById('view_nim').value      = d.nim;
        document.getElementById('view_email').value    = d.email;
        document.getElementById('view_angkatan').value = d.angkatan;
        document.getElementById('view_prodi').value    = d.prodi;
        document.getElementById('view_topik').value    = d.topik || '-';
        document.getElementById('view_judul').value    = d.judul || '-';
        document.getElementById('view_status').value   = d.status;

        document.getElementById('viewStudentModal').classList.remove('hidden');
    }

    // ==================== EDIT MODAL ====================
    function openEditModal(row, urlEdit) {
        const d = row.dataset;

        document.getElementById('edit_nama').value     = d.nama;
        document.getElementById('edit_email').value    = d.email;
        document.getElementById('edit_nim').value      = d.nim;
        document.getElementById('edit_angkatan').value = d.angkatan;
        document.getElementById('edit_topik_ta').value = d.topik;
        document.getElementById('edit_judul_ta').value = d.judul;

        const prodiSelect = document.getElementById('edit_prodi');
        for (let opt of prodiSelect.options) {
            opt.selected = opt.value === d.prodi;
        }

        const statusSelect = document.getElementById('edit_status_akun');
        for (let opt of statusSelect.options) {
            opt.selected = opt.value === d.status;
        }

        document.getElementById('editForm').action = urlEdit;
        document.getElementById('editStudentModal').classList.remove('hidden');
    }

    // ==================== DELETE MODAL ====================
    function openDeleteModal(row, urlDelete) {
        const d = row.dataset;

        document.getElementById('delete_nama').textContent = d.nama;
        document.getElementById('deleteForm').action = urlDelete;

        document.getElementById('deleteStudentModal').classList.remove('hidden');
    }
</script>
@endpush