// test/app_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tassist/theme/app_theme.dart';

void main() {
  // `AppTheme.lightTheme` builds its text theme through google_fonts, which
  // needs the services binding (asset bundle) to be available.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme tokens', () {
    test('core palette', () {
      expect(AppTheme.primary, const Color(0xFF0D4AA3));
      expect(AppTheme.primaryDark, const Color(0xFF082E6B));
      expect(AppTheme.primaryLight, const Color(0xFF1A65C8));
      expect(AppTheme.primaryGhost, const Color(0xFFE8F0FB));
      expect(AppTheme.background, const Color(0xFFF3F5F8));
      expect(AppTheme.surface, const Color(0xFFFFFFFF));
      expect(AppTheme.surfaceVariant, const Color(0xFFF8FAFC));
      expect(AppTheme.cardBorder, const Color(0xFFDCE2EA));
      expect(AppTheme.textPrimary, const Color(0xFF0F1B2D));
      expect(AppTheme.textSecondary, const Color(0xFF526071));
      expect(AppTheme.textMuted, const Color(0xFF5C6B7D));
      expect(AppTheme.accentGold, const Color(0xFF8A5D0A));
      expect(AppTheme.accentGoldOnDark, const Color(0xFFD4A64A));
    });

    test('glassmorphism tokens and helper', () {
      expect(AppTheme.glassSurfaceLight, AppTheme.surface.withValues(alpha: 0.62));
      expect(AppTheme.glassBorderLight, AppTheme.surface.withValues(alpha: 0.85));
      expect(AppTheme.glassSurfaceOnDark, AppTheme.surface.withValues(alpha: 0.14));
      expect(AppTheme.glassBorderOnDark, AppTheme.surface.withValues(alpha: 0.28));
      expect(AppTheme.floatingShadow, isNotEmpty);

      final deco = AppTheme.glassDecoration();
      expect(deco.color, AppTheme.glassSurfaceLight);
      expect(deco.borderRadius, BorderRadius.circular(AppTheme.radiusLg));
    });

    test('border radius scale tokens', () {
      expect(AppTheme.radiusSm, 8.0);
      expect(AppTheme.radiusMd, 12.0);
      expect(AppTheme.radiusLg, 16.0);
      expect(AppTheme.radiusXl, 24.0);
    });

    test('semantic status palette', () {
      expect(AppTheme.pending, const Color(0xFFB45309));
      expect(AppTheme.pendingBg, const Color(0xFFFFF7E6));
      expect(AppTheme.pendingBorder, const Color(0xFFF5D9A8));

      expect(AppTheme.accepted, const Color(0xFF047857));
      expect(AppTheme.acceptedBg, const Color(0xFFECFDF3));
      expect(AppTheme.acceptedBorder, const Color(0xFFA6E5C6));

      expect(AppTheme.declined, const Color(0xFFB42318));
      expect(AppTheme.declinedBg, const Color(0xFFFEF3F2));
      expect(AppTheme.declinedBorder, const Color(0xFFFECDCA));

      expect(AppTheme.info, const Color(0xFF0D4AA3));
      expect(AppTheme.infoBg, const Color(0xFFE8F0FB));
      expect(AppTheme.infoBorder, const Color(0xFFBFD3F2));
    });

    test('shadow and decoration helpers are clean and subtle', () {
      expect(AppTheme.cardShadow, isNotEmpty);
      expect(AppTheme.subtleShadow, isNotEmpty);
      expect(AppTheme.avatarGlow, isEmpty);

      final decoration = AppTheme.cardDecoration();

      expect(decoration.color, AppTheme.surface);
      expect(decoration.borderRadius, BorderRadius.circular(16));
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
      expect(
        theme.elevatedButtonTheme.style?.shape?.resolve({}),
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      );
    });

    test('builds a dark Material 3 theme and resolves context tokens', () {
      final theme = AppTheme.darkTheme;

      expect(theme, isA<ThemeData>());
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppTheme.darkBackground);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    testWidgets('context-aware accent gold and glass helpers adapt to theme', (tester) async {
      late Color lightGold;
      late Color darkGold;
      late BoxDecoration lightGlass;
      late BoxDecoration darkGlass;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: Builder(
            builder: (context) {
              lightGold = AppTheme.accentGoldOf(context);
              lightGlass = AppTheme.glassDecorationOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              darkGold = AppTheme.accentGoldOf(context);
              darkGlass = AppTheme.glassDecorationOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(lightGold, AppTheme.accentGold);
      expect(darkGold, AppTheme.accentGoldOnDark);
      expect(lightGlass.color, AppTheme.glassSurfaceLight);
      expect(darkGlass.color, AppTheme.darkSurface.withValues(alpha: 0.68));
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
