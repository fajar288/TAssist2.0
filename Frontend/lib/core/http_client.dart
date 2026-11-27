import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';

export 'api_client.dart' show SessionExpiredException;

/// Thin backwards-compatible facade over [ApiClient].
///
/// All HTTP work (auth header, 401 refresh + retry, logout redirect) now lives
/// in `core/api_client.dart`. This class is kept so existing imports -
/// `MaterialApp.navigatorKey` in `app/app.dart` - keep working.
class AuthHttpClient {
  AuthHttpClient._();

  /// Global navigator key - must be assigned to `MaterialApp.navigatorKey`.
  static GlobalKey<NavigatorState> get navigatorKey =>
      ApiClient.instance.navigatorKey;

  /// Returns `true` if the response indicates an expired / invalid token.
  static bool isUnauthorized(http.Response response) =>
      response.statusCode == 401;

  /// Clears the session, redirects to `/` and shows the "session expired"
  /// snackbar. Delegates to [ApiClient.expireSession].
  static Future<void> handleUnauthorized() => ApiClient.instance.expireSession();
}
