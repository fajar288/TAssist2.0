// lib/widgets/app_dialogs.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ─── Shared: Glass Dialog Shell ───────────────────────────────────────────────
class _GlassDialogShell extends StatelessWidget {
  final Widget child;

  const _GlassDialogShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
          ),
          // Dialog card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: AppTheme.glassDecorationOf(
                    context,
                    radius: AppTheme.radiusXl,
                    color: AppTheme.surfaceOf(context).withValues(alpha: 0.92),
                    borderWidth: 1.2,
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper: Show with animated transition ────────────────────────────────────
Future<T?> _showGlassDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: '',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (ctx, _, __) => builder(ctx),
    transitionBuilder: (ctx, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return ScaleTransition(
        scale: Tween<double>(begin: 0.82, end: 1.0).animate(curved),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    },
  );
}

// ─── 1. Accept Success Dialog ─────────────────────────────────────────────────
Future<void> showAcceptedDialog(BuildContext context) {
  return _showGlassDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _GlassDialogShell(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated check circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.acceptedBgOf(ctx),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.acceptedBorderOf(ctx), width: 1.5),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppTheme.accepted,
                size: 42,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 200.ms),

            const SizedBox(height: 24),
            Text(
              'Request Accepted!',
              style: GoogleFonts.poppins(
                color: AppTheme.textPrimaryOf(ctx),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'The counseling request has been\nsuccessfully accepted. The student\nwill be notified shortly.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondaryOf(ctx),
                fontSize: 13.5,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accepted,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Great, Thanks!',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── 2. Decline Confirmation Dialog ──────────────────────────────────────────
Future<bool> showDeclineConfirmDialog(BuildContext context) async {
  final result = await _showGlassDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _GlassDialogShell(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.declinedBgOf(ctx),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.declinedBorderOf(ctx), width: 1.5),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.declined,
                size: 38,
              ),
            )
                .animate()
                .shake(duration: 500.ms, delay: 200.ms, hz: 3)
                .fadeIn(duration: 200.ms),

            const SizedBox(height: 20),
            Text(
              'Decline Request?',
              style: GoogleFonts.poppins(
                color: AppTheme.textPrimaryOf(ctx),
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to decline\nthis counseling request? This action\ncannot be undone.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondaryOf(ctx),
                fontSize: 13.5,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondaryOf(ctx),
                      side: BorderSide(color: AppTheme.cardBorderOf(ctx), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Decline button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.declined,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Decline',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

// ─── 3. Send Apology / Reason Dialog ─────────────────────────────────────────
Future<String?> showApologyDialog(BuildContext context) {
  final controller = TextEditingController();

  return _showGlassDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _GlassDialogShell(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariantOf(ctx),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(
                    Icons.mail_outline_rounded,
                    color: AppTheme.primaryOf(ctx),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send Apology',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textPrimaryOf(ctx),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Provide a reason for declining',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textMutedOf(ctx),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Text field
            TextField(
              controller: controller,
              maxLines: 4,
              autofocus: true,
              style: GoogleFonts.poppins(
                color: AppTheme.textPrimaryOf(ctx),
                fontSize: 13.5,
                height: 1.6,
              ),
              decoration: InputDecoration(
                hintText:
                    'e.g., I sincerely apologize, but I have a scheduling conflict at this time. Please submit another request and I will do my best to accommodate you.',
                hintStyle: GoogleFonts.poppins(
                  color: AppTheme.textMutedOf(ctx),
                  fontSize: 12.5,
                  height: 1.6,
                ),
                filled: true,
                fillColor: AppTheme.backgroundOf(ctx),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(
                    color: AppTheme.primaryOf(ctx),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(null),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondaryOf(ctx),
                      side: BorderSide(color: AppTheme.cardBorderOf(ctx)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(controller.text),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Send Message',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}