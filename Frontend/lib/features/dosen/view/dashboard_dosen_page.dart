import 'package:flutter/material.dart';
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
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}