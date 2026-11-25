// lib/features/analytics/widgets/risk_detail_sheet.dart

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../model/risk_snapshot_model.dart';

class RiskDetailSheet extends StatelessWidget {
  final RiskSnapshotModel risk;
  final String studentName;
  final String nim;

  const RiskDetailSheet({
    super.key,
    required this.risk,
    required this.studentName,
    required this.nim,
  });

  @override
  Widget build(BuildContext context) {
    final color = risk.color;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (nim.isNotEmpty)
                      Text(
                        'NIM: $nim',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: risk.backgroundColor,
                  border: Border.all(color: risk.borderColor),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(risk.icon, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      risk.levelLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Score Gauge Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: risk.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: risk.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Skor Indeks Risiko',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${risk.skor} / 100',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (risk.skor / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  risk.isAtRisk
                      ? 'Tingkat risiko tinggi! Mahasiswa memerlukan perhatian khusus dan tindak lanjut segera.'
                      : (risk.isAttention
                          ? 'Perlu perhatian. Terdeteksi beberapa keterlambatan bimbingan atau dokumen.'
                          : 'Progres bimbingan berjalan lancar sesuai jadwal.'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Faktor Sinyal & Rekomendasi Tindakan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          // Signal List
          Expanded(
            child: risk.signals.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada rincian data sinyal.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    itemCount: risk.signals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = risk.signals[index];
                      final isHigh = item.kontribusi >= 10;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isHigh ? AppTheme.riskAttentionBorder : AppTheme.cardBorder,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isHigh ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                              size: 18,
                              color: isHigh ? AppTheme.riskAttention : AppTheme.riskSafe,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.deskripsi,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getActionableSuggestion(item.nama, item.nilai),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isHigh ? AppTheme.riskAttention : AppTheme.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isHigh ? Colors.amber.shade100 : AppTheme.cardBorder,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '+${item.kontribusi}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isHigh ? Colors.amber.shade900 : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 12),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Tutup',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _getActionableSuggestion(String namaSinyal, dynamic nilai) {
    switch (namaSinyal) {
      case 'hari_sejak_bimbingan_terakhir':
        return 'Saran: Jadwalkan sesi pertemuan bimbingan baru dengan mahasiswa.';
      case 'hari_sejak_versi_terakhir':
        return 'Saran: Ingatkan mahasiswa untuk mengunggah draf revisi terbaru.';
      case 'anotasi_terbuka_lama':
        return 'Saran: Periksa dan selesaikan anotasi/catatan revisi yang belum resolved.';
      case 'checklist_terlambat':
        return 'Saran: Tinjau target checklist bab/tahapan yang tertunda bersama mahasiswa.';
      case 'progres_stagnan':
        return 'Saran: Lakukan evaluasi kendala penelitian agar progres dapat bertambah.';
      case 'waktu_terpakai_periode':
        return 'Saran: Evaluasi sisa waktu periode TA dan percepat jadwal sidang.';
      default:
        return 'Tindakan: Pantau perkembangan berkala.';
    }
  }
}
