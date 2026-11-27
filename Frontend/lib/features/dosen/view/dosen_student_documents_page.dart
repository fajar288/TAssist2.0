import 'package:flutter/material.dart';
import 'package:tassist/features/dosen/data/dosen_service.dart';
import 'package:tassist/model/models.dart';
import 'package:tassist/theme/app_theme.dart';
import 'package:tassist/widgets/app_empty_state_widget.dart';
import 'package:tassist/widgets/app_error_widget.dart';
import 'package:tassist/widgets/app_loading_widget.dart';
import 'package:tassist/widgets/app_snackbars.dart';
import '../../anotasi/view/annotation_viewer_page.dart';

class DosenStudentDocumentsPage extends StatefulWidget {
  final StudentModel student;

  const DosenStudentDocumentsPage({
    super.key,
    required this.student,
  });

  @override
  State<DosenStudentDocumentsPage> createState() =>
      _DosenStudentDocumentsPageState();
}

class _DosenStudentDocumentsPageState extends State<DosenStudentDocumentsPage> {
  final DosenService _dosenService = DosenService();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _documents = [];

  StudentModel get student => widget.student;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final bimbinganId = student.bimbinganIdAsInt;

    if (bimbinganId == null) {
      setState(() {
        _errorMessage = 'ID bimbingan tidak valid.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final docs = await _dosenService.getDokumenMahasiswaList(
        bimbinganId: bimbinganId,
        perPage: 30,
      );

      if (!mounted) return;

      setState(() {
        _documents = docs;
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

  String _fileExtension(String fileName) {
    final cleanName = fileName.split('?').first;
    final dotIndex = cleanName.lastIndexOf('.');

    if (dotIndex == -1 || dotIndex == cleanName.length - 1) {
      return '';
    }

    return cleanName.substring(dotIndex + 1).toLowerCase();
  }

  IconData _documentIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc':
      case 'docx':
        return Icons.article_outlined;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_outlined;
      case 'zip':
        return Icons.folder_zip_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  String _formatStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return 'Draf';
      case 'diajukan':
        return 'Diajukan';
      case 'direvisi':
        return 'Perlu Revisi';
      case 'disetujui':
        return 'Disetujui';
      default:
        return status ?? '-';
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return AppTheme.textMuted;
      case 'diajukan':
        return AppTheme.pending;
      case 'direvisi':
        return AppTheme.declined;
      case 'disetujui':
        return AppTheme.accepted;
      default:
        return AppTheme.textMuted;
    }
  }

  String _formatDateTime(String? value) {
    if (value == null || value.trim().isEmpty) return '-';

    try {
      final date = DateTime.parse(value);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day/$month/$year, $hour:$minute';
    } catch (e) {
      debugPrint('DosenStudentDocumentsPage: _formatDateTime failed for "$value": $e');
      return value;
    }
  }

  Future<void> _showFeedbackDialog(Map<String, dynamic> version) async {
    final versiId = int.tryParse(version['versi_id']?.toString() ?? '');

    if (versiId == null) {
      _showSnackBar('ID versi dokumen tidak valid.', isError: true);
      return;
    }

    final formKey = GlobalKey<FormState>();
    final komentarController = TextEditingController();
    final halamanController = TextEditingController();
    final posisiController = TextEditingController();

    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              title: const Text('Give Feedback'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: komentarController,
                        maxLines: 5,
                        maxLength: 2000,
                        decoration: const InputDecoration(
                          labelText: 'Comment',
                          hintText: 'Write your feedback here...',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';

                          if (text.isEmpty) {
                            return 'Komentar wajib diisi.';
                          }

                          if (text.length > 2000) {
                            return 'Komentar maksimal 2000 karakter.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: halamanController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Page',
                          hintText: 'Optional',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: posisiController,
                        maxLength: 255,
                        decoration: const InputDecoration(
                          labelText: 'Annotation Position',
                          hintText: 'Optional',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          final halamanText = halamanController.text.trim();
                          final halaman = halamanText.isEmpty
                              ? null
                              : int.tryParse(halamanText);

                          if (halamanText.isNotEmpty && halaman == null) {
                            _showSnackBar(
                              'Halaman harus berupa angka.',
                              isError: true,
                            );
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                          });

                          try {
                            await _dosenService.storeFeedback(
                              versiId: versiId,
                              komentar: komentarController.text,
                              halaman: halaman,
                              posisiAnotasi: posisiController.text,
                            );

                            if (!mounted) return;

                            Navigator.pop(dialogContext);
                            _showSnackBar('Feedback berhasil dikirim.');
                          } catch (e) {
                            if (!mounted) return;

                            setDialogState(() {
                              isSubmitting = false;
                            });

                            _showSnackBar(
                              e.toString().replaceFirst('Exception: ', ''),
                              isError: true,
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );

    komentarController.dispose();
    halamanController.dispose();
    posisiController.dispose();
  }

  void _showVersionsSheet(Map<String, dynamic> document) {
    final dokumenId = int.tryParse(document['dokumen_id']?.toString() ?? '');

    if (dokumenId == null) {
      _showSnackBar('ID dokumen tidak valid.', isError: true);
      return;
    }

    final future = _dosenService.getRiwayatVersiDokumenList(
      dokumenId: dokumenId,
      perPage: 30,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.76,
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceOf(sheetContext),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
          ),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingWidget();
              }

              if (snapshot.hasError) {
                return AppErrorWidget(
                  message: snapshot.error.toString().replaceFirst('Exception: ', ''),
                );
              }

              final versions = snapshot.data ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBorderOf(context),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    document['judul_dokumen']?.toString() ?? '-',
                    style: TextStyle(
                      color: AppTheme.textPrimaryOf(context),
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    document['jenis_dokumen']?.toString() ?? '-',
                    style: TextStyle(
                      color: AppTheme.textSecondaryOf(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: versions.isEmpty
                        ? Center(
                            child: Text(
                              'No version history yet.',
                              style: TextStyle(color: AppTheme.textMutedOf(context)),
                            ),
                          )
                        : ListView.builder(
                            itemCount: versions.length,
                            itemBuilder: (context, index) {
                              return _buildVersionItem(versions[index]);
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildVersionItem(Map<String, dynamic> version) {
    final status = version['status_versi']?.toString();
    final feedbackRaw = version['feedback'];
    final feedback = feedbackRaw is List
        ? feedbackRaw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : <Map<String, dynamic>>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantOf(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.cardBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_outlined, color: AppTheme.primaryOf(context)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Version ${version['nomor_versi'] ?? '-'}',
                  style: TextStyle(
                    color: AppTheme.textPrimaryOf(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  _formatStatus(status),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Uploaded at ${_formatDateTime(version['uploaded_at']?.toString())}',
            style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 12),
          ),
          if (version['catatan_revisi'] != null &&
              version['catatan_revisi'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              version['catatan_revisi'].toString(),
              style: TextStyle(
                color: AppTheme.textPrimaryOf(context),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
          if (feedback.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Existing Feedback',
              style: TextStyle(
                color: AppTheme.textPrimaryOf(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...feedback.take(3).map(_buildFeedbackPreview),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final versiId = int.tryParse(version['versi_id']?.toString() ?? '');
                    if (versiId == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnnotationViewerPage(
                          versiId: versiId,
                          dokumenId: int.tryParse(version['dokumen_id']?.toString() ?? ''),
                          documentTitle: 'Versi ${version['nomor_versi'] ?? ''}',
                          isDosen: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_note_outlined, size: 18),
                  label: const Text('Anotasi PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showFeedbackDialog(version),
                  icon: const Icon(Icons.rate_review_outlined, size: 18),
                  label: const Text('Masukan'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackPreview(Map<String, dynamic> feedback) {
    final page = feedback['halaman']?.toString();
    final comment = feedback['komentar']?.toString() ?? '-';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Text(
        page == null || page.isEmpty ? comment : 'Page $page: $comment',
        style: TextStyle(
          color: AppTheme.textPrimaryOf(context),
          fontSize: 12,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> document) {
    final latestVersion = document['versi_terbaru'] is Map
        ? Map<String, dynamic>.from(document['versi_terbaru'])
        : <String, dynamic>{};

    final fileUrl = latestVersion['file_url']?.toString() ?? '';
    final extension = _fileExtension(fileUrl);
    final status = latestVersion['status_versi']?.toString();
    final versionNumber = latestVersion['nomor_versi']?.toString();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showVersionsSheet(document),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration:
              AppTheme.cardDecorationOf(context, radius: AppTheme.radiusLg),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGhostOf(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(
                  _documentIcon(extension),
                  color: AppTheme.primaryOf(context),
                  size: 31,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document['judul_dokumen']?.toString() ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textPrimaryOf(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      document['jenis_dokumen']?.toString() ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textSecondaryOf(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'V${versionNumber ?? '-'} • ${_formatStatus(status)}',
                      style: TextStyle(
                        color: _statusColor(status),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_outlined,
                size: 20,
                color: AppTheme.textMutedOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 80),
        AppEmptyStateWidget(
          icon: Icons.folder_open_outlined,
          title: 'Belum ada dokumen yang diunggah.',
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return AppErrorWidget(
      title: 'Gagal memuat dokumen',
      message: _errorMessage ?? '-',
      onRetry: _loadDocuments,
      retryLabel: 'Coba Lagi',
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (isError) {
      AppSnackBars.error(context, message);
    } else {
      AppSnackBars.success(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOf(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        title: const Text(
          'Student Documents',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppTheme.radiusXl)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white24,
                  child: Text(
                    student.imageInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${student.nim} • ${student.major}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const AppLoadingWidget()
                : _errorMessage != null
                    ? _buildErrorState()
                    : RefreshIndicator(
                        onRefresh: _loadDocuments,
                        child: _documents.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 20, 18, 32),
                                itemCount: _documents.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 14),
                                itemBuilder: (context, index) {
                                  return _buildDocumentCard(_documents[index]);
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}
