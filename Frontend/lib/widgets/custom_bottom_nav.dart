// lib/widgets/custom_bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:tassist/widgets/navbar_shared.dart';

// ─── Wrapper ──────────────────────────────────────────────────────────────────
// Gunakan DosenNavbarWrapper sebagai body Scaffold (bukan bottomNavigationBar)
// agar BackdropFilter blur bisa bekerja.
class DosenNavbarWrapper extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Widget child;

  const DosenNavbarWrapper({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: CustomBottomNav(
            currentIndex: currentIndex,
            onTap: onTap,
          ),
        ),
      ],
    );
  }
}

// ─── Navbar ───────────────────────────────────────────────────────────────────
class CustomBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  // Konsisten dengan NavbarShell: capsule height 68 + bottom padding 16 (+ buffer)
  static const double navBarHeight = 84.0;
  static const double bottomPadding = 16.0;
  static const double totalHeight = navBarHeight;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _labelAnimations;

  static const List<NavItem> _items = [
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
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
      label: 'Mahasiswa',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _controllers[widget.currentIndex].forward();
  }

  void _initAnimations() {
    _controllers = List.generate(
      _items.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 220),
      ),
    );

    _scaleAnimations = _controllers.map((ctrl) {
      return Tween<double>(begin: 1.0, end: 1.04).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic),
      );
    }).toList();

    _labelAnimations = _controllers.map((ctrl) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeOut),
      );
    }).toList();
  }

  @override
  void didUpdateWidget(CustomBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _controllers[oldWidget.currentIndex].reverse();
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    for (final ctrl in _controllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavbarShell(
      items: _items,
      currentIndex: widget.currentIndex,
      onTap: widget.onTap,
      scaleAnimations: _scaleAnimations,
      labelAnimations: _labelAnimations,
    );
  }
}
