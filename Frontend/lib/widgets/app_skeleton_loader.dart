import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tassist/theme/app_theme.dart';

enum _SkeletonVariant { card, list, profile, custom }

/// Shimmer skeleton loader powered by `flutter_animate` and [AppTheme] tokens.
class AppSkeletonLoader extends StatelessWidget {
  const AppSkeletonLoader.card({
    super.key,
    this.count = 3,
    this.padding = const EdgeInsets.all(16),
  })  : _variant = _SkeletonVariant.card,
        width = null,
        height = null,
        borderRadius = AppTheme.radiusLg,
        child = null;

  const AppSkeletonLoader.list({
    super.key,
    this.count = 5,
    this.padding = const EdgeInsets.all(16),
  })  : _variant = _SkeletonVariant.list,
        width = null,
        height = null,
        borderRadius = AppTheme.radiusMd,
        child = null;

  const AppSkeletonLoader.profile({
    super.key,
    this.padding = const EdgeInsets.all(16),
  })  : _variant = _SkeletonVariant.profile,
        count = 1,
        width = null,
        height = null,
        borderRadius = AppTheme.radiusLg,
        child = null;

  const AppSkeletonLoader.custom({
    super.key,
    this.width,
    this.height,
    this.borderRadius = AppTheme.radiusMd,
    this.child,
    this.padding = EdgeInsets.zero,
  })  : _variant = _SkeletonVariant.custom,
        count = 1;

  final _SkeletonVariant _variant;
  final int count;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final double borderRadius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final skeletonBody = switch (_variant) {
      _SkeletonVariant.card => _buildCardSkeletons(),
      _SkeletonVariant.list => _buildListSkeletons(),
      _SkeletonVariant.profile => _buildProfileSkeleton(),
      _SkeletonVariant.custom => child ??
          _SkeletonBox(
            width: width ?? double.infinity,
            height: height ?? 80,
            radius: borderRadius,
          ),
    };

    return Padding(
      padding: padding,
      child: skeletonBody
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            duration: 1200.ms,
            color: AppTheme.surface.withValues(alpha: 0.72),
          ),
    );
  }

  Widget _buildCardSkeletons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SkeletonBox(
                      width: 44,
                      height: 44,
                      radius: AppTheme.radiusMd,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SkeletonBox(width: 160, height: 14, radius: AppTheme.radiusSm),
                          SizedBox(height: 8),
                          _SkeletonBox(width: 110, height: 11, radius: AppTheme.radiusSm),
                        ],
                      ),
                    ),
                    _SkeletonBox(width: 64, height: 24, radius: AppTheme.radiusSm),
                  ],
                ),
                SizedBox(height: 14),
                _SkeletonBox(width: double.infinity, height: 12, radius: AppTheme.radiusSm),
                SizedBox(height: 8),
                _SkeletonBox(width: 220, height: 12, radius: AppTheme.radiusSm),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildListSkeletons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Row(
              children: [
                _SkeletonBox(width: 40, height: 40, radius: AppTheme.radiusMd),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(width: 180, height: 13, radius: AppTheme.radiusSm),
                      SizedBox(height: 7),
                      _SkeletonBox(width: 120, height: 10, radius: AppTheme.radiusSm),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                _SkeletonBox(width: 22, height: 22, radius: AppTheme.radiusSm),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProfileSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _SkeletonBox(width: 64, height: 64, radius: AppTheme.radiusLg),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 170, height: 16, radius: AppTheme.radiusSm),
                    SizedBox(height: 8),
                    _SkeletonBox(width: 120, height: 12, radius: AppTheme.radiusSm),
                    SizedBox(height: 8),
                    _SkeletonBox(width: 90, height: 22, radius: AppTheme.radiusSm),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          _SkeletonBox(width: double.infinity, height: 12, radius: AppTheme.radiusSm),
          SizedBox(height: 8),
          _SkeletonBox(width: double.infinity, height: 12, radius: AppTheme.radiusSm),
          SizedBox(height: 8),
          _SkeletonBox(width: 200, height: 12, radius: AppTheme.radiusSm),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.cardBorder,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
