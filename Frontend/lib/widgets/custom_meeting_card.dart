// lib/widgets/custom_meeting_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/models.dart';
import '../theme/app_theme.dart';
import 'custom_request_card.dart';

class MeetingRequestCard extends StatelessWidget {
  final MeetingRequest request;
  final VoidCallback onTap;
  final int animationIndex;

  const MeetingRequestCard({
    super.key,
    required this.request,
    required this.onTap,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryOf(context);
    final primaryGhost = AppTheme.primaryGhostOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: AppTheme.cardDecorationOf(context, radius: AppTheme.radiusMd),
        child: Column(
          children: [
            // ── Schedule Banner ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGhostOf(context).withValues(alpha: 0.55),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusMd),
                  topRight: Radius.circular(AppTheme.radiusMd),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceOf(context),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: AppTheme.cardBorderOf(context)),
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scheduled on ${request.dayName}',
                          style: GoogleFonts.poppins(
                            color: primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${request.formattedDate}  •  ${request.meetingTime}',
                          style: GoogleFonts.poppins(
                            color: textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: request.status, small: true),
                ],
              ),
            ),

            // Thin divider
            Divider(height: 1, color: AppTheme.cardBorderOf(context)),

            // ── Student Info ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  StylizedAvatar(
                    avatarUrl: request.avatarUrl,
                    initials: request.initials,
                    size: 48,
                    heroTag: 'meeting-avatar-${request.id}',
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.studentName,
                          style: GoogleFonts.poppins(
                            color: textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${request.major}  ·  ${request.nim}',
                          style: GoogleFonts.poppins(
                            color: textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          request.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: textSecondary,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryGhost,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (animationIndex * 80).ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.15, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}