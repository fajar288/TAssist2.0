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
        Schema::create('basis_pengetahuan_ta', function (Blueprint $table) {
            $table->id();
            $table->string('kategori')->default('umum'); // prosedur, format, jadwal, faq, umum
            $table->string('judul');
            $table->longText('konten');
            $table->json('tags')->nullable();
            $table->longText('stemmed_konten')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index(['kategori', 'is_active']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('basis_pengetahuan_ta');
    }
};
