// lib/features/chatbot/widget/chat_bubble_widget.dart

import 'package:flutter/material.dart';
import '../../../model/chatbot_model.dart';
import '../../../theme/app_theme.dart';

class ChatBubbleWidget extends StatelessWidget {
  final ChatbotPesanModel message;

  const ChatBubbleWidget({
    super.key,
    required this.message,
  });

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _showCitationDetail(BuildContext context, ChatbotSumberModel citation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.chatCitationBg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: AppTheme.chatCitation, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          citation.tipe.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.chatCitation,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          citation.judul,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Label Kutipan Resmi:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Text(
                  citation.label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isUser;
    final bool isRefused = message.isRefused;
    final bool dark = AppTheme.isDark(context);
    final assistantBg = dark ? AppTheme.darkSurface : AppTheme.chatAssistantBubble;
    final assistantText = dark ? AppTheme.darkTextPrimary : AppTheme.chatAssistantText;
    final refusalBg = dark ? AppTheme.darkPendingBg : AppTheme.chatRefusalBg;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isRefused ? refusalBg : AppTheme.primaryLight.withOpacity(0.15),
                  child: Icon(
                    isRefused ? Icons.shield_outlined : Icons.chat_bubble_outline,
                    size: 16,
                    color: isRefused ? AppTheme.chatRefusal : AppTheme.primaryOf(context),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppTheme.chatUserBubble
                        : (isRefused ? refusalBg : assistantBg),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppTheme.radiusMd),
                      topRight: const Radius.circular(AppTheme.radiusMd),
                      bottomLeft: isUser ? const Radius.circular(AppTheme.radiusMd) : Radius.zero,
                      bottomRight: isUser ? Radius.zero : const Radius.circular(AppTheme.radiusMd),
                    ),
                    border: isRefused
                        ? Border.all(color: AppTheme.chatRefusal, width: 1.2)
                        : (isUser ? null : Border.all(color: AppTheme.cardBorderOf(context), width: 0.8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Refusal badge header
                      if (isRefused) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.chatRefusal),
                            const SizedBox(width: 6),
                            Text(
                              'Di Luar Cakupan Asisten TA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.chatRefusal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Message text
                      SelectableText(
                        message.pesan,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: isUser ? AppTheme.chatUserText : assistantText,
                        ),
                      ),

                      // Tappable Citations
                      if (message.sumber != null && message.sumber!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: message.sumber!.map((citation) {
                            return InkWell(
                              onTap: () => _showCitationDetail(context, citation),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.chatCitationBg,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  border: Border.all(color: AppTheme.chatCitation.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.menu_book_rounded, size: 12, color: AppTheme.chatCitation),
                                    const SizedBox(width: 4),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 200),
                                      child: Text(
                                        citation.judul,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.chatCitation,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isUser ? Colors.white70 : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
