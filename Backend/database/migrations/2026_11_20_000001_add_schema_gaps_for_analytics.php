<?php
// database/migrations/2026_11_20_000001_add_schema_gaps_for_analytics.php
//
// T-80 — closes the four schema gaps every later wave silently assumes
// (decisions C1, C2, C3 in Docs/task.md).
//
// Contract notes for the tasks that consume these columns:
//
//  * `bimbingan.periode_selesai >= periode_mulai` is deliberately NOT a DB
//    constraint. It must be enforced where the period is written (the admin
//    request/validation layer, and a model-level guard in App\Models\Bimbingan
//    if a write path bypasses the request). Both columns nullable = period not
//    set; the analytics signal (`waktu_terpakai_periode`) reports `inactive`
//    in that case rather than dividing by a zero-length window.
//  * `progres_ta.catatan` becomes mandatory when `is_override` is true. That
//    rule lives in the request layer (T-40's FormRequest), not in MySQL, so a
//    direct DB write can still violate it.
//  * `checklist_progress` is intentionally untouched: `bobot` and the
//    `tgl_selesai` -> `is_selesai` rename ship together in T-40/T-44.
//  * `down()` restores the previous schema exactly (columns, index, table).

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('bimbingan', function (Blueprint $table) {
            // Set when `status_bimbingan` leaves 'aktif' (T-04 writes it;
            // T-27's idle nudge and T-33's retention job read it). Indexed
            // because both queries filter on it.
            $table->date('tanggal_selesai')
                ->nullable()
                ->after('status_bimbingan')
                ->comment('Diisi saat status_bimbingan keluar dari aktif');

            // TA period, admin-set (decision C1). Nullable: not yet scheduled.
            $table->date('periode_mulai')
                ->nullable()
                ->after('tanggal_selesai')
                ->comment('Awal periode TA (admin-set); null = belum ditetapkan');

            $table->date('periode_selesai')
                ->nullable()
                ->after('periode_mulai')
                ->comment('Akhir periode TA; invariant periode_selesai >= periode_mulai dijaga di layer validasi/model');

            $table->index('tanggal_selesai', 'bimbingan_tanggal_selesai_index');
        });

        Schema::table('progres_ta', function (Blueprint $table) {
            // Decision C3 / F-PRG-04: progress may be overridden by hand, but
            // then `catatan` is mandatory (enforced at the request layer in T-40).
            $table->boolean('is_override')
                ->default(false)
                ->after('status_progress')
                ->comment('true = persentase di-override manual; catatan wajib diisi (T-40)');
        });

        // Decision C2 — academic-break calendar. T-27 suppresses the idle nudge
        // inside these windows. Kept as its own table rather than overloading
        // the risk-signal config JSON.
        Schema::create('periode_libur', function (Blueprint $table) {
            $table->id('periode_libur_id');
            $table->date('mulai');
            $table->date('selesai');
            $table->string('keterangan')->nullable();
            $table->timestamps();

            $table->index('mulai');
            $table->index('selesai');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('periode_libur');

        Schema::table('progres_ta', function (Blueprint $table) {
            $table->dropColumn('is_override');
        });

        Schema::table('bimbingan', function (Blueprint $table) {
            // Drop the index before its column: SQLite refuses to drop an
            // indexed column, and MySQL would drop the index implicitly anyway.
            $table->dropIndex('bimbingan_tanggal_selesai_index');
            $table->dropColumn(['tanggal_selesai', 'periode_mulai', 'periode_selesai']);
        });
    }
};
