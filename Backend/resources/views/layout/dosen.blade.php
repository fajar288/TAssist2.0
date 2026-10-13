<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $title ?? 'Dosen Portal - TAssist' }}</title>

    <script>
        (function () {
            const savedTheme = localStorage.getItem('tassist-theme') || 'dark';
            document.documentElement.setAttribute('data-theme', savedTheme);
        })();
    </script>

    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>

@php
    $navItems = [
        [
            'label' => 'Dashboard',
            'route' => 'dosen.dashboard',
            'active' => 'dosen.dashboard',
            'icon' => '<svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M3.75 13.5h6.75V3.75H3.75v9.75zM13.5 20.25h6.75V10.5H13.5v9.75zM13.5 7.5h6.75V3.75H13.5V7.5zM3.75 20.25h6.75V16.5H3.75v3.75z" /></svg>',
        ],
        [
            'label' => 'Permohonan Bimbingan',
            'route' => 'dosen.permohonan.index',
            'active' => 'dosen.permohonan.*',
            'icon' => '<svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M8.25 6.75h12M8.25 12h12M8.25 17.25h12M3.75 6.75h.008v.008H3.75V6.75zM3.75 12h.008v.008H3.75V12zM3.75 17.25h.008v.008H3.75v-.008z" /></svg>',
        ],
        [
            'label' => 'Mahasiswa Bimbingan',
            'route' => 'dosen.mahasiswa-bimbingan.index',
            'active' => 'dosen.mahasiswa-bimbingan.*',
            'icon' => '<svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.5 20.25a8.25 8.25 0 0115 0" /></svg>',
        ],
        [
            'label' => 'Jadwal Bimbingan',
            'route' => 'dosen.jadwal.index',
            'active' => 'dosen.jadwal.*',
            'icon' => '<svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3.75 8.25h16.5M5.25 5.25h13.5A1.5 1.5 0 0120.25 6.75v12A1.5 1.5 0 0118.75 20.25H5.25A1.5 1.5 0 013.75 18.75v-12A1.5 1.5 0 015.25 5.25z" /></svg>',
        ],
        [
            'label' => 'Dokumen & Feedback',
            'route' => 'dosen.dokumen.index',
            'active' => 'dosen.dokumen.*',
            'icon' => '<svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M19.5 14.25v-2.625A3.375 3.375 0 0016.125 8.25h-1.5A1.125 1.125 0 0113.5 7.125v-1.5A3.375 3.375 0 0010.125 2.25H6.75A2.25 2.25 0 004.5 4.5v15A2.25 2.25 0 006.75 21.75h10.5A2.25 2.25 0 0019.5 19.5v-5.25z" /></svg>',
        ],
        [
            'label' => 'Progress & Checklist',
            'route' => 'dosen.progress-checklist.index',
            'active' => 'dosen.progress-checklist.*',
            'icon' => '<svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M3.75 19.5h16.5M6.75 16.5V10.5M12 16.5V4.5M17.25 16.5V7.5" /></svg>',
        ],
    ];
@endphp

<body
    x-data="{ mobileSidebarOpen: false }"
    class="theme-bg-main theme-text-main assist-shell min-h-screen"
    style="font-family: Inter, Instrument Sans, ui-sans-serif, system-ui, sans-serif;"
