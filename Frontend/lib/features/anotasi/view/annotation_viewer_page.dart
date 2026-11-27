// lib/features/anotasi/view/annotation_viewer_page.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../model/annotation_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_error_widget.dart';
import '../../../widgets/app_loading_widget.dart';
import '../../../widgets/app_snackbars.dart';
import '../data/annotation_service.dart';
import '../data/offline_annotation_cache.dart';

class AnnotationViewerPage extends StatefulWidget {
  final int versiId;
  final int? dokumenId;
  final String documentTitle;
  final bool isDosen;

  const AnnotationViewerPage({
    super.key,
    required this.versiId,
    this.dokumenId,
    required this.documentTitle,
    required this.isDosen,
  });

  @override
  State<AnnotationViewerPage> createState() => _AnnotationViewerPageState();
}

class _AnnotationViewerPageState extends State<AnnotationViewerPage> {
  final AnnotationService _service = AnnotationService();
  final OfflineAnnotationCache _offlineCache = OfflineAnnotationCache.instance;
  final PdfViewerController _pdfController = PdfViewerController();

  String? _signedUrl;
  String? _cachedPdfPath;
  bool _isOfflineMode = false;
  bool _isLoadingPdf = true;
  String? _pdfError;

  List<AnnotationModel> _annotations = [];
  List<AnnotationModel> _offlineDrafts = [];
  bool _isLoadingAnnotations = false;
  int _currentPage = 1;
  int _pageCount = 1;

