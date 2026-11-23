// lib/features/analytics/widgets/risk_badge_widget.dart

import 'package:flutter/material.dart';
import '../model/risk_snapshot_model.dart';
import 'risk_detail_sheet.dart';

class RiskBadgeWidget extends StatelessWidget {
  final RiskSnapshotModel risk;
  final String? studentName;
  final String? nim;
  final VoidCallback? onTap;
  final bool compact;

  const RiskBadgeWidget({
    super.key,
    required this.risk,
    this.studentName,
    this.nim,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = risk.color;
    final bgColor = risk.backgroundColor;
    final borderColor = risk.borderColor;

    return InkWell(
      onTap: onTap ?? () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => RiskDetailSheet(
            risk: risk,
            studentName: studentName ?? 'Mahasiswa Bimbingan',
            nim: nim ?? '',
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              risk.icon,
              size: compact ? 12 : 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              risk.levelLabel,
              style: TextStyle(
                color: color,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${risk.skor}',
                style: TextStyle(
                  color: color,
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
