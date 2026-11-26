import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:tassist/widgets/app_snackbars.dart';

import 'api_config.dart';

/// Thrown when the session is no longer valid and the user has to log in again.
///
/// The redirect / snackbar is already triggered when this is thrown, so UI
/// layers only need to swallow it (or ignore its message).
class SessionExpiredException implements Exception {
  const SessionExpiredException();

  @override
  String toString() => 'Sesi telah berakhir. Silakan login kembali.';
}

/// Typed error thrown by [ApiClient] for every failed request.
///
/// Replaces the previous pattern of hand-decoding the response body in each
/// service.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.errors});

  /// Builds an exception from the standard backend envelope
  /// (`{success, message, errors?}`).
  factory ApiException.fromBody(Map<String, dynamic> body, int statusCode) {
    final message = body['message']?.toString() ?? 'Request gagal.';
    final rawErrors = body['errors'];

    Map<String, dynamic>? errors;
    final details = <String>[];

    if (rawErrors is Map) {
      errors = rawErrors.map((key, value) => MapEntry(key.toString(), value));

      errors.forEach((_, value) {
        if (value is List) {
          details.addAll(value.map((item) => item.toString()));
        } else if (value != null) {
          details.add(value.toString());
        }
      });
    }

    return ApiException(
      details.isEmpty ? message : '$message\n${details.join('\n')}',
      statusCode: statusCode,
      errors: errors,
    );
  }

  /// Human readable (Indonesian) message from the server.
  final String message;

  /// HTTP status code, or `null` for connection / timeout failures.
  final int? statusCode;

  /// Validation errors, keyed by field name, when the server sent them.
  final Map<String, dynamic>? errors;

  /// Keeps the legacy `Exception: <message>` string shape so existing UI code
  /// (`e.toString().replaceFirst('Exception: ', '')`) renders the same copy.
  @override
  String toString() => 'Exception: $message';
}

/// Secure-storage backed token cache shared by [ApiClient] and `AuthService`.
///
/// `AuthService` remains the owner of the whole session (role, nama, …); this
/// class only reads / writes the bearer token so a refresh can persist the new
/// token without a circular dependency on the auth layer.
class AuthTokenStore {
  AuthTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String tokenKey = 'token';

  final FlutterSecureStorage _storage;

  String? _cached;
  bool _loaded = false;

  /// Current bearer token, or `null` when the user is not logged in.
  Future<String?> read() async {
    if (_loaded) return _cached;

    final value = await _storage.read(key: tokenKey);
    _cached = (value == null || value.isEmpty) ? null : value;
    _loaded = true;

    return _cached;
  }

  /// Persists [token] and updates the in-memory cache.
  Future<void> write(String? token) async {
    final normalized = (token == null || token.isEmpty) ? null : token;
    _cached = normalized;
    _loaded = true;

    if (normalized == null) {
      await _storage.delete(key: tokenKey);
    } else {
      await _storage.write(key: tokenKey, value: normalized);
    }
  }

  /// Drops every stored auth key (token, role, user_id, nama, email).
  Future<void> clearAll() async {
    _cached = null;
    _loaded = true;
    await _storage.deleteAll();
  }
}

/// A single file part for [ApiClient.multipart].
class ApiFile {
  const ApiFile({
    required this.field,
    required this.filename,
    this.bytes,
    this.path,
  });

  /// File already loaded in memory (web / picked bytes).
  factory ApiFile.fromBytes(String field, List<int> bytes, String filename) =>
      ApiFile(field: field, filename: filename, bytes: bytes);

  /// File on disk (mobile / desktop).
  factory ApiFile.fromPath(String field, String path, String filename) =>
      ApiFile(field: field, filename: filename, path: path);

  final String field;
  final String filename;
  final List<int>? bytes;
  final String? path;
}

/// The single HTTP entry point for the whole app.
///
/// Responsibilities:
/// * builds the URL from [ApiConfig.baseUrl],
/// * always sends `Accept: application/json` and the bearer token when present,
/// * on `401` refreshes the Sanctum token once (`POST /refresh-token`) and
///   replays the original request exactly once,
/// * when the refresh also fails, clears the session, redirects to `/` and
///   shows the "Sesi telah berakhir" snackbar ([expireSession]),
/// * decodes the JSON envelope and throws [ApiException] on failure.
class ApiClient {
  ApiClient._();

  /// App-wide singleton.
  static final ApiClient instance = ApiClient._();

  /// Timeout applied to every request (including the refresh + replay).
  Duration timeout = const Duration(seconds: 30);

  /// Overrides [ApiConfig.baseUrl]; mainly useful for tests.
  String? baseUrlOverride;

  String get baseUrl => baseUrlOverride ?? ApiConfig.baseUrl;

  /// Global navigator key — must be assigned to `MaterialApp.navigatorKey`.
  final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Bearer token storage (shared with `AuthService`).
  final AuthTokenStore tokenStore = AuthTokenStore();

