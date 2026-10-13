<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dosen Login - TAssist</title>
    <script>
        (function () {
            const savedTheme = localStorage.getItem('tassist-theme') || 'dark';
            document.documentElement.setAttribute('data-theme', savedTheme);
        })();
    </script>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="min-h-screen flex items-center justify-center relative overflow-hidden theme-bg-main theme-text-main" style="font-family: Inter, sans-serif;">

    <div class="absolute top-5 right-5 z-20">
        @include('components.theme-switcher')
    </div>

    <div class="absolute top-0 right-0 w-96 h-96 rounded-full opacity-10 blur-3xl theme-decoration-primary"></div>
    <div class="absolute bottom-0 left-0 w-96 h-96 rounded-full opacity-10 blur-3xl theme-decoration-accent"></div>

    <div class="relative z-10 w-full max-w-md mx-4 rounded-2xl p-8 border theme-card">

        <div class="flex flex-col items-center mb-8">
            <div class="w-14 h-14 rounded-2xl flex items-center justify-center mb-4 theme-logo-bg">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-7 h-7 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l9-5-9-5-9 5 9 5z"/>
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l6.16-3.422A12.083 12.083 0 0118 13.5c0 2.485-2.686 4.5-6 4.5s-6-2.015-6-4.5c0-.986.316-1.891.84-2.922L12 14z"/>
                </svg>
            </div>

            <h1 class="theme-text-main text-2xl font-extrabold">TAssist</h1>
            <p class="text-sm mt-1 theme-text-muted">
                Thesis Supervision System
            </p>
            <div class="mt-3 px-3 py-1 rounded-full text-xs font-medium theme-badge-primary">
                Dosen Portal
            </div>
        </div>

        <form method="POST" action="{{ route('dosen.login.post') }}" class="space-y-5">
            @csrf

            @if ($errors->any())
                <div class="flex items-start gap-2 p-3 rounded-xl text-sm border theme-alert-error">
                    <span>{{ $errors->first() }}</span>
                </div>
            @endif

            @if (session('error'))
                <div class="flex items-start gap-2 p-3 rounded-xl text-sm border theme-alert-error">
                    <span>{{ session('error') }}</span>
                </div>
            @endif

            @if (session('success'))
                <div class="flex items-start gap-2 p-3 rounded-xl text-sm border theme-alert-success">
                    <span>{{ session('success') }}</span>
                </div>
            @endif

            <div>
                <label for="email" class="block text-sm mb-2 theme-text-muted font-medium">
                    Email Address
                </label>
                <input
                    id="email"
                    type="email"
                    name="email"
                    value="{{ old('email') }}"
                    placeholder="Enter your email"
                    required
                    class="w-full px-4 py-3 rounded-xl outline-none transition-all duration-200 text-sm border theme-input"
                >
            </div>

            <div x-data="{ show: false }">
                <label for="password" class="block text-sm mb-2 theme-text-muted font-medium">
                    Password
                </label>

                <div class="relative">
                    <input
                        :type="show ? 'text' : 'password'"
                        id="password"
                        name="password"
                        placeholder="Enter your password"
                        required
                        class="w-full px-4 py-3 pr-12 rounded-xl outline-none transition-all duration-200 text-sm border theme-input"
                    >

                    <button
                        type="button"
                        @click="show = !show"
                        class="absolute right-3 top-1/2 -translate-y-1/2 p-1 theme-text-muted"
                    >
                        <span x-show="!show">👁️</span>
                        <span x-show="show">🙈</span>
                    </button>
                </div>
            </div>

            <button
                type="submit"
                class="w-full py-3 rounded-xl text-white text-sm transition-all duration-200 flex items-center justify-center gap-2 theme-primary-btn font-semibold"
            >
                Sign In
            </button>
        </form>

        <p class="text-center text-xs mt-6 theme-text-muted">
            Dosen Web Access
        </p>
    </div>

    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
</body>
</html>