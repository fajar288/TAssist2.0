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
         Schema::create('informasi_ta', function (Blueprint $table) {
            $table->id('info_id');
            $table->unsignedBigInteger('admin_id');
            $table->string('kategori');
            $table->string('judul');
            $table->longText('konten_or_file');
            $table->timestamp('published_at')->nullable();
            $table->timestamps();
            $table->foreign('admin_id')->references('admin_id')->on('admin')->onDelete('cascade');
            $table->index('admin_id');
            $table->index('kategori');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('informasi_ta');
    }
};
