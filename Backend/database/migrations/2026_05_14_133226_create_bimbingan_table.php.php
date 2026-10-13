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
        Schema::create('bimbingan', function (Blueprint $table) {
            $table->id('bimbingan_id');
            $table->unsignedBigInteger('permohonan_id');
            $table->unsignedBigInteger('mahasiswa_id');
            $table->unsignedBigInteger('dosen_id');
            $table->date('tanggal_mulai');
            $table->enum('status_bimbingan', ['aktif', 'selesai', 'dibatalkan'])->default('aktif');
            $table->timestamps();
            $table->foreign('permohonan_id')->references('permohonan_id')->on('permohonan_bimbingan')->onDelete('cascade');
            $table->foreign('mahasiswa_id')->references('mahasiswa_id')->on('mahasiswa')->onDelete('cascade');
            $table->foreign('dosen_id')->references('dosen_id')->on('dosen')->onDelete('cascade');
            $table->index('mahasiswa_id');
            $table->index('dosen_id');
            $table->index('permohonan_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('bimbingan');
    }
};
