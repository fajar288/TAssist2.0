@extends('layout.admin')

@section('title', 'Tambah Basis Pengetahuan - TAssist Admin')
@section('page-title', 'Tambah Entri Pengetahuan')
@section('page-subtitle', 'Tambahkan panduan atau FAQ baru untuk asisten chatbot AI')

@section('content')
<div class="max-w-3xl">
    <div class="theme-card rounded-2xl border p-6">
        <form method="POST" action="{{ route('admin.basis-pengetahuan.store') }}" class="space-y-5">
            @csrf

            <div>
                <label class="block text-sm font-semibold text-slate-700 mb-1">Kategori *</label>
                <select name="kategori" required class="w-full px-4 py-2 border rounded-xl text-sm focus:ring-2 focus:ring-[var(--color-primary)]">
                    <option value="prosedur" {{ old('kategori') == 'prosedur' ? 'selected' : '' }}>Prosedur</option>
                    <option value="format" {{ old('kategori') == 'format' ? 'selected' : '' }}>Format Penulisan</option>
                    <option value="jadwal" {{ old('kategori') == 'jadwal' ? 'selected' : '' }}>Jadwal / Kalender</option>
                    <option value="faq" {{ old('kategori') == 'faq' ? 'selected' : '' }}>FAQ</option>
                    <option value="umum" {{ old('kategori') == 'umum' ? 'selected' : '' }}>Umum</option>
                </select>
                @error('kategori') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>

            <div>
                <label class="block text-sm font-semibold text-slate-700 mb-1">Judul *</label>
                <input type="text" name="judul" value="{{ old('judul') }}" required placeholder="Contoh: Panduan Format Penulisan Daftar Isi"
                       class="w-full px-4 py-2 border rounded-xl text-sm focus:ring-2 focus:ring-[var(--color-primary)]" />
                @error('judul') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>

            <div>
                <label class="block text-sm font-semibold text-slate-700 mb-1">Konten / Isi Lengkap *</label>
                <textarea name="konten" rows="8" required placeholder="Tuliskan isi pedoman atau jawaban lengkap..."
                          class="w-full px-4 py-2 border rounded-xl text-sm focus:ring-2 focus:ring-[var(--color-primary)]">{{ old('konten') }}</textarea>
                @error('konten') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>

            <div>
                <label class="block text-sm font-semibold text-slate-700 mb-1">Tags (Pisahkan dengan koma)</label>
                <input type="text" name="tags" value="{{ old('tags') }}" placeholder="Contoh: format, daftar isi, bab 1"
                       class="w-full px-4 py-2 border rounded-xl text-sm focus:ring-2 focus:ring-[var(--color-primary)]" />
            </div>

            <div class="flex items-center gap-2">
                <input type="checkbox" id="is_active" name="is_active" value="1" {{ old('is_active', true) ? 'checked' : '' }} class="rounded border-slate-300 text-[var(--color-primary)]" />
                <label for="is_active" class="text-sm font-medium text-slate-700">Aktifkan untuk pencarian Chatbot</label>
            </div>

            <div class="flex justify-end gap-3 pt-4 border-t">
                <a href="{{ route('admin.basis-pengetahuan.index') }}" class="px-5 py-2 border rounded-xl text-sm text-slate-600 hover:bg-slate-50">Batal</a>
                <button type="submit" class="px-5 py-2 bg-[var(--color-primary)] text-white rounded-xl text-sm font-semibold hover:opacity-90">Simpan Entri</button>
            </div>
        </form>
    </div>
</div>
@endsection
