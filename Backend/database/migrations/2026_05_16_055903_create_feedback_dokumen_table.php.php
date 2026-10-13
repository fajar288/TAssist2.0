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
        Schema::create('feedback_dokumen', function (Blueprint $table) {
            $table->id('feedback_id');
            $table->unsignedBigInteger('versi_id');
            $table->unsignedBigInteger('dosen_id');
            $table->text('komentar');
            $table->integer('halaman')->nullable();
            $table->string('posisi_anotasi')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->timestamp('updated_at')->useCurrent()->useCurrentOnUpdate();
            $table->foreign('versi_id')->references('versi_id')->on('versi_dokumen')->onDelete('cascade');
            $table->foreign('dosen_id')->references('dosen_id')->on('dosen')->onDelete('cascade');
            $table->index('versi_id');
            $table->index('dosen_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('feedback_dokumen');
    }
};
