import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tassist/core/api_client.dart';
import 'package:tassist/features/auth/data/auth_service.dart';
import 'package:tassist/features/auth/view/edit_student_profile_page.dart';
import 'package:tassist/theme/app_theme.dart';
import 'package:tassist/theme/theme_controller.dart';
import 'package:tassist/widgets/user_avatar_circle.dart';

class _FakeStorage implements FlutterSecureStorage {
  const _FakeStorage(this.token);

  final String? token;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #read &&
        invocation.namedArguments[#key] == AuthTokenStore.tokenKey) {
      return Future<String?>.value(token);
    }
    return super.noSuchMethod(invocation);
  }
}

class _FakeApiClient implements ApiClient {
  @override
  final AuthTokenStore tokenStore =
      AuthTokenStore(storage: const _FakeStorage('valid-token'));
  String? lastMethod;
  String? lastPath;
  Object? lastBody;
  Map<String, String>? lastFields;
  List<ApiFile>? lastFiles;

  Map<String, dynamic> responseToReturn = {
    'success': true,
    'message': 'Profil mahasiswa berhasil diperbarui.',
    'data': {
      'profile': {
        'nim': '210001',
        'prodi': 'Informatika',
        'angkatan': 2021,
        'topik_ta': 'AI Bimbingan',
        'judul_ta': 'TAssist Mobile',
      },
      'user': {
        'user_id': 7,
        'nama': 'Budi Santoso',
        'avatar': 'avatars/budi.jpg',
      },
    },
  };

