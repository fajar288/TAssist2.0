import 'package:flutter/material.dart';
import 'package:tassist/features/dosen/view/home_screen.dart';
import 'package:tassist/widgets/custom_bottom_nav.dart';
import 'package:tassist/features/dosen/view/schedule_list_screen.dart';
import 'package:tassist/features/dosen/view/student_list_screen.dart';

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
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}