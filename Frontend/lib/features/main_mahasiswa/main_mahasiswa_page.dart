import 'package:flutter/material.dart';

import 'navbar_mahasiswa.dart';
import '../lecturer_selection/view/lecturer_selection_dashboard_page.dart';
import '../../mahasiswa/data/mahasiswa_service.dart';
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

  Widget _buildLockedFeaturePage() {
    return const Scaffold(
      backgroundColor: Color(0xFFEEF2F6),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            "This feature is not available\nuntil you have an academic advisor",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingPage() {
    return const Scaffold(
      backgroundColor: Color(0xFFEEF2F6),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorPage(Object error) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 42,
              ),
              const SizedBox(height: 14),
              const Text(
                'Failed to load student dashboard',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF2D3238),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString().replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _reloadBimbinganStatus,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasActiveBimbinganFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingPage();
        }

        if (snapshot.hasError) {
          return _buildErrorPage(snapshot.error!);
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
                _buildLockedFeaturePage(),
                _buildLockedFeaturePage(),
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