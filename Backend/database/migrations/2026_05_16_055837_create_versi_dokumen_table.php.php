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
        Schema::create('versi_dokumen', function (Blueprint $table) {
            $table->id('versi_id');
            $table->unsignedBigInteger('dokumen_id');
            $table->unsignedBigInteger('uploader_user_id');
            $table->unsignedInteger('nomor_versi')->default(1);
            $table->string('file_url_or_path');
            $table->text('catatan_revisi')->nullable();
            $table->timestamp('uploaded_at')->useCurrent();
            $table->enum('status_versi', ['draft', 'diajukan', 'direvisi', 'disetujui'])->default('diajukan');
            $table->timestamps();
            $table->foreign('dokumen_id')->references('dokumen_id')->on('dokumen_ta')->onDelete('cascade');
            $table->foreign('uploader_user_id')->references('user_id')->on('users')->onDelete('cascade');
            $table->index('dokumen_id');
            $table->index('uploader_user_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('versi_dokumen');
    }
};
