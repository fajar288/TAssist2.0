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
        Schema::create('checklist_progress', function (Blueprint $table) {
            $table->id('checklist_id');
            $table->unsignedBigInteger('progress_id');
            $table->string('nama_item');
            $table->boolean('tgl_selesai')->default(false);
            $table->date('tanggal_selesai')->nullable();
            $table->text('catatan')->nullable();
            $table->timestamps();
            $table->foreign('progress_id')->references('progress_id')->on('progres_ta')->onDelete('cascade');
            $table->index('progress_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('checklist_progress');
    }
};
