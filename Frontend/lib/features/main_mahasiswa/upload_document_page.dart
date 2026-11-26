import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:tassist/features/main_mahasiswa/data/mahasiswa_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_empty_state_widget.dart';
import '../../widgets/app_error_widget.dart';
import '../../widgets/app_loading_widget.dart';
import '../../widgets/app_skeleton_loader.dart';
import '../../widgets/app_snackbars.dart';
import '../anotasi/view/annotation_viewer_page.dart';

class UploadDocumentPage extends StatefulWidget {
  const UploadDocumentPage({super.key});

  @override
  State<UploadDocumentPage> createState() => _UploadDocumentPageState();
}

class _UploadDocumentPageState extends State<UploadDocumentPage> {
  final MahasiswaService _mahasiswaService = MahasiswaService();

  final List<String> _allowedExtensions = const [
    'pdf',
    'doc',
    'docx',
    'ppt',
    'pptx',
    'zip',
  ];

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final docs = await _mahasiswaService.getDokumen(perPage: 30);

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

  Future<PlatformFile?> _pickAllowedFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;

      if (!_isFileAllowed(file)) {
        if (mounted) {
          AppSnackBars.error(
            context,
            'File harus berformat pdf, doc, docx, ppt, pptx, atau zip.',
          );
        }
        return null;
      }

      if (file.size > 20 * 1024 * 1024) {
        AppSnackBars.error(
          context,
          'Ukuran file maksimal 20MB.',
        );
        return null;
      }

      if (file.bytes == null && (file.path == null || file.path!.isEmpty)) {
        AppSnackBars.error(
          context,
          'File tidak bisa dibaca. Coba pilih file lain.',
        );
        return null;
      }

