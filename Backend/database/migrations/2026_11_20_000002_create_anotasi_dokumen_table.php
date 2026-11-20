<?php
// database/migrations/2026_11_20_000002_create_anotasi_dokumen_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations (T-03: Annotation schema migration + backfill).
     */
    public function up(): void
    {
        // 1. Create anotasi_dokumen table (PRD §4.3)
        Schema::create('anotasi_dokumen', function (Blueprint $table) {
            $table->id('anotasi_id');
            $table->foreignId('versi_id')
                ->constrained('versi_dokumen', 'versi_id')
                ->cascadeOnDelete();
            $table->foreignId('dosen_id')
                ->nullable()
                ->constrained('dosen', 'dosen_id')
                ->nullOnDelete();
            $table->foreignId('user_id')
                ->constrained('users', 'user_id')
                ->cascadeOnDelete();
            $table->foreignId('parent_id')
                ->nullable()
                ->constrained('anotasi_dokumen', 'anotasi_id')
                ->nullOnDelete();
            $table->unsignedInteger('halaman')->nullable();
            $table->double('x')->nullable();
            $table->double('y')->nullable();
            $table->double('lebar')->nullable();
            $table->double('tinggi')->nullable();
            $table->enum('tipe', ['highlight', 'komentar', 'coretan'])->default('komentar');
            $table->text('konten')->nullable();
            $table->json('data_coretan')->nullable();
            $table->enum('status', ['open', 'revised', 'resolved'])->default('open');
            $table->timestamps();
        });

        // 2. Add counter cache column on versi_dokumen (PRD §4.2)
        Schema::table('versi_dokumen', function (Blueprint $table) {
            $table->unsignedInteger('jumlah_anotasi_terbuka')->default(0)->after('status_versi');
        });

        // 3. Backfill existing feedback_dokumen into anotasi_dokumen
        // Rows without page coordinates or with legacy feedback are preserved as document-level annotations.
        $feedbacks = DB::table('feedback_dokumen')->get();
        foreach ($feedbacks as $fb) {
            $dosen = DB::table('dosen')->where('dosen_id', $fb->dosen_id)->first();
            $userId = $dosen ? $dosen->user_id : null;

            // If user_id cannot be found, try looking up via a fallback or first admin
            if (!$userId) {
                $firstUser = DB::table('users')->first();
                $userId = $firstUser ? $firstUser->user_id : 1;
            }

            DB::table('anotasi_dokumen')->insert([
                'versi_id'     => $fb->versi_id,
                'dosen_id'     => $fb->dosen_id,
                'user_id'      => $userId,
                'parent_id'    => null,
                'halaman'      => $fb->halaman,
                'x'            => null,
                'y'            => null,
                'lebar'        => null,
                'tinggi'       => null,
                'tipe'         => 'komentar',
                'konten'       => $fb->komentar,
                'data_coretan' => null,
                'status'       => 'open',
                'created_at'   => $fb->created_at ?? now(),
                'updated_at'   => $fb->updated_at ?? now(),
            ]);
        }

        // 4. Update jumlah_anotasi_terbuka counter on versi_dokumen
        $counts = DB::table('anotasi_dokumen')
            ->where('status', 'open')
            ->select('versi_id', DB::raw('count(*) as aggregate'))
            ->groupBy('versi_id')
            ->get();

        foreach ($counts as $item) {
            DB::table('versi_dokumen')
                ->where('versi_id', $item->versi_id)
                ->update(['jumlah_anotasi_terbuka' => $item->aggregate]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('anotasi_dokumen');

        if (Schema::hasColumn('versi_dokumen', 'jumlah_anotasi_terbuka')) {
            Schema::table('versi_dokumen', function (Blueprint $table) {
                $table->dropColumn('jumlah_anotasi_terbuka');
            });
        }
    }
};
