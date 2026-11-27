import 'package:flutter/material.dart';
import '../core/http_client.dart';
import '../features/auth/view/login_page.dart';
import '../features/auth/view/complete_student_profile_page.dart';
import '../features/auth/view/edit_student_profile_page.dart';
import '../features/chatbot/view/chatbot_conversation_list_page.dart';
import '../features/chatbot/view/chatbot_page.dart';
import '../features/loglearning/view/learning_placeholder_page.dart';
import '../features/dosen/view/dashboard_dosen_page.dart';
import '../features/main_mahasiswa/main_mahasiswa_page.dart';
import '../features/splash/splash_screen.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

class TAssistApp extends StatelessWidget {
  const TAssistApp({super.key});

  // ── Named Routes ────────────────────────────────────────────────────────────
  static const String splashRoute         = '/splash';
  static const String loginRoute          = '/';
  static const String dashboardRoute      = '/dashboard-mahasiswa';
  static const String dashboardDosenRoute = '/dashboard-dosen';   // ← counselor home
  static const String learningRoute       = '/learning';
  static const String completeStudentProfileRoute = '/complete-student-profile';
  static const String editStudentProfileRoute     = '/edit-student-profile';
  static const String chatbotRoute        = '/chatbot';
  static const String chatbotHistoryRoute = '/chatbot-history';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: AuthHttpClient.navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'TAssist',

          // ── Use light + dark theme controlled by ThemeController (T-68) ────
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.instance.themeMode,

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
            editStudentProfileRoute: (_) => const EditStudentProfilePage(
              initialProfile: {},
            ),
            chatbotRoute:        (_) => const ChatbotPage(),
            chatbotHistoryRoute: (_) => const ChatbotConversationListPage(),
          },
        );
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