// test/berita_acara_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:produk/model/berita_acara_model.dart';

void main() {
  group('BeritaAcaraModel Tests', () {
    test('parses draft Berita Acara JSON correctly', () {
      final json = {
        'berita_acara_id': 1,
        'bimbingan_id': 10,
        'nomor': 'BA/TA/2026/0001',
        'periode_mulai': '2026-01-01',
        'periode_selesai': '2026-06-30',
        'data_snapshot': {
          'mahasiswa': {'nama': 'Ahmad Fauzi', 'nim': '1202200001'},
          'dosen': {'nama': 'Dr. Ir. Hendra', 'nid': '0412345678'},
          'total_sesi': 8,
          'anotasi': {'resolved': 5, 'total': 6},
          'progres': {'persentase': 80},
        },
        'file_path': 'berita_acara/BA_TA_2026_0001.pdf',
        'file_hash': 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        'token_verifikasi': 'test-token-12345',
        'status_persetujuan': 'draft',
        'metode_persetujuan': null,
        'approved_at': null,
        'approved_hash': null,
        'created_at': '2026-06-30T10:00:00Z',
        'download_url': 'http://localhost/download/1',
      };

      final model = BeritaAcaraModel.fromJson(json);

      expect(model.beritaAcaraId, 1);
      expect(model.bimbinganId, 10);
      expect(model.nomor, 'BA/TA/2026/0001');
      expect(model.isDraft, isTrue);
      expect(model.isDisetujui, isFalse);
      expect(model.studentName, 'Ahmad Fauzi');
      expect(model.studentNim, '1202200001');
      expect(model.professorName, 'Dr. Ir. Hendra');
      expect(model.professorNid, '0412345678');
      expect(model.totalSessions, 8);
      expect(model.activeHash, 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890');
      expect(model.tokenVerifikasi, 'test-token-12345');
      expect(model.downloadUrl, 'http://localhost/download/1');
    });

    test('parses approved Berita Acara JSON correctly', () {
      final json = {
        'berita_acara_id': 2,
        'bimbingan_id': 10,
        'nomor': 'BA/TA/2026/0002',
        'file_hash': 'hash-draft-000',
        'approved_hash': 'hash-approved-999',
        'token_verifikasi': 'approved-token',
        'status_persetujuan': 'disetujui',
        'metode_persetujuan': 'pin',
        'approved_at': '2026-06-30T11:00:00Z',
      };

      final model = BeritaAcaraModel.fromJson(json);

      expect(model.isDisetujui, isTrue);
      expect(model.isDraft, isFalse);
      expect(model.metodePersetujuan, 'pin');
      expect(model.approvedAt, isNotNull);
      expect(model.activeHash, 'hash-approved-999');
    });

    test('handles missing or nullable fields with safe defaults', () {
      final model = BeritaAcaraModel.fromJson({});

      expect(model.beritaAcaraId, 0);
      expect(model.bimbinganId, 0);
      expect(model.nomor, '');
      expect(model.isDraft, isTrue);
      expect(model.studentName, 'Mahasiswa');
      expect(model.studentNim, '-');
      expect(model.professorName, 'Dosen Pembimbing');
      expect(model.totalSessions, 0);
      expect(model.activeHash, '');
    });

    test('serializes to JSON correctly', () {
      const model = BeritaAcaraModel(
        beritaAcaraId: 5,
        bimbinganId: 12,
        nomor: 'BA/TA/2026/0005',
        filePath: 'path/doc.pdf',
        fileHash: 'dummyhash',
        tokenVerifikasi: 'token-xyz',
        statusPersetujuan: BeritaAcaraStatus.disetujui,
        metodePersetujuan: 'tanda_tangan',
      );

      final json = model.toJson();

      expect(json['berita_acara_id'], 5);
      expect(json['nomor'], 'BA/TA/2026/0005');
      expect(json['status_persetujuan'], 'disetujui');
      expect(json['metode_persetujuan'], 'tanda_tangan');
    });
  });
}
