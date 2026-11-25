import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// Manages Firebase Cloud Messaging (FCM) initialization and device-token
/// registration with the Laravel backend (T-42 / F-NOT-04).
///
/// Initialization is guarded so local builds and widget tests without
/// `google-services.json` / `GoogleService-Info.plist` degrade safely.
class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  final ApiClient _client = ApiClient.instance;

  bool _initialized = false;
  bool _firebaseReady = false;
  String? _lastRegisteredToken;
  StreamSubscription<String>? _tokenRefreshSub;

  bool get isFirebaseReady => _firebaseReady;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();
      _firebaseReady = true;

      _tokenRefreshSub ??=
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        if (newToken.isNotEmpty) {
          _sendTokenToBackend(newToken);
        }
      });
    } catch (e) {
      _firebaseReady = false;
      debugPrint('FcmService: Firebase.initializeApp skipped/unavailable: $e');
    }
  }

  Future<void> registerCurrentDevice() async {
    if (!_initialized) {
      await init();
    }
    if (!_firebaseReady) return;

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('FcmService: registerCurrentDevice failed: $e');
    }
  }

  Future<void> deregisterCurrentDevice() async {
    try {
      await _client.delete(
        '/device-token',
        body: _lastRegisteredToken != null
            ? {'token': _lastRegisteredToken}
            : null,
        retryOnUnauthorized: false,
        expireSessionOnUnauthorized: false,
      );
      _lastRegisteredToken = null;
    } catch (e) {
      debugPrint('FcmService: deregisterCurrentDevice failed: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    final platform = _detectPlatform();
    try {
      await _client.post(
        '/device-token',
        body: {
          'token': token,
          'platform': platform,
        },
        retryOnUnauthorized: false,
        expireSessionOnUnauthorized: false,
      );
      _lastRegisteredToken = token;
    } catch (e) {
      debugPrint('FcmService: _sendTokenToBackend failed: $e');
    }
  }

  String _detectPlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'android';
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }
}
