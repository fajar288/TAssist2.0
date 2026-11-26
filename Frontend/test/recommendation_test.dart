import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tassist/features/lecturer_selection/view/lecturer_recommendation_page.dart';
import 'package:tassist/features/lecturer_selection/view/lecturers_page.dart';
import 'package:tassist/model/lecturer_recommendation_model.dart';
import 'package:tassist/theme/app_theme.dart';

void main() {
  group('Wave 6 Topic-Based Supervisor Recommendation', () {
    test('LecturerRecommendationResponse parses ranked payload and converts to LecturerModel', () {
      final response = LecturerRecommendationResponse.fromJson({
        'topik': 'Deteksi Penyakit Tanaman Deep Learning',
        'kata_kunci_stemmed': ['deteksi', 'penyakit', 'tanam', 'deep', 'learning'],
        'is_topik_singkat': false,
        'catatan_kueri': null,
        'total_kandidat': 1,
        'total_dosen_dikecualikan_kuota_habis': 2,
        'rekomendasi': [
          {
            'dosen_id': 7,
            'nama': 'Dr. Budi Santoso',
            'email': 'budi@tassist.ac.id',
            'avatar': null,
            'nid': 'NID001',
            'bidang_keahlian': 'Kecerdasan Buatan dan Machine Learning',
            'kuota_bimbingan': 5,
            'sisa_kuota': 3,
            'bimbingan_aktif': 2,
            'profil_singkat': 'Peneliti deep learning.',
            'skor_total': 0.842,
            'skor_persen': 84.2,
            'kata_kunci_cocok': ['deep', 'learning'],
            'riwayat_topik_cocok': 2,
            'komponen_skor': {
              'kemiripan_topik': 0.85,
              'ketersediaan_kuota_ternormalisasi': 0.75,
              'beban_aktif_ternormalisasi': 0.4,
              'skor_beban_rendah': 0.6,
              'sisa_kuota': 3,
              'kuota_bimbingan': 5,
              'bimbingan_aktif': 2,
              'kontribusi': {
                'kemiripan': 0.51,
                'kuota': 0.1875,
                'beban': 0.09,
              },
            },
            'alasan':
                'Kecocokan topik 85% (deep, learning), kuota tersisa 3 dari 5, beban bimbingan aktif sedang (2/5), 2 riwayat bimbingan relevan.',
          },
        ],
      });

      expect(response.totalKandidat, 1);
      expect(response.totalDosenDikecualikanKuotaHabis, 2);
      expect(response.rekomendasi, hasLength(1));

      final first = response.rekomendasi.first;
      expect(first.nama, 'Dr. Budi Santoso');
      expect(first.skorPersen, closeTo(84.2, 0.01));
      expect(first.komponenSkor.kemiripanTopik, closeTo(0.85, 0.001));
      expect(first.riwayatTopikCocok, 2);

      final lecturer = LecturerModel.fromJson(first.toLecturerJson());
      expect(lecturer.id, '7');
      expect(lecturer.name, 'Dr. Budi Santoso');
      expect(lecturer.quotaLeft, 3);
    });

    testWidgets('LecturerRecommendationPage renders ranked supervisors and short-topic warning',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: LecturerRecommendationPage(
            initialTopik: 'AI',
            fetcher: (topik) async {
              return LecturerRecommendationResponse.fromJson({
                'topik': topik,
                'kata_kunci_stemmed': ['ai'],
                'is_topik_singkat': true,
                'catatan_kueri':
                    'Topik masih singkat atau umum. Berikan deskripsi topik yang lebih detail untuk meningkatkan akurasi pencocokan keahlian dosen.',
                'total_kandidat': 1,
                'total_dosen_dikecualikan_kuota_habis': 1,
                'rekomendasi': [
                  {
                    'dosen_id': 1,
                    'nama': 'Dr. Budi Santoso',
                    'nid': 'NID001',
                    'bidang_keahlian': 'Kecerdasan Buatan',
                    'kuota_bimbingan': 5,
                    'sisa_kuota': 4,
                    'bimbingan_aktif': 1,
                    'skor_total': 0.78,
                    'skor_persen': 78.0,
                    'kata_kunci_cocok': ['ai'],
                    'riwayat_topik_cocok': 1,
                    'komponen_skor': {
                      'kemiripan_topik': 0.75,
                      'ketersediaan_kuota_ternormalisasi': 1.0,
                      'beban_aktif_ternormalisasi': 0.2,
                      'skor_beban_rendah': 0.8,
                      'sisa_kuota': 4,
                      'kuota_bimbingan': 5,
                      'bimbingan_aktif': 1,
                    },
                    'alasan': 'Kecocokan topik 75% (ai), kuota tersisa 4 dari 5.',
                  },
                ],
              });
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Topik masih singkat atau umum'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('78.0% Skor'), findsOneWidget);
      expect(find.text('Dr. Budi Santoso'), findsOneWidget);
      expect(find.textContaining('kuota penuh dikecualikan'), findsOneWidget);
      expect(find.textContaining('Kecocokan topik 75%'), findsOneWidget);
    });

    testWidgets('LecturersPage switches cleanly to Rekomendasi Topik mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LecturersPage(),
        ),
      );

      expect(find.text('Semua Dosen'), findsOneWidget);
      expect(find.text('Rekomendasi Topik'), findsOneWidget);

      await tester.tap(find.text('Rekomendasi Topik'));
      await tester.pump();

      expect(find.text('Cari Pembimbing Sesuai Topik TA'), findsOneWidget);
    });
  });
}
