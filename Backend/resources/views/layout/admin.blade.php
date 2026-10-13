<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $title ?? 'Admin Panel' }}</title>
    <script>
        (function () {
            const savedTheme = localStorage.getItem('tassist-theme') || 'dark';
            document.documentElement.setAttribute('data-theme', savedTheme);
        })();
    </script>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="theme-bg-main theme-text-main min-h-screen" style="font-family: Inter, sans-serif;">
    <div class="flex min-h-screen">
        @include('components.sidebar')

        <div class="flex-1 flex flex-col min-w-0">
            @include('components.navbar')

            {{-- Page Content --}}
            <main class="flex-1 overflow-y-auto p-6">
            
                {{-- Flash Messages --}}
                @if(session('success'))
                    <div class="mb-4 flex items-center gap-2 px-4 py-3 rounded-xl text-sm border theme-alert-success">
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/>
                        </svg>
                        {{ session('success') }}
                    </div>
                @endif
            
                @if(session('error'))
                    <div class="mb-4 flex items-center gap-2 px-4 py-3 rounded-xl text-sm border theme-alert-error">
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                        </svg>
                        {{ session('error') }}
                    </div>
                @endif
            
                {{-- Validasi Error --}}
                @if($errors->any())
                    <div class="mb-4 p-4 rounded-xl text-sm border theme-alert-error">
                        <p class="font-semibold mb-2">Terdapat kesalahan:</p>
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