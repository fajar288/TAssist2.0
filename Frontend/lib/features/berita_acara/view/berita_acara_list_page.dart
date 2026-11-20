// lib/features/berita_acara/view/berita_acara_list_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../model/berita_acara_model.dart';
import '../../../theme/app_theme.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh Berita Acara: $e'),
            backgroundColor: AppTheme.declined,
          ),
        );
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
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    ba.nomor,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
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
            const Text(
              'KODE HASH SHA-256:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: SelectableText(
                ba.activeHash,
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppTheme.textPrimary),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.download, size: 20),
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
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
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
          color: AppTheme.acceptedBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.acceptedBorder),
        ),
        child: const Text(
          'DISETUJUI',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accepted),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.pendingBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.pendingBorder),
      ),
      child: const Text(
        'DRAFT',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.pending),
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Berita Acara Bimbingan'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.declined),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGhost,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.description_outlined, size: 48, color: AppTheme.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum Ada Berita Acara',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Berita Acara resmi akan diterbitkan oleh dosen pembimbing setelah sesi bimbingan selesai dievaluasi.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
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
          color: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.cardBorder),
          ),
          child: InkWell(
            onTap: () => _showDetailSheet(ba),
            borderRadius: BorderRadius.circular(16),
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
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      _buildStatusChip(ba),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Periode: ${_formatDate(ba.periodeMulai)} — ${_formatDate(ba.periodeSelesai)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${ba.totalSessions} Sesi Pertemuan',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _showDetailSheet(ba),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.cardBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.info_outline, size: 16, color: AppTheme.textPrimary),
                        label: const Text('Detail', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _downloadPdf(ba),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Unduh PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
