import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tassist/theme/app_theme.dart';

enum _BannerTone { success, error, info, warning }

/// Top-floating notification banner helper backed by [Overlay] and [AppTheme].
class AppSnackBars {
  AppSnackBars._();

  static OverlayEntry? _activeEntry;
  static Timer? _dismissTimer;

  static void success(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      title: title,
      tone: _BannerTone.success,
      duration: duration,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message: message,
      title: title,
      tone: _BannerTone.error,
      duration: duration,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      title: title,
      tone: _BannerTone.info,
      duration: duration,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      title: title,
      tone: _BannerTone.warning,
      duration: duration,
    );
  }

  /// Dismisses any currently visible floating banner.
  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _activeEntry?.remove();
    _activeEntry = null;
  }

  static void _show(
    BuildContext context, {
    required String message,
    String? title,
    required _BannerTone tone,
    required Duration duration,
  }) {
    if (!context.mounted) return;

    final style = _styleFor(context, tone);
    final overlay = Overlay.maybeOf(context, rootOverlay: true);

    if (overlay == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: style.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          duration: duration,
        ),
      );
      return;
    }

    dismiss();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopFloatingBanner(
        message: message,
        title: title,
        style: style,
        onClose: () {
          if (_activeEntry == entry) {
            dismiss();
          } else {
            entry.remove();
          }
        },
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
    _dismissTimer = Timer(duration, () {
      if (_activeEntry == entry) {
        dismiss();
      }
    });
  }

  static _BannerStyle _styleFor(BuildContext context, _BannerTone tone) =>
      switch (tone) {
        _BannerTone.success => _BannerStyle(
            accent: AppTheme.accepted,
            bg: AppTheme.acceptedBgOf(context),
            border: AppTheme.acceptedBorderOf(context),
            icon: Icons.check_circle_rounded,
          ),
        _BannerTone.error => _BannerStyle(
            accent: AppTheme.declined,
            bg: AppTheme.declinedBgOf(context),
            border: AppTheme.declinedBorderOf(context),
            icon: Icons.error_rounded,
          ),
        _BannerTone.info => _BannerStyle(
            accent: AppTheme.info,
            bg: AppTheme.infoBgOf(context),
            border: AppTheme.infoBorderOf(context),
            icon: Icons.info_rounded,
          ),
        _BannerTone.warning => _BannerStyle(
            accent: AppTheme.warning,
            bg: AppTheme.warningBgOf(context),
            border: AppTheme.warningBorderOf(context),
            icon: Icons.warning_amber_rounded,
          ),
      };
}

class _BannerStyle {
  const _BannerStyle({
    required this.accent,
    required this.bg,
    required this.border,
    required this.icon,
  });

  final Color accent;
  final Color bg;
  final Color border;
  final IconData icon;
}

class _TopFloatingBanner extends StatelessWidget {
  const _TopFloatingBanner({
    required this.message,
    required this.style,
    required this.onClose,
    this.title,
  });

  final String message;
  final String? title;
  final _BannerStyle style;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Dismissible(
            key: ValueKey('app-snackbar-$message-${style.accent.toARGB32()}'),
            direction: DismissDirection.up,
            onDismissed: (_) => onClose(),
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: style.border, width: 1.2),
                  boxShadow: AppTheme.subtleShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: style.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Icon(style.icon, size: 18, color: style.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null && title!.trim().isNotEmpty) ...[
                            Text(
                              title!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryOf(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimaryOf(context),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onClose,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppTheme.textSecondaryOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
