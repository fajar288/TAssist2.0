@extends('layout.admin')

@section('title', 'Basis Pengetahuan TA - TAssist Admin')
@section('page-title', 'Basis Pengetahuan TA')
@section('page-subtitle', 'Kelola artikel panduan, prosedur, format, dan FAQ untuk asisten chatbot AI')

@section('content')
<div class="space-y-6">
    @if(session('success'))
        <div class="p-4 bg-emerald-50 border border-emerald-200 text-emerald-700 rounded-xl flex items-center justify-between">
            <span>{{ session('success') }}</span>
        </div>
    @endif

    {{-- Filter & Action Bar --}}
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <form method="GET" action="{{ route('admin.basis-pengetahuan.index') }}" class="flex flex-wrap items-center gap-3 w-full sm:w-auto">
            <input type="text" name="q" value="{{ request('q') }}" placeholder="Cari judul atau isi..." 
                   class="px-4 py-2 border rounded-xl theme-card text-sm focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)] w-full sm:w-64" />
            <select name="kategori" class="px-4 py-2 border rounded-xl theme-card text-sm focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]">
                <option value="">Semua Kategori</option>
                @foreach($categories as $cat)
                    <option value="{{ $cat }}" {{ request('kategori') == $cat ? 'selected' : '' }}>{{ ucfirst($cat) }}</option>
                @endforeach
            </select>
            <button type="submit" class="px-4 py-2 bg-[var(--color-primary)] text-white rounded-xl text-sm font-semibold hover:opacity-90">
                Filter
            </button>
        </form>

        <a href="{{ route('admin.basis-pengetahuan.create') }}" class="px-4 py-2 bg-[var(--color-primary)] text-white rounded-xl text-sm font-semibold hover:opacity-90 flex items-center gap-2">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
            Tambah Entri Pengetahuan
        </a>
    </div>

    {{-- Table List --}}
    <div class="theme-card rounded-2xl border overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left text-sm">
                <thead class="bg-slate-50 border-b text-slate-600 font-semibold">
                    <tr>
                        <th class="px-6 py-4">Kategori</th>
                        <th class="px-6 py-4">Judul</th>
                        <th class="px-6 py-4">Tags</th>
                        <th class="px-6 py-4">Status</th>
                        <th class="px-6 py-4 text-right">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    @forelse($items as $item)
                        <tr class="hover:bg-slate-50/50">
                            <td class="px-6 py-4">
                                <span class="px-2.5 py-1 text-xs font-semibold rounded-lg bg-indigo-50 text-indigo-700">
                                    {{ ucfirst($item->kategori) }}
                                </span>
                            </td>
                            <td class="px-6 py-4">
                                <div class="font-bold text-slate-800">{{ $item->judul }}</div>
                                <div class="text-xs text-slate-500 truncate max-w-md mt-0.5">{{ Str::limit($item->konten, 80) }}</div>
                            </td>
                            <td class="px-6 py-4">
                                @if(!empty($item->tags) && is_array($item->tags))
                                    <div class="flex flex-wrap gap-1">
                                        @foreach($item->tags as $t)
                                            <span class="px-2 py-0.5 text-xs bg-slate-100 text-slate-600 rounded">{{ $t }}</span>
                                        @endforeach
                                    </div>
                                @else
                                    <span class="text-slate-400 text-xs">-</span>
                                @endif
                            </td>
                            <td class="px-6 py-4">
                                @if($item->is_active)
                                    <span class="px-2.5 py-1 text-xs font-semibold rounded-lg bg-emerald-50 text-emerald-700">Aktif</span>
                                @else
                                    <span class="px-2.5 py-1 text-xs font-semibold rounded-lg bg-slate-100 text-slate-500">Nonaktif</span>
                                @endif
                            </td>
                            <td class="px-6 py-4 text-right space-x-2">
                                <a href="{{ route('admin.basis-pengetahuan.edit', $item->id) }}" class="text-indigo-600 hover:text-indigo-800 font-medium text-xs">Edit</a>
                                <form action="{{ route('admin.basis-pengetahuan.destroy', $item->id) }}" method="POST" class="inline" onsubmit="return confirm('Hapus entri ini?')">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="text-red-500 hover:text-red-700 font-medium text-xs">Hapus</button>
                                </form>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="px-6 py-12 text-center text-slate-400">
                                Belum ada data basis pengetahuan.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($items->hasPages())
            <div class="px-6 py-4 border-t">
                {{ $items->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
