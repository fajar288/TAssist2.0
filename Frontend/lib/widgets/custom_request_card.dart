// lib/widgets/custom_request_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/models.dart';
import '../theme/app_theme.dart';

// Warna navbar aktif — dipakai konsisten di seluruh UI dosen
const Color _navBlue      = Color(0xFF0D4AA3);
const Color _navBlueDark  = Color(0xFF082E6B);
const Color _navBlueLight = Color(0xFF1A65C8);

// ─── Status Badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final RequestStatus status;
  final bool small;

  const StatusBadge({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 10 : 12,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: status.borderColor, width: 1),
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
          boxShadow: glowing ? AppTheme.avatarGlow : AppTheme.subtleShadow,
          border: Border.all(
            color: Colors.white,
            width: 2.5,
          ),
        ),
        child: ClipOval(
          child: Image.network(
            avatarUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                // Diselaraskan dengan warna navbar aktif 0xFF0D4AA3
                gradient: LinearGradient(
                  colors: [_navBlueDark, _navBlueLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: size * 0.3,
                    fontWeight: FontWeight.w700,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: AppTheme.cardDecoration(),
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
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      request.major,
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIM: ${request.nim}',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textMuted,
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
                          color: AppTheme.textSecondary,
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
                      // Ghost biru navbar
                      color: _navBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: _navBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: (animationIndex * 80).ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.15, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}