// lib/features/chatbot/view/chatbot_page.dart

import 'package:flutter/material.dart';
import '../../../model/chatbot_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_loading_widget.dart';
import '../data/chatbot_service.dart';
import '../widget/chat_bubble_widget.dart';
import '../widget/typing_indicator_widget.dart';
import 'chatbot_conversation_list_page.dart';

class ChatbotPage extends StatefulWidget {
  final int? initialConversationId;
  final String? initialTitle;
  final ChatbotService? service;

  const ChatbotPage({
    super.key,
    this.initialConversationId,
    this.initialTitle,
    this.service,
  });

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  late final ChatbotService _service;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  int? _conversationId;
  String _title = 'Asisten TA Virtual';

  bool _isLoadingHistory = false;
  bool _isSending = false;
  String? _rateLimitError;
  String? _circuitBreakerError;
  String? _generalError;

  final List<ChatbotPesanModel> _messages = [];

  static const List<String> _suggestedPrompts = [
    'Apa syarat pendaftaran sidang TA?',
    'Bagaimana alur revisi dokumen bimbingan?',
    'Berapa batas waktu pengerjaan Tugas Akhir?',
    'Siapa dosen pembimbing saya dan progres saya?',
    'Format dokumen apa yang didukung untuk bimbingan?',
  ];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ChatbotService();
    _conversationId = widget.initialConversationId;
    if (widget.initialTitle != null && widget.initialTitle!.isNotEmpty) {
      _title = widget.initialTitle!;
    }

