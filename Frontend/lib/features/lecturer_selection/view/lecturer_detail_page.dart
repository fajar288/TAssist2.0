import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import 'package:tassist/features/main_mahasiswa/data/mahasiswa_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_loading_widget.dart';
import '../../../widgets/app_snackbars.dart';
import '../../main_mahasiswa/navbar_mahasiswa.dart';
import 'lecturers_page.dart';

class LecturerDetailPage extends StatefulWidget {
  final LecturerModel lecturer;

  const LecturerDetailPage({
    super.key,
    required this.lecturer,
  });

  @override
  State<LecturerDetailPage> createState() => _LecturerDetailPageState();
}

class _LecturerDetailPageState extends State<LecturerDetailPage> {
  final MahasiswaService _mahasiswaService = MahasiswaService();

  bool _isLoadingRequestStatus = true;
  bool _isSubmitting = false;
  String? _requestStatus;
  Map<String, dynamic>? _latestRequest;

  LecturerModel get lecturer => widget.lecturer;

  @override
  void initState() {
    super.initState();
    _loadExistingRequest();
  }

  Future<void> _loadExistingRequest() async {
    setState(() {
      _isLoadingRequestStatus = true;
    });

    try {
      final requests = await _mahasiswaService.getPermohonan(perPage: 50);

      Map<String, dynamic>? latestForThisLecturer;

      for (final request in requests) {
        final dosen = request['dosen'];

        if (dosen is Map) {
          final dosenId = dosen['dosen_id']?.toString();

          if (dosenId == lecturer.id) {
            latestForThisLecturer = request;
            break;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _latestRequest = latestForThisLecturer;
        _requestStatus = latestForThisLecturer?['status']?.toString();
        _isLoadingRequestStatus = false;
      });
    } catch (e) {
      debugPrint('LecturerDetailPage: _loadRequestStatus failed: $e');
      if (!mounted) return;

      setState(() {
        _isLoadingRequestStatus = false;
      });
    }
  }

  Future<void> _showRequestDialog() async {
    final result = await showDialog<_ProposalRequestResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _RequestCounselingDialog(
          lecturerName: lecturer.name,
        );
      },
    );

    if (!mounted) return;

    if (result == null || result.topikTa.trim().isEmpty) {
      return;
    }

