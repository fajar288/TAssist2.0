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
        Schema::create('progres_ta', function (Blueprint $table) {
            $table->id('progress_id');
            $table->unsignedBigInteger('bimbingan_id');
            $table->decimal('persentase', 5, 2)->default(0);
            $table->string('status_progress')->default('berjalan');
            $table->unsignedBigInteger('updated_dosen_id')->nullable();
            $table->timestamp('updated_at')->useCurrent()->useCurrentOnUpdate();
            $table->text('catatan')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->foreign('bimbingan_id')->references('bimbingan_id')->on('bimbingan')->onDelete('cascade');
            $table->foreign('updated_dosen_id')->references('dosen_id')->on('dosen')->nullOnDelete();
            $table->index('bimbingan_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('progress_ta');
    }
};