  @override
  Future<void> Function()? onSessionExpired;

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool authenticated = true,
    bool retryOnUnauthorized = true,
    bool expireSessionOnUnauthorized = true,
  }) async {
    lastMethod = 'PUT';
    lastPath = path;
    lastBody = body;
    return responseToReturn;
  }

  @override
  Future<Map<String, dynamic>> multipart(
    String method,
    String path, {
    Map<String, String> fields = const {},
    List<ApiFile> files = const [],
    Map<String, dynamic>? query,
    bool authenticated = true,
    bool retryOnUnauthorized = true,
    bool expireSessionOnUnauthorized = true,
  }) async {
    lastMethod = method;
    lastPath = path;
    lastFields = fields;
    lastFiles = files;
    return responseToReturn;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final Uint8List _samplePng1x1 = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('T-68 ThemeController & Dark Theme', () {
    test('defaults to ThemeMode.system and persists changes', () async {
      final controller = ThemeController.forTest();
      await controller.load();

      expect(controller.themeMode, ThemeMode.system);
      expect(controller.label, 'Ikuti Sistem');
      expect(controller.icon, Icons.brightness_auto_outlined);

      await controller.setThemeMode(ThemeMode.dark);
      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.label, 'Gelap');
      expect(controller.icon, Icons.dark_mode_outlined);

      final reloaded = ThemeController.forTest();
      await reloaded.load();
      expect(reloaded.themeMode, ThemeMode.dark);

      await reloaded.setThemeMode(ThemeMode.light);
      expect(reloaded.themeMode, ThemeMode.light);
      expect(reloaded.label, 'Terang');
      expect(reloaded.icon, Icons.light_mode_outlined);
    });

    test('AppTheme.darkTheme exposes dark tokens', () {
      final dark = AppTheme.darkTheme;
      expect(dark.brightness, Brightness.dark);
      expect(dark.scaffoldBackgroundColor, AppTheme.darkBackground);
      expect(dark.cardColor, AppTheme.darkSurface);
      expect(dark.colorScheme.brightness, Brightness.dark);
    });

    testWidgets('context-aware helpers switch tokens cleanly between light and dark',
        (tester) async {
      late bool darkDetected;
      late Color bgResolved;
      late Color surfaceResolved;
      late Color textResolved;
      late Color primaryResolved;

      Widget harness(ThemeMode mode) => MaterialApp(
            key: ValueKey(mode),
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: mode,
            themeAnimationDuration: Duration.zero,
            home: Builder(
              builder: (ctx) {
                darkDetected = AppTheme.isDark(ctx);
                bgResolved = AppTheme.backgroundOf(ctx);
                surfaceResolved = AppTheme.surfaceOf(ctx);
                textResolved = AppTheme.textPrimaryOf(ctx);
                primaryResolved = AppTheme.primaryOf(ctx);
                return const SizedBox.shrink();
              },
            ),
          );

      await tester.pumpWidget(harness(ThemeMode.light));
      await tester.pumpAndSettle();
      expect(darkDetected, isFalse);
      expect(bgResolved, AppTheme.background);
      expect(surfaceResolved, AppTheme.surface);
      expect(textResolved, AppTheme.textPrimary);
      expect(primaryResolved, AppTheme.primary);

      await tester.pumpWidget(harness(ThemeMode.dark));
      await tester.pumpAndSettle();
      expect(darkDetected, isTrue);
      expect(bgResolved, AppTheme.darkBackground);
      expect(surfaceResolved, AppTheme.darkSurface);
      expect(textResolved, AppTheme.darkTextPrimary);
      expect(primaryResolved, AppTheme.darkPrimary);
    });

    testWidgets('showThemeSelectorSheet switches ThemeMode on tap', (tester) async {
      final controller = ThemeController.forTest();
      await controller.load();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ThemeController.showThemeSelectorSheet(
                  ctx,
                  controller: controller,
                ),
                child: const Text('Buka Tema'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Tema'));
      await tester.pumpAndSettle();

      expect(find.text('Tema Tampilan'), findsOneWidget);
      expect(find.text('Mode Gelap'), findsOneWidget);

      await tester.tap(find.text('Mode Gelap'));
      await tester.pumpAndSettle();

      expect(controller.themeMode, ThemeMode.dark);
    });
  });

  group('T-69 Student Avatar Circle & Profile Upload', () {
    testWidgets('UserAvatarCircle shows initials fallback when avatar is null',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatarCircle(name: 'Budi Santoso'),
          ),
        ),
      );

      expect(find.text('BS'), findsOneWidget);
    });

    testWidgets('UserAvatarCircle displays MemoryImage when localBytes provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserAvatarCircle(
              name: 'Budi Santoso',
              localBytes: _samplePng1x1,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('BS'), findsNothing);
    });

    testWidgets('EditStudentProfilePage renders in dark mode and opens photo picker sheet',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const EditStudentProfilePage(
            initialProfile: {
              'nama': 'Budi Santoso',
              'nim': '210001',
              'prodi': 'Informatika',
              'angkatan': 2021,
              'topik_ta': 'Deep Learning',
              'judul_ta': 'Klasifikasi Citra',
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Profil Mahasiswa'), findsOneWidget);
      expect(find.text('Ubah Foto Profil'), findsOneWidget);
      expect(find.text('BS'), findsOneWidget);

      await tester.tap(find.text('Ubah Foto Profil'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih dari Galeri'), findsOneWidget);
    });

    test('AuthService.updateMahasiswaProfile uses multipart POST with _method=PUT when avatar bytes are sent',
        () async {
      final fakeClient = _FakeApiClient();
      final authService = AuthService(
        client: fakeClient,
        storage: const _FakeStorage('valid-token'),
      );

      final result = await authService.updateMahasiswaProfile(
        topikTa: 'AI Bimbingan',
        judulTa: 'TAssist Mobile',
        avatarBytes: _samplePng1x1,
        avatarFilename: 'foto.png',
      );

      expect(result.isSuccess, isTrue);
      expect(result.avatar, 'avatars/budi.jpg');
      expect(fakeClient.lastMethod, 'POST');
      expect(fakeClient.lastPath, '/mahasiswa/profile');
      expect(fakeClient.lastFields, {
        '_method': 'PUT',
        'topik_ta': 'AI Bimbingan',
        'judul_ta': 'TAssist Mobile',
      });
      expect(fakeClient.lastFiles, hasLength(1));
      expect(fakeClient.lastFiles!.first.field, 'avatar');
      expect(fakeClient.lastFiles!.first.filename, 'foto.png');
    });

    test('AuthService.updateMahasiswaProfile uses standard PUT JSON when no avatar is attached',
        () async {
      final fakeClient = _FakeApiClient();
      final authService = AuthService(
        client: fakeClient,
        storage: const _FakeStorage('valid-token'),
      );

      final result = await authService.updateMahasiswaProfile(
        topikTa: 'Topik Baru',
        judulTa: 'Judul Baru',
      );

      expect(result.isSuccess, isTrue);
      expect(fakeClient.lastMethod, 'PUT');
      expect(fakeClient.lastPath, '/mahasiswa/profile');
      expect(fakeClient.lastBody, {
        'topik_ta': 'Topik Baru',
        'judul_ta': 'Judul Baru',
      });
    });
  });
}
