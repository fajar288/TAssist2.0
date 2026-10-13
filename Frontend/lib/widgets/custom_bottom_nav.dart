// lib/widgets/custom_bottom_nav.dart
import 'dart:ui';
import 'package:flutter/material.dart';

// ─── Wrapper ──────────────────────────────────────────────────────────────────
// Gunakan DosenNavbarWrapper sebagai body Scaffold (bukan bottomNavigationBar)
// agar BackdropFilter blur bisa bekerja.
//
// Contoh:
//   Scaffold(
//     body: DosenNavbarWrapper(
//       currentIndex: _index,
//       onTap: (i) => setState(() => _index = i),
//       child: _pages[_index],
//     ),
//   )
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

  // Sama dengan NavbarShell: height 95, padding bawah 16
  static const double navBarHeight  = 95.0;
  static const double bottomPadding = 16.0;
  static const double totalHeight   = navBarHeight; // total sudah termasuk padding dalam

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

  static const _items = [
    _NavItem(icon: Icons.home_rounded,             label: 'home'),
    _NavItem(icon: Icons.calendar_month_rounded,   label: 'schedule'),
    _NavItem(icon: Icons.person_rounded,           label: 'students'),
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
      return Tween<double>(begin: 1.0, end: 1.1).animate(
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
  void didUpdateWidget(CustomBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _controllers[oldWidget.currentIndex].reverse();
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    for (final ctrl in _controllers) ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Identik dengan NavbarShell: SizedBox 95, padding fromLTRB(16,0,16,16)
    return SizedBox(
      height: CustomBottomNav.navBarHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_items.length, (i) {
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onTap(i),
                      child: _NavItemWidget(
                        item: _items[i],
                        isActive: widget.currentIndex == i,
                        scaleAnimation: _scaleAnimations[i],
                        labelAnimation: _labelAnimations[i],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Nav Item Widget ──────────────────────────────────────────────────────────
class _NavItemWidget extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final Animation<double> scaleAnimation;
  final Animation<double> labelAnimation;

  // Warna identik dengan NavbarShell
  static const Color _activeColor   = Color(0xFF0D4AA3);
  static const Color _inactiveColor = Color(0xFF2D3238);

  const _NavItemWidget({
    required this.item,
    required this.isActive,
    required this.scaleAnimation,
    required this.labelAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([scaleAnimation, labelAnimation]),
      builder: (context, _) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width:  isActive ? 110 : 60,
              height: isActive ? 60  : 50,
              decoration: BoxDecoration(
                color: isActive ? _activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: _activeColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: 24,
                    color: isActive ? Colors.white : _inactiveColor,
                  ),
                  if (isActive)
                    Flexible(
                      child: FadeTransition(
                        opacity: labelAnimation,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            item.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Nav Item Model ───────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}