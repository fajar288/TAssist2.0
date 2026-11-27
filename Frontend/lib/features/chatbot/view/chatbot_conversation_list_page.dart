// lib/features/chatbot/view/chatbot_conversation_list_page.dart

import 'package:flutter/material.dart';
import '../../../model/chatbot_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_empty_state_widget.dart';
import '../../../widgets/app_error_widget.dart';
import '../../../widgets/app_loading_widget.dart';
import '../../../widgets/app_snackbars.dart';
import '../data/chatbot_service.dart';
import 'chatbot_page.dart';

class ChatbotConversationListPage extends StatefulWidget {
  final ChatbotService? service;

  const ChatbotConversationListPage({super.key, this.service});

  @override
  State<ChatbotConversationListPage> createState() => _ChatbotConversationListPageState();
}

class _ChatbotConversationListPageState extends State<ChatbotConversationListPage> {
  late final ChatbotService _service;
  bool _isLoading = true;
  String? _errorMessage;
  List<ChatbotPercakapanModel> _conversations = [];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ChatbotService();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _service.getConversations();
      if (mounted) {
        setState(() {
          _conversations = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteConversation(ChatbotPercakapanModel conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        title: Text(
          'Hapus Percakapan',
          style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimaryOf(ctx)),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${conversation.judul}"? Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(color: AppTheme.textSecondaryOf(ctx)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: AppTheme.textSecondaryOf(ctx))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.declined,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _service.deleteConversation(conversation.percakapanId);
        if (success && mounted) {
          setState(() {
            _conversations.removeWhere((c) => c.percakapanId == conversation.percakapanId);
          });
          AppSnackBars.success(context, 'Percakapan berhasil dihapus.');
        }
      } catch (e) {
        if (mounted) {
          AppSnackBars.error(context, 'Gagal menghapus percakapan: $e');
        }
      }
    }
  }

  void _openConversation(ChatbotPercakapanModel conversation) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatbotPage(
          service: _service,
          initialConversationId: conversation.percakapanId,
          initialTitle: conversation.judul,
        ),
      ),
    );

    if (result == true || mounted) {
      _loadConversations();
    }
  }

  void _startNewConversation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatbotPage(service: _service),
      ),
    );

    if (result == true || mounted) {
      _loadConversations();
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryOf(context);
    final primary = AppTheme.primaryOf(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceOf(context),
        elevation: 0,
        leading: IconButton(
          tooltip: 'Kembali',
          icon: Icon(Icons.arrow_back_ios_new_outlined, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Riwayat Percakapan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: primary),
            tooltip: 'Segarkan',
            onPressed: _loadConversations,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Percakapan Baru', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: _startNewConversation,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppLoadingWidget();
    }

    if (_errorMessage != null) {
      return AppErrorWidget(
        message: _errorMessage!,
        onRetry: _loadConversations,
      );
    }

    if (_conversations.isEmpty) {
      return AppEmptyStateWidget(
        icon: Icons.chat_bubble_outline,
        title: 'Belum Ada Riwayat',
        subtitle:
            'Mulai tanyakan seputar informasi dan alur Tugas Akhir Anda kepada Asisten TA.',
        actionLabel: 'Mulai Chat Baru',
        onAction: _startNewConversation,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: AppTheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 88),
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return Container(
            decoration:
                AppTheme.cardDecorationOf(context, radius: AppTheme.radiusMd),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                onTap: () => _openConversation(conversation),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGhostOf(context),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline,
                          color: AppTheme.primaryOf(context),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conversation.judul,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryOf(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(conversation.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: AppTheme.textMutedOf(context),
                          size: 20,
                        ),
                        tooltip: 'Hapus',
                        onPressed: () => _deleteConversation(conversation),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
