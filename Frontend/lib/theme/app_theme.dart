// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── Core Palette (Navy + Glassmorphism) ─────────────────────────────────────
  static const Color primary       = Color(0xFF0D4AA3); // Navy Blue
  static const Color primaryLight  = Color(0xFF1A65C8); // Accent Navy-Blue
  static const Color primaryDark   = Color(0xFF082E6B); // Deep Navy Surface
  static const Color primaryGhost  = Color(0xFFE8F0FB); // Soft Navy Tint
  static const Color background    = Color(0xFFF3F5F8); // Cool Neutral Gray
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color textPrimary   = Color(0xFF0F1B2D); // Deep Navy Charcoal
  static const Color textSecondary = Color(0xFF526071); // Cool Slate
  static const Color textMuted     = Color(0xFF5C6B7D); // Accessible Muted Slate (>= 4.99:1 AA)

  // ─── Deliberate Secondary Accent (Subtle Academic Dark Gold) ─────────────────
  static const Color accentGold           = Color(0xFF8A5D0A); // Light surface (>= 5.33:1 AA)
  static const Color accentGoldOnDark     = Color(0xFFD4A64A); // Deep navy / dark surface (>= 5.80:1 AA)
  static const Color accentGoldBg         = Color(0xFFFBF6EA);
  static const Color accentGoldBorder     = Color(0xFFE7D3A1);
  static const Color darkAccentGoldBg     = Color(0xFF281F0E);
  static const Color darkAccentGoldBorder = Color(0xFF6E5320);

  // ─── Glassmorphism Tokens ────────────────────────────────────────────────────
  static Color get glassSurfaceLight  => surface.withValues(alpha: 0.62);
  static Color get glassBorderLight   => surface.withValues(alpha: 0.85);
  static Color get glassSurfaceOnDark => surface.withValues(alpha: 0.14);
  static Color get glassBorderOnDark  => surface.withValues(alpha: 0.28);

  // ─── Radius Scale ────────────────────────────────────────────────────────────
  static const double radiusSm = 8.0;  // chips, badges, small icon boxes
  static const double radiusMd = 12.0; // cards, buttons, inputs, popup menus
  static const double radiusLg = 16.0; // large cards, containers, floating navbar
  static const double radiusXl = 24.0; // dialogs, bottom sheets

  // ─── Semantic Colors ─────────────────────────────────────────────────────────
  static const Color pending       = Color(0xFFB45309); // Amber-700
  static const Color pendingBg     = Color(0xFFFFF7E6);
  static const Color pendingBorder = Color(0xFFF5D9A8);

  static const Color accepted       = Color(0xFF047857); // Emerald-700
  static const Color acceptedBg     = Color(0xFFECFDF3);
  static const Color acceptedBorder = Color(0xFFA6E5C6);

  static const Color declined       = Color(0xFFB42318); // Red-700
  static const Color declinedBg     = Color(0xFFFEF3F2);
  static const Color declinedBorder = Color(0xFFFECDCA);

  // ─── Info / Caution ──────────────────────────────────────────────────────────
  static const Color info       = primary;
  static const Color infoBg     = primaryGhost;
  static const Color infoBorder = Color(0xFFBFD3F2);

  static const Color warning       = pending;
  static const Color warningBg     = pendingBg;
  static const Color warningBorder = pendingBorder;

  // ─── Surfaces & Interactive Borders ──────────────────────────────────────────
  static const Color surfaceVariant = Color(0xFFF8FAFC);
  static const Color cardBorder     = Color(0xFFDCE2EA);
  static const Color inputBorder    = Color(0xFF8592A3); // >= 3.16:1 non-text contrast on surface

  // ─── Annotation Status (S8.3) ────────────────────────────────────────────────
  static const Color annotationOpen       = warning;
  static const Color annotationOpenBg     = warningBg;
  static const Color annotationOpenBorder = warningBorder;

  static const Color annotationRevised       = info;
  static const Color annotationRevisedBg     = infoBg;
  static const Color annotationRevisedBorder = infoBorder;

  static const Color annotationResolved       = accepted;
  static const Color annotationResolvedBg     = acceptedBg;
  static const Color annotationResolvedBorder = acceptedBorder;

  // ─── Risk Level (S8.4) ───────────────────────────────────────────────────────
  static const Color riskSafe       = accepted;
  static const Color riskSafeBg     = acceptedBg;
  static const Color riskSafeBorder = acceptedBorder;

  static const Color riskAttention       = warning;
  static const Color riskAttentionBg     = warningBg;
  static const Color riskAttentionBorder = warningBorder;

  static const Color riskAtRisk       = declined;
  static const Color riskAtRiskBg     = declinedBg;
  static const Color riskAtRiskBorder = declinedBorder;

  // ─── Chat (S8.5) ─────────────────────────────────────────────────────────────
  static const Color chatUserText        = surface;
  static const Color chatUserBubble      = primary;
  static const Color chatAssistantText   = textPrimary;
  static const Color chatAssistantBubble = background;
  static const Color chatCitation        = primaryLight;
  static const Color chatCitationBg      = primaryGhost;
  static const Color chatRefusal         = warning;
  static const Color chatRefusalBg       = warningBg;

  // ─── Notification Types (F-NOT-03) ───────────────────────────────────────────
  static const Color notificationInfo       = info;
  static const Color notificationInfoBg     = infoBg;
  static const Color notificationInfoBorder = infoBorder;

  static const Color notificationSuccess       = accepted;
  static const Color notificationSuccessBg     = acceptedBg;
  static const Color notificationSuccessBorder = acceptedBorder;

  static const Color notificationWarning       = warning;
  static const Color notificationWarningBg     = warningBg;
  static const Color notificationWarningBorder = warningBorder;

  static const Color notificationError       = declined;
  static const Color notificationErrorBg     = declinedBg;
  static const Color notificationErrorBorder = declinedBorder;

  static const Color notificationNeutral       = textSecondary;
  static const Color notificationNeutralBg     = surfaceVariant;
  static const Color notificationNeutralBorder = cardBorder;

  // ─── Dark Core Palette (Navy Dark Variant) ───────────────────────────────────
  static const Color darkBackground     = Color(0xFF091322);
  static const Color darkSurface        = Color(0xFF101D33);
  static const Color darkSurfaceVariant = Color(0xFF172642);
  static const Color darkCardBorder     = Color(0xFF243656);
  static const Color darkInputBorder    = Color(0xFF5E779E);
  static const Color darkTextPrimary    = Color(0xFFF3F5F8);
  static const Color darkTextSecondary  = Color(0xFF94A3B8);
  static const Color darkTextMuted      = Color(0xFF93A3B8);
  static const Color darkPrimary        = Color(0xFF5B93E8);
  static const Color darkPrimaryGhost   = Color(0xFF162B4D);

  // ─── Dark Semantic Surfaces (T-68) ───────────────────────────────────────────
  static const Color darkPendingBg      = Color(0xFF2B2111);
  static const Color darkPendingBorder  = Color(0xFF6B4E1B);
  static const Color darkAcceptedBg     = Color(0xFF0E2923);
  static const Color darkAcceptedBorder = Color(0xFF1B5E4A);
  static const Color darkDeclinedBg     = Color(0xFF2D151B);
  static const Color darkDeclinedBorder = Color(0xFF6D2636);
  static const Color darkInfoBg         = Color(0xFF122645);
  static const Color darkInfoBorder     = Color(0xFF214880);
  static const Color darkWarningBg      = Color(0xFF2B2111);
  static const Color darkWarningBorder  = Color(0xFF6B4E1B);

  // ─── Card Shadow ─────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> get subtleShadow => cardShadow;

  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: primaryDark.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get avatarGlow => const [];

  // ─── Decoration Helpers ───────────────────────────────────────────────────────
  static BoxDecoration cardDecoration({
    double radius = radiusLg,
    bool withBorder = true,
  }) =>
      BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: withBorder ? Border.all(color: cardBorder) : null,
        boxShadow: cardShadow,
      );

  static BoxDecoration glassDecoration({
    double radius = radiusLg,
    Color? color,
    Color? borderColor,
    double borderWidth = 1.0,
    List<BoxShadow>? boxShadow,
  }) =>
      BoxDecoration(
        color: color ?? glassSurfaceLight,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? glassBorderLight,
          width: borderWidth,
        ),
        boxShadow: boxShadow,
      );

  // ─── Annotation Status Helpers (S8.3) ────────────────────────────────────────
  /// Maps an annotation status (`open` / `revised` / `resolved`) to its colour.
  /// Unknown or empty input returns a neutral token - never throws, never null.
  static Color annotationStatusColor(String status) =>
      switch (_normalize(status)) {
        'open' => annotationOpen,
        'revised' => annotationRevised,
        'resolved' => annotationResolved,
        _ => textSecondary,
      };

  /// Background companion of [annotationStatusColor].
  static Color annotationStatusBg(String status) =>
      switch (_normalize(status)) {
        'open' => annotationOpenBg,
        'revised' => annotationRevisedBg,
        'resolved' => annotationResolvedBg,
        _ => surfaceVariant,
      };

  /// Border companion of [annotationStatusColor].
  static Color annotationStatusBorder(String status) =>
      switch (_normalize(status)) {
        'open' => annotationOpenBorder,
        'revised' => annotationRevisedBorder,
        'resolved' => annotationResolvedBorder,
        _ => cardBorder,
      };

  // ─── Risk Level Helpers (S8.4) ───────────────────────────────────────────────
  /// Maps a risk level (`aman` / `perlu_perhatian` / `berisiko`) to its colour.
  /// Unknown or empty input returns a neutral token - never throws, never null.
  static Color riskLevelColor(String level) => switch (_normalize(level)) {
        'aman' || 'safe' => riskSafe,
        'perlu_perhatian' || 'attention' => riskAttention,
        'berisiko' || 'at_risk' => riskAtRisk,
        _ => textSecondary,
      };

  /// Background companion of [riskLevelColor].
  static Color riskLevelBg(String level) => switch (_normalize(level)) {
        'aman' || 'safe' => riskSafeBg,
        'perlu_perhatian' || 'attention' => riskAttentionBg,
        'berisiko' || 'at_risk' => riskAtRiskBg,
        _ => surfaceVariant,
      };

  /// Border companion of [riskLevelColor].
  static Color riskLevelBorder(String level) => switch (_normalize(level)) {
        'aman' || 'safe' => riskSafeBorder,
        'perlu_perhatian' || 'attention' => riskAttentionBorder,
        'berisiko' || 'at_risk' => riskAtRiskBorder,
        _ => cardBorder,
      };

  // ─── Notification Type Helpers (F-NOT-03) ────────────────────────────────────
  /// Maps a backend `tipe_notifikasi` value to its five-category style.
  ///
  /// Recognised values are the real ones written by `NotifikasiService::kirim()`
  /// call sites plus the F-NOT-03 v2.0 triggers. Anything unknown or empty
  /// returns [notificationNeutralStyle] - never throws, never null.
  static NotificationStyle notificationTypeStyle(String tipe) =>
      switch (_normalize(tipe)) {
        // Backend values: guidance request, meeting, documents, checklists, info.
        'informasi_ta' ||
        'permohonan_bimbingan' ||
        'jadwal_bimbingan' ||
        'feedback_dokumen' ||
        'upload_dokumen' ||
        'upload_versi_dokumen' ||
        'checklist_baru' ||
        // F-NOT-03 v2.0 triggers.
        'anotasi_baru' ||
        'berita_acara_siap' ||
        'pengingat_jadwal' =>
          notificationInfoStyle,
        // Backend values: accepted request, confirmed meeting, finished checklist.
        'permohonan_diterima' ||
        'konfirmasi_jadwal' ||
        'checklist_selesai' ||
        // F-NOT-03 v2.0 triggers.
        'anotasi_resolved' ||
        'berita_acara_disetujui' =>
          notificationSuccessStyle,
        // Caution: needs the user's attention but nothing failed.
        'anotasi_revised' ||
        'risiko_meningkat' ||
        'idle_supervisi' =>
          notificationWarningStyle,
        // Failure / rejection paths.
        'permohonan_ditolak' ||
        'jadwal_ditolak' ||
        'berita_acara_ditolak' =>
          notificationErrorStyle,
        // Backend value with no status implication, plus the safe fallback.
        'update_progres' => notificationNeutralStyle,
        _ => notificationNeutralStyle,
      };

  /// `trim` + lower-case + `-`/space → `_`, so `"Perlu Perhatian"` also matches.
  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');

  // ─── Notification Style Constants ────────────────────────────────────────────
  static const NotificationStyle notificationInfoStyle = NotificationStyle(
    color: notificationInfo,
    bg: notificationInfoBg,
    border: notificationInfoBorder,
    icon: Icons.info_outlined,
  );

  static const NotificationStyle notificationSuccessStyle = NotificationStyle(
    color: notificationSuccess,
    bg: notificationSuccessBg,
    border: notificationSuccessBorder,
    icon: Icons.check_circle_outlined,
  );

  static const NotificationStyle notificationWarningStyle = NotificationStyle(
    color: notificationWarning,
    bg: notificationWarningBg,
    border: notificationWarningBorder,
    icon: Icons.warning_amber_outlined,
  );

  static const NotificationStyle notificationErrorStyle = NotificationStyle(
    color: notificationError,
    bg: notificationErrorBg,
    border: notificationErrorBorder,
    icon: Icons.error_outline,
  );

  static const NotificationStyle notificationNeutralStyle = NotificationStyle(
    color: notificationNeutral,
    bg: notificationNeutralBg,
    border: notificationNeutralBorder,
    icon: Icons.notifications_outlined,
  );

  // ─── Context-Aware Token Helpers (T-68) ──────────────────────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color backgroundOf(BuildContext context) =>
      isDark(context) ? darkBackground : background;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? darkSurface : surface;

  static Color surfaceVariantOf(BuildContext context) =>
      isDark(context) ? darkSurfaceVariant : surfaceVariant;

  static Color cardBorderOf(BuildContext context) =>
      isDark(context) ? darkCardBorder : cardBorder;

  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;

  static Color textMutedOf(BuildContext context) =>
      isDark(context) ? darkTextMuted : textMuted;

  static Color primaryOf(BuildContext context) =>
      isDark(context) ? darkPrimary : primary;

  static Color primaryGhostOf(BuildContext context) =>
      isDark(context) ? darkPrimaryGhost : primaryGhost;

  static Color pendingBgOf(BuildContext context) =>
      isDark(context) ? darkPendingBg : pendingBg;

  static Color pendingBorderOf(BuildContext context) =>
      isDark(context) ? darkPendingBorder : pendingBorder;

  static Color acceptedBgOf(BuildContext context) =>
      isDark(context) ? darkAcceptedBg : acceptedBg;

  static Color acceptedBorderOf(BuildContext context) =>
      isDark(context) ? darkAcceptedBorder : acceptedBorder;

  static Color declinedBgOf(BuildContext context) =>
      isDark(context) ? darkDeclinedBg : declinedBg;

  static Color declinedBorderOf(BuildContext context) =>
      isDark(context) ? darkDeclinedBorder : declinedBorder;

  static Color infoBgOf(BuildContext context) =>
      isDark(context) ? darkInfoBg : infoBg;

  static Color infoBorderOf(BuildContext context) =>
      isDark(context) ? darkInfoBorder : infoBorder;

  static Color warningBgOf(BuildContext context) =>
      isDark(context) ? darkWarningBg : warningBg;

  static Color warningBorderOf(BuildContext context) =>
      isDark(context) ? darkWarningBorder : warningBorder;

  static Color accentGoldOf(BuildContext context) =>
      isDark(context) ? accentGoldOnDark : accentGold;

  static Color accentGoldBgOf(BuildContext context) =>
      isDark(context) ? darkAccentGoldBg : accentGoldBg;

  static Color accentGoldBorderOf(BuildContext context) =>
      isDark(context) ? darkAccentGoldBorder : accentGoldBorder;

  static Color inputBorderOf(BuildContext context) =>
      isDark(context) ? darkInputBorder : inputBorder;

  static Color glassSurfaceOf(BuildContext context) => isDark(context)
      ? darkSurface.withValues(alpha: 0.68)
      : glassSurfaceLight;

  static Color glassBorderOf(BuildContext context) => isDark(context)
      ? Colors.white.withValues(alpha: 0.18)
      : glassBorderLight;

  static BoxDecoration glassDecorationOf(
    BuildContext context, {
    double radius = radiusLg,
    Color? color,
    Color? borderColor,
    double borderWidth = 1.0,
    List<BoxShadow>? boxShadow,
  }) =>
      glassDecoration(
        radius: radius,
        color: color ?? glassSurfaceOf(context),
        borderColor: borderColor ?? glassBorderOf(context),
        borderWidth: borderWidth,
        boxShadow: boxShadow,
      );

  static List<BoxShadow> cardShadowOf(BuildContext context) => isDark(context)
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ]
      : cardShadow;

  static BoxDecoration cardDecorationOf(
    BuildContext context, {
    double radius = radiusLg,
    bool withBorder = true,
  }) =>
      BoxDecoration(
        color: surfaceOf(context),
        borderRadius: BorderRadius.circular(radius),
        border: withBorder ? Border.all(color: cardBorderOf(context)) : null,
        boxShadow: cardShadowOf(context),
      );

  // ─── Theme ────────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        surface: surface,
        brightness: Brightness.light,
      ).copyWith(
        primary: primary,
        onPrimary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        outline: cardBorder,
      ),
      scaffoldBackgroundColor: background,
      cardColor: surface,
      dividerColor: cardBorder,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.poppins(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryLight, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: surface,
          foregroundColor: primary,
          elevation: 0,
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: cardBorder),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        surface: darkSurface,
        brightness: Brightness.dark,
      ).copyWith(
        primary: darkPrimary,
        onPrimary: Colors.white,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        outline: darkCardBorder,
      ),
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkSurface,
      dividerColor: darkCardBorder,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: darkTextPrimary,
        displayColor: darkTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: darkTextPrimary),
        titleTextStyle: GoogleFonts.poppins(
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: darkCardBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        titleTextStyle: GoogleFonts.poppins(
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.poppins(
          color: darkTextSecondary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceVariant,
        hintStyle: const TextStyle(color: darkTextMuted),
        labelStyle: const TextStyle(color: darkTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: darkInputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: darkInputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: darkPrimary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: darkSurface,
          foregroundColor: darkPrimary,
          elevation: 0,
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: darkCardBorder),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Notification Style Value Object ─────────────────────────────────────────
/// Immutable fg/bg/border/icon bundle for one notification category (F-NOT-03).
class NotificationStyle {
  const NotificationStyle({
    required this.color,
    required this.bg,
    required this.border,
    required this.icon,
  });

  /// Foreground / icon colour.
  final Color color;

  /// Chip / container background.
  final Color bg;

  /// Hairline border.
  final Color border;

  /// Leading glyph for list tiles and badges.
  final IconData icon;
}

// ─── Status Badge Helper ─────────────────────────────────────────────────────
extension RequestStatusStyle on RequestStatus {
  Color get color {
    switch (this) {
      case RequestStatus.pending:  return AppTheme.pending;
      case RequestStatus.accepted: return AppTheme.accepted;
      case RequestStatus.declined: return AppTheme.declined;
    }
  }

  Color get bgColor {
    switch (this) {
      case RequestStatus.pending:  return AppTheme.pendingBg;
      case RequestStatus.accepted: return AppTheme.acceptedBg;
      case RequestStatus.declined: return AppTheme.declinedBg;
    }
  }

  Color get borderColor {
    switch (this) {
      case RequestStatus.pending:  return AppTheme.pendingBorder;
      case RequestStatus.accepted: return AppTheme.acceptedBorder;
      case RequestStatus.declined: return AppTheme.declinedBorder;
    }
  }

  String get label {
    switch (this) {
      case RequestStatus.pending:  return 'Pending';
      case RequestStatus.accepted: return 'Accepted';
      case RequestStatus.declined: return 'Declined';
    }
  }

  IconData get icon {
    switch (this) {
      case RequestStatus.pending:  return Icons.schedule_outlined;
      case RequestStatus.accepted: return Icons.check_circle_outlined;
      case RequestStatus.declined: return Icons.cancel_outlined;
    }
  }
}

enum RequestStatus { pending, accepted, declined }