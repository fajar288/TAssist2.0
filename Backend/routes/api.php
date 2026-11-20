<?php
// routes/api.php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Response;

// Auth Controllers
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DokumenFileController;
use App\Http\Controllers\Api\NotifikasiController;

// Mahasiswa Controllers
use App\Http\Controllers\Api\Mahasiswa\MahasiswaController;
use App\Http\Controllers\Api\Mahasiswa\PermohonanBimbinganController as MahasiswaPermohonanController;
use App\Http\Controllers\Api\Mahasiswa\BimbinganController as MahasiswaBimbinganController;
use App\Http\Controllers\Api\Mahasiswa\DokumenTAController as MahasiswaDokumenController;
use App\Http\Controllers\Api\Mahasiswa\JadwalBimbinganController as MahasiswaJadwalController;
use App\Http\Controllers\Api\Mahasiswa\FeedbackDokumenController as MahasiswaFeedbackController;
use App\Http\Controllers\Api\Mahasiswa\ProgresTAController as MahasiswaProgresController;

// Dosen Controllers
use App\Http\Controllers\Api\Dosen\DosenController;
use App\Http\Controllers\Api\Dosen\BimbinganController as DosenBimbinganController;
use App\Http\Controllers\Api\Dosen\PermohonanBimbinganController as DosenPermohonanController;
use App\Http\Controllers\Api\Dosen\FeedbackDokumenController as DosenFeedbackController;
use App\Http\Controllers\Api\Dosen\JadwalBimbinganController as DosenJadwalController;
use App\Http\Controllers\Api\Dosen\ProgresTAController as DosenProgresController;
use App\Http\Controllers\Api\Dosen\ChecklistProgressController;

// Admin Controllers
use App\Http\Controllers\Api\Admin\AdminMahasiswaController;
use App\Http\Controllers\Api\Admin\AdminDosenController;
use App\Http\Controllers\Api\Admin\InformasiTAController;
use App\Http\Controllers\Api\Admin\AdminMonitoringController;

