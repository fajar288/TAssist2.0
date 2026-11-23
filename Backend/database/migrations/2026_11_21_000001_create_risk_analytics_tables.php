<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * T-21, T-22, T-24, T-27 (Wave 3).
     */
    public function up(): void
    {
        // 1. Table: risiko_konfigurasi
        Schema::create('risiko_konfigurasi', function (Blueprint $table) {
            $table->id('konfigurasi_id');
            $table->string('nama_sinyal')->unique();
            $table->string('deskripsi');
            $table->double('bobot', 8, 4)->default(0.0);
            $table->json('ambang_batas');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // 2. Table: risiko_snapshot
        Schema::create('risiko_snapshot', function (Blueprint $table) {
            $table->id('snapshot_id');
            $table->unsignedBigInteger('bimbingan_id');
            $table->unsignedTinyInteger('skor')->default(0);
            $table->string('level', 20)->default('aman'); // 'aman', 'perlu_perhatian', 'berisiko'
            $table->json('sinyal'); // explainability payload: array of { nama, nilai, bobot, kontribusi, deskripsi }
            $table->date('tanggal_hitung');
            $table->timestamps();

            $table->foreign('bimbingan_id')
                ->references('bimbingan_id')
                ->on('bimbingan')
                ->onDelete('cascade');

            $table->index(['bimbingan_id', 'tanggal_hitung']);
            $table->index('tanggal_hitung');
            $table->index('level');
        });

        // 3. Track last nudge sent on bimbingan
        Schema::table('bimbingan', function (Blueprint $table) {
            $table->timestamp('last_nudge_at')->nullable()->after('tanggal_selesai');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('bimbingan', function (Blueprint $table) {
            $table->dropColumn('last_nudge_at');
        });

        Schema::dropIfExists('risiko_snapshot');
        Schema::dropIfExists('risiko_konfigurasi');
    }
};
