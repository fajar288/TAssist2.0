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
        Schema::create('jadwal_bimbingan', function (Blueprint $table) {
            $table->id('jadwal_id');
            $table->unsignedBigInteger('bimbingan_id');
            $table->unsignedBigInteger('pengaju_user_id');
            $table->date('tanggal');
            $table->time('waktu_mulai');
            $table->time('waktu_selesai');
            $table->enum('mode', ['online', 'offline'])->default('online');
            $table->enum('status_konfirmasi', ['menunggu', 'dikonfirmasi', 'ditolak'])->default('menunggu');
            $table->text('catatan')->nullable();
            $table->timestamps();
            $table->foreign('bimbingan_id')->references('bimbingan_id')->on('bimbingan')->onDelete('cascade');
            $table->foreign('pengaju_user_id')->references('user_id')->on('users')->onDelete('cascade');
            $table->index('bimbingan_id');
            $table->index('pengaju_user_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('jadwal_bimbingan');
    }
};
