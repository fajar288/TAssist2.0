import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../features/auth/data/auth_service.dart';

/// Provides a [GlobalKey<NavigatorState>] so any layer (including non-widget
/// code) can trigger navigation — e.g. redirecting to login on 401.
///
/// Wire this into `MaterialApp.navigatorKey` in `app.dart`.
class AuthHttpClient {
  AuthHttpClient._();

  /// Global navigator key — must be assigned to `MaterialApp.navigatorKey`.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Returns `true` if the response indicates an expired / invalid token.
  static bool isUnauthorized(http.Response response) =>
      response.statusCode == 401;

  /// Call this from any service's response handler when a 401 is detected.
  ///
  /// It will:
  /// 1. Clear all stored auth data.
  /// 2. Redirect to the login route (`/`).
  /// 3. Show a "Session expired" snackbar.
  static Future<void> handleUnauthorized() async {
    // 1. Capture navigator state before any async work.
    final nav = navigatorKey.currentState;

    // 2. Clear local session.
    final authService = AuthService();
    await authService.logout();

    // 3. Navigate to login (clearing the entire stack).
    if (nav != null) {
      nav.pushNamedAndRemoveUntil('/', (_) => false);

      // 4. Show a snackbar via the overlay context.
      final overlayContext = nav.overlay?.context;
      if (overlayContext != null) {
        ScaffoldMessenger.of(overlayContext).showSnackBar(
          SnackBar(
            content: const Text('Sesi telah berakhir. Silakan login kembali.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      }
    }
  }
}

/// Mixin for services that use `_decodeResponse`.
///
/// Add `with AuthInterceptorMixin` to your service class, then call
/// `await checkUnauthorized(response)` at the top of `_decodeResponse`.
///
/// ```dart
/// class MyService with AuthInterceptorMixin {
///   Map<String, dynamic> _decodeResponse(http.Response response) {
///     checkUnauthorized(response);   // ← add this line
///     ...existing logic...
///   }
/// }
/// ```
mixin AuthInterceptorMixin {
  /// Checks whether the server returned 401 and triggers logout + redirect.
  ///
  /// Throws a [SessionExpiredException] after handling so that callers
  /// don't continue processing the invalid response.
  void checkUnauthorized(http.Response response) {
    if (AuthHttpClient.isUnauthorized(response)) {
      // Fire-and-forget: the redirect happens asynchronously.
      AuthHttpClient.handleUnauthorized();
      throw SessionExpiredException();
    }
  }
}

/// Thrown when the server responds with 401.
///
/// Services should let this propagate; UI layers catch it to avoid showing
/// a confusing error message (the user is already being redirected).
class SessionExpiredException implements Exception {
  @override
  String toString() => 'Sesi telah berakhir. Silakan login kembali.';
}
