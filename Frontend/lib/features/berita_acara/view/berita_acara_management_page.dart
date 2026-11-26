// lib/features/berita_acara/view/berita_acara_management_page.dart

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../model/berita_acara_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_empty_state_widget.dart';
import '../../../widgets/app_error_widget.dart';
import '../../../widgets/app_loading_widget.dart';
import '../../../widgets/app_snackbars.dart';
import '../../../widgets/signature_pad_widget.dart';
import '../data/berita_acara_service.dart';

class BeritaAcaraManagementPage extends StatefulWidget {
  final int bimbinganId;
  final String studentName;
  final String judulTa;

  const BeritaAcaraManagementPage({
    super.key,
    required this.bimbinganId,
    this.studentName = '',
    this.judulTa = '',
  });

  @override
  State<BeritaAcaraManagementPage> createState() => _BeritaAcaraManagementPageState();
}

class _BeritaAcaraManagementPageState extends State<BeritaAcaraManagementPage> {
  final BeritaAcaraService _service = BeritaAcaraService();
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _errorMessage;
  List<BeritaAcaraModel> _items = [];

  // Date range form state
  DateTime _periodeMulai = DateTime.now().subtract(const Duration(days: 90));
  DateTime _periodeSelesai = DateTime.now();

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
      final list = await _service.getBeritaAcaraDosen(widget.bimbinganId);
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

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initial = isStart ? _periodeMulai : _periodeSelesai;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _periodeMulai = picked;
        } else {
          _periodeSelesai = picked;
        }
      });
    }
  }

  Future<void> _generateDraft() async {
    if (_periodeMulai.isAfter(_periodeSelesai)) {
      AppSnackBars.error(
        context,
        'Tanggal mulai periode tidak boleh melebihi tanggal selesai.',
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final created = await _service.generateBeritaAcara(
        widget.bimbinganId,
        periodeMulai: _periodeMulai,
        periodeSelesai: _periodeSelesai,
      );

      if (mounted) {
        AppSnackBars.success(
          context,
          'Berita Acara ${created.nomor} berhasil dibuat (Draft).',
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBars.error(context, 'Gagal membuat Berita Acara: $e');
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showApprovalDialog(BeritaAcaraModel ba) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ApprovalModal(
        ba: ba,
        onApproved: (updatedBa) {
          Navigator.pop(ctx);
          AppSnackBars.success(
            context,
            'Berita Acara ${updatedBa.nomor} berhasil disetujui!',
          );
          _loadData();
        },
      ),
    );
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

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Manajemen Berita Acara'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGeneratorCard(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Berita Acara',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '${_items.length} Dokumen',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDocumentList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratorCard() {
    return Card(
      elevation: 0,
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(color: AppTheme.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGhost,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.post_add, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Terbitkan Berita Acara Baru',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Pilih rentang periode supervisi yang akan dirangkum dalam dokumen formal Berita Acara:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        border: Border.all(color: AppTheme.cardBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Periode Mulai', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(_periodeMulai),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 16, color: AppTheme.textSecondary),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        border: Border.all(color: AppTheme.cardBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Periode Selesai', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(_periodeSelesai),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateDraft,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                ),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_stories, size: 18),
                label: Text(
                  _isGenerating ? 'Memproses Dokumen...' : 'Generate Berita Acara (Draft)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentList() {
    if (_isLoading) {
      return const AppLoadingWidget();
    }

    if (_errorMessage != null) {
      return AppErrorWidget(
        message: _errorMessage!,
        onRetry: _loadData,
        compact: true,
      );
    }

    if (_items.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: const AppEmptyStateWidget(
          icon: Icons.inventory_2_outlined,
          title: 'Belum ada Berita Acara',
          subtitle:
              'Gunakan formulir di atas untuk men-generate dokumen Berita Acara pertama.',
          compact: true,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ba = _items[index];
        return Card(
          elevation: 0,
          color: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            side: const BorderSide(color: AppTheme.cardBorder),
          ),
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
                  'Periode: ${_formatDate(ba.periodeMulai)} s/d ${_formatDate(ba.periodeSelesai)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sesi: ${ba.totalSessions} Pertemuan Terkonfirmasi',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                if (ba.isDisetujui && ba.approvedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Disetujui: ${_formatDate(ba.approvedAt)} (${ba.metodePersetujuan?.toUpperCase() ?? 'PIN'})',
                    style: const TextStyle(fontSize: 11, color: AppTheme.accepted, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (ba.isDraft)
                      ElevatedButton.icon(
                        onPressed: () => _showApprovalDialog(ba),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accepted,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.verified, size: 16),
                        label: const Text('Setujui Dokumen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    if (ba.isDraft) const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _downloadPdf(ba),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.download, size: 16, color: AppTheme.textPrimary),
                      label: const Text('Unduh PDF', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ApprovalModal extends StatefulWidget {
  final BeritaAcaraModel ba;
  final ValueChanged<BeritaAcaraModel> onApproved;

  const _ApprovalModal({
    required this.ba,
    required this.onApproved,
  });

  @override
  State<_ApprovalModal> createState() => _ApprovalModalState();
}

class _ApprovalModalState extends State<_ApprovalModal> {
  final BeritaAcaraService _service = BeritaAcaraService();
  final TextEditingController _pinController = TextEditingController();
  String _selectedMethod = 'pin'; // 'pin' or 'tanda_tangan'
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submitPinApproval() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() => _error = 'Silakan masukkan PIN atau password dosen.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final approved = await _service.approveWithPin(widget.ba.beritaAcaraId, pin);
      widget.onApproved(approved);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _submitSignatureApproval(Uint8List signatureBytes) async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final approved = await _service.approveWithSignature(widget.ba.beritaAcaraId, signatureBytes);
      widget.onApproved(approved);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      child: SingleChildScrollView(
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
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
            ),
            Text(
              'Persetujuan ${widget.ba.nomor}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih metode otorisasi untuk mengesahkan Berita Acara bimbingan:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('PIN / Password')),
                    selected: _selectedMethod == 'pin',
                    selectedColor: AppTheme.primaryGhost,
                    labelStyle: TextStyle(
                      color: _selectedMethod == 'pin' ? AppTheme.primary : AppTheme.textSecondary,
                      fontWeight: _selectedMethod == 'pin' ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedMethod = 'pin');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Tanda Tangan')),
                    selected: _selectedMethod == 'tanda_tangan',
                    selectedColor: AppTheme.primaryGhost,
                    labelStyle: TextStyle(
                      color: _selectedMethod == 'tanda_tangan' ? AppTheme.primary : AppTheme.textSecondary,
                      fontWeight: _selectedMethod == 'tanda_tangan' ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedMethod = 'tanda_tangan');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.declinedBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.declinedBorder),
                ),
                child: Text(_error!, style: const TextStyle(color: AppTheme.declined, fontSize: 12)),
              ),
              const SizedBox(height: 12),
            ],
            if (_selectedMethod == 'pin') ...[
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'PIN Otorisasi (atau Password Akun Dosen)',
                  hintText: 'Masukkan 6 digit PIN',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPinApproval,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Sahkan Berita Acara', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ] else ...[
              SignaturePadWidget(
                onSigned: (bytes) => _submitSignatureApproval(bytes),
                onCancel: () => Navigator.pop(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
