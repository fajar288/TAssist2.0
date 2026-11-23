<?php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\BasisPengetahuanTA;
use Illuminate\Http\Request;

class BasisPengetahuanWebController extends Controller
{
    public function index(Request $request)
    {
        $query = BasisPengetahuanTA::query();

        if ($request->filled('kategori')) {
            $query->where('kategori', $request->kategori);
        }

        if ($request->filled('q')) {
            $search = $request->q;
            $query->where(function ($q) use ($search) {
                $q->where('judul', 'like', "%{$search}%")
                  ->orWhere('konten', 'like', "%{$search}%");
            });
        }

        $items = $query->orderBy('kategori')->orderBy('judul')->paginate(12)->withQueryString();
        $categories = BasisPengetahuanTA::select('kategori')->distinct()->pluck('kategori');

        return view('admin.basis-pengetahuan.index', compact('items', 'categories'));
    }

    public function create()
    {
        return view('admin.basis-pengetahuan.create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'kategori' => ['required', 'string', 'max:50'],
            'judul' => ['required', 'string', 'max:255'],
            'konten' => ['required', 'string'],
            'tags' => ['nullable', 'string'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $tagsArray = [];
        if (!empty($validated['tags'])) {
            $tagsArray = array_map('trim', explode(',', $validated['tags']));
        }

        BasisPengetahuanTA::create([
            'kategori' => $validated['kategori'],
            'judul' => $validated['judul'],
            'konten' => $validated['konten'],
            'tags' => $tagsArray,
            'is_active' => $request->has('is_active'),
        ]);

        return redirect()->route('admin.basis-pengetahuan.index')->with('success', 'Entri basis pengetahuan berhasil ditambahkan.');
    }

    public function edit(int $id)
    {
        $item = BasisPengetahuanTA::findOrFail($id);
        return view('admin.basis-pengetahuan.edit', compact('item'));
    }

    public function update(Request $request, int $id)
    {
        $item = BasisPengetahuanTA::findOrFail($id);

        $validated = $request->validate([
            'kategori' => ['required', 'string', 'max:50'],
            'judul' => ['required', 'string', 'max:255'],
            'konten' => ['required', 'string'],
            'tags' => ['nullable', 'string'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $tagsArray = [];
        if (!empty($validated['tags'])) {
            $tagsArray = array_map('trim', explode(',', $validated['tags']));
        }

        $item->update([
            'kategori' => $validated['kategori'],
            'judul' => $validated['judul'],
            'konten' => $validated['konten'],
            'tags' => $tagsArray,
            'is_active' => $request->has('is_active'),
        ]);

        return redirect()->route('admin.basis-pengetahuan.index')->with('success', 'Entri basis pengetahuan berhasil diperbarui.');
    }

    public function destroy(int $id)
    {
        $item = BasisPengetahuanTA::findOrFail($id);
        $item->delete();

        return redirect()->route('admin.basis-pengetahuan.index')->with('success', 'Entri basis pengetahuan berhasil dihapus.');
    }
}