// =============================================================
// PUBLIC ROUTES — Tidak butuh autentikasi
// =============================================================
Route::prefix('v1')->group(function () {

    // Registrasi
    Route::post('/register/mahasiswa', [AuthController::class, 'registerMahasiswa']);
    Route::post('/register/dosen',     [AuthController::class, 'registerDosen']);

    // Login
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/login/google', [AuthController::class, 'loginGoogle']);

    // =============================================================
    // AUTHENTICATED ROUTES — Butuh token Sanctum
    // =============================================================
    Route::middleware(['auth:sanctum'])->group(function () {

        // Logout, Profile & Token refresh
        Route::post('/logout',        [AuthController::class, 'logout']);
        Route::post('/refresh-token', [AuthController::class, 'refreshToken']);
        Route::get('/profile',        [AuthController::class, 'profile']);

        // Notifikasi shared (mahasiswa & dosen)
        Route::prefix('notifikasi')->group(function () {
            Route::get('/',             [NotifikasiController::class, 'index']);
            Route::put('/{id}/read',    [NotifikasiController::class, 'markAsRead']);
            Route::put('/read-all',     [NotifikasiController::class, 'markAllAsRead']);
        });

        // Dokumen TA — signed URL issuance (T-02).
        // Any authenticated user may ask; VersiDokumenPolicy decides who gets one.
        Route::get('/dokumen/signed-url/{versi_id}', [DokumenFileController::class, 'signedUrl'])
            ->name('dokumen.signed-url');

        // =============================================================
        // MAHASISWA ROUTES
        // =============================================================
        Route::middleware(['role:mahasiswa'])
            ->prefix('mahasiswa')
            ->group(function () {

                // Lengkapi profil mahasiswa setelah Google auto-register
                Route::post('/complete-profile', [MahasiswaController::class, 'completeProfile']);

                // Update profil mahasiswa (topik_ta, judul_ta)
                Route::put('/profile', [MahasiswaController::class, 'updateProfile']);

                // Lihat daftar dosen
                Route::get('/dosen', [MahasiswaController::class, 'daftarDosen']);

                // Permohonan bimbingan
                Route::prefix('permohonan')->group(function () {
                    Route::post('/',  [MahasiswaPermohonanController::class, 'ajukan']);
                    Route::get('/',   [MahasiswaPermohonanController::class, 'daftarPermohonan']);
                });

                // Bimbingan
                Route::get('/bimbingan', [MahasiswaBimbinganController::class, 'index']);

                // Dokumen TA
                Route::prefix('dokumen')->group(function () {
                    Route::post('/',                      [MahasiswaDokumenController::class, 'upload']);
                    Route::get('/',                       [MahasiswaDokumenController::class, 'index']);
                    Route::get('/{id}/versi',             [MahasiswaDokumenController::class, 'riwayatVersi']);
                    Route::post('/{id}/versi',            [MahasiswaDokumenController::class, 'uploadVersi']);
                });

                // Jadwal bimbingan
                Route::prefix('jadwal')->group(function () {
                    Route::post('/', [MahasiswaJadwalController::class, 'ajukan']);
                    Route::get('/',  [MahasiswaJadwalController::class, 'index']);
                });

                // Feedback dokumen
                Route::get('/feedback', [MahasiswaFeedbackController::class, 'index']);

                // Progres TA
                Route::get('/progres', [MahasiswaProgresController::class, 'index']);

                // Notifikasi mahasiswa
                Route::get('/notifikasi', [NotifikasiController::class, 'index']);
            });

        // =============================================================
        // DOSEN ROUTES
        // =============================================================
        Route::middleware(['role:dosen'])
            ->prefix('dosen')
            ->group(function () {

                // Profil dosen
                Route::get('/profile',  [DosenController::class, 'profile']);
                Route::put('/profile',  [DosenController::class, 'updateProfile']);

                // Permohonan bimbingan
                Route::prefix('permohonan')->group(function () {
                    Route::get('/',                [DosenPermohonanController::class, 'index']);
                    Route::put('/{id}/terima',     [DosenPermohonanController::class, 'terima']);
                    Route::put('/{id}/tolak',      [DosenPermohonanController::class, 'tolak']);
                });

                // Mahasiswa bimbingan
                Route::prefix('mahasiswa-bimbingan')->group(function () {
                    Route::get('/',              [DosenController::class, 'mahasiswaBimbingan']);
                    Route::get('/{id}/progres',  [DosenController::class, 'progreesMahasiswa']);
                    // dosen melihat dokumen mahasiswa bimbingan
                    Route::get('/{id}/dokumen',  [DosenController::class, 'dokumenMahasiswa']);
                });

                // Status bimbingan (T-04)
                Route::put('/bimbingan/{id}/status', [DosenBimbinganController::class, 'updateStatus']);

                // Feedback dokumen
                Route::prefix('feedback')->group(function () {
                    Route::post('/', [DosenFeedbackController::class, 'store']);
                    Route::get('/',  [DosenFeedbackController::class, 'index']);
                });

                // Jadwal bimbingan
                Route::prefix('jadwal')->group(function () {
                    Route::post('/',                  [DosenJadwalController::class, 'store']);
                    Route::get('/',                   [DosenJadwalController::class, 'index']);
                    Route::put('/{id}/konfirmasi',    [DosenJadwalController::class, 'konfirmasi']);
                });

                // Progres TA
                Route::prefix('progres')->group(function () {
                    Route::put('/{id}', [DosenProgresController::class, 'update']);

                    // Checklist progress
                    Route::post('/{id}/checklist', [ChecklistProgressController::class, 'store']);
                });

                // Melihat riwayat versi dokumen
                Route::prefix('dokumen')->group(function () {
                    Route::get('/{id}/versi', [DosenController::class, 'riwayatVersiDokumen']);
                });

                // Checklist CRUD
                Route::prefix('checklist')->group(function () {
                    Route::put('/{id}',    [ChecklistProgressController::class, 'update']);
                    Route::delete('/{id}', [ChecklistProgressController::class, 'destroy']);
                });

                // Notifikasi dosen
                Route::get('/notifikasi', [NotifikasiController::class, 'index']);
            });

        // =============================================================
        // ADMIN ROUTES
        // =============================================================
        Route::middleware(['role:admin'])
            ->prefix('admin')
            ->group(function () {

                // Dashboard statistik
                Route::get('/dashboard', [AdminMonitoringController::class, 'dashboard']);

                // Manajemen Mahasiswa
                Route::prefix('mahasiswa')->group(function () {
                    Route::get('/',        [AdminMahasiswaController::class, 'index']);
                    Route::post('/',       [AdminMahasiswaController::class, 'store']);
                    Route::put('/{id}',    [AdminMahasiswaController::class, 'update']);
                    Route::delete('/{id}', [AdminMahasiswaController::class, 'destroy']);
                });

                // Manajemen Dosen
                Route::prefix('dosen')->group(function () {
                    Route::get('/',             [AdminDosenController::class, 'index']);
                    Route::post('/',            [AdminDosenController::class, 'store']);
                    Route::put('/{id}',         [AdminDosenController::class, 'update']);
                    Route::delete('/{id}',      [AdminDosenController::class, 'destroy']);
                    Route::put('/{id}/kuota',   [AdminDosenController::class, 'updateKuota']);
                });

                // Informasi TA
                Route::prefix('informasi-ta')->group(function () {
                    Route::get('/',        [InformasiTAController::class, 'index']);
                    Route::post('/',       [InformasiTAController::class, 'store']);
                    Route::put('/{id}',    [InformasiTAController::class, 'update']);
                    Route::delete('/{id}', [InformasiTAController::class, 'destroy']);
                });

                // Monitoring
                Route::prefix('monitoring')->group(function () {
                    Route::get('/permohonan', [AdminMonitoringController::class, 'permohonan']);
                    Route::get('/bimbingan',  [AdminMonitoringController::class, 'bimbingan']);
                    Route::get('/jadwal',     [AdminMonitoringController::class, 'jadwal']);
                    Route::get('/dokumen',    [AdminMonitoringController::class, 'dokumen']);
                    Route::get('/progres',    [AdminMonitoringController::class, 'progres']);
                });

                // Shorthand monitoring (sesuai spec awal)
                Route::get('/permohonan', [AdminMonitoringController::class, 'permohonan']);
                Route::get('/bimbingan',  [AdminMonitoringController::class, 'bimbingan']);
                Route::get('/jadwal',     [AdminMonitoringController::class, 'jadwal']);
                Route::get('/dokumen',    [AdminMonitoringController::class, 'dokumen']);
                Route::get('/progres',    [AdminMonitoringController::class, 'progres']);
            });
    });

    // Dokumen TA — file delivery (T-02).
    //
    // Deliberately outside `auth:sanctum`: Flutter Web and the PDF viewer fetch
    // this URL with no `Authorization` header, so the HMAC signature is the
    // credential. Authorization is enforced once, at signed-URL issuance
    // (DokumenFileController::signedUrl), and the 15-minute signature carries
    // the grant.
    Route::get('/dokumen/{versi_id}/file', [DokumenFileController::class, 'show'])
        ->middleware('signed')
        ->name('dokumen.file');

    // Endpoint khusus untuk melayani gambar avatar dengan header CORS (T-02 / C5)
    // Direktori dibatasi hanya pada app/public/avatars untuk menutup celah IDOR.
    Route::get('/avatar/{path}', function ($path) {
        if (str_contains($path, '..')) {
            abort(400, 'Invalid path');
        }

        $clean = ltrim($path, '/');
        if (!str_starts_with($clean, 'avatars/')) {
            $clean = 'avatars/' . $clean;
        }

        $fullPath = storage_path('app/public/' . $clean);

        if (!File::exists($fullPath)) {
            abort(404);
        }

        $file = File::get($fullPath);
        $type = File::mimeType($fullPath);

        return Response::make($file, 200)
            ->header('Content-Type', $type)
            ->header('Access-Control-Allow-Origin', '*');
    })->where('path', '.*');
});