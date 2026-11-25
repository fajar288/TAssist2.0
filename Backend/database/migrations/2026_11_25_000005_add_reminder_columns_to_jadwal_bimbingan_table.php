<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('jadwal_bimbingan', function (Blueprint $table) {
            $table->timestamp('reminder_24h_sent_at')->nullable()->after('catatan');
            $table->timestamp('reminder_1h_sent_at')->nullable()->after('reminder_24h_sent_at');
            $table->index(['status_konfirmasi', 'tanggal'], 'jadwal_reminder_lookup_index');
        });
    }

    public function down(): void
    {
        Schema::table('jadwal_bimbingan', function (Blueprint $table) {
            $table->dropIndex('jadwal_reminder_lookup_index');
            $table->dropColumn(['reminder_24h_sent_at', 'reminder_1h_sent_at']);
        });
    }
};
