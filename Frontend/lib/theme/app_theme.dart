// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── Core Palette ────────────────────────────────────────────────────────────
  static const Color primary       = Color(0xFF4338CA); // Deep Indigo
  static const Color primaryLight  = Color(0xFF6366F1); // Indigo-500
  static const Color primaryGhost  = Color(0xFFEEF2FF); // Indigo-50
  static const Color background    = Color(0xFFF1F5F9); // Slate-100
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color textPrimary   = Color(0xFF1E1B4B); // Indigo-950
  static const Color textSecondary = Color(0xFF64748B); // Slate-500
  static const Color textMuted     = Color(0xFF94A3B8); // Slate-400

  // ─── Semantic Colors ─────────────────────────────────────────────────────────
  static const Color pending     = Color(0xFFF59E0B); // Amber-400
  static const Color pendingBg   = Color(0xFFFFFBEB); // Amber-50
  static const Color pendingBorder = Color(0xFFFDE68A); // Amber-200

  static const Color accepted    = Color(0xFF10B981); // Emerald-500
  static const Color acceptedBg  = Color(0xFFECFDF5); // Emerald-50
  static const Color acceptedBorder = Color(0xFFA7F3D0); // Emerald-200

  static const Color declined    = Color(0xFFEF4444); // Rose-500
  static const Color declinedBg  = Color(0xFFFFF1F2); // Rose-50
  static const Color declinedBorder = Color(0xFFFFCDD2); // Rose-200

  // ─── Info / Caution (S8.1) ───────────────────────────────────────────────────
  static const Color info          = Color(0xFF3B82F6); // S8.1 info - Blue-500
  static const Color infoBg        = Color(0xFFEFF6FF); // S8.1 info background - Blue-50
  static const Color infoBorder    = Color(0xFFBFDBFE); // S8.1 info border - Blue-200

  static const Color warning       = Color(0xFFD97706); // S8.1 caution - Amber-600 (distinct from pending)
  static const Color warningBg     = Color(0xFFFFFBEB); // S8.1 caution background - Amber-50
  static const Color warningBorder = Color(0xFFFDE68A); // S8.1 caution border - Amber-200

  // ─── Surfaces (S8.1) ─────────────────────────────────────────────────────────
  static const Color surfaceVariant = Color(0xFFF8FAFC); // S8.1 inset surface - Slate-50
  static const Color cardBorder     = Color(0xFFE2E8F0); // S8.1 card hairline border - Slate-200

  // ─── Annotation Status (S8.3) ────────────────────────────────────────────────
  static const Color annotationOpen          = Color(0xFFF59E0B); // S8.3 annotation open - Amber-500
  static const Color annotationOpenBg        = Color(0xFFFFFBEB); // S8.3 annotation open background - Amber-50
  static const Color annotationOpenBorder    = Color(0xFFFDE68A); // S8.3 annotation open border - Amber-200

  static const Color annotationRevised       = Color(0xFF3B82F6); // S8.3 annotation revised - Blue-500
  static const Color annotationRevisedBg     = Color(0xFFEFF6FF); // S8.3 annotation revised background - Blue-50
  static const Color annotationRevisedBorder = Color(0xFFBFDBFE); // S8.3 annotation revised border - Blue-200

  static const Color annotationResolved       = Color(0xFF10B981); // S8.3 annotation resolved - Emerald-500
  static const Color annotationResolvedBg     = Color(0xFFECFDF5); // S8.3 annotation resolved background - Emerald-50
  static const Color annotationResolvedBorder = Color(0xFFA7F3D0); // S8.3 annotation resolved border - Emerald-200

  // ─── Risk Level (S8.4) ───────────────────────────────────────────────────────
  static const Color riskSafe          = Color(0xFF10B981); // S8.4 risk aman - Emerald-500
  static const Color riskSafeBg        = Color(0xFFECFDF5); // S8.4 risk aman background - Emerald-50
  static const Color riskSafeBorder    = Color(0xFFA7F3D0); // S8.4 risk aman border - Emerald-200

  static const Color riskAttention       = Color(0xFFF59E0B); // S8.4 risk perlu_perhatian - Amber-500
  static const Color riskAttentionBg     = Color(0xFFFFFBEB); // S8.4 risk perlu_perhatian background - Amber-50
  static const Color riskAttentionBorder = Color(0xFFFDE68A); // S8.4 risk perlu_perhatian border - Amber-200

  static const Color riskAtRisk       = Color(0xFFEF4444); // S8.4 risk berisiko - Rose-500
  static const Color riskAtRiskBg     = Color(0xFFFFF1F2); // S8.4 risk berisiko background - Rose-50
  static const Color riskAtRiskBorder = Color(0xFFFFCDD2); // S8.4 risk berisiko border - Rose-200

  // ─── Chat (S8.5) ─────────────────────────────────────────────────────────────
  static const Color chatUserText        = Color(0xFFFFFFFF); // S8.5 user bubble text
  static const Color chatUserBubble      = Color(0xFF4338CA); // S8.5 user bubble - primary
  static const Color chatAssistantText   = Color(0xFF1E1B4B); // S8.5 assistant bubble text - textPrimary
  static const Color chatAssistantBubble = Color(0xFFF1F5F9); // S8.5 assistant bubble - Slate-100
  static const Color chatCitation        = Color(0xFF6366F1); // S8.5 source citation - primaryLight
  static const Color chatCitationBg      = Color(0xFFEEF2FF); // S8.5 source citation background - primaryGhost
  static const Color chatRefusal         = Color(0xFFF59E0B); // S8.5 refusal indicator - Amber-500
  static const Color chatRefusalBg       = Color(0xFFFFFBEB); // S8.5 refusal indicator background - Amber-50

  // ─── Notification Types (F-NOT-03) ───────────────────────────────────────────
  static const Color notificationInfo          = Color(0xFF3B82F6); // F-NOT-03 info - Blue-500
  static const Color notificationInfoBg        = Color(0xFFEFF6FF); // F-NOT-03 info background - Blue-50
  static const Color notificationInfoBorder    = Color(0xFFBFDBFE); // F-NOT-03 info border - Blue-200

  static const Color notificationSuccess       = Color(0xFF10B981); // F-NOT-03 success - Emerald-500
  static const Color notificationSuccessBg     = Color(0xFFECFDF5); // F-NOT-03 success background - Emerald-50
  static const Color notificationSuccessBorder = Color(0xFFA7F3D0); // F-NOT-03 success border - Emerald-200

  static const Color notificationWarning       = Color(0xFFD97706); // F-NOT-03 warning - Amber-600 (caution)
  static const Color notificationWarningBg     = Color(0xFFFFFBEB); // F-NOT-03 warning background - Amber-50
  static const Color notificationWarningBorder = Color(0xFFFDE68A); // F-NOT-03 warning border - Amber-200

  static const Color notificationError         = Color(0xFFEF4444); // F-NOT-03 error - Rose-500
  static const Color notificationErrorBg       = Color(0xFFFFF1F2); // F-NOT-03 error background - Rose-50
  static const Color notificationErrorBorder   = Color(0xFFFFCDD2); // F-NOT-03 error border - Rose-200

  static const Color notificationNeutral       = Color(0xFF64748B); // F-NOT-03 neutral - textSecondary
  static const Color notificationNeutralBg     = Color(0xFFF8FAFC); // F-NOT-03 neutral background - Slate-50
  static const Color notificationNeutralBorder = Color(0xFFE2E8F0); // F-NOT-03 neutral border - Slate-200

  // ─── Card Shadow ─────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF4338CA).withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 10),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get subtleShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get avatarGlow => [
        BoxShadow(
          color: const Color(0xFF4338CA).withOpacity(0.25),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ];

  // ─── Decoration Helpers ───────────────────────────────────────────────────────
  static BoxDecoration cardDecoration({double radius = 20}) => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: cardShadow,
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
    icon: Icons.info_outline_rounded,
  );

  static const NotificationStyle notificationSuccessStyle = NotificationStyle(
    color: notificationSuccess,
    bg: notificationSuccessBg,
    border: notificationSuccessBorder,
    icon: Icons.check_circle_outline_rounded,
  );

  static const NotificationStyle notificationWarningStyle = NotificationStyle(
    color: notificationWarning,
    bg: notificationWarningBg,
    border: notificationWarningBorder,
    icon: Icons.warning_amber_rounded,
  );

  static const NotificationStyle notificationErrorStyle = NotificationStyle(
    color: notificationError,
    bg: notificationErrorBg,
    border: notificationErrorBorder,
    icon: Icons.error_outline_rounded,
  );

  static const NotificationStyle notificationNeutralStyle = NotificationStyle(
    color: notificationNeutral,
    bg: notificationNeutralBg,
    border: notificationNeutralBorder,
    icon: Icons.notifications_none_rounded,
  );

  // ─── Theme ────────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        background: background,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
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
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
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
      case RequestStatus.pending:  return Icons.schedule_rounded;
      case RequestStatus.accepted: return Icons.check_circle_rounded;
      case RequestStatus.declined: return Icons.cancel_rounded;
    }
  }
}

enum RequestStatus { pending, accepted, declined }