      return file;
    } catch (e) {
      AppSnackBars.error(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  bool _isFileAllowed(PlatformFile file) {
    final extension = _fileExtension(file.name);
    return _allowedExtensions.contains(extension);
  }

  String _fileExtension(String fileName) {
    final cleanName = fileName.split('?').first;
    final dotIndex = cleanName.lastIndexOf('.');

    if (dotIndex == -1 || dotIndex == cleanName.length - 1) {
      return '';
    }

    return cleanName.substring(dotIndex + 1).toLowerCase();
  }

  String _fileNameWithoutExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');

    if (dotIndex <= 0) {
      return fileName;
    }

    return fileName.substring(0, dotIndex);
  }

  IconData _documentIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.article_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'zip':
        return Icons.folder_zip_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  String _formatStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'diajukan':
        return 'Submitted';
      case 'direvisi':
        return 'Needs Revision';
      case 'disetujui':
        return 'Approved';
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
    if (value == null || value.trim().isEmpty) {
      return '-';
    }

    try {
      final date = DateTime.parse(value);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day/$month/$year, $hour:$minute';
    } catch (e) {
      debugPrint('UploadDocumentPage: _formatDateTime failed for "$value": $e');
      return value;
    }
  }

  Future<List<Map<String, dynamic>>> _loadAllFeedback() async {
    final feedbackItems = <Map<String, dynamic>>[];

    for (final doc in _documents) {
      final dokumenId = int.tryParse(doc['dokumen_id']?.toString() ?? '');

      if (dokumenId == null) continue;

      final versionPackage = await _mahasiswaService.getRiwayatVersiDokumen(
        dokumenId: dokumenId,
        perPage: 30,
      );

      final versionsRaw = versionPackage['versi'];
      final versions = versionsRaw is List
          ? versionsRaw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];

      for (final version in versions) {
        final feedbackRaw = version['feedback'];
        final feedback = feedbackRaw is List
            ? feedbackRaw
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
            : <Map<String, dynamic>>[];

        for (final item in feedback) {
          feedbackItems.add({
            ...item,
            'judul_dokumen': doc['judul_dokumen'],
            'jenis_dokumen': doc['jenis_dokumen'],
            'nomor_versi': version['nomor_versi'],
          });
        }
      }
    }

    feedbackItems.sort((a, b) {
      final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '');
      final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '');

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    return feedbackItems;
  }

  Future<void> _showUploadDocumentSheet() async {
    final file = await _pickAllowedFile();

    if (file == null) return;

    final formKey = GlobalKey<FormState>();
    final jenisController = TextEditingController();
    final judulController = TextEditingController(
      text: _fileNameWithoutExtension(file.name),
    );
    final deskripsiController = TextEditingController();
    final catatanController = TextEditingController();

    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusXl),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.cardBorder,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Upload New Document',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Fill the document details before sending it to your lecturer.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSelectedFileCard(file),
                        const SizedBox(height: 18),
                        _buildTextFormField(
                          controller: jenisController,
                          label: 'Document Type',
                          hint: 'Example: Proposal TA, Bab 1, Full Draft',
                          validatorMessage: 'Jenis dokumen wajib diisi.',
                        ),
                        const SizedBox(height: 14),
                        _buildTextFormField(
                          controller: judulController,
                          label: 'Document Title',
                          hint: 'Example: Proposal Sistem Informasi TA',
                          validatorMessage: 'Judul dokumen wajib diisi.',
                        ),
                        const SizedBox(height: 14),
                        _buildTextFormField(
                          controller: deskripsiController,
                          label: 'Description',
                          hint: 'Optional description...',
                          maxLines: 3,
                          required: false,
                        ),
                        const SizedBox(height: 14),
                        _buildTextFormField(
                          controller: catatanController,
                          label: 'Revision Note',
                          hint: 'Optional note for your lecturer...',
                          maxLines: 3,
                          required: false,
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }

                                    setSheetState(() {
                                      isSubmitting = true;
                                    });

                                    try {
                                      await _mahasiswaService.uploadDokumen(
                                        jenisDokumen: jenisController.text,
                                        judulDokumen: judulController.text,
                                        deskripsi: deskripsiController.text,
                                        catatanRevisi: catatanController.text,
                                        file: file,
                                      );

                                      if (!mounted) return;

                                      // tutup sheet
                                      if (Navigator.canPop(sheetContext)) {
                                        Navigator.pop(sheetContext);
                                      }

                                      // tunggu sheet hilang
                                      await Future.delayed(Duration.zero);

                                      if (!mounted) return;

                                      // refresh halaman
                                      await _loadDocuments();

                                      if (!mounted) return;

                                      AppSnackBars.success(context, 'Dokumen berhasil diunggah.');
                                    } catch (e) {
                                      if (!mounted) return;

                                      setSheetState(() {
                                        isSubmitting = false;
                                      });

                                      AppSnackBars.error(
                                        context,
                                        e
                                            .toString()
                                            .replaceFirst('Exception: ', ''),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : const Text(
                                    'Upload Document',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await Future.delayed(Duration.zero);

    jenisController.dispose();
    judulController.dispose();
    deskripsiController.dispose();
    catatanController.dispose();
  }

  Future<void> _showUploadVersionSheet(Map<String, dynamic> document) async {
    final dokumenId = int.tryParse(document['dokumen_id']?.toString() ?? '');

    if (dokumenId == null) {
      AppSnackBars.error(context, 'ID dokumen tidak valid.');
      return;
    }

    final file = await _pickAllowedFile();

    if (file == null) return;

    final catatanController = TextEditingController();
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusXl),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.cardBorder,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Upload New Version',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        document['judul_dokumen']?.toString() ?? '-',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSelectedFileCard(file),
                      const SizedBox(height: 18),
                      _buildTextFormField(
                        controller: catatanController,
                        label: 'Revision Note',
                        hint: 'Optional note for this new version...',
                        maxLines: 4,
                        required: false,
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  setSheetState(() {
                                    isSubmitting = true;
                                  });

                                  try {
                                    await _mahasiswaService.uploadVersiDokumen(
                                      dokumenId: dokumenId,
                                      catatanRevisi: catatanController.text,
                                      file: file,
                                    );

                                    if (!mounted) return;

                                    if (Navigator.canPop(sheetContext)) {
                                      Navigator.pop(sheetContext);
                                    }

                                    await Future.delayed(Duration.zero);

                                    if (!mounted) return;

                                    await _loadDocuments();

                                    if (!mounted) return;

                                    AppSnackBars.success(
                                      context,
                                      'Versi baru dokumen berhasil diunggah.',
                                    );
                                  } catch (e) {
                                    if (!mounted) return;

                                    setSheetState(() {
                                      isSubmitting = false;
                                    });

                                    AppSnackBars.error(
                                      context,
                                      e.toString().replaceFirst('Exception: ', ''),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : const Text(
                                  'Upload Version',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await Future.delayed(Duration.zero);

    catatanController.dispose();
  }

  void _showDocumentOptions(Map<String, dynamic> document) {
    final latestVersion = document['versi_terbaru'] is Map
        ? Map<String, dynamic>.from(document['versi_terbaru'])
        : <String, dynamic>{};

    final status = latestVersion['status_versi']?.toString();
    final versionNumber = latestVersion['nomor_versi']?.toString() ?? '-';
    final description = document['deskripsi']?.toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
              const SizedBox(height: 22),
              Icon(
                _documentIcon(
                  _fileExtension(
                    latestVersion['file_url']?.toString() ?? '',
                  ),
                ),
                color: AppTheme.primary,
                size: 52,
              ),
              const SizedBox(height: 12),
              Text(
                document['judul_dokumen']?.toString() ?? '-',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                document['jenis_dokumen']?.toString() ?? '-',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _buildDetailRow('Latest Version', 'V$versionNumber'),
              _buildDetailRow('Status', _formatStatus(status)),
              _buildDetailRow(
                'Uploaded',
                _formatDateTime(latestVersion['uploaded_at']?.toString()),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showVersionHistorySheet(document);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppTheme.primary,
                          width: 1.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Versions',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showUploadVersionSheet(document);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'New Version',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVersionHistorySheet(Map<String, dynamic> document) {
    final dokumenId = int.tryParse(document['dokumen_id']?.toString() ?? '');

    if (dokumenId == null) {
      AppSnackBars.error(context, 'ID dokumen tidak valid.');
      return;
    }

    final future = _mahasiswaService.getRiwayatVersiDokumen(
      dokumenId: dokumenId,
      perPage: 30,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.72,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: FutureBuilder<Map<String, dynamic>>(
            future: future,
            builder: (context, snapshot) {
              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting;

              if (isLoading) {
                return const Center(
                  child: AppLoadingWidget(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.declined),
                  ),
                );
              }

              final data = snapshot.data ?? {};
              final versiRaw = data['versi'];

              final versions = versiRaw is List
                  ? versiRaw
                      .whereType<Map>()
                      .map((item) => Map<String, dynamic>.from(item))
                      .toList()
                  : <Map<String, dynamic>>[];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBorder,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Document Versions',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    document['judul_dokumen']?.toString() ?? '-',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: versions.isEmpty
                        ? const AppEmptyStateWidget(
                            compact: true,
                            icon: Icons.history_rounded,
                            title: 'No version history yet.',
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

  void _showCommentsBottomSheet() {
    final future = _loadAllFeedback();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.72,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: AppLoadingWidget());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.declined),
                  ),
                );
              }

              final comments = snapshot.data ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBorder,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Dosen Pembimbing Comments',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Riwayat masukan dari dosen untuk dokumenmu.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: comments.isEmpty
                        ? const AppEmptyStateWidget(
                            compact: true,
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'No feedback yet.',
                          )
                        : ListView.builder(
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              return _buildFeedbackTimelineItem(
                                comments[index],
                                index == comments.length - 1,
                              );
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

  Widget _buildFeedbackTimelineItem(
    Map<String, dynamic> feedback,
    bool isLast,
  ) {
    final dosen = feedback['dosen'] is Map
        ? Map<String, dynamic>.from(feedback['dosen'])
        : <String, dynamic>{};

    final page = feedback['halaman']?.toString();
    final position = feedback['posisi_anotasi']?.toString();
    final docTitle = feedback['judul_dokumen']?.toString() ?? '-';
    final version = feedback['nomor_versi']?.toString() ?? '-';

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : AppTheme.cardBorder,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$docTitle • V$version',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Text(feedback['komentar']?.toString() ?? '-'),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    [
                      if (dosen['nama'] != null) 'By ${dosen['nama']}',
                      if (page != null && page.isNotEmpty) 'Page $page',
                      if (position != null && position.isNotEmpty) position,
                      _formatDateTime(feedback['created_at']?.toString()),
                    ].join(' • '),
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionItem(Map<String, dynamic> version) {
    final status = version['status_versi']?.toString();
    final uploader = version['uploader'] is Map
        ? Map<String, dynamic>.from(version['uploader'])
        : <String, dynamic>{};

    final uploaderName = uploader['nama']?.toString() ?? '-';
    final note = version['catatan_revisi']?.toString();

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _statusColor(status),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: AppTheme.cardBorder,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Version ${version['nomor_versi'] ?? '-'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Text(
                      note == null || note.isEmpty
                          ? 'Uploaded by $uploaderName'
                          : note,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatStatus(status)} • ${_formatDateTime(version['uploaded_at']?.toString())}',
                    style: TextStyle(
                      color: _statusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
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
                              isDosen: false,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('Buka Dokumen & Anotasi'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFileCard(PlatformFile file) {
    final extension = _fileExtension(file.name);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Icon(
            _documentIcon(extension),
            color: AppTheme.primary,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB',
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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? validatorMessage,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLines > 1 ? 1000 : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppTheme.surfaceVariant,
        counterStyle: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(
            color: AppTheme.primary,
            width: 1.5,
          ),
        ),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';

        if (required && text.isEmpty) {
          return validatorMessage ?? 'Field wajib diisi.';
        }

        if (text.length > 1000) {
          return 'Maksimal 1000 karakter.';
        }

        return null;
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(top: 16),
            child: AppSkeletonLoader.card(count: 4),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: AppErrorWidget(
          title: 'Failed to load documents',
          message: _errorMessage ?? '-',
          retryLabel: 'Try Again',
          onRetry: _loadDocuments,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _loadDocuments,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 40, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload your Docs here!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            "and don't forget to tell your lecturer :)",
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: _documents.isEmpty
                            ? _buildEmptyState()
                            : _buildDocumentGrid(),
                      ),
                    ),
                  ],
                ),

                if (_documents.isNotEmpty)
                  Positioned(
                    bottom: 95,
                    left: 24,
                    child: _buildCommentButton(),
                  ),

                Positioned(
                  bottom: 95,
                  right: 24,
                  child: _buildNewButton(),
                ),
              ],
            )
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      key: const ValueKey('empty'),
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 140),
        AppEmptyStateWidget(
          icon: Icons.upload_file_rounded,
          title: 'no documents yet',
          subtitle: 'Ketuk tombol New untuk mengunggah dokumen bimbingan TA.',
        ),
      ],
    );
  }

  Widget _buildDocumentGrid() {
    return GridView.builder(
      key: const ValueKey('grid'),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final doc = _documents[index];

        final latestVersion = doc['versi_terbaru'] is Map
            ? Map<String, dynamic>.from(doc['versi_terbaru'])
            : <String, dynamic>{};

        final fileUrl = latestVersion['file_url']?.toString() ?? '';
        final extension = _fileExtension(fileUrl);
        final status = latestVersion['status_versi']?.toString();
        final versionNumber = latestVersion['nomor_versi']?.toString();

        return InkWell(
          onTap: () => _showDocumentOptions(doc),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            decoration: AppTheme.cardDecoration(radius: AppTheme.radiusMd),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _documentIcon(extension),
                    size: 58,
                    color: AppTheme.textPrimary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    doc['judul_dokumen']?.toString() ?? '-',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    doc['jenis_dokumen']?.toString() ?? '-',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    ),
                    child: Text(
                      'V${versionNumber ?? '-'} • ${_formatStatus(status)}',
                      style: TextStyle(
                        color: _statusColor(status),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showCommentsBottomSheet,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: AppTheme.primary,
                  size: 28,
                ),
                SizedBox(height: 4),
                Text(
                  'Comments',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showUploadDocumentSheet,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'New',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
