import 'package:flutter/material.dart';
import 'package:tassist/theme/app_theme.dart';
import 'package:tassist/widgets/app_empty_state_widget.dart';
import 'package:tassist/widgets/app_error_widget.dart';
import 'package:tassist/widgets/app_skeleton_loader.dart';
import 'package:tassist/widgets/app_snackbars.dart';

import '../data/notifikasi_service.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({
    super.key,
    this.title = 'Notifications',
  });

  final String title;

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  final NotifikasiService _service = NotifikasiService();

  bool _isLoading = true;
  bool _isUnreadOnly = false;
  String? _errorMessage;
  int _unreadCount = 0;
  List<Map<String, dynamic>> _notifikasi = [];

  @override
  void initState() {
    super.initState();
    _loadNotifikasi();
  }

  Future<void> _loadNotifikasi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final decoded = await _service.getNotifikasi(
        unreadOnly: _isUnreadOnly,
        perPage: 50,
      );

      if (!mounted) return;

      setState(() {
        _notifikasi = _service.extractNotifikasiList(decoded);
        _unreadCount = _service.extractUnreadCount(decoded);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (_unreadCount <= 0) return;

    try {
      await _service.markAllAsRead();
      await _loadNotifikasi();

      if (!mounted) return;
      AppSnackBars.success(
        context,
        'Semua notifikasi ditandai sebagai dibaca.',
      );
    } catch (e) {
      if (!mounted) return;

      AppSnackBars.error(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _openNotificationDetail(Map<String, dynamic> item) async {
    final id = int.tryParse(item['notifikasi_id']?.toString() ?? '');
    final isRead = item['is_read'] == true;

    final detailItem = Map<String, dynamic>.from(item);

    if (id != null && !isRead) {
      try {
        await _service.markAsRead(id);

        detailItem['is_read'] = true;

        if (!mounted) return;

        setState(() {
          final index = _notifikasi.indexWhere(
            (row) => row['notifikasi_id']?.toString() == id.toString(),
          );

          if (index != -1) {
            _notifikasi[index] = detailItem;
          }

          if (_unreadCount > 0) {
            _unreadCount--;
          }
        });
      } catch (e) {
        if (!mounted) return;

        AppSnackBars.error(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => _buildNotificationDetailSheet(detailItem),
    );

    if (!mounted) return;

    await _loadNotifikasi();
  }

  Widget _buildNotificationDetailSheet(Map<String, dynamic> item) {
    final title = item['judul']?.toString() ?? '-';
    final message = item['pesan']?.toString() ?? '-';
    final type = item['tipe_notifikasi']?.toString() ?? '-';
    final isRead = item['is_read'] == true;

    final iconColor = _iconColorForType(type);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.46,
      minChildSize: 0.30,
      maxChildSize: 0.75,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(
                      _iconForType(type),
                      color: iconColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notification Detail',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: AppTheme.cardBorder,
                  ),
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              _buildDetailRow(
                icon: isRead
                    ? Icons.mark_email_read_rounded
                    : Icons.mark_email_unread_rounded,
                label: 'Status',
                value: isRead ? 'Read' : 'Unread',
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.surface,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.cardBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String? type) {
    final value = type?.toLowerCase() ?? '';

    if (value.contains('dokumen')) return Icons.description_rounded;
    if (value.contains('feedback')) return Icons.comment_rounded;
    if (value.contains('jadwal')) return Icons.event_rounded;
    if (value.contains('permohonan')) return Icons.person_add_alt_1_rounded;
    if (value.contains('progres')) return Icons.check_circle_rounded;

    return Icons.notifications_rounded;
  }

  Color _iconColorForType(String? type) {
    final value = type?.toLowerCase() ?? '';

    if (value.contains('dokumen')) return AppTheme.primary;
    if (value.contains('feedback')) return AppTheme.accepted;
    if (value.contains('jadwal')) return AppTheme.pending;
    if (value.contains('permohonan')) return AppTheme.primaryLight;
    if (value.contains('progres')) return AppTheme.info;

    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          IconButton(
            tooltip: _isUnreadOnly ? 'Tampilkan semua' : 'Tampilkan belum dibaca',
            onPressed: () {
              setState(() {
                _isUnreadOnly = !_isUnreadOnly;
              });
              _loadNotifikasi();
            },
            icon: Icon(
              _isUnreadOnly
                  ? Icons.mark_email_read_outlined
                  : Icons.mark_email_unread_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Tandai semua dibaca',
            onPressed: _unreadCount > 0 ? _markAllAsRead : null,
            icon: const Icon(Icons.done_all_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifikasi,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: AppSkeletonLoader.list(count: 6),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 60),
          AppErrorWidget(
            message: _errorMessage!,
            onRetry: _loadNotifikasi,
          ),
        ],
      );
    }

    if (_notifikasi.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          AppEmptyStateWidget(
            icon: Icons.notifications_none_rounded,
            title: _isUnreadOnly
                ? 'Belum ada notifikasi yang belum dibaca.'
                : 'Belum ada notifikasi.',
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _notifikasi.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader();
        }

        final item = _notifikasi[index - 1];
        return _buildNotificationCard(item);
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryGhost,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _unreadCount > 0
                      ? '$_unreadCount belum dibaca'
                      : 'Semua sudah dibaca',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isUnreadOnly
                      ? 'Menampilkan notifikasi yang belum dibaca.'
                      : 'Menampilkan semua notifikasi terbaru.',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    final title = item['judul']?.toString() ?? '-';
    final message = item['pesan']?.toString() ?? '-';
    final createdAt = item['created_at']?.toString() ?? '';
    final type = item['tipe_notifikasi']?.toString();
    final isRead = item['is_read'] == true;
    final iconColor = _iconColorForType(type);

    return InkWell(
      onTap: () => _openNotificationDetail(item),
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: isRead ? AppTheme.cardBorder : AppTheme.infoBorder,
          ),
          boxShadow: AppTheme.subtleShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(
                _iconForType(type),
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(top: 5, left: 8),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.textMuted,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  if (createdAt.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          createdAt,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