>
    <div class="min-h-screen flex">

        <aside class="tassist-sidebar w-80 min-h-screen border-r p-5 hidden lg:flex lg:flex-col sticky top-0">
            <div class="mb-8">
                <div class="flex items-center gap-3">
                    <div class="tassist-brand-mark w-12 h-12 rounded-2xl flex items-center justify-center font-black">
                        TA
                    </div>

                    <div>
                        <h1 class="text-2xl font-black tracking-tight theme-text-main">
                            TAssist
                        </h1>
                        <p class="text-sm theme-text-muted">
                            Dosen Portal
                        </p>
                    </div>
                </div>
            </div>

            <nav class="flex-1 space-y-2">
                @foreach($navItems as $item)
                    <a
                        href="{{ route($item['route']) }}"
                        class="theme-nav-link {{ request()->routeIs($item['active']) ? 'theme-nav-active' : '' }} group flex items-center gap-3 px-4 py-3.5 rounded-2xl border text-sm font-extrabold"
                    >
                        <span class="theme-nav-icon flex-shrink-0">
                            {!! $item['icon'] !!}
                        </span>
                        <span>{{ $item['label'] }}</span>
                    </a>
                @endforeach
            </nav>

            <div class="mt-6 rounded-3xl border theme-soft-card p-4">
                <p class="text-xs theme-text-muted font-bold uppercase tracking-wide">
                    Logged in as
                </p>
                <p class="mt-1 font-extrabold theme-text-main leading-snug">
                    {{ session('dosen_user.nama') }}
                </p>
                <p class="text-xs theme-text-muted mt-1 truncate">
                    {{ session('dosen_user.email') }}
                </p>

                <form method="POST" action="{{ route('dosen.logout') }}" class="mt-4">
                    @csrf
                    <button
                        type="submit"
                        class="theme-logout-link w-full px-4 py-3 rounded-2xl border text-sm font-extrabold text-left transition"
                    >
                        Logout
                    </button>
                </form>
            </div>
        </aside>

        <div
            x-cloak
            x-show="mobileSidebarOpen"
            class="fixed inset-0 z-50 lg:hidden"
        >
            <div
                class="absolute inset-0 bg-black/60"
                @click="mobileSidebarOpen = false"
            ></div>

            <aside class="tassist-sidebar relative w-[86%] max-w-sm h-full border-r p-5 flex flex-col">
                <div class="flex items-center justify-between mb-8">
                    <div class="flex items-center gap-3">
                        <div class="tassist-brand-mark w-11 h-11 rounded-2xl flex items-center justify-center font-black">
                            TA
                        </div>

                        <div>
                            <h1 class="text-xl font-black theme-text-main">TAssist</h1>
                            <p class="text-sm theme-text-muted">Dosen Portal</p>
                        </div>
                    </div>

                    <button
                        type="button"
                        @click="mobileSidebarOpen = false"
                        class="theme-icon-button w-10 h-10 rounded-2xl border flex items-center justify-center"
                    >
                        ✕
                    </button>
                </div>

                <nav class="flex-1 space-y-2">
                    @foreach($navItems as $item)
                        <a
                            href="{{ route($item['route']) }}"
                            class="theme-nav-link {{ request()->routeIs($item['active']) ? 'theme-nav-active' : '' }} flex items-center gap-3 px-4 py-3.5 rounded-2xl border text-sm font-extrabold"
                        >
                            <span class="theme-nav-icon flex-shrink-0">
                                {!! $item['icon'] !!}
                            </span>
                            <span>{{ $item['label'] }}</span>
                        </a>
                    @endforeach
                </nav>
            </aside>
        </div>

        <div class="flex-1 flex flex-col min-w-0">
            <header class="tassist-topbar sticky top-0 z-30 border-b px-4 sm:px-6 lg:px-8 py-4">
                <div class="flex items-center justify-between gap-4">
                    <div class="flex items-center gap-3 min-w-0">
                        <button
                            type="button"
                            @click="mobileSidebarOpen = true"
                            class="theme-icon-button lg:hidden w-11 h-11 rounded-2xl border flex items-center justify-center"
                        >
                            ☰
                        </button>

                        <div class="min-w-0">
                            <p class="text-xs theme-text-muted font-bold uppercase tracking-wide">
                                Dosen Portal
                            </p>
                            <h2 class="font-black theme-text-main truncate">
                                {{ session('dosen_user.nama') }}
                            </h2>
                        </div>
                    </div>

                    <div class="flex items-center gap-3">
                        @include('components.theme-switcher')

                        <form method="POST" action="{{ route('dosen.logout') }}" class="hidden sm:block lg:hidden">
                            @csrf
                            <button
                                type="submit"
                                class="theme-logout-link px-4 py-2.5 rounded-full border text-xs font-extrabold transition"
                            >
                                Logout
                            </button>
                        </form>
                    </div>
                </div>
            </header>

            <main class="flex-1 w-full max-w-[1600px] mx-auto p-4 sm:p-6 lg:p-8">

                @if(session('success'))
                    <div class="mb-5 px-5 py-4 rounded-2xl text-sm border theme-alert-success font-semibold">
                        {{ session('success') }}
                    </div>
                @endif

                @if(session('error'))
                    <div class="mb-5 px-5 py-4 rounded-2xl text-sm border theme-alert-error font-semibold">
                        {{ session('error') }}
                    </div>
                @endif

                @if($errors->any())
                    <div class="mb-5 p-5 rounded-2xl text-sm border theme-alert-error">
                        <p class="font-extrabold mb-2">Terdapat kesalahan:</p>
                        <ul class="list-disc list-inside space-y-1">
                            @foreach($errors->all() as $error)
                                <li>{{ $error }}</li>
                            @endforeach
                        </ul>
                    </div>
                @endif

                @yield('content')
            </main>
        </div>
    </div>

    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
    @stack('scripts')
</body>
</html>