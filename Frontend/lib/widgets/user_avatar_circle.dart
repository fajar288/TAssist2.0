import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tassist/core/helpers/avatar_helper.dart';
import 'package:tassist/theme/app_theme.dart';

/// Shared circular user avatar supporting local preview bytes, remote `/api/v1/avatar` URLs,
/// external HTTPS URLs, and a crisp initials fallback.
class UserAvatarCircle extends StatelessWidget {
  const UserAvatarCircle({
    super.key,
    required this.name,
    this.avatar,
    this.localBytes,
    this.size = 56,
    this.borderColor,
    this.borderWidth = 2,
    this.showShadow = false,
  });

  final String name;
  final String? avatar;
  final Uint8List? localBytes;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final bool showShadow;

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasLocal = localBytes != null && localBytes!.isNotEmpty;
    final hasRemote = AvatarHelper.hasAvatar(avatar);
    final effectiveBorder = borderColor ?? Colors.white.withValues(alpha: 0.7);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primary,
        border: borderWidth > 0
            ? Border.all(color: effectiveBorder, width: borderWidth)
            : null,
      ),
      child: ClipOval(
        child: hasLocal
            ? Image.memory(
                localBytes!,
                width: size,
                height: size,
                fit: BoxFit.cover,
              )
            : hasRemote
                ? Image.network(
                    AvatarHelper.getAvatarUrl(avatar: avatar),
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallback(),
                  )
                : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      color: AppTheme.primary,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
