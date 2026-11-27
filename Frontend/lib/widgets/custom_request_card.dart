// lib/widgets/custom_request_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/models.dart';
import '../theme/app_theme.dart';

// ─── Status Badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final RequestStatus status;
  final bool small;

  const StatusBadge({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final bg = switch (status) {
      RequestStatus.pending => AppTheme.pendingBgOf(context),
      RequestStatus.accepted => AppTheme.acceptedBgOf(context),
      RequestStatus.declined => AppTheme.declinedBgOf(context),
    };
    final border = switch (status) {
      RequestStatus.pending => AppTheme.pendingBorderOf(context),
      RequestStatus.accepted => AppTheme.acceptedBorderOf(context),
      RequestStatus.declined => AppTheme.declinedBorderOf(context),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 10 : 12,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: small ? 11 : 13, color: status.color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: GoogleFonts.poppins(
              color: status.color,
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stylized Avatar ──────────────────────────────────────────────────────────
class StylizedAvatar extends StatelessWidget {
  final String avatarUrl;
  final String initials;
  final double size;
  final String heroTag;
  final bool glowing;

  const StylizedAvatar({
    super.key,
    required this.avatarUrl,
    required this.initials,
    this.size = 52,
    required this.heroTag,
    this.glowing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.surfaceOf(context),
            width: 2,
          ),
        ),
        child: ClipOval(
          child: Image.network(
            avatarUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppTheme.primary,
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: size * 0.32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Counseling Request Card ──────────────────────────────────────────────────
class CounselingRequestCard extends StatelessWidget {
  final CounselingRequest request;
  final VoidCallback onTap;
  final int animationIndex;

  const CounselingRequestCard({
    super.key,
    required this.request,
    required this.onTap,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Ink(
            decoration:
                AppTheme.cardDecorationOf(context, radius: AppTheme.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // Avatar
                  StylizedAvatar(
                    avatarUrl: request.avatarUrl,
                    initials: request.initials,
                    size: 56,
                    heroTag: 'counseling-avatar-${request.id}',
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.studentName,
                          style: GoogleFonts.poppins(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          request.major,
                          style: GoogleFonts.poppins(
                            color: textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NIM: ${request.nim}',
                          style: GoogleFonts.poppins(
                            color: textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (request.message.isNotEmpty)
                          Text(
                            request.message,
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
                  const SizedBox(width: 12),

                  // Status + Arrow
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(status: request.status, small: true),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGhostOf(context),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: AppTheme.primaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}