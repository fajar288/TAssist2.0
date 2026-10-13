import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../data/auth_service.dart';

class EditStudentProfilePage extends StatefulWidget {
  final Map<String, dynamic> initialProfile;

  const EditStudentProfilePage({super.key, required this.initialProfile});

  @override
  State<EditStudentProfilePage> createState() => _EditStudentProfilePageState();
}

class _EditStudentProfilePageState extends State<EditStudentProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _topikTaController = TextEditingController();
  final _judulTaController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isSubmitting = false;

  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  Map<String, dynamic> _profileData = {};

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

    _entryController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

    return currentTopikTa != initialTopikTa || currentJudulTa != initialJudulTa;
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
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result.isSuccess) {
      _showSnackBar(result.message);

      await Future.delayed(const Duration(milliseconds: 450));

      if (!mounted) return;

      Navigator.pop(context, true);
    } else {
      _showSnackBar(result.message, isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildReadOnlyField(
                          label: 'NIM',
                          value: _profileData['nim']?.toString() ?? '-',
                        ),
                        const SizedBox(height: 16),
                        _buildReadOnlyField(
                          label: 'Program Studi',
                          value: _profileData['prodi']?.toString() ?? '-',
                        ),
                        const SizedBox(height: 16),
                        _buildReadOnlyField(
                          label: 'Angkatan',
                          value: _profileData['angkatan']?.toString() ?? '-',
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          controller: _topikTaController,
                          label: 'Topik TA',
                          hintText: 'Contoh: Sistem Informasi Bimbingan TA',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          controller: _judulTaController,
                          label: 'Judul TA',
                          hintText: 'Contoh: Pengembangan Aplikasi TAsisst',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _hasChanges && !_isSubmitting ? _submitProfile : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasChanges ? AppTheme.primary : AppTheme.textMuted,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppTheme.textMuted,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
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
                                      'SIMPAN PERUBAHAN',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Edit Profil Mahasiswa',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Perbarui topik dan judul TA Anda. NIM, program studi, dan angkatan tidak dapat diubah.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.primaryGhost,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryLight.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          enabled: !_isSubmitting,
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.length > 500) {
              return 'Maksimal 500 karakter';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: AppTheme.primaryGhost,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primaryLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primaryLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}