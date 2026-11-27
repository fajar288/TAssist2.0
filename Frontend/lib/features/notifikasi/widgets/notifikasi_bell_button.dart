import 'package:flutter/material.dart';
import 'package:tassist/theme/app_theme.dart';

import '../data/notifikasi_service.dart';
import '../view/notifikasi_page.dart';

class NotifikasiBellButton extends StatefulWidget {
  const NotifikasiBellButton({
    super.key,
    this.size = 50,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.badgeColor = AppTheme.declined,
    this.pageTitle = 'Notifications',
  });

  final double size;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color badgeColor;
  final String pageTitle;

  @override
  State<NotifikasiBellButton> createState() => _NotifikasiBellButtonState();
}

class _NotifikasiBellButtonState extends State<NotifikasiBellButton> {
  final NotifikasiService _service = NotifikasiService();

  int _unreadCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final count = await _service.getUnreadCount();

      if (!mounted) return;

      setState(() {
        _unreadCount = count;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('NotifikasiBellButton: _loadUnreadCount failed: $e');
      if (!mounted) return;

      setState(() {
        _unreadCount = 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _openNotifikasiPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotifikasiPage(title: widget.pageTitle),
      ),
    );

    if (!mounted) return;

    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final badgeText = _unreadCount > 99 ? '99+' : _unreadCount.toString();

    return Semantics(
      button: true,
      label: _unreadCount > 0
          ? 'Notifications, $_unreadCount unread'
          : 'Notifications',
      child: Tooltip(
        message: 'Notifications',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openNotifikasiPage,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.backgroundColor ?? AppTheme.surfaceOf(context),
                      border: Border.all(
                        color: widget.borderColor ?? AppTheme.cardBorderOf(context),
                        width: 1.0,
                      ),
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: widget.iconColor ?? AppTheme.primaryOf(context),
                      size: widget.size * 0.48,
                    ),
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: widget.badgeColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
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
        ),
      ),
    );
  }
}
