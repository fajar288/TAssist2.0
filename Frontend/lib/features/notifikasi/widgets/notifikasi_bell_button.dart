import 'package:flutter/material.dart';

import '../data/notifikasi_service.dart';
import '../view/notifikasi_page.dart';

class NotifikasiBellButton extends StatefulWidget {
  const NotifikasiBellButton({
    super.key,
    this.size = 50,
    this.iconColor = const Color(0xFF0D4AA3),
    this.backgroundColor = Colors.white,
    this.borderColor,
    this.badgeColor = const Color(0xFFDC2626),
    this.pageTitle = 'Notifications',
  });

  final double size;
  final Color iconColor;
  final Color backgroundColor;
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
    } catch (_) {
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

    return GestureDetector(
      onTap: _openNotifikasiPage,
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
                color: widget.backgroundColor,
                border: Border.all(
                  color: widget.borderColor ?? Colors.black.withOpacity(0.05),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.notifications_rounded,
                color: widget.iconColor,
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
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
