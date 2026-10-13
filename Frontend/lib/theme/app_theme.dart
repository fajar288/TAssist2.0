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