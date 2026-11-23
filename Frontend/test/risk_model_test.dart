// test/risk_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:produk/features/analytics/model/risk_snapshot_model.dart';
import 'package:produk/theme/app_theme.dart';

void main() {
  group('RiskSnapshotModel Tests', () {
    test('parses safe risk snapshot JSON correctly', () {
      final json = {
        'snapshot_id': 1,
        'bimbingan_id': 10,
        'skor': 25,
        'level': 'aman',
        'tanggal_hitung': '2026-11-20',
        'sinyal': [
          {
            'nama': 'hari_sejak_bimbingan_terakhir',
            'nilai': 3,
            'bobot': 0.25,
            'kontribusi': 2.0,
            'deskripsi': '3 hari sejak pertemuan terakhir',
          },
        ],
      };

      final model = RiskSnapshotModel.fromJson(json);

      expect(model.snapshotId, 1);
      expect(model.bimbinganId, 10);
      expect(model.skor, 25);
      expect(model.level, 'aman');
      expect(model.isSafe, isTrue);
      expect(model.isAttention, isFalse);
      expect(model.isAtRisk, isFalse);
      expect(model.levelLabel, 'Aman');
      expect(model.color, AppTheme.riskSafe);
      expect(model.signals.length, 1);
      expect(model.signals.first.nama, 'hari_sejak_bimbingan_terakhir');
      expect(model.signals.first.kontribusi, 2.0);
    });

    test('parses at-risk snapshot JSON correctly', () {
      final json = {
        'snapshot_id': 2,
        'bimbingan_id': 15,
        'skor': 85,
        'level': 'berisiko',
        'tanggal_hitung': '2026-11-20',
        'sinyal': [
          {
            'nama': 'hari_sejak_bimbingan_terakhir',
            'nilai': 35,
            'bobot': 0.25,
            'kontribusi': 21.3,
            'deskripsi': '35 hari sejak bimbingan terakhir',
          },
          {
            'nama': 'checklist_terlambat',
            'nilai': 2,
            'bobot': 0.15,
            'kontribusi': 10.5,
            'deskripsi': '2 item checklist melewati batas',
          },
        ],
      };

      final model = RiskSnapshotModel.fromJson(json);

      expect(model.skor, 85);
      expect(model.level, 'berisiko');
      expect(model.isAtRisk, isTrue);
      expect(model.levelLabel, 'Berisiko');
      expect(model.color, AppTheme.riskAtRisk);
      expect(model.signals.length, 2);
    });

    test('parses attention risk snapshot JSON correctly', () {
      final json = {
        'snapshot_id': 3,
        'bimbingan_id': 20,
        'skor': 55,
        'level': 'perlu_perhatian',
        'tanggal_hitung': '2026-11-20',
        'sinyal': [],
      };

      final model = RiskSnapshotModel.fromJson(json);

      expect(model.skor, 55);
      expect(model.level, 'perlu_perhatian');
      expect(model.isAttention, isTrue);
      expect(model.levelLabel, 'Perlu Perhatian');
      expect(model.color, AppTheme.riskAttention);
    });
  });
}
