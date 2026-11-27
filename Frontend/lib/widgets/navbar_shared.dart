import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tassist/theme/app_theme.dart';

class NavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  const NavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

class NavbarShell extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<Animation<double>>? scaleAnimations;
  final List<Animation<double>>? labelAnimations;

  static const double outerRadius = 32.0;
  static const double innerRadius = 27.0;
  static const double barHeight = 68.0;

  const NavbarShell({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.scaleAnimations,
    this.labelAnimations,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          height: barHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(outerRadius),
            boxShadow: AppTheme.floatingShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(outerRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: AppTheme.glassDecorationOf(
                  context,
                  radius: outerRadius,
                  color: AppTheme.surfaceOf(context).withValues(alpha: 0.92),
                  borderWidth: 1.4,
                ),
                child: Row(
                  children: List.generate(items.length, (i) {
                    return Expanded(
                      child: _NavbarItemWidget(
                        item: items[i],
                        isActive: currentIndex == i,
                        onTap: () => onTap(i),
                        scaleAnimation:
                            scaleAnimations != null && i < scaleAnimations!.length
                                ? scaleAnimations![i]
                                : null,
                        labelAnimation:
                            labelAnimations != null && i < labelAnimations!.length
                                ? labelAnimations![i]
                                : null,
                      ),
                    );
                  }),
                ),
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
  final VoidCallback onTap;
  final Animation<double>? scaleAnimation;
  final Animation<double>? labelAnimation;

  const _NavbarItemWidget({
    required this.item,
    required this.isActive,
    required this.onTap,
    this.scaleAnimation,
    this.labelAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppTheme.primary;
    final inactiveIconColor = AppTheme.textPrimaryOf(context);

    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isActive ? (item.activeIcon ?? item.icon) : item.icon,
          size: 22,
          color: isActive ? Colors.white : inactiveIconColor,
        ),
        const SizedBox(height: 2),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.white : inactiveIconColor,
            fontSize: 11.5,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            height: 1.1,
          ),
        ),
      ],
    );

    if (scaleAnimation != null) {
      content = AnimatedBuilder(
        animation: scaleAnimation!,
        builder: (context, child) => Transform.scale(
          scale: scaleAnimation!.value,
          child: child,
        ),
        child: content,
      );
    }

    return Semantics(
      button: true,
      selected: isActive,
      label: item.label,
      child: Tooltip(
        message: item.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(NavbarShell.innerRadius),
            focusColor: AppTheme.primary.withValues(alpha: 0.16),
            hoverColor: AppTheme.primary.withValues(alpha: 0.08),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(NavbarShell.innerRadius),
              ),
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }
}
