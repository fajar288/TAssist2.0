<?php

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
        Schema::create('berita_acara', function (Blueprint $table) {
            $table->id('berita_acara_id');
            $table->unsignedBigInteger('bimbingan_id');
            $table->string('nomor')->unique();
            $table->date('periode_mulai');
            $table->date('periode_selesai');
            $table->json('data_snapshot');
            $table->string('file_path');
            $table->string('file_hash', 64);
            $table->string('token_verifikasi')->unique();
            $table->enum('status_persetujuan', ['draft', 'disetujui'])->default('draft');
            $table->enum('metode_persetujuan', ['pin', 'tanda_tangan'])->nullable();
            $table->string('tanda_tangan_path')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->string('approved_hash', 64)->nullable();
            $table->timestamps();

            $table->foreign('bimbingan_id')
                ->references('bimbingan_id')
                ->on('bimbingan')
                ->onDelete('cascade');

            $table->index('bimbingan_id');
            $table->index('token_verifikasi');
            $table->index('status_persetujuan');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('berita_acara');
    }
};
