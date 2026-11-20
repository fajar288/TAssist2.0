// test/app_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:produk/theme/app_theme.dart';

void main() {
  // `AppTheme.lightTheme` builds its text theme through google_fonts, which
  // needs the services binding (asset bundle) to be available.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme tokens', () {
    test('core palette', () {
      expect(AppTheme.primary, const Color(0xFF4338CA));
      expect(AppTheme.primaryLight, const Color(0xFF6366F1));
      expect(AppTheme.primaryGhost, const Color(0xFFEEF2FF));
      expect(AppTheme.background, const Color(0xFFF1F5F9));
      expect(AppTheme.surface, const Color(0xFFFFFFFF));
      expect(AppTheme.textPrimary, const Color(0xFF1E1B4B));
      expect(AppTheme.textSecondary, const Color(0xFF64748B));
      expect(AppTheme.textMuted, const Color(0xFF94A3B8));
    });

    test('semantic status palette', () {
      expect(AppTheme.pending, const Color(0xFFF59E0B));
      expect(AppTheme.pendingBg, const Color(0xFFFFFBEB));
      expect(AppTheme.pendingBorder, const Color(0xFFFDE68A));

      expect(AppTheme.accepted, const Color(0xFF10B981));
      expect(AppTheme.acceptedBg, const Color(0xFFECFDF5));
      expect(AppTheme.acceptedBorder, const Color(0xFFA7F3D0));

      expect(AppTheme.declined, const Color(0xFFEF4444));
      expect(AppTheme.declinedBg, const Color(0xFFFFF1F2));
      expect(AppTheme.declinedBorder, const Color(0xFFFFCDD2));
    });

    test('shadow and decoration helpers are usable', () {
      expect(AppTheme.cardShadow, isNotEmpty);
      expect(AppTheme.subtleShadow, isNotEmpty);
      expect(AppTheme.avatarGlow, isNotEmpty);

      final decoration = AppTheme.cardDecoration();

      expect(decoration.color, AppTheme.surface);
      expect(decoration.borderRadius, BorderRadius.circular(20));
      expect(
        AppTheme.cardDecoration(radius: 8).borderRadius,
        BorderRadius.circular(8),
      );
    });
  });

  group('AppTheme.lightTheme', () {
    test('builds a light Material 3 theme on the shared background', () {
      final theme = AppTheme.lightTheme;

      expect(theme, isA<ThemeData>());
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, AppTheme.background);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.backgroundColor, Colors.transparent);
      expect(
        theme.elevatedButtonTheme.style?.backgroundColor?.resolve({}),
        AppTheme.primary,
      );
    });
  });

  group('RequestStatusStyle extension', () {
    test('maps each request status to its tokens', () {
      expect(RequestStatus.pending.color, AppTheme.pending);
      expect(RequestStatus.accepted.color, AppTheme.accepted);
      expect(RequestStatus.declined.color, AppTheme.declined);

      expect(RequestStatus.pending.bgColor, AppTheme.pendingBg);
      expect(RequestStatus.accepted.bgColor, AppTheme.acceptedBg);
      expect(RequestStatus.declined.bgColor, AppTheme.declinedBg);

      expect(RequestStatus.pending.borderColor, AppTheme.pendingBorder);
      expect(RequestStatus.accepted.borderColor, AppTheme.acceptedBorder);
      expect(RequestStatus.declined.borderColor, AppTheme.declinedBorder);
    });

    test('maps each request status to a label and an icon', () {
      expect(RequestStatus.pending.label, 'Pending');
      expect(RequestStatus.accepted.label, 'Accepted');
      expect(RequestStatus.declined.label, 'Declined');

      expect(RequestStatus.pending.icon, Icons.schedule_rounded);
      expect(RequestStatus.accepted.icon, Icons.check_circle_rounded);
      expect(RequestStatus.declined.icon, Icons.cancel_rounded);
    });
  });
}
