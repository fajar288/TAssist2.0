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
        Schema::create('chatbot_percakapan', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->string('judul')->default('Percakapan Baru');
            $table->timestamps();

            $table->foreign('user_id')->references('user_id')->on('users')->onDelete('cascade');
            $table->index(['user_id', 'updated_at']);
        });

        Schema::create('chatbot_pesan', function (Blueprint $table) {
            $table->id();
            $table->foreignId('percakapan_id')->constrained('chatbot_percakapan')->onDelete('cascade');
            $table->enum('role', ['user', 'assistant']);
            $table->longText('pesan');
            $table->json('sumber')->nullable();
            $table->boolean('is_refused')->default(false);
            $table->integer('tokens_used')->default(0);
            $table->timestamps();

            $table->index(['percakapan_id', 'created_at']);
            $table->index(['created_at', 'role']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('chatbot_pesan');
        Schema::dropIfExists('chatbot_percakapan');
    }
};
