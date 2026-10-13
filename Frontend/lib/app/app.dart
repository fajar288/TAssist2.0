import 'package:flutter/material.dart';
import '../core/http_client.dart';
import '../features/auth/view/login_page.dart';
import '../features/loglearning/view/learning_placeholder_page.dart';
import '../features/dosen/view/dashboard_dosen_page.dart';
import '../features/main_mahasiswa/main_mahasiswa_page.dart';
import '../features/splash/splash_screen.dart';
import '../features/auth/view/complete_student_profile_page.dart';
import '../theme/app_theme.dart';

class TAssistApp extends StatelessWidget {
  const TAssistApp({super.key});

  // ── Named Routes ────────────────────────────────────────────────────────────
  static const String splashRoute         = '/splash';
  static const String loginRoute          = '/';
  static const String dashboardRoute      = '/dashboard-mahasiswa';
  static const String dashboardDosenRoute = '/dashboard-dosen';   // ← counselor home
  static const String learningRoute       = '/learning';
  static const String completeStudentProfileRoute = '/complete-student-profile';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AuthHttpClient.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'TAssist',

      // ── Use the full premium theme instead of bare ThemeData ───────────────
      theme: AppTheme.lightTheme,

      initialRoute: splashRoute,
      routes: {
        splashRoute: (_) => SplashScreen(
          destinationBuilder: (_) => const LoginPage(),
        ),
        loginRoute:          (_) => const LoginPage(),
        dashboardRoute:      (_) => const DashboardMahasiswaWrapper(),
        dashboardDosenRoute: (_) => const DashboardDosenPage(),   
        learningRoute:       (_) => const LearningPlaceholderPage(),
        completeStudentProfileRoute: (_) => const CompleteStudentProfilePage(),
      },
    );
  }
}

// ── Keeps the student-side wrapper exactly as before ──────────────────────────
class DashboardMahasiswaWrapper extends StatelessWidget {
  const DashboardMahasiswaWrapper({super.key});

  @override
  Widget build(BuildContext context) => const MainMahasiswaPage();
}