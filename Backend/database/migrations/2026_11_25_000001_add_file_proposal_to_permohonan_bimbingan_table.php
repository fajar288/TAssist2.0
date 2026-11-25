<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('permohonan_bimbingan', function (Blueprint $table) {
            $table->string('file_proposal')->nullable()->after('topik_ta');
        });
    }

    public function down(): void
    {
        Schema::table('permohonan_bimbingan', function (Blueprint $table) {
            $table->dropColumn('file_proposal');
        });
    }
};
