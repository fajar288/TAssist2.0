// test/informasi_ta_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:produk/model/informasi_ta_model.dart';

void main() {
  group('InformasiTAModel', () {
    test('parses valid announcement JSON correctly', () {
      final json = {
        'info_id': 42,
        'kategori': 'Pengumuman',
        'judul': 'Jadwal Pendaftaran Sidang Tugas Akhir',
        'konten_or_file': 'Pendaftaran dibuka mulai 1 Desember.',
        'published_at': '2026-11-20 09:00:00',
        'created_at': '2026-11-20 08:00:00',
        'penulis': 'Admin Koordinator TA',
      };

      final info = InformasiTAModel.fromJson(json);

      expect(info.infoId, 42);
      expect(info.kategori, 'Pengumuman');
      expect(info.judul, 'Jadwal Pendaftaran Sidang Tugas Akhir');
      expect(info.kontenOrFile, 'Pendaftaran dibuka mulai 1 Desember.');
      expect(info.publishedAt, isNotNull);
      expect(info.penulis, 'Admin Koordinator TA');
    });

    test('handles missing or nullable fields with safe defaults', () {
      final json = {
        'info_id': '15',
        'judul': 'Pengumuman Singkat',
      };

      final info = InformasiTAModel.fromJson(json);

      expect(info.infoId, 15);
      expect(info.kategori, 'Pengumuman');
      expect(info.judul, 'Pengumuman Singkat');
      expect(info.kontenOrFile, isNull);
      expect(info.publishedAt, isNull);
      expect(info.penulis, 'Admin TA');
    });
  });
}
