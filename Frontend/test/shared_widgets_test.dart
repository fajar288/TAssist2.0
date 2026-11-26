import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tassist/theme/app_theme.dart';
import 'package:tassist/widgets/app_empty_state_widget.dart';
import 'package:tassist/widgets/app_error_widget.dart';
import 'package:tassist/widgets/app_loading_widget.dart';
import 'package:tassist/widgets/app_skeleton_loader.dart';
import 'package:tassist/widgets/app_snackbars.dart';

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
}