    if (_conversationId != null) {
      _loadConversationHistory(_conversationId!);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadConversationHistory(int id) async {
    setState(() {
      _isLoadingHistory = true;
      _generalError = null;
    });

    try {
      final messages = await _service.getConversationMessages(id);
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
          _isLoadingHistory = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generalError = 'Gagal memuat riwayat: ${e.toString().replaceFirst("Exception: ", "")}';
          _isLoadingHistory = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = (presetText ?? _textController.text).trim();
    if (text.isEmpty || _isSending) return;

    if (presetText == null) {
      _textController.clear();
    }

    // Clear previous temporary errors
    setState(() {
      _rateLimitError = null;
      _circuitBreakerError = null;
      _generalError = null;
      _isSending = true;

      // Optimistic user message insertion
      _messages.add(
        ChatbotPesanModel(
          id: DateTime.now().millisecondsSinceEpoch,
          role: 'user',
          pesan: text,
          createdAt: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();

    try {
      final result = await _service.sendMessage(text, percakapanId: _conversationId);

      if (!mounted) return;

      final newConvId = result['percakapan_id'] as int?;
      final newTitle = result['judul_percakapan'] as String?;
      final assistantMsg = result['pesan_asisten'] as ChatbotPesanModel?;

      setState(() {
        if (newConvId != null && newConvId > 0) {
          _conversationId = newConvId;
        }
        if (newTitle != null && newTitle.isNotEmpty) {
          _title = newTitle;
        }
        if (assistantMsg != null) {
          _messages.add(assistantMsg);
        }
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      final errStr = e.toString().replaceFirst('Exception: ', '');

      setState(() {
        _isSending = false;
        if (errStr.contains('429') || errStr.toLowerCase().contains('kuota') || errStr.toLowerCase().contains('limit')) {
          _rateLimitError = 'Batas pesan harian tercapai (maksimum 50 pesan/hari). Kuota akan diperbarui besok.';
        } else if (errStr.contains('503') || errStr.toLowerCase().contains('beban') || errStr.toLowerCase().contains('kapasitas')) {
          _circuitBreakerError = 'Layanan Asisten TA sedang dalam beban puncak sistem. Silakan coba kembali dalam beberapa saat.';
        } else {
          _generalError = errStr;
        }
      });
      _scrollToBottom();
    }
  }

  void _resetToNewChat() {
    setState(() {
      _conversationId = null;
      _title = 'Asisten TA Virtual';
      _messages.clear();
      _rateLimitError = null;
      _circuitBreakerError = null;
      _generalError = null;
    });
  }

  void _openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatbotConversationListPage(service: _service),
      ),
    );

    // Refresh if needed
    if (_conversationId != null) {
      _loadConversationHistory(_conversationId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppTheme.surfaceOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Kembali',
          icon: Icon(Icons.arrow_back_ios_new_outlined, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.primaryGhostOf(context),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chat_bubble_outline, color: AppTheme.primaryOf(context), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppTheme.accepted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Asisten Resmi TA • RAG Aktif',
                        style: TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_comment_outlined, color: AppTheme.primaryOf(context)),
            tooltip: 'Percakapan Baru',
            onPressed: _resetToNewChat,
          ),
          IconButton(
            icon: Icon(Icons.history_outlined, color: textPrimary),
            tooltip: 'Riwayat Percakapan',
            onPressed: _openHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_rateLimitError != null) _buildRateLimitBanner(),
          if (_circuitBreakerError != null) _buildCircuitBreakerBanner(),
          if (_generalError != null) _buildGeneralErrorBanner(),
          Expanded(child: _buildChatArea()),
          _buildSuggestedChipsBar(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildRateLimitBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.pendingBgOf(context),
      child: Row(
        children: [
          const Icon(Icons.speed_outlined, color: AppTheme.pending, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _rateLimitError!,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimaryOf(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Tutup',
            icon: Icon(Icons.close_outlined, size: 18, color: AppTheme.textMutedOf(context)),
            onPressed: () => setState(() => _rateLimitError = null),
          ),
        ],
      ),
    );
  }

  Widget _buildCircuitBreakerBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.declinedBgOf(context),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppTheme.declined, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _circuitBreakerError!,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimaryOf(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Tutup',
            icon: Icon(Icons.close_outlined, size: 18, color: AppTheme.textMutedOf(context)),
            onPressed: () => setState(() => _circuitBreakerError = null),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.warningBgOf(context),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined, color: AppTheme.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _generalError!,
              style: TextStyle(fontSize: 12, color: AppTheme.textPrimaryOf(context)),
            ),
          ),
          IconButton(
            tooltip: 'Tutup',
            icon: Icon(Icons.close_outlined, size: 16, color: AppTheme.textMutedOf(context)),
            onPressed: () => setState(() => _generalError = null),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    if (_isLoadingHistory) {
      return const AppLoadingWidget();
    }

    if (_messages.isEmpty && !_isSending) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surfaceOf(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: AppTheme.cardBorderOf(context)),
                boxShadow: AppTheme.cardShadowOf(context),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGhostOf(context),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(Icons.school_outlined, color: AppTheme.primaryOf(context), size: 36),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Halo! Saya Asisten Tugas Akhir',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryOf(context)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tanyakan apa saja seputar alur Tugas Akhir, format penulisan, jadwal sidang, atau panduan bimbingan Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryOf(context), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppTheme.primaryOf(context), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Saran Pertanyaan:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._suggestedPrompts.map(
              (prompt) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () => _sendMessage(prompt),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceOf(context),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.cardBorderOf(context)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 16, color: AppTheme.primaryOf(context)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            prompt,
                            style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context), fontWeight: FontWeight.w500),
                          ),
                        ),
                        Icon(Icons.chevron_right_outlined, size: 18, color: AppTheme.textMutedOf(context)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isSending) {
          return const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TypingIndicatorWidget(),
            ),
          );
        }

        final msg = _messages[index];
        return ChatBubbleWidget(message: msg);
      },
    );
  }

  Widget _buildSuggestedChipsBar() {
    if (_messages.isEmpty) return const SizedBox.shrink();

    final surface = AppTheme.surfaceOf(context);
    final border = AppTheme.cardBorderOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestedPrompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final p = _suggestedPrompts[index];
          return ActionChip(
            backgroundColor: surface,
            side: BorderSide(color: border),
            label: Text(
              p,
              style: TextStyle(fontSize: 11, color: textPrimary, fontWeight: FontWeight.w500),
            ),
            onPressed: _isSending ? null : () => _sendMessage(p),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    final surface = AppTheme.surfaceOf(context);
    final border = AppTheme.cardBorderOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 16),
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          top: BorderSide(color: border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariantOf(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: border),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  enabled: !_isSending,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  style: TextStyle(fontSize: 14, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Tanyakan sesuatu tentang Tugas Akhir...',
                    hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined, color: Colors.white, size: 20),
                tooltip: 'Kirim',
                onPressed: _isSending ? null : () => _sendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
