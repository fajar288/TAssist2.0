<?php
// routes/web.php

use Illuminate\Support\Facades\Route;

// Admin Controllers
use App\Http\Controllers\Web\Admin\AuthController as AdminAuthController;
use App\Http\Controllers\Web\Admin\DashboardController as AdminDashboardController;
use App\Http\Controllers\Web\Admin\MahasiswaController;
use App\Http\Controllers\Web\Admin\DosenController;
use App\Http\Controllers\Web\Admin\InformasiTAController;
use App\Http\Controllers\Web\Admin\MonitoringController;
use App\Http\Controllers\Web\Admin\SupervisorQuotaController;

// Dosen Controllers
use App\Http\Controllers\Web\Dosen\AuthController as DosenAuthController;
use App\Http\Controllers\Web\Dosen\DashboardController as DosenDashboardController;
use App\Http\Controllers\Web\Dosen\PermohonanBimbinganController as DosenPermohonanController;
use App\Http\Controllers\Web\Dosen\MahasiswaBimbinganController as DosenMahasiswaBimbinganController;
use App\Http\Controllers\Web\Dosen\JadwalBimbinganController as DosenJadwalController;
use App\Http\Controllers\Web\Dosen\DokumenFeedbackController as DosenDokumenController;
use App\Http\Controllers\Web\Dosen\ProgressChecklistController as DosenProgressController;

