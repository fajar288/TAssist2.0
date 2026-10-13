@extends('layout.admin')

@php
    $title = 'Manage Profile - TAssist Admin';
    $pageTitle = 'Manage Profile';
    $pageDescription = 'Update your account details';

    $user = [
        'name' => 'Administrator',
        'email' => 'admin@tassist.ac.id',
        'role' => 'Administrator',
        'status' => 'Active',
        'member_since' => 'Jan 2024',
    ];

    $cardClass = 'rounded-3xl p-6 border theme-card';
    $labelClass = 'block theme-text-muted text-sm font-medium mb-2';
    $inputClass = 'w-full pl-12 pr-4 py-4 rounded-2xl border theme-input text-sm outline-none transition-all duration-200';
    $passwordInputClass = 'w-full pl-12 pr-12 py-4 rounded-2xl border theme-input text-sm outline-none transition-all duration-200';
@endphp

@section('content')
<div class="max-w-6xl">
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-5 items-start">

        <!-- Left Section -->
        <div class="space-y-5">

            <!-- Profile Card -->
            <div class="{{ $cardClass }} flex flex-col items-center text-center min-h-[350px] justify-center">
                <div class="relative mb-5">
                    <div class="w-32 h-32 rounded-full theme-logo-bg flex items-center justify-center text-white text-5xl font-extrabold">
                        {{ strtoupper(substr($user['name'], 0, 1)) }}
                    </div>

                    <button
                        type="button"
                        class="absolute bottom-0 right-0 w-10 h-10 rounded-full theme-logo-bg border-[3px] border-[var(--color-bg-card)] flex items-center justify-center text-white hover:opacity-90 transition"
                    >
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M3 7h4l2-2h6l2 2h4v12a1 1 0 01-1 1H4a1 1 0 01-1-1V7z"/>
                            <circle cx="12" cy="13" r="4"/>
                        </svg>
                    </button>
                </div>

                <h2 class="theme-text-main text-2xl font-bold">{{ $user['name'] }}</h2>
                <p class="theme-text-muted text-lg mt-1">{{ $user['email'] }}</p>

                <span class="mt-4 px-4 py-1.5 rounded-full bg-[var(--color-primary-soft)] text-[var(--color-accent)] text-sm font-medium">
                    System Administrator
                </span>
            </div>

            <!-- Account Information -->
            <div class="{{ $cardClass }} min-h-[410px]">
                <h3 class="theme-text-main text-xl font-bold mb-5">Account Information</h3>

                <div class="space-y-0">
                    <div class="flex items-start gap-3 py-4 border-b theme-border">
                        <div class="w-10 h-10 rounded-xl bg-[var(--color-primary-soft)] flex items-center justify-center text-[var(--color-primary)] flex-shrink-0">
                            <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M12 3l7 4v5c0 5-3.5 8-7 9-3.5-1-7-4-7-9V7l7-4z"/>
                            </svg>
                        </div>

                        <div>
                            <p class="theme-text-muted text-sm">Role</p>
                            <p class="theme-text-main text-lg font-medium mt-1">{{ $user['role'] }}</p>
                        </div>
                    </div>

                    <div class="flex items-start gap-3 py-4 border-b theme-border">
                        <div class="w-10 h-10 rounded-xl bg-[var(--color-success-bg)] flex items-center justify-center text-[var(--color-success-text)] flex-shrink-0">
                            <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4"/>
                                <circle cx="12" cy="12" r="9"/>
                            </svg>
                        </div>

                        <div>
                            <p class="theme-text-muted text-sm">Status</p>
                            <p class="theme-text-main text-lg font-medium mt-1">{{ $user['status'] }}</p>
                        </div>
                    </div>

                    <div class="flex items-start gap-3 py-4">
                        <div class="w-10 h-10 rounded-xl bg-[var(--color-primary-soft)] flex items-center justify-center text-[var(--color-accent)] flex-shrink-0">
                            <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M5.121 17.804A8 8 0 1118.879 17.804M15 11a3 3 0 11-6 0 3 3 0 016 0z"/>
                            </svg>
                        </div>

                        <div>
                            <p class="theme-text-muted text-sm">Member Since</p>
                            <p class="theme-text-main text-lg font-medium mt-1">{{ $user['member_since'] }}</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Right Section -->
        <div class="lg:col-span-2 space-y-5">

            <!-- Personal Information -->
            <div class="{{ $cardClass }} min-h-[350px]">
                <div class="flex items-center gap-2 mb-6">
                    <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 text-[var(--color-accent)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M5.121 17.804A8 8 0 1118.879 17.804M15 11a3 3 0 11-6 0 3 3 0 016 0z"/>
                    </svg>
                    <h3 class="theme-text-main text-xl font-bold">Personal Information</h3>
                </div>

                <div class="space-y-5">
                    <div>
                        <label class="{{ $labelClass }}">Full Name</label>
                        <div class="relative">
                            <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 absolute left-4 top-1/2 -translate-y-1/2 theme-text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M5.121 17.804A8 8 0 1118.879 17.804M15 11a3 3 0 11-6 0 3 3 0 016 0z"/>
                            </svg>

                            <input
                                type="text"
                                value="{{ $user['name'] }}"
                                class="{{ $inputClass }}"
                            >
                        </div>
                    </div>

                    <div>
                        <label class="{{ $labelClass }}">Email Address</label>
                        <div class="relative">
                            <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 absolute left-4 top-1/2 -translate-y-1/2 theme-text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M16 12H8m8 0l-8 5m8-5l-8-5m13 10V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2h14a2 2 0 002-2z"/>
                            </svg>

                            <input
                                type="email"
                                value="{{ $user['email'] }}"
                                class="{{ $inputClass }}"
                            >
                        </div>
                    </div>
                </div>
            </div>

            <!-- Change Password -->
            <div class="{{ $cardClass }} min-h-[410px]">
                <div class="flex items-center gap-2 mb-6">
                    <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 text-[var(--color-accent)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m6-8V7a6 6 0 10-12 0v2m-1 0h14a1 1 0 011 1v9a1 1 0 01-1 1H5a1 1 0 01-1-1v-9a1 1 0 011-1z"/>
                    </svg>
                    <h3 class="theme-text-main text-xl font-bold">Change Password</h3>
                </div>

                <div class="space-y-5">
                    <div>
                        <label class="{{ $labelClass }}">Current Password</label>
                        <div class="relative">
                            <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 absolute left-4 top-1/2 -translate-y-1/2 theme-text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m6-8V7a6 6 0 10-12 0v2m-1 0h14a1 1 0 011 1v9a1 1 0 01-1 1H5a1 1 0 01-1-1v-9a1 1 0 011-1z"/>
                            </svg>

                            <input
                                type="password"
                                placeholder="Enter current password"
                                class="{{ $passwordInputClass }}"
                            >

                            <button type="button" class="absolute right-4 top-1/2 -translate-y-1/2 theme-text-muted hover:text-[var(--color-text-main)] transition">
                                <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                                </svg>
                            </button>
                        </div>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label class="{{ $labelClass }}">New Password</label>
                            <div class="relative">
                                <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 absolute left-4 top-1/2 -translate-y-1/2 theme-text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m6-8V7a6 6 0 10-12 0v2m-1 0h14a1 1 0 011 1v9a1 1 0 01-1 1H5a1 1 0 01-1-1v-9a1 1 0 011-1z"/>
                                </svg>

                                <input
                                    type="password"
                                    placeholder="New password"
                                    class="{{ $passwordInputClass }}"
                                >

                                <button type="button" class="absolute right-4 top-1/2 -translate-y-1/2 theme-text-muted hover:text-[var(--color-text-main)] transition">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                                    </svg>
                                </button>
                            </div>
                        </div>

                        <div>
                            <label class="{{ $labelClass }}">Confirm Password</label>
                            <div class="relative">
                                <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 absolute left-4 top-1/2 -translate-y-1/2 theme-text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m6-8V7a6 6 0 10-12 0v2m-1 0h14a1 1 0 011 1v9a1 1 0 01-1 1H5a1 1 0 01-1-1v-9a1 1 0 011-1z"/>
                                </svg>

                                <input
                                    type="password"
                                    placeholder="Confirm new password"
                                    class="{{ $passwordInputClass }}"
                                >

                                <button type="button" class="absolute right-4 top-1/2 -translate-y-1/2 theme-text-muted hover:text-[var(--color-text-main)] transition">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                                    </svg>
                                </button>
                            </div>
                        </div>
                    </div>

                    <p class="theme-text-muted text-sm">
                        Leave password fields empty if you don't want to change your password.
                    </p>
                </div>
            </div>

            <!-- Actions -->
            <div class="flex justify-end gap-3">
                <button
                    type="button"
                    class="inline-flex items-center gap-2 px-6 py-3 rounded-2xl border theme-border theme-text-muted text-sm hover:bg-[var(--color-hover)] transition"
                >
                    <svg xmlns="http://www.w3.org/2000/svg" class="w-[16px] h-[16px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                    Cancel
                </button>

                <button
                    type="button"
                    class="inline-flex items-center gap-2 px-6 py-3 rounded-2xl theme-primary-btn text-sm font-semibold transition"
                >
                    <svg xmlns="http://www.w3.org/2000/svg" class="w-[16px] h-[16px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z"/>
                        <path stroke-linecap="round" stroke-linejoin="round" d="M17 21v-8H7v8"/>
                        <path stroke-linecap="round" stroke-linejoin="round" d="M7 3v5h8"/>
                    </svg>
                    Save Changes
                </button>
            </div>
        </div>
    </div>
</div>
@endsection