  // Dosen annotation creation mode (Decision A3)
  bool _isAddingAnnotationMode = false;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _fetchSignedUrl(),
      _fetchAnnotations(),
    ]);
    await _syncOfflineDraftsIfOnline();
  }

  Future<void> _fetchSignedUrl() async {
    setState(() {
      _isLoadingPdf = true;
      _pdfError = null;
    });

    try {
      final url = await _service.getSignedUrl(widget.versiId);
      if (!mounted) return;
      setState(() {
        _signedUrl = url;
        _isOfflineMode = false;
        _isLoadingPdf = false;
      });
      // Cache PDF in the background for offline reading (T-45)
      unawaited(_offlineCache.cachePdfFromUrl(widget.versiId, url));
    } catch (e) {
      debugPrint('AnnotationViewerPage: getSignedUrl error: $e');
      final cachedPath = await _offlineCache.getCachedPdfPath(widget.versiId);
      if (!mounted) return;
      if (cachedPath != null) {
        setState(() {
          _cachedPdfPath = cachedPath;
          _isOfflineMode = true;
          _pdfError = null;
          _isLoadingPdf = false;
        });
      } else {
        setState(() {
          _pdfError = 'Gagal memuat dokumen PDF. Pastikan tautan masih berlaku.';
          _isLoadingPdf = false;
        });
      }
    }
  }

  Future<void> _fetchAnnotations() async {
    setState(() {
      _isLoadingAnnotations = true;
    });

    try {
      final list = widget.isDosen
          ? await _service.getAnnotationsForDosen(
              widget.versiId,
              status: _statusFilter == 'all' ? null : _statusFilter,
            )
          : await _service.getAnnotationsForMahasiswa(
              widget.versiId,
              status: _statusFilter == 'all' ? null : _statusFilter,
            );

      if (_statusFilter == 'all') {
        unawaited(_offlineCache.saveServerAnnotations(widget.versiId, list));
      }
      final drafts = await _offlineCache.getPendingDraftModels(widget.versiId);

      if (!mounted) return;
      setState(() {
        _annotations = list;
        _offlineDrafts = drafts;
        _isLoadingAnnotations = false;
      });
    } catch (e) {
      debugPrint('AnnotationViewerPage: _fetchAnnotations error: $e');
      final cached = await _offlineCache.getCachedAnnotations(widget.versiId);
      final drafts = await _offlineCache.getPendingDraftModels(widget.versiId);
      if (!mounted) return;
      setState(() {
        _annotations = cached;
        _offlineDrafts = drafts;
        _isOfflineMode = true;
        _isLoadingAnnotations = false;
      });
    }
  }

  Future<void> _syncOfflineDraftsIfOnline() async {
    if (_isOfflineMode || kIsWeb) return;
    final drafts = await _offlineCache.getPendingDraftModels(widget.versiId);
    if (drafts.isEmpty) return;

    try {
      final result = await _offlineCache.syncDraftsAndCheckConflicts(
        versiId: widget.versiId,
        service: _service,
        isDosen: widget.isDosen,
      );
      if (!mounted) return;
      await _fetchAnnotations();
      if (!mounted) return;

      if (result.syncedCount > 0 || result.newFromOthersCount > 0) {
        final parts = <String>[];
        if (result.syncedCount > 0) {
          parts.add('${result.syncedCount} draft offline disinkronkan');
        }
        if (result.newFromOthersCount > 0) {
          parts.add('${result.newFromOthersCount} new annotations from others since your last sync');
        }
        AppSnackBars.info(context, parts.join(' • '));
      }
    } catch (e) {
      debugPrint('AnnotationViewerPage: syncOfflineDraftsIfOnline skipped: $e');
    }
  }

  List<AnnotationModel> get _currentPageAnnotations {
    return [
      ..._annotations.where((a) => a.halaman == _currentPage),
      ..._offlineDrafts.where((a) => a.halaman == _currentPage),
    ];
  }

  void _onPdfTapped(TapUpDetails details, BoxConstraints constraints) {
    if (!_isAddingAnnotationMode || !widget.isDosen) return;

    final x = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
    final y = (details.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);

    _showCreateAnnotationDialog(x, y);
  }

  void _showCreateAnnotationDialog(double x, double y) {
    final kontenController = TextEditingController();
    String selectedTipe = 'komentar';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              title: Row(
                children: [
                  const Icon(Icons.note_add_rounded, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text('Anotasi Halaman $_currentPage', style: const TextStyle(fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tipe Anotasi:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Komentar'),
                        selected: selectedTipe == 'komentar',
                        onSelected: (val) => setDialogState(() => selectedTipe = 'komentar'),
                      ),
                      ChoiceChip(
                        label: const Text('Highlight'),
                        selected: selectedTipe == 'highlight',
                        onSelected: (val) => setDialogState(() => selectedTipe = 'highlight'),
                      ),
                      ChoiceChip(
                        label: const Text('Coretan'),
                        selected: selectedTipe == 'coretan',
                        onSelected: (val) => setDialogState(() => selectedTipe = 'coretan'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Catatan / Masukan:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: kontenController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tuliskan catatan perbaikan untuk mahasiswa...',
                      hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final text = kontenController.text.trim();
                    if (text.isEmpty) return;

                    Navigator.pop(dialogCtx);
                    setState(() => _isAddingAnnotationMode = false);

                    try {
                      if (_isOfflineMode && !kIsWeb) {
                        await _offlineCache.saveDraftAnnotation(
                          versiId: widget.versiId,
                          halaman: _currentPage,
                          x: x,
                          y: y,
                          tipe: selectedTipe,
                          konten: text,
                        );
                        final drafts = await _offlineCache.getPendingDraftModels(widget.versiId);
                        if (!mounted) return;
                        setState(() => _offlineDrafts = drafts);
                        AppSnackBars.info(
                          context,
                          'Draft anotasi disimpan offline. Akan disinkronkan saat online.',
                        );
                        return;
                      }

                      await _service.createAnnotation(
                        versiId: widget.versiId,
                        halaman: _currentPage,
                        x: x,
                        y: y,
                        tipe: selectedTipe,
                        konten: text,
                      );

                      if (!mounted) return;
                      AppSnackBars.success(context, 'Anotasi berhasil ditambahkan.');
                      _fetchAnnotations();
                    } catch (e) {
                      debugPrint('Error creating annotation: $e');
                      if (!kIsWeb) {
                        await _offlineCache.saveDraftAnnotation(
                          versiId: widget.versiId,
                          halaman: _currentPage,
                          x: x,
                          y: y,
                          tipe: selectedTipe,
                          konten: text,
                        );
                        final drafts = await _offlineCache.getPendingDraftModels(widget.versiId);
                        if (!mounted) return;
                        setState(() {
                          _isOfflineMode = true;
                          _offlineDrafts = drafts;
                        });
                        AppSnackBars.info(
                          context,
                          'Koneksi terputus: anotasi disimpan sebagai draft offline.',
                        );
                      } else if (mounted) {
                        AppSnackBars.error(context, 'Gagal membuat anotasi: $e');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                  ),
                  child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAnnotationDetailSheet(AnnotationModel anotasi) {
    final replyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final dateStr = anotasi.createdAt != null
                ? '${anotasi.createdAt!.day.toString().padLeft(2, '0')}/${anotasi.createdAt!.month.toString().padLeft(2, '0')}/${anotasi.createdAt!.year} ${anotasi.createdAt!.hour.toString().padLeft(2, '0')}:${anotasi.createdAt!.minute.toString().padLeft(2, '0')}'
                : '-';

            Color statusColor;
            Color statusBg;
            String statusLabel;
            switch (anotasi.status) {
              case AnnotationStatus.resolved:
                statusColor = AppTheme.accepted;
                statusBg = AppTheme.acceptedBgOf(context);
                statusLabel = 'Selesai (Resolved)';
                break;
              case AnnotationStatus.revised:
                statusColor = AppTheme.info;
                statusBg = AppTheme.infoBgOf(context);
                statusLabel = 'Sudah Direvisi';
                break;
              case AnnotationStatus.open:
              default:
                statusColor = AppTheme.pending;
                statusBg = AppTheme.pendingBgOf(context);
                statusLabel = 'Perlu Revisi (Open)';
                break;
            }

            final surface = AppTheme.surfaceOf(context);
            final surfaceVariant = AppTheme.surfaceVariantOf(context);
            final cardBorder = AppTheme.cardBorderOf(context);
            final textPrimary = AppTheme.textPrimaryOf(context);
            final textMuted = AppTheme.textMutedOf(context);
            final primary = AppTheme.primaryOf(context);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sheet Handle
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cardBorder,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      anotasi.authorName,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGhostOf(context),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                      ),
                                      child: Text(
                                        anotasi.tipe.name.toUpperCase(),
                                        style: TextStyle(
                                          color: primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Hal ${anotasi.halaman} • $dateStr',
                                  style: TextStyle(color: textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Body / Notes
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          anotasi.konten ?? 'Tidak ada catatan teks.',
                          style: TextStyle(fontSize: 15, height: 1.4, color: textPrimary),
                        ),
                      ),
                    ),
                    // Lifecycle Action Button
                    if (!widget.isDosen && anotasi.status == AnnotationStatus.open)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: const Text('Tandai Sudah Direvisi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.info,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                            ),
                            onPressed: () async {
                              Navigator.pop(sheetContext);
                              try {
                                await _service.markRevised(anotasi.anotasiId);
                                if (!mounted) return;
                                AppSnackBars.success(context, 'Anotasi berhasil ditandai sebagai revised.');
                                _fetchAnnotations();
                              } catch (e) {
                                debugPrint('Error marking revised: $e');
                              }
                            },
                          ),
                        ),
                      ),
                    if (widget.isDosen && anotasi.status != AnnotationStatus.resolved)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.task_alt_rounded, size: 18),
                            label: const Text('Selesaikan Anotasi (Resolved)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accepted,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                            ),
                            onPressed: () async {
                              Navigator.pop(sheetContext);
                              try {
                                await _service.markResolved(anotasi.anotasiId);
                                if (!mounted) return;
                                AppSnackBars.success(context, 'Anotasi berhasil diselesaikan.');
                                _fetchAnnotations();
                              } catch (e) {
                                debugPrint('Error marking resolved: $e');
                              }
                            },
                          ),
                        ),
                      ),
                    const Divider(height: 16),
                    // Reply Thread
                    Expanded(
                      child: anotasi.replies.isEmpty
                          ? Center(
                              child: Text(
                                'Belum ada balasan diskusi.',
                                style: TextStyle(color: textMuted, fontSize: 13),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: anotasi.replies.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, idx) {
                                final r = anotasi.replies[idx];
                                final rDate = r.createdAt != null
                                    ? '${r.createdAt!.hour.toString().padLeft(2, '0')}:${r.createdAt!.minute.toString().padLeft(2, '0')}'
                                    : '';
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: surfaceVariant,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    border: Border.all(color: cardBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            r.authorName,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                          const Spacer(),
                                          Text(rDate, style: TextStyle(color: textMuted, fontSize: 11)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(r.konten, style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    // Reply Input
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      decoration: BoxDecoration(
                        color: surface,
                        border: Border(top: BorderSide(color: cardBorder)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: replyController,
                              decoration: InputDecoration(
                                hintText: 'Tulis balasan...',
                                hintStyle: TextStyle(fontSize: 13, color: textMuted),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                filled: true,
                                fillColor: surfaceVariant,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.send_rounded, color: primary),
                            onPressed: () async {
                              final text = replyController.text.trim();
                              if (text.isEmpty) return;

                              replyController.clear();
                              try {
                                await _service.reply(
                                  anotasiId: anotasi.anotasiId,
                                  konten: text,
                                  isDosen: widget.isDosen,
                                );
                                Navigator.pop(sheetContext);
                                _fetchAnnotations();
                              } catch (e) {
                                debugPrint('Error replying annotation: $e');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCrossVersionSummarySheet() async {
    if (widget.dokumenId == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _service.getCrossVersionSummary(widget.dokumenId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 250,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
                ),
                child: const Center(child: AppLoadingWidget()),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Container(
                height: 200,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
                ),
                child: const Center(child: Text('Gagal memuat ringkasan anotasi versi.')),
              );
            }

            final data = snapshot.data!;
            final versions = (data['versi'] as List?) ?? [];

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceOf(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history_rounded, color: AppTheme.primaryOf(context)),
                      const SizedBox(width: 8),
                      const Text(
                        'Ringkasan Anotasi Lintas Versi',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ListView.separated(
                    shrinkWrap: true,
                    itemCount: versions.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, idx) {
                      final v = versions[idx] as Map;
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGhostOf(context),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: Text(
                              'v${v['nomor_versi']}',
                              style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryOf(context)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v['file_name']?.toString() ?? 'Dokumen',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Total: ${v['total']} • Terbuka: ${v['open']} • Direvisi: ${v['revised']} • Selesai: ${v['resolved']}',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppTheme.surfaceOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundOf(context),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.documentTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Halaman $_currentPage dari $_pageCount',
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
          ],
        ),
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        actions: [
          if (_offlineDrafts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cloud_upload_outlined, color: AppTheme.warning),
              tooltip: 'Sinkronkan Draft Offline (${_offlineDrafts.length})',
              onPressed: _syncOfflineDraftsIfOnline,
            ),
          // Filter popup
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter Anotasi',
            onSelected: (val) {
              setState(() => _statusFilter = val);
              _fetchAnnotations();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Semua Status')),
              const PopupMenuItem(value: 'open', child: Text('Hanya Open (Perlu Revisi)')),
              const PopupMenuItem(value: 'revised', child: Text('Hanya Direvisi')),
              const PopupMenuItem(value: 'resolved', child: Text('Hanya Selesai')),
            ],
          ),
          // Cross-version summary button (T-12)
          if (widget.dokumenId != null)
            IconButton(
              icon: const Icon(Icons.summarize_outlined),
              tooltip: 'Ringkasan Lintas Versi',
              onPressed: _showCrossVersionSummarySheet,
            ),
          // Dosen Add Annotation Toggle (T-13, Decision A3)
          if (widget.isDosen)
            IconButton(
              icon: Icon(
                _isAddingAnnotationMode ? Icons.edit_note : Icons.add_comment_outlined,
                color: _isAddingAnnotationMode ? AppTheme.warning : AppTheme.primary,
              ),
              tooltip: _isAddingAnnotationMode ? 'Mode Anotasi Aktif (Tap pada PDF)' : 'Tambah Anotasi',
              onPressed: () {
                setState(() {
                  _isAddingAnnotationMode = !_isAddingAnnotationMode;
                });
                if (_isAddingAnnotationMode) {
                  AppSnackBars.info(
                    context,
                    'Mode Anotasi Aktif: Tap pada area halaman PDF untuk meletakkan anotasi.',
                    duration: const Duration(seconds: 2),
                  );
                }
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingPdf) {
      return const Center(child: AppLoadingWidget());
    }

    if (_pdfError != null || (_signedUrl == null && _cachedPdfPath == null)) {
      return AppErrorWidget(
        message: _pdfError ?? 'Gagal memuat PDF',
        onRetry: _loadInitialData,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // PDF Viewer layer (online signed URL or offline cached file)
            if (_isOfflineMode && _cachedPdfPath != null && !kIsWeb)
              SfPdfViewer.file(
                File(_cachedPdfPath!),
                controller: _pdfController,
                onDocumentLoaded: (details) {
                  setState(() {
                    _pageCount = details.document.pages.count;
                  });
                },
                onPageChanged: (details) {
                  setState(() {
                    _currentPage = details.newPageNumber;
                  });
                },
              )
            else
              SfPdfViewer.network(
                _signedUrl!,
                controller: _pdfController,
                onDocumentLoaded: (details) {
                  setState(() {
                    _pageCount = details.document.pages.count;
                  });
                },
                onPageChanged: (details) {
                  setState(() {
                    _currentPage = details.newPageNumber;
                  });
                },
              ),

            // Offline cache banner (F-DOC-08)
            if (_isOfflineMode)
              Positioned(
                top: 8,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.offline_pin_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Viewing cached version. Annotations will sync when online',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Mode indicator banner
            if (_isAddingAnnotationMode && widget.isDosen)
              Positioned(
                top: 8,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.warning,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.touch_app_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mode Tambah Anotasi: Ketuk posisi yang ingin dianotasi di halaman ini.',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Annotation overlay layer for current page
            ..._currentPageAnnotations.map((anotasi) {
              final posX = (anotasi.x * constraints.maxWidth).clamp(0.0, constraints.maxWidth - 36);
              final posY = (anotasi.y * constraints.maxHeight).clamp(0.0, constraints.maxHeight - 36);

              Color pinColor;
              switch (anotasi.status) {
                case AnnotationStatus.resolved:
                  pinColor = AppTheme.accepted;
                  break;
                case AnnotationStatus.revised:
                  pinColor = AppTheme.info;
                  break;
                case AnnotationStatus.open:
                default:
                  pinColor = AppTheme.pending;
                  break;
              }

              return Positioned(
                left: posX,
                top: posY,
                child: GestureDetector(
                  onTap: () => _showAnnotationDetailSheet(anotasi),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: pinColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.comment_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }),

            // Transparent touch layer when in creation mode
            if (_isAddingAnnotationMode && widget.isDosen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapUp: (details) => _onPdfTapped(details, constraints),
                ),
              ),
          ],
        );
      },
    );
  }
}