    await _submitRequest(
      result.topikTa.trim(),
      proposalFile: result.proposalFile,
    );
  }

  Future<void> _submitRequest(
    String topikTa, {
    ApiFile? proposalFile,
  }) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await _mahasiswaService.ajukanPermohonan(
        dosenId: int.parse(lecturer.id),
        topikTa: topikTa,
        proposalFile: proposalFile,
      );

      if (!mounted) return;

      AppSnackBars.success(
        context,
        'Request counseling with ${lecturer.name} submitted successfully.',
      );

      await _loadExistingRequest();
    } catch (e) {
      if (!mounted) return;

      AppSnackBars.error(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  bool get _isBlockedByExistingRequest {
    final status = _requestStatus?.toLowerCase();

    return status == 'menunggu' || status == 'diterima';
  }

  String _formatStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'menunggu':
        return 'Waiting for lecturer response';
      case 'diterima':
        return 'Accepted by lecturer';
      case 'ditolak':
        return 'Rejected by lecturer';
      default:
        return '-';
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'menunggu':
        return AppTheme.pending;
      case 'diterima':
        return AppTheme.accepted;
      case 'ditolak':
        return AppTheme.declined;
      default:
        return AppTheme.textSecondaryOf(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOf(context),
      extendBody: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 110),
          child: Column(
            children: [
              const SizedBox(height: 18),
              _buildHeader(context),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildDetailCard(context),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavbarMahasiswa(
        currentIndex: 0,
        onTap: (index) {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryOf(context);
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Kembali',
              icon: Icon(
                Icons.arrow_back_ios_new_outlined,
                color: textPrimary,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Text(
            'Detail Dosen',
            style: TextStyle(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context) {
    final cardBorder = AppTheme.cardBorderOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecorationOf(context, radius: AppTheme.radiusLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Image.network(
              lecturer.imageUrl,
              height: 280,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  height: 280,
                  width: double.infinity,
                  color: cardBorder,
                  child: Center(
                    child: Icon(
                      Icons.person_outline,
                      color: textSecondary,
                      size: 80,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoRow('Nama :', lecturer.displayName),
          const SizedBox(height: 12),
          _buildInfoRow('NID :', lecturer.nid),
          const SizedBox(height: 12),
          _buildInfoRow('Keahlian :', lecturer.bidangKeahlian),
          if (lecturer.email != null && lecturer.email!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Email :', lecturer.email!),
          ],
          if (lecturer.profilSingkat != null &&
              lecturer.profilSingkat!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildProfileSection(lecturer.profilSingkat!),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'Sisa kuota bimbingan :',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGhostOf(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  '${lecturer.quotaLeft}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.primaryOf(context),
                  ),
                ),
              ),
            ],
          ),
          if (_latestRequest != null) ...[
            const SizedBox(height: 20),
            _buildRequestStatusCard(),
          ],
          const SizedBox(height: 32),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildRequestStatusCard() {
    final status = _requestStatus;
    final topikTa = _latestRequest?['topik_ta']?.toString();
    final catatan = _latestRequest?['catatan_respons']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: _statusColor(status).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatStatus(status),
            style: TextStyle(
              color: _statusColor(status),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (topikTa != null && topikTa.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              topikTa,
              style: TextStyle(
                color: AppTheme.textSecondaryOf(context),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (catatan != null && catatan.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Note: $catatan',
              style: TextStyle(
                color: AppTheme.textSecondaryOf(context),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isLoadingRequestStatus) {
      return const SizedBox(
        height: 52,
        child: Center(child: AppLoadingWidget(compact: true)),
      );
    }

    if (_isBlockedByExistingRequest) {
      final isAccepted = _requestStatus?.toLowerCase() == 'diterima';
      final badgeColor = _statusColor(_requestStatus);
      return Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariantOf(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.45),
          ),
        ),
        child: Text(
          isAccepted ? 'Sudah Diterima' : 'Sudah Diajukan',
          style: TextStyle(
            color: badgeColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (lecturer.quotaLeft <= 0) {
      return Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariantOf(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.cardBorderOf(context)),
        ),
        child: Text(
          'Kuota Penuh',
          style: TextStyle(
            color: AppTheme.textSecondaryOf(context),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _showRequestDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Request Counseling',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final textPrimary = AppTheme.textPrimaryOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection(String profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantOf(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Short Profile',
            style: TextStyle(
              color: AppTheme.textPrimaryOf(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile,
            style: TextStyle(
              color: AppTheme.textSecondaryOf(context),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProposalRequestResult {
  final String topikTa;
  final ApiFile? proposalFile;

  const _ProposalRequestResult({
    required this.topikTa,
    this.proposalFile,
  });
}

class _RequestCounselingDialog extends StatefulWidget {
  final String lecturerName;

  const _RequestCounselingDialog({
    required this.lecturerName,
  });

  @override
  State<_RequestCounselingDialog> createState() =>
      _RequestCounselingDialogState();
}

class _RequestCounselingDialogState extends State<_RequestCounselingDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _topicController;
  late final FocusNode _topicFocusNode;
  ApiFile? _pickedProposal;

  @override
  void initState() {
    super.initState();
    _topicController = TextEditingController();
    _topicFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _topicController.dispose();
    _topicFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickProposalPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final ApiFile? apiFile;
    if (file.bytes != null) {
      apiFile = ApiFile.fromBytes('file_proposal', file.bytes!, file.name);
    } else if (file.path != null) {
      apiFile = ApiFile.fromPath('file_proposal', file.path!, file.name);
    } else {
      apiFile = null;
    }

    if (apiFile != null && mounted) {
      setState(() => _pickedProposal = apiFile);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      _ProposalRequestResult(
        topikTa: _topicController.text.trim(),
        proposalFile: _pickedProposal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);
    final cardBorder = AppTheme.cardBorderOf(context);
    final primary = AppTheme.primaryOf(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: AppTheme.cardDecorationOf(context, radius: AppTheme.radiusXl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGhostOf(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school_outlined,
                  color: primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Ajukan Bimbingan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Kirim rencana topik TA untuk mengajukan bimbingan kepada ${widget.lecturerName}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _topicController,
                focusNode: _topicFocusNode,
                maxLines: 5,
                maxLength: 500,
                textInputAction: TextInputAction.newline,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
                decoration: InputDecoration(
                  labelText: 'Topik Tugas Akhir',
                  hintText: 'Contoh: Sistem Informasi Monitoring TA',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: AppTheme.surfaceVariantOf(context),
                  counterStyle: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(
                      color: cardBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(
                      color: cardBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(
                      color: primary,
                      width: 1.7,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: const BorderSide(
                      color: AppTheme.declined,
                      width: 1.4,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: const BorderSide(
                      color: AppTheme.declined,
                      width: 1.7,
                    ),
                  ),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return 'Topik TA wajib diisi.';
                  }

                  if (text.length > 500) {
                    return 'Topik TA maksimal 500 karakter.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickProposalPdf,
                icon: const Icon(Icons.attach_file_outlined, size: 18),
                label: Text(
                  _pickedProposal != null
                      ? 'Proposal: ${_pickedProposal!.filename}'
                      : 'Lampirkan Proposal PDF (Opsional)',
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  foregroundColor: primary,
                  side: BorderSide(color: cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: cardBorder,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}