  /// Optional hook run right before the local session is cleared — e.g. to
  /// sign out of Google. Must not perform HTTP calls.
  Future<void> Function()? onSessionExpired;

  Future<String?>? _refreshInFlight;
  Future<void>? _expireInFlight;

  // ── Public verbs ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool authenticated = true,
    bool retryOnUnauthorized = true,
    bool expireSessionOnUnauthorized = true,
  }) =>
      _send(
        'GET',
        path,
        query: query,
        authenticated: authenticated,
        retryOnUnauthorized: retryOnUnauthorized,
        expireSessionOnUnauthorized: expireSessionOnUnauthorized,
      );

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool authenticated = true,
    bool retryOnUnauthorized = true,
    bool expireSessionOnUnauthorized = true,
  }) =>
      _send(
        'POST',
        path,
        query: query,
        body: body,
        authenticated: authenticated,
        retryOnUnauthorized: retryOnUnauthorized,
        expireSessionOnUnauthorized: expireSessionOnUnauthorized,
      );

  Future<Map<String, dynamic>> put(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool authenticated = true,
    bool retryOnUnauthorized = true,
    bool expireSessionOnUnauthorized = true,
  }) =>
      _send(
        'PUT',
        path,
        query: query,
        body: body,
        authenticated: authenticated,
        retryOnUnauthorized: retryOnUnauthorized,
        expireSessionOnUnauthorized: expireSessionOnUnauthorized,
      );

  Future<Map<String, dynamic>> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool authenticated = true,
    bool retryOnUnauthorized = true,
    bool expireSessionOnUnauthorized = true,
  }) =>
      _send(
        'DELETE',
        path,
        query: query,
        body: body,
        authenticated: authenticated,
        retryOnUnauthorized: retryOnUnauthorized,
        expireSessionOnUnauthorized: expireSessionOnUnauthorized,
      );

  /// `multipart/form-data` request (file uploads, `_method` spoofing, …).
  Future<Map<String, dynamic>> multipart(
    String method,
    String path, {
    Map<String, String> fields = const {},
    List<ApiFile> files = const [],
    Map<String, dynamic>? query,
    bool authenticated = true,
    bool retryOnUnauthorized = true,
    bool expireSessionOnUnauthorized = true,
  }) =>
      _send(
        method,
        path,
        query: query,
        fields: fields,
        files: files,
        authenticated: authenticated,
        retryOnUnauthorized: retryOnUnauthorized,
        expireSessionOnUnauthorized: expireSessionOnUnauthorized,
      );

  // ── Session handling ──────────────────────────────────────────────────────

  /// Clears the local session, redirects to `/` and shows the "session
  /// expired" snackbar. Safe to call from anywhere (including non-widget code).
  ///
  /// Concurrent calls share the same redirect.
  Future<void> expireSession() {
    return _expireInFlight ??=
        _performExpireSession().whenComplete(() => _expireInFlight = null);
  }

  Future<void> _performExpireSession() async {
    // 1. Capture navigator state before any async work.
    final nav = navigatorKey.currentState;

    // 2. Optional extra cleanup (Google sign-out) + wipe stored session.
    try {
      await onSessionExpired?.call();
    } catch (e) {
      debugPrint('ApiClient: onSessionExpired cleanup error: $e');
    }
    try {
      await tokenStore.clearAll();
    } catch (e) {
      debugPrint('ApiClient: tokenStore.clearAll error: $e');
    }

    // 3. Navigate to login (clearing the entire stack) + snackbar.
    if (nav == null) return;

    nav.pushNamedAndRemoveUntil('/', (_) => false);

    // The navigator state was captured before the awaits above, so the overlay
    // context is still valid; the lint cannot see that through the global key.
    final overlayContext = nav.overlay?.context;
    if (overlayContext != null) {
      // ignore: use_build_context_synchronously
      AppSnackBars.error(
        overlayContext,
        'Sesi telah berakhir. Silakan login kembali.',
      );
    }
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('$baseUrl$path');

    if (query == null || query.isEmpty) return uri;

    final cleanQuery = <String, String>{};

    query.forEach((key, value) {
      if (value != null && value.toString().trim().isNotEmpty) {
        cleanQuery[key] = value.toString();
      }
    });

    if (cleanQuery.isEmpty) return uri;

    return uri.replace(queryParameters: cleanQuery);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, String>? fields,
    List<ApiFile>? files,
    bool authenticated = true,
    bool retryOnUnauthorized = true,
    bool expireSessionOnUnauthorized = true,
  }) async {
    final request = _Request(
      method: method,
      uri: _uri(path, query),
      body: body,
      fields: fields,
      files: files,
    );

    final token = authenticated ? await tokenStore.read() : null;

    if (authenticated && (token == null || token.isEmpty)) {
      throw const ApiException(
        'Token tidak ditemukan. Silakan login ulang.',
        statusCode: 401,
      );
    }

    var response = await _execute(request, token);

    if (authenticated && response.statusCode == 401) {
      if (!retryOnUnauthorized) {
        if (expireSessionOnUnauthorized) await expireSession();
        throw const SessionExpiredException();
      }

      final refreshedToken = await _refreshToken(failedToken: token);

      if (refreshedToken == null) {
        if (expireSessionOnUnauthorized) await expireSession();
        throw const SessionExpiredException();
      }

      // Replay the original request exactly once with the fresh token.
      response = await _execute(request, refreshedToken);

      if (response.statusCode == 401) {
        if (expireSessionOnUnauthorized) await expireSession();
        throw const SessionExpiredException();
      }
    }

    return _decode(response);
  }

  Future<http.Response> _execute(_Request request, String? token) async {
    try {
      return await request.send(token).timeout(timeout);
    } on TimeoutException {
      throw const ApiException('Koneksi ke server timeout. Silakan coba lagi.');
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException('Gagal terhubung ke server: $error');
    }
  }

  /// Refreshes the bearer token once. Returns `null` when the refresh fails
  /// (invalid / expired token, network error, …).
  ///
  /// Concurrent 401s share a single refresh call.
  Future<String?> _refreshToken({String? failedToken}) {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    return _refreshInFlight = _performRefresh(failedToken: failedToken)
        .whenComplete(() => _refreshInFlight = null);
  }

  Future<String?> _performRefresh({String? failedToken}) async {
    try {
      final current = await tokenStore.read();

      if (current == null || current.isEmpty) return null;

      // Another request already refreshed while this one was in flight.
      if (failedToken != null && current != failedToken) return current;

      final response = await http
          .post(
            Uri.parse('$baseUrl/refresh-token'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $current',
            },
          )
          .timeout(timeout);

      if (response.statusCode != 200) return null;

      final decoded = _tryDecode(response.body);
      final data = decoded?['data'];

      final newToken =
          data is Map ? data['token']?.toString().trim() : null;

      if (newToken == null || newToken.isEmpty) return null;

      await tokenStore.write(newToken);

      return newToken;
    } catch (e) {
      debugPrint('ApiClient: Token refresh request failed: $e');
      return null;
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = _tryDecode(response.body);

    if (decoded == null) {
      // Tolerate empty bodies (e.g. 204 / no content).
      if (response.body.trim().isEmpty) return const <String, dynamic>{};

      throw ApiException(
        'Response server tidak valid. Status: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final isHttpSuccess =
        response.statusCode >= 200 && response.statusCode < 300;

    if (!isHttpSuccess || decoded['success'] == false) {
      throw ApiException.fromBody(decoded, response.statusCode);
    }

    return decoded;
  }

  /// Returns the decoded JSON object, or `null` when the body is empty or not
  /// JSON (e.g. an HTML error page).
  Map<String, dynamic>? _tryDecode(String body) {
    if (body.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(body);

      if (decoded is Map) return Map<String, dynamic>.from(decoded);

      return null;
    } catch (e) {
      debugPrint('ApiClient: JSON decode failed: $e');
      return null;
    }
  }
}

/// One HTTP call, replayable with a different bearer token.
class _Request {
  _Request({
    required this.method,
    required this.uri,
    this.body,
    this.fields,
    this.files,
  });

  final String method;
  final Uri uri;
  final Object? body;
  final Map<String, String>? fields;
  final List<ApiFile>? files;

  bool get isMultipart => fields != null || files != null;

  Future<http.Response> send(String? token) async {
    final headers = <String, String>{'Accept': 'application/json'};

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (isMultipart) {
      final request = http.MultipartRequest(method, uri);
      request.headers.addAll(headers);

      if (fields != null) request.fields.addAll(fields!);

      for (final file in files ?? const <ApiFile>[]) {
        if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              file.field,
              file.bytes!,
              filename: file.filename,
            ),
          );
        } else if (file.path != null && file.path!.isNotEmpty) {
          request.files.add(
            await http.MultipartFile.fromPath(
              file.field,
              file.path!,
              filename: file.filename,
            ),
          );
        } else {
          throw const ApiException('File tidak valid atau tidak bisa dibaca.');
        }
      }

      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    }

    final payload = body == null ? null : jsonEncode(body);
    if (payload != null) headers['Content-Type'] = 'application/json';

    switch (method.toUpperCase()) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(uri, headers: headers, body: payload);
      case 'PUT':
        return http.put(uri, headers: headers, body: payload);
      case 'PATCH':
        return http.patch(uri, headers: headers, body: payload);
      case 'DELETE':
        return http.delete(uri, headers: headers, body: payload);
      default:
        throw ApiException('Metode HTTP tidak didukung: $method');
    }
  }
}
