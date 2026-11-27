import 'dart:ui'; // Diperlukan untuk ImageFilter
import 'package:flutter/material.dart';
import 'package:tassist/theme/app_theme.dart';

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
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: AppTheme.glassDecorationOf(
                context,
                radius: AppTheme.radiusLg,
                borderWidth: 1.2,
                boxShadow: AppTheme.cardShadow,
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

  @override
  Widget build(BuildContext context) {
    final activeColor = AppTheme.primaryOf(context);
    final activeBg = AppTheme.primaryGhostOf(context);
    final inactiveColor = AppTheme.textMutedOf(context);

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
                color: isActive ? activeBg : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: 24,
                    color: isActive ? activeColor : inactiveColor,
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
                            style: TextStyle(
                              color: activeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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