// =====================================================
// PUBLIC — Halaman Login Admin
// =====================================================
Route::prefix('admin')->name('admin.')->group(function () {

    Route::get('/login',  [AdminAuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [AdminAuthController::class, 'login'])->name('login.post');

    // =====================================================
    // PROTECTED — Butuh session admin
    // =====================================================
    Route::middleware(['admin.auth'])->group(function () {

        Route::post('/logout', [AdminAuthController::class, 'logout'])->name('logout');

        // Dashboard
        Route::get('/dashboard', [AdminDashboardController::class, 'index'])->name('dashboard');

        // Manage Profile
        Route::get('/manage-profile', function () {
            return view('admin.manage-profile.index');
        })->name('manage-profile.index');

        // Manajemen Mahasiswa
        Route::prefix('mahasiswa')->name('mahasiswa.')->group(function () {
            Route::get('/',            [MahasiswaController::class, 'index'])->name('index');
            Route::get('/create',      [MahasiswaController::class, 'create'])->name('create');
            Route::post('/',           [MahasiswaController::class, 'store'])->name('store');
            Route::get('/{id}/edit',   [MahasiswaController::class, 'edit'])->name('edit');
            Route::put('/{id}',        [MahasiswaController::class, 'update'])->name('update');
            Route::delete('/{id}',     [MahasiswaController::class, 'destroy'])->name('destroy');
        });

        // Manajemen Dosen
        Route::prefix('dosen')->name('dosen.')->group(function () {
            Route::get('/',              [DosenController::class, 'index'])->name('index');
            Route::get('/create',        [DosenController::class, 'create'])->name('create');
            Route::post('/',             [DosenController::class, 'store'])->name('store');
            Route::get('/{id}/edit',     [DosenController::class, 'edit'])->name('edit');
            Route::put('/{id}',          [DosenController::class, 'update'])->name('update');
            Route::delete('/{id}',       [DosenController::class, 'destroy'])->name('destroy');
            Route::put('/{id}/kuota',    [DosenController::class, 'updateKuota'])->name('kuota');
        });

        // Supervisor Quota
        Route::prefix('supervisor-quota')->name('supervisor-quota.')->group(function () {
            Route::get('/',           [SupervisorQuotaController::class, 'index'])->name('index');
            Route::put('/{id}/kuota', [SupervisorQuotaController::class, 'updateKuota'])->name('update');
        });

        // Informasi TA
        Route::prefix('informasi-ta')->name('informasi-ta.')->group(function () {
            Route::get('/',              [InformasiTAController::class, 'index'])->name('index');
            Route::post('/',             [InformasiTAController::class, 'store'])->name('store');
            Route::put('/{id}',          [InformasiTAController::class, 'update'])->name('update');
            Route::delete('/{id}',       [InformasiTAController::class, 'destroy'])->name('destroy');
            Route::post('/{id}/toggle',  [InformasiTAController::class, 'togglePublish'])->name('toggle');
        });

        // Monitoring
        Route::prefix('monitoring')->name('monitoring.')->group(function () {
            Route::get('/permohonan', [MonitoringController::class, 'permohonan'])->name('permohonan');
            Route::get('/bimbingan',  [MonitoringController::class, 'bimbingan'])->name('bimbingan');
            Route::get('/jadwal',     [MonitoringController::class, 'jadwal'])->name('jadwal');
            Route::get('/dokumen',    [MonitoringController::class, 'dokumen'])->name('dokumen');
            Route::get('/progres',    [MonitoringController::class, 'progres'])->name('progres');
        });
    });
});

// =====================================================
// PUBLIC — Halaman Login Dosen
// =====================================================
Route::prefix('dosen')->name('dosen.')->group(function () {

    Route::get('/login',  [DosenAuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [DosenAuthController::class, 'login'])->name('login.post');

    // =====================================================
    // PROTECTED — Butuh session dosen
    // =====================================================
    Route::middleware(['dosen.auth'])->group(function () {

        Route::post('/logout', [DosenAuthController::class, 'logout'])->name('logout');

        Route::get('/dashboard', [DosenDashboardController::class, 'index'])->name('dashboard');

        // Permohonan Bimbingan
        Route::prefix('permohonan')->name('permohonan.')->group(function () {
            Route::get('/', [DosenPermohonanController::class, 'index'])->name('index');
            Route::get('/{id}', [DosenPermohonanController::class, 'show'])->name('show');
            Route::put('/{id}/terima', [DosenPermohonanController::class, 'terima'])->name('terima');
            Route::put('/{id}/tolak', [DosenPermohonanController::class, 'tolak'])->name('tolak');
        });

        // Mahasiswa Bimbingan
        Route::prefix('mahasiswa-bimbingan')->name('mahasiswa-bimbingan.')->group(function () {
            Route::get('/', [DosenMahasiswaBimbinganController::class, 'index'])->name('index');
            Route::get('/{id}', [DosenMahasiswaBimbinganController::class, 'show'])->name('show');
        });

        // Jadwal Bimbingan
        Route::prefix('jadwal')->name('jadwal.')->group(function () {
            Route::get('/', [DosenJadwalController::class, 'index'])->name('index');
            Route::get('/create', [DosenJadwalController::class, 'create'])->name('create');
            Route::post('/', [DosenJadwalController::class, 'store'])->name('store');
            Route::get('/{id}', [DosenJadwalController::class, 'show'])->name('show');
            Route::put('/{id}/konfirmasi', [DosenJadwalController::class, 'konfirmasi'])->name('konfirmasi');
            Route::put('/{id}/tolak', [DosenJadwalController::class, 'tolak'])->name('tolak');
        });

        // Dokumen & Feedback
        Route::prefix('dokumen')->name('dokumen.')->group(function () {
            Route::get('/', [DosenDokumenController::class, 'index'])->name('index');
            Route::get('/{id}', [DosenDokumenController::class, 'show'])->name('show');
            Route::post('/feedback', [DosenDokumenController::class, 'storeFeedback'])->name('feedback.store');
        });

        // Progress & Checklist
        Route::prefix('progress-checklist')->name('progress-checklist.')->group(function () {
            Route::get('/', [DosenProgressController::class, 'index'])->name('index');
            Route::get('/{bimbinganId}', [DosenProgressController::class, 'show'])->name('show');

            Route::post('/{bimbinganId}/progress', [DosenProgressController::class, 'storeProgress'])->name('progress.store');
            Route::post('/{bimbinganId}/checklist', [DosenProgressController::class, 'storeChecklist'])->name('checklist.store');

            Route::put('/checklist/{id}', [DosenProgressController::class, 'updateChecklist'])->name('checklist.update');
            Route::delete('/checklist/{id}', [DosenProgressController::class, 'destroyChecklist'])->name('checklist.destroy');
        });
    });
});

// Redirect root ke dashboard sesuai session
Route::get('/', function () {
    if (session()->has('admin_user')) {
        return redirect()->route('admin.dashboard');
    }

    if (session()->has('dosen_user')) {
        return redirect()->route('dosen.dashboard');
    }

    return redirect()->route('admin.login');
});