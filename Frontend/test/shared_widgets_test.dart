import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tassist/features/auth/view/login_page.dart';
import 'package:tassist/theme/app_theme.dart';
import 'package:tassist/widgets/app_empty_state_widget.dart';
import 'package:tassist/widgets/app_error_widget.dart';
import 'package:tassist/widgets/app_loading_widget.dart';
import 'package:tassist/widgets/app_skeleton_loader.dart';
import 'package:tassist/widgets/app_snackbars.dart';
import 'package:tassist/widgets/custom_bottom_nav.dart';
import 'package:tassist/widgets/navbar_shared.dart';

void main() {
  group('AppLoadingWidget', () {
    testWidgets('renders centered spinner and optional message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLoadingWidget(message: 'Memuat data...'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Memuat data...'), findsOneWidget);
    });

    testWidgets('supports compact mode without message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLoadingWidget(compact: true, size: 20),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('AppEmptyStateWidget', () {
    testWidgets('renders title, subtitle, icon, and invokes action', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyStateWidget(
              title: 'Belum ada data',
              subtitle: 'Tambahkan item baru untuk memulai.',
              icon: Icons.folder_open_rounded,
              actionLabel: 'Tambah',
              onAction: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.folder_open_rounded), findsOneWidget);
      expect(find.text('Belum ada data'), findsOneWidget);
      expect(find.text('Tambahkan item baru untuk memulai.'), findsOneWidget);

      await tester.tap(find.text('Tambah'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('AppErrorWidget', () {
    testWidgets('renders title, message, and triggers onRetry', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget(
              title: 'Gagal Memuat',
              message: 'Koneksi bermasalah',
              retryLabel: 'Coba Lagi',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('Gagal Memuat'), findsOneWidget);
      expect(find.text('Koneksi bermasalah'), findsOneWidget);

      await tester.tap(find.text('Coba Lagi'));
      await tester.pump();
      expect(retried, isTrue);
    });
  });

  group('AppSkeletonLoader', () {
    testWidgets('renders card, list, profile, and custom variants', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  AppSkeletonLoader.card(count: 2),
                  AppSkeletonLoader.list(count: 2),
                  AppSkeletonLoader.profile(),
                  AppSkeletonLoader.custom(width: 120, height: 24),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(AppSkeletonLoader), findsNWidgets(4));

      // Clear widget tree cleanly so repeating animation timers are disposed.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });

  group('AppSnackBars', () {
    testWidgets('shows top floating overlay banner for semantic tones and dismisses', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      AppSnackBars.success(capturedContext, 'Berhasil disimpan', title: 'Sukses');
      await tester.pump();
      expect(find.text('Berhasil disimpan'), findsOneWidget);
      expect(find.text('Sukses'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      AppSnackBars.error(capturedContext, 'Terjadi kesalahan');
      await tester.pump();
      expect(find.text('Berhasil disimpan'), findsNothing);
      expect(find.text('Terjadi kesalahan'), findsOneWidget);
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);

      // Tap close icon to dismiss
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(find.text('Terjadi kesalahan'), findsNothing);

      AppSnackBars.info(capturedContext, 'Informasi singkat');
      await tester.pump();
      expect(find.text('Informasi singkat'), findsOneWidget);

      AppSnackBars.warning(capturedContext, 'Perhatian');
      await tester.pump();
      expect(find.text('Perhatian'), findsOneWidget);

      AppSnackBars.dismiss();
      await tester.pump();
      expect(find.text('Perhatian'), findsNothing);
    });

    testWidgets('falls back to ScaffoldMessenger when no Overlay exists', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ScaffoldMessenger(
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  capturedContext = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      AppSnackBars.info(capturedContext, 'Fallback snackbar');
      await tester.pump();

      expect(find.text('Fallback snackbar'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor,
        AppTheme.info,
      );
    });
  });

  group('NavbarShell & CustomBottomNav', () {
    const items = [
      NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Beranda',
      ),
      NavItem(
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month_rounded,
        label: 'Jadwal',
      ),
      NavItem(
        icon: Icons.upload_file_outlined,
        activeIcon: Icons.upload_file_rounded,
        label: 'Unggah',
      ),
    ];

    testWidgets(
      'renders frosted glass capsule, active navy pill with filled icon, and labels on all tabs',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        var currentIndex = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  bottomNavigationBar: NavbarShell(
                    items: items,
                    currentIndex: currentIndex,
                    onTap: (index) => setState(() => currentIndex = index),
                  ),
                );
              },
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(BackdropFilter), findsOneWidget);
        expect(find.text('Beranda'), findsOneWidget);
        expect(find.text('Jadwal'), findsOneWidget);
        expect(find.text('Unggah'), findsOneWidget);
        expect(find.byIcon(Icons.home_rounded), findsOneWidget);
        expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);

        await tester.tap(find.byIcon(Icons.calendar_month_outlined));
        await tester.pumpAndSettle();

        expect(currentIndex, 1);
        expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
        expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      },
    );

    testWidgets('CustomBottomNav switches tabs and supports dark mode without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var selected = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                bottomNavigationBar: CustomBottomNav(
                  currentIndex: selected,
                  onTap: (index) => setState(() => selected = index),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(NavbarShell), findsOneWidget);
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Jadwal'), findsOneWidget);
      expect(find.text('Mahasiswa'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.groups_outlined));
      await tester.pumpAndSettle();

      expect(selected, 2);
      expect(find.byIcon(Icons.groups_rounded), findsOneWidget);
    });
  });

  group('LoginPage visual layout & glass sheet', () {
    testWidgets(
      'renders navy backdrop, brand card without eyebrow pill, Indonesian form, and frosted glass without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginPage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('KAMPUS DIGITAL'), findsNothing);
        expect(find.text('TAssist'), findsOneWidget);
        expect(find.text('Sistem Bimbingan Tugas Akhir'), findsOneWidget);
        expect(find.text('Masuk'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Kata Sandi'), findsOneWidget);
        expect(find.text('Lanjutkan'), findsOneWidget);
        expect(find.byType(BackdropFilter), findsAtLeastNWidgets(2));

        // Verify Masuk sits at the top of the bottom form above Email
        expect(
          tester.getTopLeft(find.text('Masuk')).dy,
          lessThan(tester.getTopLeft(find.text('Email')).dy),
        );
        expect(
          tester.getTopLeft(find.text('TAssist')).dy,
          lessThan(tester.getTopLeft(find.text('Masuk')).dy),
        );

        // Verify decorative scattered graduation caps were removed
        final decorativeCaps = tester
            .widgetList<Icon>(find.byIcon(Icons.school_outlined))
            .where((icon) => icon.size != null && icon.size! >= 30)
            .toList();
        expect(decorativeCaps, isEmpty);
      },
    );
  });
}
