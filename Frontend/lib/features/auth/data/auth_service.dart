import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/api_client.dart';
import '../../../core/api_config.dart';

class AuthService {
  AuthService() {
    // On an unrecoverable 401 the ApiClient clears the session itself; this
    // hook keeps the previous behaviour of also signing out of Google.
    ApiClient.instance.onSessionExpired = _signOutGoogleQuietly;
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiClient _client = ApiClient.instance;

  static bool _isGoogleInitialized = false;
  static Future<void>? _googleInitFuture;

  Future<void> initGoogleSignIn() async {
    if (_isGoogleInitialized) return;

    if (_googleInitFuture != null) {
      await _googleInitFuture;
      return;
    }

    if (kIsWeb) {
      _googleInitFuture = GoogleSignIn.instance.initialize(
        clientId: ApiConfig.googleClientId,
      );
    } else {
      _googleInitFuture = GoogleSignIn.instance.initialize(
        serverClientId: ApiConfig.googleServerClientId,
      );
    }

    try {
      await _googleInitFuture;
      _isGoogleInitialized = true;
    } catch (_) {
      _googleInitFuture = null;
      _isGoogleInitialized = false;
      rethrow;
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      return const AuthResult(
        isSuccess: false,
        message: 'Email dan password wajib diisi.',
      );
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(normalizedEmail)) {
      return const AuthResult(
        isSuccess: false,
        message: 'Format email tidak valid.',
      );
    }

    try {
      // Login must never carry a bearer token nor trigger a token refresh.
      final data = await _client.post(
        '/login',
        authenticated: false,
        body: {
          'email': normalizedEmail,
          'password': normalizedPassword,
        },
      );

      final result = _parseAuthResult(data);

      if (result.token != null) {
        await _saveAuthData(result);
      }

      return result;
    } on ApiException catch (e) {
      return AuthResult(
        isSuccess: false,
        message: e.message,
      );
    } on SessionExpiredException catch (e) {
      return AuthResult(
        isSuccess: false,
        message: e.toString(),
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  Future<AuthResult> loginWithGoogle() async {
    if (kIsWeb) {
      return const AuthResult(
        isSuccess: false,
        message:
            'Pada Flutter Web, login Google harus menggunakan tombol resmi Google.',
      );
    }

    try {
      await initGoogleSignIn();

      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        return const AuthResult(
          isSuccess: false,
          message:
              'ID Token Google kosong. Cek Web Client ID dan konfigurasi Google Cloud.',
        );
      }

      return loginWithGoogleIdToken(idToken);
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'Login Google gagal: $e',
      );
    }
  }

  Future<AuthResult> loginWithGoogleIdToken(String idToken) async {
    try {
      final data = await _client.post(
        '/login/google',
        authenticated: false,
        body: {
          'id_token': idToken,
        },
      );

      final result = _parseAuthResult(data);

      if (result.token != null) {
        await _saveAuthData(result);
      }

      return result;
    } on ApiException catch (e) {
      return AuthResult(
        isSuccess: false,
        message: e.message,
      );
    } on SessionExpiredException catch (e) {
      return AuthResult(
        isSuccess: false,
        message: e.toString(),
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'Login Google gagal: $e',
      );
    }
  }

  AuthResult _parseAuthResult(Map<String, dynamic> data) {
    final responseData = data['data'];

    String? token;
    String? role;
    int? userId;
    String? nama;
    String? email;
    Map<String, dynamic>? profile;

    if (responseData is Map<String, dynamic>) {
      token = responseData['token']?.toString();

      final user = responseData['user'];
      if (user is Map<String, dynamic>) {
        userId = int.tryParse(user['user_id']?.toString() ?? '');
        nama = user['nama']?.toString();
        email = user['email']?.toString();
        role = user['role']?.toString().trim().toLowerCase();
      }

      final rawProfile = responseData['profile'];
      if (rawProfile is Map<String, dynamic>) {
        profile = rawProfile;
      }
    }

    return AuthResult(
      isSuccess: data['success'] == true,
      message: data['message']?.toString() ?? 'Berhasil.',
      token: token,
      role: role,
      userId: userId,
      nama: nama,
      email: email,
      profile: profile,
    );
  }

  Future<void> _saveAuthData(AuthResult result) async {
    // The token lives in the shared token store so ApiClient can read it and
    // persist refreshed tokens.
    await _client.tokenStore.write(result.token);
    await _storage.write(key: 'role', value: result.role);
    await _storage.write(key: 'user_id', value: result.userId?.toString());
    await _storage.write(key: 'nama', value: result.nama);
    await _storage.write(key: 'email', value: result.email);
  }

  Future<String?> getToken() {
    return _client.tokenStore.read();
  }

  Future<String?> getRole() async {
    return _storage.read(key: 'role');
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();

    if (token == null) return null;

    try {
      return await _client.get('/profile');
    } catch (_) {
      return null;
    }
  }

  Future<AuthResult> completeMahasiswaProfile({
    required String nim,
    required String prodi,
    required int angkatan,
    String? topikTa,
    String? judulTa,
  }) async {
    final token = await getToken();

    if (token == null) {
      return const AuthResult(
        isSuccess: false,
        message: 'Token tidak ditemukan. Silakan login ulang.',
      );
    }

    try {
      final data = await _client.post(
        '/mahasiswa/complete-profile',
        body: {
          'nim': nim.trim(),
          'prodi': prodi.trim(),
          'angkatan': angkatan,
          'topik_ta': topikTa?.trim().isEmpty == true ? null : topikTa?.trim(),
          'judul_ta': judulTa?.trim().isEmpty == true ? null : judulTa?.trim(),
        },
      );

      final responseData = data['data'];

      Map<String, dynamic>? profile;

      if (responseData is Map<String, dynamic> &&
          responseData['profile'] is Map<String, dynamic>) {
        profile = Map<String, dynamic>.from(responseData['profile']);
      }

      return AuthResult(
        isSuccess: true,
        message:
            data['message']?.toString() ?? 'Profil mahasiswa berhasil dilengkapi.',
        role: 'mahasiswa',
        profile: profile,
      );
    } on ApiException catch (e) {
      return AuthResult(
        isSuccess: false,
        message: e.message,
      );
    } on SessionExpiredException catch (e) {
      return AuthResult(
        isSuccess: false,
        message: e.toString(),
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  Future<AuthResult> updateMahasiswaProfile({
    String? topikTa,
    String? judulTa,
  }) async {
    final token = await getToken();

    if (token == null) {
      return const AuthResult(
        isSuccess: false,
        message: 'Token tidak ditemukan. Silakan login ulang.',
      );
    }

    try {
      final data = await _client.put(
        '/mahasiswa/profile',
        body: {
          'topik_ta': topikTa?.trim().isEmpty == true ? null : topikTa?.trim(),
          'judul_ta': judulTa?.trim().isEmpty == true ? null : judulTa?.trim(),
        },
      );

      final responseData = data['data'];

      Map<String, dynamic>? profile;

      if (responseData is Map<String, dynamic> &&
          responseData['profile'] is Map<String, dynamic>) {
        profile = Map<String, dynamic>.from(responseData['profile']);
      }

      return AuthResult(
        isSuccess: true,
        message: data['message']?.toString() ??
            'Profil mahasiswa berhasil diperbarui.',
        role: 'mahasiswa',
        profile: profile,
      );
    } on ApiException catch (e) {
      return AuthResult(
        isSuccess: false,
        message: e.message,
      );
    } on SessionExpiredException catch (e) {
      return AuthResult(
        isSuccess: false,
        message: e.toString(),
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  Future<void> logout() async {
    final token = await getToken();

    if (token != null) {
      try {
        // Best effort only: no refresh, no redirect when the token is stale.
        await _client.post(
          '/logout',
          retryOnUnauthorized: false,
          expireSessionOnUnauthorized: false,
        );
      } catch (_) {
        // Kalau server tidak bisa dihubungi, local session tetap dibersihkan.
      }
    }

    await _signOutGoogleQuietly();

    await _client.tokenStore.clearAll();
  }

  Future<void> _signOutGoogleQuietly() async {
    try {
      if (_isGoogleInitialized) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {
      // Aman diabaikan kalau user tidak login lewat Google.
    }
  }
}

class AuthResult {
  final bool isSuccess;
  final String message;
  final String? role;
  final String? token;
  final int? userId;
  final String? nama;
  final String? email;
  final Map<String, dynamic>? profile;

  const AuthResult({
    required this.isSuccess,
    required this.message,
    this.role,
    this.token,
    this.userId,
    this.nama,
    this.email,
    this.profile,
  });

  bool get needCompleteMahasiswaProfile {
    return role == 'mahasiswa' && profile == null;
  }
}
