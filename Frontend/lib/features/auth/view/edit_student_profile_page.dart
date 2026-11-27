import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_snackbars.dart';
import '../../../widgets/user_avatar_circle.dart';
import '../data/auth_service.dart';

class EditStudentProfilePage extends StatefulWidget {
  final Map<String, dynamic> initialProfile;

  const EditStudentProfilePage({super.key, required this.initialProfile});

  @override
  State<EditStudentProfilePage> createState() => _EditStudentProfilePageState();
}

class _EditStudentProfilePageState extends State<EditStudentProfilePage>
    with SingleTickerProviderStateMixin {
  static const int _maxAvatarBytes = 2 * 1024 * 1024; // 2 MB

  final _formKey = GlobalKey<FormState>();

  final _topikTaController = TextEditingController();
  final _judulTaController = TextEditingController();

  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSubmitting = false;
  bool _didInitArgs = false;

  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  Map<String, dynamic> _profileData = {};
  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoName;
  String? _selectedPhotoPath;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutCubic,
      ),
    );

    _topikTaController.addListener(() => setState(() {}));
    _judulTaController.addListener(() => setState(() {}));
    _entryController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitArgs) return;
    _didInitArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _profileData = args;
      _topikTaController.text = _profileData['topik_ta']?.toString() ?? '';
      _judulTaController.text = _profileData['judul_ta']?.toString() ?? '';
    } else if (widget.initialProfile.isNotEmpty) {
      _profileData = widget.initialProfile;
      _topikTaController.text = widget.initialProfile['topik_ta']?.toString() ?? '';
      _judulTaController.text = widget.initialProfile['judul_ta']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _topikTaController.dispose();
    _judulTaController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final currentTopikTa = _topikTaController.text.trim();
    final currentJudulTa = _judulTaController.text.trim();
    final initialTopikTa = _profileData['topik_ta']?.toString().trim() ?? '';
    final initialJudulTa = _profileData['judul_ta']?.toString().trim() ?? '';

    return currentTopikTa != initialTopikTa ||
        currentJudulTa != initialJudulTa ||
        _selectedPhotoBytes != null;
  }

  Future<void> _showPhotoSourceSheet() async {
    if (_isSubmitting) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final surface = AppTheme.surfaceOf(ctx);
        final textPrimary = AppTheme.textPrimaryOf(ctx);
        final textSecondary = AppTheme.textSecondaryOf(ctx);
        final border = AppTheme.cardBorderOf(ctx);
        final accent = AppTheme.primaryOf(ctx);

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusLg),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: border,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                ),
                Text(
                  'Ubah Foto Profil',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Format JPG atau PNG dengan ukuran maksimal 2 MB.',
                  style: TextStyle(color: textSecondary, fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryGhostOf(ctx),
                    child: Icon(Icons.photo_library_outlined, color: accent),
                  ),
                  title: Text(
                    'Pilih dari Galeri',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPhoto(ImageSource.gallery);
                  },
                ),
                if (!kIsWeb)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryGhostOf(ctx),
                      child: Icon(Icons.photo_camera_outlined, color: accent),
                    ),
                    title: Text(
                      'Ambil dari Kamera',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickPhoto(ImageSource.camera);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      _applySelectedPhoto(
        bytes: bytes,
        fileName: picked.name,
        filePath: kIsWeb ? null : picked.path,
      );
    } on MissingPluginException {
      await _pickWithFilePickerFallback();
    } on UnimplementedError {
      await _pickWithFilePickerFallback();
    } on PlatformException catch (e) {
      if (source == ImageSource.camera) {
        if (mounted) {
          AppSnackBars.warning(
            context,
            'Kamera tidak tersedia di perangkat ini. Membuka pemilih file...',
          );
        }
        await _pickWithFilePickerFallback();
      } else if (mounted) {
        AppSnackBars.error(context, 'Gagal memilih foto: ${e.message ?? e.code}');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBars.error(context, 'Gagal memilih foto: $e');
      }
    }
  }

  Future<void> _pickWithFilePickerFallback() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        if (mounted) {
          AppSnackBars.error(context, 'File gambar tidak dapat dibaca.');
        }
        return;
      }

      _applySelectedPhoto(
        bytes: bytes,
        fileName: file.name,
        filePath: kIsWeb ? null : file.path,
      );
    } catch (e) {
      if (mounted) {
        AppSnackBars.error(context, 'Gagal membuka file gambar: $e');
      }
    }
  }

  void _applySelectedPhoto({
    required Uint8List bytes,
    required String fileName,
    String? filePath,
  }) {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    if (!const ['jpg', 'jpeg', 'png'].contains(ext)) {
      if (mounted) {
        AppSnackBars.error(
          context,
          'Format foto harus JPG, JPEG, atau PNG.',
        );
      }
      return;
    }

    if (bytes.lengthInBytes > _maxAvatarBytes) {
      if (mounted) {
        AppSnackBars.error(
          context,
          'Ukuran foto profil maksimal 2 MB.',
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _selectedPhotoBytes = bytes;
      _selectedPhotoName = fileName;
      _selectedPhotoPath = filePath;
    });
  }

  Future<void> _submitProfile() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) return;

    setState(() {
      _isSubmitting = true;
    });

    final result = await _authService.updateMahasiswaProfile(
      topikTa: _topikTaController.text,
      judulTa: _judulTaController.text,
      avatarBytes: _selectedPhotoBytes,
      avatarFilename: _selectedPhotoName,
      avatarPath: _selectedPhotoPath,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result.isSuccess) {
      AppSnackBars.success(context, result.message);

      await Future.delayed(const Duration(milliseconds: 450));

      if (!mounted) return;

      Navigator.pop(context, true);
    } else {
      AppSnackBars.error(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.backgroundOf(context);
    final surface = AppTheme.surfaceOf(context);
    final primary = AppTheme.primaryOf(context);
    final displayName = _profileData['nama']?.toString() ?? 'Mahasiswa';
    final existingAvatar = _profileData['avatar']?.toString();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profil Mahasiswa',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perbarui foto profil, topik, dan judul TA Anda. NIM, program studi, dan angkatan tidak dapat diubah.',
                  style: TextStyle(
                    color: AppTheme.textSecondaryOf(context),
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          UserAvatarCircle(
                            name: displayName,
                            avatar: existingAvatar,
                            localBytes: _selectedPhotoBytes,
                            size: 108,
                            borderColor: surface,
                            borderWidth: 4,
                            showShadow: true,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Semantics(
                              button: true,
                              label: 'Ubah foto profil',
                              child: Tooltip(
                                message: 'Ubah foto profil',
                                child: InkWell(
                                  onTap: _showPhotoSourceSheet,
                                  customBorder: const CircleBorder(),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: surface, width: 2.5),
                                    ),
                                    child: const Icon(
                                      Icons.photo_camera_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _showPhotoSourceSheet,
                        icon: Icon(Icons.photo_camera_outlined, size: 18, color: primary),
                        label: Text(
                          _selectedPhotoBytes != null
                              ? 'Ganti Foto (${_selectedPhotoName ?? 'baru'})'
                              : 'Ubah Foto Profil',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecorationOf(
                    context,
                    radius: AppTheme.radiusXl,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildReadOnlyField(
                          context,
                          label: 'NIM',
                          value: _profileData['nim']?.toString() ?? '-',
                        ),
                        const SizedBox(height: 16),
                        _buildReadOnlyField(
                          context,
                          label: 'Program Studi',
                          value: _profileData['prodi']?.toString() ?? '-',
                        ),
                        const SizedBox(height: 16),
                        _buildReadOnlyField(
                          context,
                          label: 'Angkatan',
                          value: _profileData['angkatan']?.toString() ?? '-',
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          context,
                          controller: _topikTaController,
                          label: 'Topik TA',
                          hintText: 'Contoh: Sistem Informasi Bimbingan TA',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          context,
                          controller: _judulTaController,
                          label: 'Judul TA',
                          hintText: 'Contoh: Pengembangan Aplikasi TAssist',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _hasChanges && !_isSubmitting ? _submitProfile : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasChanges
                                  ? AppTheme.primary
                                  : AppTheme.textMutedOf(context),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppTheme.textMutedOf(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                              elevation: 0,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      key: ValueKey('loading'),
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      key: ValueKey('text'),
                                      'Simpan Perubahan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondaryOf(context),
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariantOf(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: AppTheme.cardBorderOf(context),
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimaryOf(context),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hintText,
    int maxLines = 1,
  }) {
    final textPrimary = AppTheme.textPrimaryOf(context);
    final primary = AppTheme.primaryOf(context);
    final borderColor = AppTheme.cardBorderOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          enabled: !_isSubmitting,
          style: TextStyle(color: textPrimary),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.length > 500) {
              return 'Maksimal 500 karakter';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: AppTheme.textMutedOf(context)),
            filled: true,
            fillColor: AppTheme.surfaceOf(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(color: primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(color: AppTheme.declined),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(color: AppTheme.declined, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}