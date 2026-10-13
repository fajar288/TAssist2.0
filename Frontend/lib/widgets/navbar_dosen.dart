import 'package:flutter/material.dart';
import 'navbar_shared.dart';

class NavbarDosen extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavbarDosen({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<NavbarDosen> createState() => _NavbarDosenState();
}

class _NavbarDosenState extends State<NavbarDosen>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _labelAnimations;

  // ── 3 tab dosen: Home / Manage Schedule / Manage Mahasiswa ──
  final List<NavItem> _items = [
    NavItem(icon: Icons.home_rounded,              label: 'home'),
    NavItem(icon: Icons.edit_calendar_rounded,     label: 'jadwal'),
    NavItem(icon: Icons.supervisor_account_rounded, label: 'mahasiswa'),
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
      return Tween<double>(begin: 1.0, end: 1.18).animate(
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
  void didUpdateWidget(NavbarDosen oldWidget) {
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