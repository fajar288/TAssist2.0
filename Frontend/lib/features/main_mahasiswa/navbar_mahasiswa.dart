import 'package:flutter/material.dart';
import '../../widgets/navbar_shared.dart'; 

class NavbarMahasiswa extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavbarMahasiswa({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<NavbarMahasiswa> createState() => _NavbarMahasiswaState();
}

class _NavbarMahasiswaState extends State<NavbarMahasiswa>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _labelAnimations;

  final List<NavItem> _items = [
    const NavItem(icon: Icons.home_rounded, label: 'home'),
    const NavItem(icon: Icons.calendar_month_rounded, label: 'schedule'),
    const NavItem(icon: Icons.upload_file_rounded, label: 'upload'),
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
        duration: const Duration(milliseconds: 300),
      ),
    );

    _scaleAnimations = _controllers.map((ctrl) {
      return Tween<double>(begin: 1.0, end: 1.1).animate( // Perkecil sedikit end scale agar tidak overflow
        CurvedAnimation(parent: ctrl, curve: Curves.easeOutBack),
      );
    }).toList();

    _labelAnimations = _controllers.map((ctrl) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void didUpdateWidget(NavbarMahasiswa oldWidget) {
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