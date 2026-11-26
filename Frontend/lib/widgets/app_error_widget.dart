import 'package:flutter/material.dart';
import 'package:tassist/theme/app_theme.dart';

/// Shared error state card/view with optional retry action.
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    required this.message,
    this.title = 'Gagal Memuat Data',
    this.onRetry,
    this.retryLabel = 'Coba Lagi',
    this.compact = false,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: EdgeInsets.all(compact ? 16 : 22),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.declinedBorder),
            boxShadow: AppTheme.subtleShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 44 : 54,
                height: compact ? 44 : 54,
                decoration: BoxDecoration(
                  color: AppTheme.declinedBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: compact ? 24 : 28,
                  color: AppTheme.declined,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(retryLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
