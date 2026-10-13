import 'package:flutter/foundation.dart'
    show kIsWeb, TargetPlatform, defaultTargetPlatform;

/// Centralised API configuration — single source of truth for all URLs.
///
/// ### Setting a custom server URL
/// ```bash
/// flutter run --dart-define=API_URL=http://192.168.1.10:8000
/// ```
///
/// If `API_URL` is not provided the default is chosen per platform:
/// - **Web**     → `http://127.0.0.1:8000`
/// - **Android** → `http://10.0.2.2:8000` (emulator routes to host localhost)
/// - **Others**  → `http://127.0.0.1:8000`
class ApiConfig {
  const ApiConfig._();

  // ── Compile-time override via --dart-define ──────────────────────────────
  static const String _envUrl = String.fromEnvironment('API_URL');

  /// Root Laravel server URL.
  static String get serverUrl {
    if (_envUrl.isNotEmpty) return _envUrl;

    // Platform-aware defaults when no --dart-define is provided.
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  /// API v1 endpoint.
  static String get baseUrl => '$serverUrl/api/v1';

  /// Laravel public storage URL.
  static String get storageUrl => '$serverUrl/storage';

  /// Google OAuth
  static const String googleClientId =
      '170232690367-0a18spgd9sr6lc8o6usdeipplqc1u252.apps.googleusercontent.com';

  static const String googleServerClientId =
      '170232690367-0a18spgd9sr6lc8o6usdeipplqc1u252.apps.googleusercontent.com';
}