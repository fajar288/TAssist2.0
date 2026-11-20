<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\BeritaAcara;
use Illuminate\Contracts\View\View;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class VerifikasiController extends Controller
{
    /**
     * Public unauthenticated verification page for Berita Acara (T-19, F-BA-03).
     * GET /verifikasi/{token}
     */
    public function verify(Request $request, string $token): View
    {
        $ba = BeritaAcara::where('token_verifikasi', $token)->first();

        if (! $ba) {
            return view('verifikasi.berita_acara', [
                'found'     => false,
                'ba'        => null,
                'snapshot'  => null,
                'integrity' => false,
            ]);
        }

        $integrity = false;
        if (Storage::exists($ba->file_path)) {
            $currentHash = hash_file('sha256', Storage::path($ba->file_path));
            $expectedHash = $ba->getActiveHash();
            $integrity = hash_equals($expectedHash, $currentHash);
        }

        return view('verifikasi.berita_acara', [
            'found'     => true,
            'ba'        => $ba,
            'snapshot'  => $ba->data_snapshot,
            'integrity' => $integrity,
        ]);
    }
}
