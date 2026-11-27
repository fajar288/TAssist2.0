import 'package:flutter/material.dart';
import 'package:tassist/theme/app_theme.dart';

/// Shared centered loading indicator styled with [AppTheme] tokens.
class AppLoadingWidget extends StatelessWidget {
  const AppLoadingWidget({
    super.key,
    this.message,
    this.size = 32,
    this.compact = false,
  });

  final String? message;
  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2.8,
            color: AppTheme.primaryOf(context),
          ),
        ),
        if (message != null && message!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondaryOf(context),
            ),
          ),
        ],
      ],
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Center(child: content),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: content,
      ),
    );
  }
}
