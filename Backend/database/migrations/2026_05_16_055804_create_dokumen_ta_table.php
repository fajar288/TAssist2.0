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
        Schema::create('dokumen_ta', function (Blueprint $table) {
            $table->id('dokumen_id');
            $table->unsignedBigInteger('bimbingan_id');
            $table->string('jenis_dokumen');
            $table->string('judul_dokumen');
            $table->text('deskripsi')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->timestamp('updated_at')->useCurrent()->useCurrentOnUpdate();
            $table->foreign('bimbingan_id')->references('bimbingan_id')->on('bimbingan')->onDelete('cascade');
            $table->index('bimbingan_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('dokumen_ta');
    }
};
