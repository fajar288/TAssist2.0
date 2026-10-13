import 'dart:ui'; // Diperlukan untuk ImageFilter
import 'package:flutter/material.dart';

class NavItem {
  final IconData icon;
  final String label;
  const NavItem({required this.icon, required this.label});
}

class NavbarShell extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final Function(int) onTap;
  final List<Animation<double>> scaleAnimations;
  final List<Animation<double>> labelAnimations;

  const NavbarShell({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.scaleAnimations,
    required this.labelAnimations,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 95, 
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), 
        child: ClipRRect( // ClipRRect dipindah ke luar agar efek blur tidak melebar
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter( // Widget kunci untuk efek blur di belakang
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                // Warna dibuat lebih transparan agar konten di belakang terlihat samar
                color: Colors.white.withOpacity(0.12), 
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2), // Border putih tipis memperkuat kesan kaca
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
                children: List.generate(items.length, (i) {
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: _NavbarItemWidget(
                        item: items[i],
                        isActive: currentIndex == i,
                        scaleAnimation: scaleAnimations[i],
                        labelAnimation: labelAnimations[i],
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

class _NavbarItemWidget extends StatelessWidget {
  final NavItem item;
  final bool isActive;
  final Animation<double> scaleAnimation;
  final Animation<double> labelAnimation;

  const _NavbarItemWidget({
    required this.item,
    required this.isActive,
    required this.scaleAnimation,
    required this.labelAnimation,
  });

  static const Color _activeColor = Color(0xFF0D4AA3);
  static const Color _inactiveColor = Color(0xFF2D3238); // Sedikit lebih soft dibanding hitam pekat

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
              width: isActive ? 110 : 60,
              height: isActive ? 60 : 50,
              decoration: BoxDecoration(
                // Tambahkan sedikit shadow pada pill aktif agar lebih pop-out
                color: isActive ? _activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: _activeColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : null,
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