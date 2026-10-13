import 'package:flutter/material.dart';
import 'package:produk/features/dosen/data/dosen_service.dart';
import 'package:produk/model/models.dart';

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
        return Colors.grey;
      case 'diajukan':
        return Colors.orange;
      case 'direvisi':
        return Colors.redAccent;
      case 'disetujui':
        return Colors.green;
      default:
        return Colors.grey;
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
    } catch (_) {
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
                borderRadius: BorderRadius.circular(18),
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    document['judul_dokumen']?.toString() ?? '-',
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    document['jenis_dokumen']?.toString() ?? '-',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: versions.isEmpty
                        ? const Center(
                            child: Text(
                              'No version history yet.',
                              style: TextStyle(color: Colors.black54),
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: Color(0xFF0D4AA3)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Version ${version['nomor_versi'] ?? '-'}',
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _formatStatus(status),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Uploaded at ${_formatDateTime(version['uploaded_at']?.toString())}',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          if (version['catatan_revisi'] != null &&
              version['catatan_revisi'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              version['catatan_revisi'].toString(),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
          if (feedback.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Existing Feedback',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ...feedback.take(3).map(_buildFeedbackPreview),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showFeedbackDialog(version),
              icon: const Icon(Icons.rate_review_rounded, size: 18),
              label: const Text('Give Feedback'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        page == null || page.isEmpty ? comment : 'Page $page: $comment',
        style: const TextStyle(
          color: Colors.black87,
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

    return InkWell(
      onTap: () => _showVersionsSheet(document),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1).withOpacity(0.09),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                _documentIcon(extension),
                color: const Color(0xFF0D47A1),
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
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    document['jenis_dokumen']?.toString() ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
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
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 180),
        Center(
          child: Text(
            'No documents uploaded yet.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 46,
            ),
            const SizedBox(height: 14),
            const Text(
              'Failed to load documents',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '-',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loadDocuments,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: const Text(
          'Student Documents',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF0D47A1),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
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
                      fontWeight: FontWeight.w900,
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
                          fontWeight: FontWeight.w900,
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
                ? const Center(child: CircularProgressIndicator())
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
