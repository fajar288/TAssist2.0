<button
    type="button"
    onclick="toggleTAssistTheme()"
    class="theme-switcher-button inline-flex items-center justify-center gap-2 px-3.5 py-2.5 rounded-full border text-xs font-extrabold transition-all duration-200"
    title="Switch color scheme"
>
    <span class="theme-mode-dark">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21.752 15.002A9.718 9.718 0 0118 15.75 9.75 9.75 0 018.25 6c0-1.33.266-2.597.748-3.752A9.753 9.753 0 003 11.25 9.75 9.75 0 0012.75 21a9.753 9.753 0 009.002-5.998z" />
        </svg>
        Dark
    </span>

    <span class="theme-mode-light">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 3v1.5m0 15V21m9-9h-1.5M4.5 12H3m15.364-6.364l-1.061 1.061M6.697 17.303l-1.061 1.061m12.728 0l-1.061-1.061M6.697 6.697L5.636 5.636M12 8.25A3.75 3.75 0 1112 15.75 3.75 3.75 0 0112 8.25z" />
        </svg>
        Light
    </span>
</button>

<script>
    window.setTAssistTheme = function (theme) {
        const selectedTheme = theme === 'light' ? 'light' : 'dark';

        document.documentElement.setAttribute('data-theme', selectedTheme);
        localStorage.setItem('tassist-theme', selectedTheme);
    }

    window.toggleTAssistTheme = function () {
        const currentTheme = document.documentElement.getAttribute('data-theme') || 'dark';
        const nextTheme = currentTheme === 'dark' ? 'light' : 'dark';

        window.setTAssistTheme(nextTheme);
    }
</script>