import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_empty_state_widget.dart';
import '../../widgets/app_error_widget.dart';
import '../../widgets/app_loading_widget.dart';
import 'navbar_mahasiswa.dart';
import '../lecturer_selection/view/lecturer_selection_dashboard_page.dart';
import 'package:tassist/features/main_mahasiswa/data/mahasiswa_service.dart';
import 'dashboard_main_mahasiswa_page.dart';
import 'schedule_page.dart';
import 'upload_document_page.dart';

class MainMahasiswaPage extends StatefulWidget {
  const MainMahasiswaPage({super.key});

  @override
  State<MainMahasiswaPage> createState() => _MainMahasiswaPageState();
}

class _MainMahasiswaPageState extends State<MainMahasiswaPage> {
  final MahasiswaService _mahasiswaService = MahasiswaService();

  late Future<bool> _hasActiveBimbinganFuture;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _hasActiveBimbinganFuture = _mahasiswaService.hasActiveBimbingan();
  }

  void _reloadBimbinganStatus() {
    setState(() {
      _hasActiveBimbinganFuture = _mahasiswaService.hasActiveBimbingan();
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildLockedFeaturePage(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOf(context),
      body: AppEmptyStateWidget(
        icon: Icons.lock_outline_rounded,
        title: 'Pilih Dosen Pembimbing Dahulu',
        subtitle:
            'Jadwal bimbingan dan unggah dokumen akan terbuka setelah permohonan pembimbing Anda disetujui.',
        actionLabel: 'Cari Dosen Pembimbing',
        onAction: () => _onTabTapped(0),
      ),
    );
  }

  Widget _buildLoadingPage(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOf(context),
      body: const Center(
        child: AppLoadingWidget(),
      ),
    );
  }

  Widget _buildErrorPage(BuildContext context, Object error) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOf(context),
      body: AppErrorWidget(
        title: 'Failed to load student dashboard',
        message: error.toString().replaceFirst('Exception: ', ''),
        retryLabel: 'Try Again',
        onRetry: _reloadBimbinganStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasActiveBimbinganFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingPage(context);
        }

        if (snapshot.hasError) {
          return _buildErrorPage(context, snapshot.error!);
        }

        final bool hasActiveBimbingan = snapshot.data ?? false;

        final List<Widget> pages = hasActiveBimbingan
            ? [
                const DashboardMainMahasiswaPage(),
                const SchedulePage(),
                const UploadDocumentPage(),
              ]
            : [
                const LecturerSelectionDashboardPage(),
                _buildLockedFeaturePage(context),
                _buildLockedFeaturePage(context),
              ];

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: NavbarMahasiswa(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
          ),
          extendBody: true,
        );
      },
    );
  }
}