import 'package:flutter/material.dart';
import 'package:produk/app/app.dart';
import 'package:produk/theme/app_theme.dart';
import 'package:produk/screen/home_screen.dart';
import 'package:produk/widgets/custom_bottom_nav.dart';
import 'package:produk/screen/schedule_list_screen.dart';
import 'package:produk/screen/student_list_screen.dart';

class DashboardDosenPage extends StatefulWidget {
  const DashboardDosenPage({super.key});

  @override
  State<DashboardDosenPage> createState() => _DashboardDosenPageState();
}

class _DashboardDosenPageState extends State<DashboardDosenPage> {
  int _currentIndex = 0;

  // Halaman utama aplikasi sekarang bersih dari logika simulasi
  static const List<Widget> _pages = [
    HomeScreen(),
    ScheduleListScreen(),
    StudentListPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 76.0),
        child: FloatingActionButton(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          tooltip: 'Asisten TA',
          child: const Icon(Icons.smart_toy_rounded, size: 28),
          onPressed: () {
            Navigator.pushNamed(context, TAssistApp.chatbotRoute);
          },
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}