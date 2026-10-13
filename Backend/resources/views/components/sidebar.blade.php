<aside class="w-64 theme-bg-sidebar border-r theme-border-soft flex flex-col hidden md:flex">
    {{-- Logo --}}
    <div class="px-5 py-5 border-b theme-border-soft">
        <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-xl flex items-center justify-center theme-logo-bg">
                <span class="text-white font-extrabold text-lg leading-none">T</span>
            </div>
            <div>
                <h1 class="theme-text-main text-base font-extrabold tracking-tight">TAssist</h1>
                <p class="text-xs theme-text-subtle">TA Management</p>
            </div>
        </div>
    </div>

    {{-- Navigation --}}
    <nav class="flex-1 px-4 py-4 space-y-1 overflow-y-auto">
        <p class="text-[10px] font-semibold uppercase tracking-widest theme-text-faint px-3 mb-3">Menu</p>

        {{-- Dashboard --}}
        <a href="/admin/dashboard"
            class="flex items-center gap-3 px-3 py-2.5 rounded-xl border transition-all duration-150 group
            {{ request()->is('dashboard') 
                ? 'theme-nav-active' 
                : 'theme-nav-link' }}">
            <svg class="w-4.5 h-4.5 flex-shrink-0 {{ request()->is('dashboard') ? 'theme-nav-icon-active' : 'theme-nav-icon' }}"                 xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6A2.25 2.25 0 0 1 6 3.75h2.25A2.25 2.25 0 0 1 10.5 6v2.25a2.25 2.25 0 0 1-2.25 2.25H6a2.25 2.25 0 0 1-2.25-2.25V6ZM3.75 15.75A2.25 2.25 0 0 1 6 13.5h2.25a2.25 2.25 0 0 1 2.25 2.25V18a2.25 2.25 0 0 1-2.25 2.25H6A2.25 2.25 0 0 1 3.75 18v-2.25ZM13.5 6a2.25 2.25 0 0 1 2.25-2.25H18A2.25 2.25 0 0 1 20.25 6v2.25A2.25 2.25 0 0 1 18 10.5h-2.25a2.25 2.25 0 0 1-2.25-2.25V6ZM13.5 15.75a2.25 2.25 0 0 1 2.25-2.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25 2.25 0 0 1 18 20.25h-2.25A2.25 2.25 0 0 1 13.5 18v-2.25Z" />
            </svg>
            <span class="text-sm font-medium">Dashboard</span>
        </a>

        {{-- Students --}}
        <a href="{{ route('admin.mahasiswa.index') }}"
           class="flex items-center gap-3 px-3 py-2.5 rounded-xl border transition-all duration-150 group
           {{ request()->is('students*') 
               ? 'theme-nav-active' 
               : 'theme-nav-link' }}">
            <svg class="w-4.5 h-4.5 flex-shrink-0 {{ request()->is('students*') ? 'theme-nav-icon-active' : 'theme-nav-icon' }}"
                 xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0 0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z" />
            </svg>
            <span class="text-sm font-medium">Students</span>
        </a>

        {{-- Lecturers --}}
        <a href="{{ route('admin.dosen.index') }}"
           class="flex items-center gap-3 px-3 py-2.5 rounded-xl border transition-all duration-150 group
           {{ request()->is('lecturers*') 
               ? 'theme-nav-active' 
               : 'theme-nav-link' }}">
            <svg class="w-4.5 h-4.5 flex-shrink-0 {{ request()->is('lecturers*') ? 'theme-nav-icon-active' : 'theme-nav-icon' }}" 
                 xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4.26 10.147a60.438 60.438 0 0 0-.491 6.347A48.62 48.62 0 0 1 12 20.904a48.62 48.62 0 0 1 8.232-4.41 60.46 60.46 0 0 0-.491-6.347m-15.482 0a50.636 50.636 0 0 0-2.658-.813A59.906 59.906 0 0 1 12 3.493a59.903 59.903 0 0 1 10.399 5.84c-.896.248-1.783.52-2.658.814m-15.482 0A50.717 50.717 0 0 1 12 13.489a50.702 50.702 0 0 1 3.741-3.342M6.75 15a.75.75 0 1 0 0-1.5.75.75 0 0 0 0 1.5Zm0 0v-3.675A55.378 55.378 0 0 1 12 8.443m-7.007 11.55A5.981 5.981 0 0 0 6.75 15.75v-1.5" />
            </svg>
            <span class="text-sm font-medium">Lecturers</span>
        </a>

        {{-- Supervisor Quota --}}
        <a href="{{ route('admin.supervisor-quota.index') }}"
           class="flex items-center gap-3 px-3 py-2.5 rounded-xl border transition-all duration-150 group
           {{ request()->is('supervisor-quota*') 
               ? 'theme-nav-active' 
               : 'theme-nav-link' }}">
            <svg class="w-4.5 h-4.5 flex-shrink-0 {{ request()->is('supervisor-quota*') ? 'theme-nav-icon-active' : 'theme-nav-icon' }}"
                 xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 0 1 3 19.875v-6.75ZM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V8.625ZM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V4.125Z" />
            </svg>
            <span class="text-sm font-medium">Supervisor Quota</span>
        </a>

        {{-- TA Information --}}
        <a href="{{ route('admin.informasi-ta.index') }}"
           class="flex items-center gap-3 px-3 py-2.5 rounded-xl border transition-all duration-150 group
           {{ request()->is('ta-information*') 
               ? 'theme-nav-active' 
               : 'theme-nav-link' }}">
            <svg class="w-4.5 h-4.5 flex-shrink-0 {{ request()->is('ta-information*') ? 'theme-nav-icon-active' : 'theme-nav-icon' }}" 
                 xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.042A8.967 8.967 0 0 0 6 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 0 1 6 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 0 1 6-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0 0 18 18a8.967 8.967 0 0 0-6 2.292m0-14.25v14.25" />
            </svg>
            <span class="text-sm font-medium">TA Information</span>
        </a>

        {{-- Manage Profile --}}
        <a href="{{ route('admin.manage-profile.index') }}"
           class="flex items-center gap-3 px-3 py-2.5 rounded-xl border transition-all duration-150 group
           {{ request()->routeIs('admin.manage-profile.*') 
               ? 'theme-nav-active' 
               : 'theme-nav-link' }}">
            <svg class="w-4.5 h-4.5 flex-shrink-0 {{ request()->routeIs('admin.manage-profile.*') ? 'theme-nav-icon-active' : 'theme-nav-icon' }}" 
                 xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="M17.982 18.725A7.488 7.488 0 0 0 12 15.75a7.488 7.488 0 0 0-5.982 2.975m11.963 0a9 9 0 1 0-11.963 0m11.963 0A8.966 8.966 0 0 1 12 21a8.966 8.966 0 0 1-5.982-2.275M15 9.75a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
            </svg>
            <span class="text-sm font-medium">Manage Profile</span>
        </a>
    </nav>

    {{-- Logout --}}
    <div class="px-4 py-4 border-t theme-border-soft">
            <button type="submit"
                class="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl border theme-logout-link transition-all duration-150 group">
                <svg class="w-4.5 h-4.5 flex-shrink-0" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0 0 13.5 3h-6a2.25 2.25 0 0 0-2.25 2.25v13.5A2.25 2.25 0 0 0 7.5 21h6a2.25 2.25 0 0 0 2.25-2.25V15M12 9l-3 3m0 0 3 3m-3-3h12.75" />
                </svg>
                <span class="text-sm font-medium">Logout</span>
            </button>
    </div>
</aside>