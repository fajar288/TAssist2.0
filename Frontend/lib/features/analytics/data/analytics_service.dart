// lib/features/analytics/data/analytics_service.dart

import '../../../core/api_client.dart';
import '../model/risk_snapshot_model.dart';

class DosenStudentRisk {
  final int bimbinganId;
  final String? tanggalMulai;
  final Map<String, dynamic> mahasiswa;
  final RiskSnapshotModel risiko;

  const DosenStudentRisk({
    required this.bimbinganId,
    this.tanggalMulai,
    required this.mahasiswa,
    required this.risiko,
  });

  factory DosenStudentRisk.fromJson(Map<String, dynamic> json) {
    final mhs = json['mahasiswa'] is Map
        ? Map<String, dynamic>.from(json['mahasiswa'])
        : <String, dynamic>{};

    final riskRaw = json['risiko'] is Map
        ? Map<String, dynamic>.from(json['risiko'])
        : <String, dynamic>{};

    return DosenStudentRisk(
      bimbinganId: json['bimbingan_id'] is int ? json['bimbingan_id'] : (int.tryParse(json['bimbingan_id']?.toString() ?? '') ?? 0),
      tanggalMulai: json['tanggal_mulai']?.toString(),
      mahasiswa: mhs,
      risiko: RiskSnapshotModel.fromJson({
        'bimbingan_id': json['bimbingan_id'],
        ...riskRaw,
      }),
    );
  }
}

class AnalyticsService {
  final ApiClient _client = ApiClient.instance;

  /**
   * Fetch professor-scoped risk indicators for supervised students (T-26, F-ANL-04).
   */
  Future<List<DosenStudentRisk>> getDosenRiskIndicators() async {
    final response = await _client.get('/dosen/analytics/risk');
    final rootData = response['data'];

    if (rootData is List) {
      return rootData
          .whereType<Map>()
          .map((item) => DosenStudentRisk.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return const [];
  }
}
