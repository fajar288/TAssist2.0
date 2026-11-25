<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('dosen_ketersediaan', function (Blueprint $table) {
            $table->id('ketersediaan_id');
            $table->unsignedBigInteger('dosen_id');
            $table->enum('tipe', ['mingguan', 'khusus']);
            $table->enum('hari', ['senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu'])->nullable();
            $table->date('tanggal')->nullable();
            $table->time('waktu_mulai');
            $table->time('waktu_selesai');
            $table->boolean('is_available')->default(true);
            $table->string('catatan')->nullable();
            $table->timestamps();

            $table->foreign('dosen_id')->references('dosen_id')->on('dosen')->onDelete('cascade');
            $table->index(['dosen_id', 'tipe']);
            $table->index('tanggal');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('dosen_ketersediaan');
    }
};
