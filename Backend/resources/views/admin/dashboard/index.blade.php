@extends('layout.admin')

@section('title', 'Dashboard - TAssist Admin')
@section('page-title', 'Dashboard')
@section('page-subtitle', 'Selamat datang, ' . session('admin_user.nama', 'Administrator') . '!')

@section('content')
<div class="space-y-6">

    {{-- Stats Cards --}}
    <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">

        <div class="rounded-2xl p-5 flex items-start gap-4 border theme-card border-l-4" style="border-left-color: var(--color-primary);">
            <div class="w-12 h-12 rounded-xl flex items-center justify-center bg-[var(--color-primary-soft)] flex-shrink-0">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6 text-[var(--color-primary)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a4 4 0 00-5-3.87M9 20H4v-2a4 4 0 015-3.87m0 0a4 4 0 118 0"/>
                </svg>
            </div>
            <div>
                <p class="text-sm mb-1 theme-text-muted font-medium">Total Mahasiswa</p>
                <p class="theme-text-main text-2xl font-extrabold">{{ $totalMahasiswa }}</p>
                @if($mahasiswaBulanIni > 0)
                    <p class="text-xs mt-1 text-[var(--color-success-text)]">+{{ $mahasiswaBulanIni }} bulan ini</p>
                @endif
            </div>
        </div>

        <div class="rounded-2xl p-5 flex items-start gap-4 border theme-card border-l-4" style="border-left-color: var(--color-accent);">
            <div class="w-12 h-12 rounded-xl flex items-center justify-center bg-[var(--color-primary-soft)] flex-shrink-0">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6 text-[var(--color-accent)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M5.121 17.804A8 8 0 1118.88 6.196M15 11a3 3 0 11-6 0 3 3 0 016 0z"/>
                </svg>
            </div>
            <div>
                <p class="text-sm mb-1 theme-text-muted font-medium">Total Dosen</p>
                <p class="theme-text-main text-2xl font-extrabold">{{ $totalDosen }}</p>
                @if($dosenBulanIni > 0)
                    <p class="text-xs mt-1 text-[var(--color-success-text)]">+{{ $dosenBulanIni }} bulan ini</p>
                @endif
            </div>
        </div>

        <div class="rounded-2xl p-5 flex items-start gap-4 border theme-card border-l-4 border-l-[#3DDC97]">
            <div class="w-12 h-12 rounded-xl flex items-center justify-center bg-[rgba(61,220,151,0.15)] flex-shrink-0">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6 text-[#3DDC97]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
            </div>
            <div>
                <p class="text-sm mb-1 theme-text-muted font-medium">Slot Tersedia</p>
                <p class="theme-text-main text-2xl font-extrabold">{{ $availableSlots }}</p>
                <p class="text-xs mt-1 theme-text-muted">dari total kuota dosen</p>
            </div>
        </div>

        <div class="rounded-2xl p-5 flex items-start gap-4 border theme-card border-l-4 border-l-[#FFB900]">
            <div class="w-12 h-12 rounded-xl flex items-center justify-center bg-[rgba(255,185,0,0.15)] flex-shrink-0">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6 text-[#FFB900]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
            </div>
            <div>
                <p class="text-sm mb-1 theme-text-muted font-medium">Permohonan Menunggu</p>
                <p class="theme-text-main text-2xl font-extrabold">{{ $permohonanMenunggu }}</p>
                @if($permohonanMingguIni > 0)
                    <p class="text-xs mt-1 text-[var(--color-success-text)]">+{{ $permohonanMingguIni }} minggu ini</p>
                @endif
            </div>
        </div>
    </div>

    {{-- Chart + Quick Actions --}}
    <div class="grid grid-cols-1 xl:grid-cols-3 gap-4">

        {{-- Chart --}}
        <div class="xl:col-span-2 rounded-2xl p-5 border theme-card">
            <div class="mb-5">
                <h3 class="theme-text-main text-sm font-bold">Ringkasan Permohonan Bimbingan</h3>
                <p class="text-xs mt-0.5 theme-text-muted">6 bulan terakhir</p>
            </div>
            <canvas id="submissionChart" height="100"></canvas>
        </div>

        {{-- Quick Actions --}}
        <div class="rounded-2xl p-5 border theme-card">
            <h3 class="theme-text-main text-sm mb-4 font-bold">Quick Actions</h3>

            <div class="space-y-3">
                <a href="{{ route('admin.mahasiswa.index') }}"
                   class="w-full flex items-center gap-3 p-3 rounded-xl theme-bg-input border theme-border hover:border-[var(--color-primary)] transition">
                    <div class="w-9 h-9 rounded-lg flex items-center justify-center bg-[var(--color-primary-soft)]">
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5 text-[var(--color-primary)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z"/>
                        </svg>
                    </div>
                    <span class="theme-text-main text-sm flex-1 font-medium">Tambah Mahasiswa</span>
                    <span class="theme-text-muted text-xs">→</span>
                </a>

                <a href="{{ route('admin.dosen.index') }}"
                   class="w-full flex items-center gap-3 p-3 rounded-xl theme-bg-input border theme-border hover:border-[var(--color-accent)] transition">
                    <div class="w-9 h-9 rounded-lg flex items-center justify-center bg-[var(--color-primary-soft)]">
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5 text-[var(--color-accent)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M5.121 17.804A8 8 0 1118.88 6.196"/>
                        </svg>
                    </div>
                    <span class="theme-text-main text-sm flex-1 font-medium">Tambah Dosen</span>
                    <span class="theme-text-muted text-xs">→</span>
                </a>

                <a href="{{ route('admin.supervisor-quota.index') }}"
                   class="w-full flex items-center gap-3 p-3 rounded-xl theme-bg-input border theme-border hover:border-[#3DDC97] transition">
                    <div class="w-9 h-9 rounded-lg flex items-center justify-center bg-[rgba(61,220,151,0.15)]">
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5 text-[#3DDC97]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"/>
                        </svg>
                    </div>
                    <span class="theme-text-main text-sm flex-1 font-medium">Set Kuota</span>
                    <span class="theme-text-muted text-xs">→</span>
                </a>

                <a href="{{ route('admin.informasi-ta.index') }}"
                   class="w-full flex items-center gap-3 p-3 rounded-xl theme-bg-input border theme-border hover:border-[#FFB900] transition">
                    <div class="w-9 h-9 rounded-lg flex items-center justify-center bg-[rgba(255,185,0,0.15)]">
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5 text-[#FFB900]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6M7 4h7l5 5v11a1 1 0 01-1 1H7a1 1 0 01-1-1V5a1 1 0 011-1z"/>
                        </svg>
                    </div>
                    <span class="theme-text-main text-sm flex-1 font-medium">Post Informasi TA</span>
                    <span class="theme-text-muted text-xs">→</span>
                </a>
            </div>
        </div>
    </div>

    {{-- Recent Students + Recent Activity --}}
    <div class="grid grid-cols-1 xl:grid-cols-3 gap-4">

        {{-- Recent Students --}}
        <div class="xl:col-span-2 rounded-2xl p-5 border theme-card">
            <div class="flex items-center justify-between mb-4">
                <h3 class="theme-text-main text-sm font-bold">Mahasiswa Terbaru</h3>
                <a href="{{ route('admin.mahasiswa.index') }}" class="text-xs text-[var(--color-accent)] hover:underline">
                    Lihat Semua →
                </a>
            </div>

            <div class="space-y-1">
                <div class="grid grid-cols-12 gap-2 px-3 py-2 text-xs theme-text-muted font-medium">
                    <span class="col-span-4">Nama</span>
                    <span class="col-span-3">Prodi</span>
                    <span class="col-span-3">Dosen Pembimbing</span>
                    <span class="col-span-2">Status</span>
                </div>

                @forelse($recentMahasiswa as $m)
                    @php
                        $bimbingan = $m->bimbinganAktif;
                        $dosenNama = $bimbingan?->dosen?->user?->nama ?? null;
                        $statusLabel = $bimbingan ? 'Aktif' : 'Belum';
                        $statusClass = $bimbingan
                            ? 'bg-[var(--color-primary-soft)] text-[var(--color-accent)]'
                            : 'bg-[rgba(160,168,192,0.15)] theme-text-muted';
                    @endphp

                    <div class="grid grid-cols-12 gap-2 px-3 py-2.5 rounded-xl text-sm items-center {{ $loop->odd ? 'theme-bg-input' : '' }}">
                        <div class="col-span-4 flex items-center gap-2">
                            <div class="w-7 h-7 rounded-full flex items-center justify-center text-xs text-white theme-logo-bg font-bold flex-shrink-0">
                                {{ strtoupper(substr($m->user->nama, 0, 1)) }}
                            </div>
                            <span class="theme-text-main text-xs truncate font-medium">{{ $m->user->nama }}</span>
                        </div>

                        <span class="col-span-3 text-xs truncate theme-text-muted">{{ $m->prodi }}</span>

                        <span class="col-span-3 text-xs truncate theme-text-muted">
                            {{ $dosenNama ?? '— Belum' }}
                        </span>

                        <div class="col-span-2">
                            <span class="px-2 py-0.5 rounded-full text-xs font-medium {{ $statusClass }}">
                                {{ $statusLabel }}
                            </span>
                        </div>
                    </div>
                @empty
                    <div class="px-3 py-6 text-center theme-text-muted text-xs">
                        Belum ada mahasiswa terdaftar.
                    </div>
                @endforelse
            </div>
        </div>

        {{-- Recent Activity --}}
        <div class="rounded-2xl p-5 border theme-card">
            <div class="flex items-center gap-2 mb-4">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 text-[var(--color-accent)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/>
                </svg>
                <h3 class="theme-text-main text-sm font-bold">Aktivitas Terbaru</h3>
            </div>

            <div class="space-y-4">
                @forelse($recentActivity as $activity)
                    <div class="flex items-start gap-3">
                        <div class="w-2 h-2 rounded-full mt-1.5 flex-shrink-0"
                             style="background-color: {{ $activity['color'] }}"></div>

                        <div class="flex-1 min-w-0">
                            <p class="theme-text-main text-xs font-medium">{{ $activity['title'] }}</p>
                            <p class="text-xs theme-text-muted truncate">{{ $activity['desc'] }}</p>
                            <p class="text-xs mt-0.5 text-[var(--color-accent)]">
                                {{ $activity['time']?->diffForHumans() ?? '-' }}
                            </p>
                        </div>
                    </div>
                @empty
                    <p class="theme-text-muted text-xs text-center py-4">Belum ada aktivitas.</p>
                @endforelse
            </div>
        </div>
    </div>

    {{-- Lecturer Quota Overview --}}
    <div class="rounded-2xl p-5 border theme-card">
        <div class="flex items-center justify-between mb-5">
            <h3 class="theme-text-main text-sm font-bold">Kuota Dosen Pembimbing</h3>
            <a href="{{ route('admin.supervisor-quota.index') }}" class="text-xs text-[var(--color-accent)] hover:underline">
                Kelola →
            </a>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
            @forelse($dosenQuota as $d)
                <div class="p-4 rounded-xl theme-bg-input border theme-border">
                    <div class="flex items-center gap-2 mb-3">
                        <div class="w-8 h-8 rounded-full flex items-center justify-center text-xs text-white theme-logo-bg font-bold flex-shrink-0">
                            {{ $d['initial'] }}
                        </div>

                        <div class="min-w-0">
                            <p class="theme-text-main text-xs font-semibold truncate">{{ $d['nama'] }}</p>
                            <p class="text-xs theme-text-muted truncate">{{ $d['bidang_keahlian'] }}</p>
                        </div>
                    </div>

                    <div class="flex items-center justify-between text-xs mb-2">
                        <span class="theme-text-muted">{{ $d['aktif'] }}/{{ $d['kuota'] }} mahasiswa</span>
                        <span class="font-semibold" style="color: {{ $d['barColor'] }}">
                            {{ $d['pct'] }}%
                        </span>
                    </div>

                    <div class="h-1.5 rounded-full overflow-hidden bg-[var(--color-border)]">
                        <div class="h-full rounded-full transition-all duration-300"
                             style="width: {{ $d['pct'] }}%; background-color: {{ $d['barColor'] }}"></div>
                    </div>

                    @if($d['isFull'])
                        <p class="text-xs text-[var(--color-error-text)] mt-2 font-medium">Kuota penuh</p>
                    @else
                        <p class="text-xs theme-text-muted mt-2">Sisa: {{ $d['sisa'] }} slot</p>
                    @endif
                </div>
            @empty
                <div class="col-span-4 text-center theme-text-muted text-xs py-6">
                    Belum ada data dosen.
                </div>
            @endforelse
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script>
    const chartData = @json($chartData);

    function getThemeVar(name, fallback = '') {
        return getComputedStyle(document.documentElement).getPropertyValue(name).trim() || fallback;
    }

    function hexToRgba(hex, alpha = 1) {
        if (!hex || !hex.startsWith('#')) {
            return hex;
        }

        const cleanHex = hex.replace('#', '');
        const fullHex = cleanHex.length === 3
            ? cleanHex.split('').map(char => char + char).join('')
            : cleanHex;

        const r = parseInt(fullHex.substring(0, 2), 16);
        const g = parseInt(fullHex.substring(2, 4), 16);
        const b = parseInt(fullHex.substring(4, 6), 16);

        return `rgba(${r}, ${g}, ${b}, ${alpha})`;
    }

    function getChartTheme() {
        const primary = getThemeVar('--color-primary', '#0057B8');
        const accent = getThemeVar('--color-accent', '#4DA3FF');
        const textMuted = getThemeVar('--color-text-muted', '#A0A8C0');
        const border = getThemeVar('--color-border', '#3A4566');

        return {
            primary,
            accent,
            textMuted,
            grid: hexToRgba(border, 0.45),
            success: '#3DDC97',
        };
    }

    function applyChartTheme(chart) {
        const theme = getChartTheme();

        chart.data.datasets[0].backgroundColor = hexToRgba(theme.primary, 0.6);
        chart.data.datasets[0].borderColor = theme.primary;

        chart.data.datasets[1].backgroundColor = hexToRgba(theme.success, 0.6);
        chart.data.datasets[1].borderColor = theme.success;

        chart.options.plugins.legend.labels.color = theme.textMuted;

        chart.options.scales.x.ticks.color = theme.textMuted;
        chart.options.scales.x.grid.color = theme.grid;

        chart.options.scales.y.ticks.color = theme.textMuted;
        chart.options.scales.y.grid.color = theme.grid;

        chart.update();
    }

    const ctx = document.getElementById('submissionChart').getContext('2d');
    const currentTheme = getChartTheme();

    const submissionChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: chartData.map(d => d.label),
            datasets: [
                {
                    label: 'Total Permohonan',
                    data: chartData.map(d => d.permohonan),
                    backgroundColor: hexToRgba(currentTheme.primary, 0.6),
                    borderColor: currentTheme.primary,
                    borderWidth: 1,
                    borderRadius: 6,
                },
                {
                    label: 'Diterima',
                    data: chartData.map(d => d.diterima),
                    backgroundColor: hexToRgba(currentTheme.success, 0.6),
                    borderColor: currentTheme.success,
                    borderWidth: 1,
                    borderRadius: 6,
                }
            ]
        },
        options: {
            responsive: true,
            plugins: {
                legend: {
                    labels: {
                        color: currentTheme.textMuted,
                        font: { size: 11 }
                    }
                }
            },
            scales: {
                x: {
                    ticks: {
                        color: currentTheme.textMuted,
                        font: { size: 11 }
                    },
                    grid: {
                        color: currentTheme.grid
                    }
                },
                y: {
                    ticks: {
                        color: currentTheme.textMuted,
                        font: { size: 11 },
                        stepSize: 1
                    },
                    grid: {
                        color: currentTheme.grid
                    },
                    beginAtZero: true
                }
            }
        }
    });

    const themeObserver = new MutationObserver(() => {
        applyChartTheme(submissionChart);
    });

    themeObserver.observe(document.documentElement, {
        attributes: true,
        attributeFilter: ['data-theme']
    });
</script>
@endpush