// lib/widgets/student_card.dart

import 'package:flutter/material.dart';
import 'package:tassist/model/models.dart';
import 'package:tassist/theme/app_theme.dart';
import '../features/analytics/model/risk_snapshot_model.dart';
import '../features/analytics/widgets/risk_badge_widget.dart';

class StudentCard extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onTap;
  final RiskSnapshotModel? risk;

  const StudentCard({
    super.key,
    required this.student,
    required this.onTap,
    this.risk,
  });

  Color _statusColor(BuildContext context) {
    switch (student.status) {
      case 'active':
        return AppTheme.accepted;
      case 'warning':
        return AppTheme.pending;
      case 'completed':
        return AppTheme.primaryOf(context);
      default:
        return AppTheme.textMutedOf(context);
    }
  }

  String _statusLabel() {
    switch (student.status) {
      case 'active':
        return 'Active';
      case 'warning':
        return 'Needs Attention';
      case 'completed':
        return 'Completed';
      default:
        return student.status;
    }
  }

  IconData _statusIcon() {
    switch (student.status) {
      case 'active':
        return Icons.check_circle_outlined;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'completed':
        return Icons.verified_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  Color _avatarColor(BuildContext context) {
    switch (student.status) {
      case 'active':
        return AppTheme.primaryOf(context);
      case 'warning':
        return AppTheme.pending;
      case 'completed':
        return AppTheme.accepted;
      default:
        return AppTheme.textSecondaryOf(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Ink(
            decoration: AppTheme.cardDecorationOf(context, radius: AppTheme.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  _buildAvatar(context),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                student.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (risk != null)
                              RiskBadgeWidget(
                                risk: risk!,
                                studentName: student.name,
                                nim: student.nim,
                                compact: true,
                              )
                            else
                              _buildStatusBadge(statusColor),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${student.nim} · ${student.major}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondaryOf(context),
                                    fontSize: 12,
                                  ),
                        ),
                        const SizedBox(height: 10),
                        // Progress bar
                        _buildProgressBar(context, statusColor),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${student.taskCompleted}/${student.taskCount} Tasks',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: 11,
                                    color: AppTheme.textSecondaryOf(context),
                                  ),
                            ),
                            Text(
                              '${(student.progress * 100).toInt()}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_outlined,
                    color: AppTheme.textMutedOf(context),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _avatarColor(context).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Center(
            child: Text(
              student.imageInitials,
              style: TextStyle(
                color: _avatarColor(context),
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        if (student.status == 'warning')
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.pending,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(), size: 10, color: statusColor),
          const SizedBox(width: 3),
          Text(
            _statusLabel(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: LinearProgressIndicator(
        value: student.progress,
        backgroundColor: color.withValues(alpha: 0.12),
        valueColor: AlwaysStoppedAnimation<Color>(color),
        minHeight: 6,
      ),
    );
  }
}