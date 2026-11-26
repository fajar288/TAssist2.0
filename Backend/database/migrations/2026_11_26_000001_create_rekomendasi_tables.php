<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Wave 6 (T-47, T-52): Supervisor recommendation configuration & anonymized low-score search logs.
     */
    public function up(): void
    {
        Schema::create('rekomendasi_konfigurasi', function (Blueprint $table) {
            $table->increments('konfigurasi_id');
            $table->decimal('bobot_kemiripan', 5, 4)->default(0.6000);
            $table->decimal('bobot_kuota', 5, 4)->default(0.2500);
            $table->decimal('bobot_beban', 5, 4)->default(0.1500);
            $table->decimal('ambang_skor_rendah', 5, 4)->default(0.3000);
            $table->unsignedBigInteger('updated_by')->nullable();
            $table->timestamps();

            $table->foreign('updated_by')
                ->references('user_id')
                ->on('users')
                ->nullOnDelete();
        });

        DB::table('rekomendasi_konfigurasi')->insert([
            'bobot_kemiripan'    => 0.6000,
            'bobot_kuota'        => 0.2500,
            'bobot_beban'        => 0.1500,
            'ambang_skor_rendah' => 0.3000,
            'created_at'         => now(),
            'updated_at'         => now(),
        ]);

        // T-52: Strictly anonymized log — no user_id, no mahasiswa_id, no IP.
        Schema::create('rekomendasi_log_pencarian', function (Blueprint $table) {
            $table->increments('log_id');
            $table->string('topik_kueri', 255);
            $table->json('kata_kunci_stemmed')->nullable();
            $table->decimal('skor_tertinggi', 5, 4)->default(0.0000);
            $table->unsignedInteger('jumlah_kandidat')->default(0);
            $table->timestamp('created_at')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('rekomendasi_log_pencarian');
        Schema::dropIfExists('rekomendasi_konfigurasi');
    }
};
