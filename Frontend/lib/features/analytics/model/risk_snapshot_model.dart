// lib/features/analytics/model/risk_snapshot_model.dart

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class RiskSignalItem {
  final String nama;
  final dynamic nilai;
  final double bobot;
  final double kontribusi;
  final String deskripsi;

  const RiskSignalItem({
    required this.nama,
    required this.nilai,
    required this.bobot,
    required this.kontribusi,
    required this.deskripsi,
  });

  factory RiskSignalItem.fromJson(Map<String, dynamic> json) {
    return RiskSignalItem(
      nama: json['nama']?.toString() ?? '',
      nilai: json['nilai'],
      bobot: (json['bobot'] is num) ? (json['bobot'] as num).toDouble() : 0.0,
      kontribusi: (json['kontribusi'] is num) ? (json['kontribusi'] as num).toDouble() : 0.0,
      deskripsi: json['deskripsi']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'nilai': nilai,
      'bobot': bobot,
      'kontribusi': kontribusi,
      'deskripsi': deskripsi,
    };
  }
}

class RiskSnapshotModel {
  final int? snapshotId;
  final int bimbinganId;
  final int skor;
  final String level; // 'aman', 'perlu_perhatian', 'berisiko'
  final String? tanggalHitung;
  final List<RiskSignalItem> signals;

  const RiskSnapshotModel({
    this.snapshotId,
    required this.bimbinganId,
    required this.skor,
    required this.level,
    this.tanggalHitung,
    this.signals = const [],
  });

  factory RiskSnapshotModel.fromJson(Map<String, dynamic> json) {
    final rawSignals = json['sinyal'];
    List<RiskSignalItem> items = [];

    if (rawSignals is List) {
      items = rawSignals
          .whereType<Map>()
          .map((item) => RiskSignalItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return RiskSnapshotModel(
      snapshotId: json['snapshot_id'] is int ? json['snapshot_id'] : int.tryParse(json['snapshot_id']?.toString() ?? ''),
      bimbinganId: json['bimbingan_id'] is int ? json['bimbingan_id'] : (int.tryParse(json['bimbingan_id']?.toString() ?? '') ?? 0),
      skor: json['skor'] is int ? json['skor'] : (int.tryParse(json['skor']?.toString() ?? '') ?? 0),
      level: json['level']?.toString() ?? 'aman',
      tanggalHitung: json['tanggal_hitung']?.toString(),
      signals: items,
    );
  }

  bool get isSafe => level.toLowerCase() == 'aman';
  bool get isAttention => level.toLowerCase() == 'perlu_perhatian';
  bool get isAtRisk => level.toLowerCase() == 'berisiko';

  String get levelLabel {
    switch (level.toLowerCase()) {
      case 'berisiko':
        return 'Berisiko';
      case 'perlu_perhatian':
        return 'Perlu Perhatian';
      case 'aman':
      default:
        return 'Aman';
    }
  }

  Color get color {
    switch (level.toLowerCase()) {
      case 'berisiko':
        return AppTheme.riskAtRisk;
      case 'perlu_perhatian':
        return AppTheme.riskAttention;
      case 'aman':
      default:
        return AppTheme.riskSafe;
    }
  }

  Color get backgroundColor {
    switch (level.toLowerCase()) {
      case 'berisiko':
        return AppTheme.riskAtRiskBg;
      case 'perlu_perhatian':
        return AppTheme.riskAttentionBg;
      case 'aman':
      default:
        return AppTheme.riskSafeBg;
    }
  }

  Color get borderColor {
    switch (level.toLowerCase()) {
      case 'berisiko':
        return AppTheme.riskAtRiskBorder;
      case 'perlu_perhatian':
        return AppTheme.riskAttentionBorder;
      case 'aman':
      default:
        return AppTheme.riskSafeBorder;
    }
  }

  IconData get icon {
    switch (level.toLowerCase()) {
      case 'berisiko':
        return Icons.error_outline;
      case 'perlu_perhatian':
        return Icons.warning_amber_outlined;
      case 'aman':
      default:
        return Icons.check_circle_outline;
    }
  }
}
