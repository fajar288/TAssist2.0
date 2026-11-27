// lib/features/berita_acara/view/berita_acara_list_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../model/berita_acara_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_empty_state_widget.dart';
import '../../../widgets/app_error_widget.dart';
import '../../../widgets/app_loading_widget.dart';
import '../../../widgets/app_snackbars.dart';
import '../data/berita_acara_service.dart';

class BeritaAcaraListPage extends StatefulWidget {
  final int bimbinganId;
  final String studentName;

  const BeritaAcaraListPage({
    super.key,
    required this.bimbinganId,
    this.studentName = '',
  });

  @override
  State<BeritaAcaraListPage> createState() => _BeritaAcaraListPageState();
}

class _BeritaAcaraListPageState extends State<BeritaAcaraListPage> {
  final BeritaAcaraService _service = BeritaAcaraService();
  bool _isLoading = true;
  String? _errorMessage;
  List<BeritaAcaraModel> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _service.getBeritaAcaraMahasiswa(widget.bimbinganId);
      if (mounted) {
        setState(() {
          _items = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadPdf(BeritaAcaraModel ba) async {
    try {
      final url = ba.downloadUrl ?? await _service.getDownloadSignedUrl(ba.beritaAcaraId);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Tidak dapat membuka URL unduhan.');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBars.error(context, 'Gagal mengunduh Berita Acara: $e');
      }
    }
  }

  void _showDetailSheet(BeritaAcaraModel ba) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceOf(ctx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBorderOf(ctx),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    ba.nomor,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryOf(ctx),
                    ),
                  ),
                ),
                _buildStatusChip(ba),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _buildDetailRow('Dosen Pembimbing', ba.professorName),
            _buildDetailRow('NID Pembimbing', ba.professorNid),
            _buildDetailRow(
              'Periode Supervisi',
              '${_formatDate(ba.periodeMulai)} s/d ${_formatDate(ba.periodeSelesai)}',
            ),
            _buildDetailRow('Total Sesi Bimbingan', '${ba.totalSessions} Sesi'),
            if (ba.isDisetujui && ba.approvedAt != null)
              _buildDetailRow('Tanggal Disetujui', _formatDateTime(ba.approvedAt)),
            if (ba.metodePersetujuan != null)
              _buildDetailRow('Metode Verifikasi', ba.metodePersetujuan!.toUpperCase()),
            const SizedBox(height: 16),
            Text(
              'KODE HASH SHA-256:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryOf(ctx),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantOf(ctx),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppTheme.cardBorderOf(ctx)),
              ),
              child: SelectableText(
                ba.activeHash,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: AppTheme.textPrimaryOf(ctx),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _downloadPdf(ba);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              ),
              icon: const Icon(Icons.file_download_outlined, size: 20),
              label: const Text('Unduh File Dokumen PDF', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryOf(context)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BeritaAcaraModel ba) {
    if (ba.isDisetujui) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.acceptedBgOf(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.acceptedBorderOf(context)),
        ),
        child: const Text(
          'DISETUJUI',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.accepted),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.pendingBgOf(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.pendingBorderOf(context)),
      ),
      child: const Text(
        'DRAFT',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.pending),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    final date = _formatDate(dt);
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time WIB';
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppTheme.surfaceOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundOf(context),
      appBar: AppBar(
        title: const Text('Berita Acara Bimbingan'),
        backgroundColor: surface,
        elevation: 0,
        foregroundColor: textPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppLoadingWidget();
    }

    if (_errorMessage != null) {
      return AppErrorWidget(
        message: _errorMessage!,
        onRetry: _loadData,
      );
    }

    if (_items.isEmpty) {
      return const AppEmptyStateWidget(
        icon: Icons.description_outlined,
        title: 'Belum Ada Berita Acara',
        subtitle:
            'Berita Acara resmi akan diterbitkan oleh dosen pembimbing setelah sesi bimbingan selesai dievaluasi.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ba = _items[index];
        return Card(
          elevation: 0,
          color: AppTheme.surfaceOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            side: BorderSide(color: AppTheme.cardBorderOf(context)),
          ),
          child: InkWell(
            onTap: () => _showDetailSheet(ba),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          ba.nomor,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryOf(context),
                          ),
                        ),
                      ),
                      _buildStatusChip(ba),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Periode: ${_formatDate(ba.periodeMulai)} - ${_formatDate(ba.periodeSelesai)}',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${ba.totalSessions} Sesi Pertemuan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimaryOf(context)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _showDetailSheet(ba),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.cardBorderOf(context)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: Icon(Icons.info_outline, size: 16, color: AppTheme.textPrimaryOf(context)),
                        label: Text('Detail', style: TextStyle(fontSize: 12, color: AppTheme.textPrimaryOf(context))),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _downloadPdf(ba),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.file_download_outlined, size: 16),
                        label: const Text('Unduh PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
