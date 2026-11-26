// lib/features/chatbot/widget/typing_indicator_widget.dart

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class TypingIndicatorWidget extends StatefulWidget {
  const TypingIndicatorWidget({super.key});

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(left: 16, right: 80, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppTheme.chatAssistantBubble,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusMd),
          topRight: Radius.circular(AppTheme.radiusMd),
          bottomRight: Radius.circular(AppTheme.radiusMd),
          bottomLeft: Radius.zero,
        ),
        border: Border.all(color: AppTheme.cardBorder, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.smart_toy_rounded, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          const Text(
            'Sedang mencari jawaban',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final value = ((_controller.value - delay) % 1.0);
                  final opacity = (value < 0.5 ? value * 2 : (1.0 - value) * 2).clamp(0.2, 1.0);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: opacity),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
