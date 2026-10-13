@php
    $notifications = [
        [
            'id' => 1,
            'type' => 'student',
            'title' => 'New TA Submission',
            'message' => 'Budi Utomo (21610003) submitted a new TA proposal.',
            'time' => '5 menit lalu',
            'read' => false,
        ],
        [
            'id' => 2,
            'type' => 'student',
            'title' => 'Pending Review',
            'message' => 'Indah Permata (21610008) is awaiting supervisor assignment.',
            'time' => '18 menit lalu',
            'read' => false,
        ],
        [
            'id' => 3,
            'type' => 'quota',
            'title' => 'Quota Almost Full',
            'message' => 'Prof. Eko Prasetyo has reached 100% of his quota (4/4).',
            'time' => '42 menit lalu',
            'read' => false,
        ],
        [
            'id' => 4,
            'type' => 'ta',
            'title' => 'Draft Ready to Publish',
            'message' => '"Persyaratan Pengambilan TA" is still in Draft status.',
            'time' => '1 jam lalu',
            'read' => false,
        ],
        [
            'id' => 5,
            'type' => 'lecturer',
            'title' => 'New Lecturer Added',
            'message' => 'Dr. Irfan Maulana has been added to the lecturer list.',
            'time' => '3 jam lalu',
            'read' => true,
        ],
        [
            'id' => 6,
            'type' => 'system',
            'title' => 'System Update',
            'message' => 'Backup completed successfully.',
            'time' => 'Kemarin',
            'read' => true,
        ],
        [
            'id' => 7,
            'type' => 'ta',
            'title' => 'TA Info Published',
            'message' => 'Jadwal Sidang TA Semester Ganjil has been published.',
            'time' => 'Kemarin',
            'read' => true,
        ],
        [
            'id' => 8,
            'type' => 'lecturer',
            'title' => 'Quota Updated',
            'message' => 'Quota for Dr. Budi Santoso has been adjusted.',
            'time' => '2 hari lalu',
            'read' => true,
        ],
    ];

    $unreadCount = collect($notifications)->where('read', false)->count();
    $readCount = count($notifications) - $unreadCount;

    if (! function_exists('notifTypeConfig')) {
        function notifTypeConfig($type) {
            return match($type) {
                'student' => [
                    'icon' => 'student',
                    'bgClass' => 'bg-[rgba(77,163,255,0.15)]',
                    'textClass' => 'text-[#4DA3FF]',
                ],
                'lecturer' => [
                    'icon' => 'lecturer',
                    'bgClass' => 'bg-[rgba(61,220,151,0.15)]',
                    'textClass' => 'text-[#3DDC97]',
                ],
                'ta' => [
                    'icon' => 'file',
                    'bgClass' => 'bg-[rgba(255,185,0,0.15)]',
                    'textClass' => 'text-[#FFB900]',
                ],
                'quota' => [
                    'icon' => 'gear',
                    'bgClass' => 'bg-[rgba(255,77,77,0.15)]',
                    'textClass' => 'text-[#FF4D4D]',
                ],
                default => [
                    'icon' => 'shield',
                    'bgClass' => 'bg-[rgba(160,168,192,0.15)]',
                    'textClass' => 'text-[#A0A8C0]',
                ],
            };
        }
    }
@endphp

<div
    id="notificationPanel"
    class="hidden absolute top-16 right-0 z-50 w-[460px] rounded-[24px] overflow-hidden border theme-card"
