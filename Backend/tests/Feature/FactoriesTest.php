<?php
// tests/Feature/FactoriesTest.php
//
// Guards the factory defaults that the rest of the suite (and every future
// lane) relies on. Defaults mirror database/seeders/.

use App\Models\Admin;
use App\Models\Bimbingan;
use App\Models\ChecklistProgress;
use App\Models\DokumenTA;
use App\Models\Dosen;
use App\Models\FeedbackDokumen;
use App\Models\JadwalBimbingan;
use App\Models\Mahasiswa;
use App\Models\Notifikasi;
use App\Models\PeriodeLibur;
use App\Models\PermohonanBimbingan;
use App\Models\ProgresTA;
use App\Models\User;
use App\Models\VersiDokumen;
use Illuminate\Support\Facades\Hash;

it('creates user profiles with the role the seeder would use', function () {
    $mahasiswa = Mahasiswa::factory()->create();
    $dosen     = Dosen::factory()->create();
    $admin     = Admin::factory()->create();

    expect($mahasiswa->user->role)->toBe('mahasiswa')
        ->and($mahasiswa->user->status_akun)->toBe('aktif')
        ->and(Hash::check('password123', $mahasiswa->user->password_hash))->toBeTrue()
        ->and($mahasiswa->prodi)->toBe('Teknik Informatika')
        ->and($mahasiswa->angkatan)->toBe(2021);

    expect($dosen->user->role)->toBe('dosen')
        ->and($dosen->kuota_bimbingan)->toBe(5)
        ->and($dosen->sisaKuota())->toBe(5);

    expect($admin->user->role)->toBe('admin')
        ->and($admin->jabatan)->toBe('Koordinator Tugas Akhir');
});

it('builds a bimbingan whose foreign keys agree with its permohonan', function () {
    $bimbingan = Bimbingan::factory()->create();

    expect($bimbingan->status_bimbingan)->toBe('aktif')
        ->and($bimbingan->permohonan->status)->toBe('diterima')
        ->and($bimbingan->permohonan->mahasiswa_id)->toBe($bimbingan->mahasiswa_id)
        ->and($bimbingan->permohonan->dosen_id)->toBe($bimbingan->dosen_id)
        ->and($bimbingan->mahasiswa->mahasiswa_id)->toBe($bimbingan->mahasiswa_id)
        ->and($bimbingan->dosen->dosen_id)->toBe($bimbingan->dosen_id);
});

it('builds a bimbingan for an explicit student/professor pair', function () {
    $mahasiswa = Mahasiswa::factory()->create();
    $dosen     = Dosen::factory()->create();

    $bimbingan = Bimbingan::factory()->untuk($mahasiswa, $dosen)->create();

    expect($bimbingan->mahasiswa_id)->toBe($mahasiswa->mahasiswa_id)
        ->and($bimbingan->dosen_id)->toBe($dosen->dosen_id)
        ->and($bimbingan->permohonan->mahasiswa_id)->toBe($mahasiswa->mahasiswa_id)
        ->and($bimbingan->permohonan->dosen_id)->toBe($dosen->dosen_id);
});

it('derives document, feedback and schedule ownership from the supervision', function () {
    $bimbingan = Bimbingan::factory()->create();

    $dokumen = DokumenTA::factory()->forBimbingan($bimbingan)->create();
    $versi   = VersiDokumen::factory()->forDokumen($dokumen)->create();
    $feedback = FeedbackDokumen::factory()->forVersi($versi)->create();
    $jadwal   = JadwalBimbingan::factory()->forBimbingan($bimbingan)->create();
    $progres  = ProgresTA::factory()->forBimbingan($bimbingan)->create();
    $checklist = ChecklistProgress::factory()->forProgress($progres)->create();

    expect($dokumen->bimbingan_id)->toBe($bimbingan->bimbingan_id)
        ->and($versi->uploader_user_id)->toBe($bimbingan->mahasiswa->user_id)
        ->and($versi->nomor_versi)->toBe(1)
        ->and($versi->status_versi)->toBe('diajukan')
        ->and($feedback->dosen_id)->toBe($bimbingan->dosen_id)
        ->and($jadwal->pengaju_user_id)->toBe($bimbingan->mahasiswa->user_id)
        ->and($jadwal->status_konfirmasi)->toBe('menunggu')
        ->and($progres->updated_dosen_id)->toBe($bimbingan->dosen_id)
        ->and($progres->persentase)->toBe(0.0)
        ->and($checklist->is_selesai)->toBeFalse()
        ->and($checklist->progress_id)->toBe($progres->progress_id);
});

it('creates the states the feature tests depend on', function () {
    $user = User::factory()->create();

    expect(PermohonanBimbingan::factory()->create()->status)->toBe('menunggu')
        ->and(PermohonanBimbingan::factory()->ditolak()->create()->status)->toBe('ditolak')
        ->and(Bimbingan::factory()->selesai()->create()->status_bimbingan)->toBe('selesai')
        ->and(Bimbingan::factory()->dibatalkan()->create()->status_bimbingan)->toBe('dibatalkan')
        ->and(JadwalBimbingan::factory()->dikonfirmasi()->create()->status_konfirmasi)->toBe('dikonfirmasi')
        ->and(ChecklistProgress::factory()->selesai()->create()->tanggal_selesai)->not->toBeNull()
        ->and(Notifikasi::factory()->forUser($user)->create()->user_id)->toBe($user->user_id)
        ->and(Notifikasi::factory()->sudahDibaca()->create()->is_read)->toBeTrue()
        ->and(Dosen::factory()->tanpaKuota()->create()->masihAdaKuota())->toBeFalse();
});

it('creates an academic break window that covers today', function () {
    $libur = PeriodeLibur::factory()->create();

    expect($libur->mulai->lessThanOrEqualTo(now()))->toBeTrue()
        ->and($libur->selesai->greaterThanOrEqualTo(now()))->toBeTrue()
        ->and($libur->keterangan)->toBe('Libur semester')
        ->and($libur->isBerlangsung())->toBeTrue()
        ->and(PeriodeLibur::aktif()->count())->toBe(1);
});
