<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('checklist_progress', function (Blueprint $table) {
            $table->renameColumn('tgl_selesai', 'is_selesai');
        });

        Schema::table('checklist_progress', function (Blueprint $table) {
            $table->float('bobot')->default(1.0)->after('catatan');
        });
    }

    public function down(): void
    {
        Schema::table('checklist_progress', function (Blueprint $table) {
            $table->dropColumn('bobot');
        });

        Schema::table('checklist_progress', function (Blueprint $table) {
            $table->renameColumn('is_selesai', 'tgl_selesai');
        });
    }
};
