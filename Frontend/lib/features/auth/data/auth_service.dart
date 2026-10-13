import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../../core/api_config.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': normalizedEmail,
          'password': normalizedPassword,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final result = _parseAuthResult(data);

        if (result.token != null) {
          await _saveAuthData(result);
        }

        return result;
      }

      return AuthResult(
        isSuccess: false,
        message: data['message']?.toString() ?? 'Email atau password salah.',
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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/login/google'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_token': idToken,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final result = _parseAuthResult(data);

        if (result.token != null) {
          await _saveAuthData(result);
        }

        return result;
      }

      return AuthResult(
        isSuccess: false,
        message: data['message']?.toString() ?? 'Login Google gagal.',
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
    await _storage.write(key: 'token', value: result.token);
    await _storage.write(key: 'role', value: result.role);
    await _storage.write(key: 'user_id', value: result.userId?.toString());
    await _storage.write(key: 'nama', value: result.nama);
    await _storage.write(key: 'email', value: result.email);
  }

  Future<String?> getToken() async {
    return _storage.read(key: 'token');
  }

  Future<String?> getRole() async {
    return _storage.read(key: 'role');
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();

    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/profile'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/mahasiswa/complete-profile'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nim': nim.trim(),
          'prodi': prodi.trim(),
          'angkatan': angkatan,
          'topik_ta': topikTa?.trim().isEmpty == true ? null : topikTa?.trim(),
          'judul_ta': judulTa?.trim().isEmpty == true ? null : judulTa?.trim(),
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        final responseData = data['data'];

        Map<String, dynamic>? profile;

        if (responseData is Map<String, dynamic> &&
            responseData['profile'] is Map<String, dynamic>) {
          profile = Map<String, dynamic>.from(responseData['profile']);
        }

        return AuthResult(
          isSuccess: true,
          message: data['message']?.toString() ??
              'Profil mahasiswa berhasil dilengkapi.',
          role: 'mahasiswa',
          profile: profile,
        );
      }

      return AuthResult(
        isSuccess: false,
        message: data['message']?.toString() ??
            'Gagal melengkapi profil mahasiswa.',
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
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/logout'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (_) {
        // Kalau server tidak bisa dihubungi, local session tetap dibersihkan.
      }
    }

    try {
      if (_isGoogleInitialized) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {
      // Aman diabaikan kalau user tidak login lewat Google.
    }

    await _storage.deleteAll();
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