>
    <!-- Header -->
    <div class="flex items-center justify-between px-5 py-4 border-b theme-border">
        <div class="flex items-center gap-3">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-[18px] h-[18px] text-[var(--color-accent)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0a3 3 0 11-6 0m6 0H9" />
            </svg>

            <span class="theme-text-main text-[18px] font-bold">Notifications</span>

            @if ($unreadCount > 0)
                <span class="px-3 py-1 rounded-full bg-[#FF5A57] text-white text-sm font-bold leading-none">
                    {{ $unreadCount }}
                </span>
            @endif
        </div>

        <div class="flex items-center gap-2">
            <button
                class="p-2 rounded-xl theme-text-muted hover:bg-[var(--color-hover)] hover:text-[var(--color-accent)] transition"
                title="Mark all as read"
            >
                <svg xmlns="http://www.w3.org/2000/svg" class="w-[17px] h-[17px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4M13 8l2 2 4-4"/>
                </svg>
            </button>

            <button
                class="p-2 rounded-xl theme-text-muted hover:bg-[var(--color-hover)] hover:text-[var(--color-error-text)] transition"
                title="Clear all"
            >
                <svg xmlns="http://www.w3.org/2000/svg" class="w-[17px] h-[17px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 7h12M9 7V5a1 1 0 011-1h4a1 1 0 011 1v2m-7 0l1 12h6l1-12" />
                </svg>
            </button>

            <button
                onclick="toggleNotificationPanel(false)"
                class="p-2 rounded-xl theme-text-muted hover:bg-[var(--color-hover)] hover:text-[var(--color-text-main)] transition"
                title="Close"
            >
                <svg xmlns="http://www.w3.org/2000/svg" class="w-[17px] h-[17px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                </svg>
            </button>
        </div>
    </div>

    <!-- Info -->
    <div class="px-5 py-3 border-b theme-border text-sm theme-text-muted">
        @if ($unreadCount > 0)
            {{ $unreadCount }} unread
            <span class="mx-2 theme-text-faint">•</span>
            {{ $readCount }} read
        @else
            All caught up!
        @endif
    </div>

    <!-- List -->
    <div class="max-h-[520px] overflow-y-auto">
        @forelse ($notifications as $notif)
            @php
                $cfg = notifTypeConfig($notif['type']);
            @endphp

            <div
                class="group relative flex items-start gap-4 px-5 py-4 border-b theme-border-soft hover:bg-[var(--color-hover)] transition {{ !$notif['read'] ? 'bg-[var(--color-primary-soft)]' : '' }}"
            >
                @if (!$notif['read'])
                    <span class="absolute left-2 top-7 w-2 h-2 rounded-full bg-[var(--color-accent)]"></span>
                @endif

                <div
                    class="w-12 h-12 rounded-2xl flex items-center justify-center flex-shrink-0 mt-0.5 {{ $cfg['bgClass'] }} {{ $cfg['textClass'] }}"
                >
                    @if ($cfg['icon'] === 'student')
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-[18px] h-[18px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5V9L12 4 2 9v11h5m10 0v-5a5 5 0 00-10 0v5m10 0H7" />
                        </svg>
                    @elseif ($cfg['icon'] === 'lecturer')
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-[18px] h-[18px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l9-5-9-5-9 5 9 5z"/>
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l6.16-3.422A12.083 12.083 0 0112 20.055a12.083 12.083 0 01-6.16-9.477L12 14z"/>
                        </svg>
                    @elseif ($cfg['icon'] === 'file')
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-[18px] h-[18px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6M7 4h7l5 5v11a1 1 0 01-1 1H7a1 1 0 01-1-1V5a1 1 0 011-1z"/>
                        </svg>
                    @elseif ($cfg['icon'] === 'gear')
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-[18px] h-[18px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 8.5a3.5 3.5 0 100 7 3.5 3.5 0 000-7z"/>
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 01-2.83 2.83l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09a1.65 1.65 0 00-1-1.51 1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 11-2.83-2.83l.06-.06a1.65 1.65 0 00.33-1.82 1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09a1.65 1.65 0 001.51-1 1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 112.83-2.83l.06.06a1.65 1.65 0 001.82.33h.01A1.65 1.65 0 0010 3.09V3a2 2 0 114 0v.09a1.65 1.65 0 001 1.51h.01a1.65 1.65 0 001.82-.33l.06-.06a2 2 0 112.83 2.83l-.06.06a1.65 1.65 0 00-.33 1.82v.01a1.65 1.65 0 001.51 1H21a2 2 0 110 4h-.09a1.65 1.65 0 00-1.51 1z"/>
                        </svg>
                    @else
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-[18px] h-[18px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 3l7 4v5c0 5-3.5 8-7 9-3.5-1-7-4-7-9V7l7-4z"/>
                        </svg>
                    @endif
                </div>

                <div class="flex-1 min-w-0 pr-10">
                    <p class="text-[15px] leading-tight {{ $notif['read'] ? 'theme-text-muted font-medium' : 'theme-text-main font-bold' }}">
                        {{ $notif['title'] }}
                    </p>

                    <p class="theme-text-muted text-sm mt-1 leading-6">
                        {{ $notif['message'] }}
                    </p>

                    <p class="text-[var(--color-accent)] text-sm mt-2">
                        {{ $notif['time'] }}
                    </p>
                </div>

                <div class="absolute right-3 top-3 hidden group-hover:flex flex-col gap-2">
                    @if (!$notif['read'])
                        <button
                            class="w-7 h-7 rounded-lg bg-[var(--color-primary-soft)] text-[var(--color-accent)] flex items-center justify-center"
                            title="Mark as read"
                        >
                            <svg xmlns="http://www.w3.org/2000/svg" class="w-[12px] h-[12px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/>
                            </svg>
                        </button>
                    @endif

                    <button
                        class="w-7 h-7 rounded-lg bg-[var(--color-error-bg)] text-[var(--color-error-text)] flex items-center justify-center"
                        title="Remove notification"
                    >
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-[12px] h-[12px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                        </svg>
                    </button>
                </div>
            </div>
        @empty
            <div class="py-14 flex flex-col items-center justify-center gap-3">
                <div class="w-14 h-14 rounded-full bg-[var(--color-primary-soft)] flex items-center justify-center">
                    <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6 theme-text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0a3 3 0 11-6 0m6 0H9" />
                    </svg>
                </div>

                <p class="theme-text-muted text-sm">No notifications</p>
            </div>
        @endforelse
    </div>

    <!-- Footer -->
    @if (count($notifications) > 0)
        <div class="px-5 py-4 text-center border-t theme-border">
            <button class="text-[var(--color-accent)] text-sm font-medium hover:text-[var(--color-primary)] transition">
                Mark all as read
            </button>
        </div>
    @endif
</div>