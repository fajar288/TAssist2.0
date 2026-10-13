import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../data/auth_service.dart';

class CompleteStudentProfilePage extends StatefulWidget {
  const CompleteStudentProfilePage({super.key});

  @override
  State<CompleteStudentProfilePage> createState() =>
      _CompleteStudentProfilePageState();
}

class _CompleteStudentProfilePageState
    extends State<CompleteStudentProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nimController = TextEditingController();
  final _prodiController = TextEditingController();
  final _angkatanController = TextEditingController();
  final _topikTaController = TextEditingController();
  final _judulTaController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isInitialLoading = true;
  bool _isSubmitting = false;

  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

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

    _preparePage();
  }

  Future<void> _preparePage() async {
    await Future.delayed(const Duration(milliseconds: 750));

    if (!mounted) return;

    setState(() {
      _isInitialLoading = false;
    });

    _entryController.forward();
  }

  @override
  void dispose() {
    _nimController.dispose();
    _prodiController.dispose();
    _angkatanController.dispose();
    _topikTaController.dispose();
    _judulTaController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final angkatan = int.tryParse(_angkatanController.text.trim());

    if (angkatan == null) {
      _showSnackBar('Angkatan harus berupa angka.', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await _authService.completeMahasiswaProfile(
      nim: _nimController.text,
      prodi: _prodiController.text,
      angkatan: angkatan,
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

      Navigator.pushNamedAndRemoveUntil(
        context,
        TAssistApp.dashboardRoute,
        (route) => false,
      );
    } else {
      _showSnackBar(result.message, isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF0D47A1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF0D47A1);

    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FF),
      body: SafeArea(
        child: _isInitialLoading
            ? const _CompleteProfileSkeleton()
            : FadeTransition(
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
                            color: Colors.white,
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
                                _buildInputField(
                                  controller: _nimController,
                                  label: 'NIM',
                                  hintText: 'Contoh: 3312301001',
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    final text = value?.trim() ?? '';
                                    if (text.isEmpty) {
                                      return 'NIM wajib diisi';
                                    }
                                    if (text.length < 5) {
                                      return 'NIM terlalu pendek';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  controller: _prodiController,
                                  label: 'Program Studi',
                                  hintText: 'Contoh: Teknik Informatika',
                                  validator: (value) {
                                    final text = value?.trim() ?? '';
                                    if (text.isEmpty) {
                                      return 'Program studi wajib diisi';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  controller: _angkatanController,
                                  label: 'Angkatan',
                                  hintText: 'Contoh: 2023',
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    final text = value?.trim() ?? '';
                                    final year = int.tryParse(text);
                                    final currentYear = DateTime.now().year;

                                    if (text.isEmpty) {
                                      return 'Angkatan wajib diisi';
                                    }

                                    if (year == null) {
                                      return 'Angkatan harus berupa angka';
                                    }

                                    if (year < 2000 ||
                                        year > currentYear + 1) {
                                      return 'Angkatan tidak valid';
                                    }

                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  controller: _topikTaController,
                                  label: 'Topik TA',
                                  hintText:
                                      'Contoh: Sistem Informasi Bimbingan TA',
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  controller: _judulTaController,
                                  label: 'Judul TA',
                                  hintText:
                                      'Contoh: Pengembangan Aplikasi TAsisst',
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 24),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isSubmitting ? null : _submitProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBlue,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          primaryBlue.withOpacity(0.55),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      child: _isSubmitting
                                          ? const SizedBox(
                                              key: ValueKey('loading'),
                                              width: 22,
                                              height: 22,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              key: ValueKey('text'),
                                              'SIMPAN PROFIL',
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
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lengkapi Profil',
          style: TextStyle(
            color: Color(0xFF0D47A1),
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Data ini diperlukan agar akun mahasiswa kamu bisa menggunakan fitur bimbingan TA dengan lengkap.',
          style: TextStyle(
            color: Colors.black.withOpacity(0.62),
            fontSize: 14.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1F2A44),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: !_isSubmitting,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: const Color(0xFFF8FBFF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2F49D1)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompleteProfileSkeleton extends StatefulWidget {
  const _CompleteProfileSkeleton();

  @override
  State<_CompleteProfileSkeleton> createState() =>
      _CompleteProfileSkeletonState();
}

class _CompleteProfileSkeletonState extends State<_CompleteProfileSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _box({
    required double height,
    double? width,
    double radius = 16,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width ?? double.infinity,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + _animation.value, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                Color(0xFFE8EEF7),
                Color(0xFFF7FAFF),
                Color(0xFFE8EEF7),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(width: 210, height: 32, radius: 12),
          const SizedBox(height: 12),
          _box(height: 16, radius: 8),
          const SizedBox(height: 8),
          _box(width: 260, height: 16, radius: 8),
          const SizedBox(height: 26),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.82),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                _box(height: 18, radius: 8),
                const SizedBox(height: 10),
                _box(height: 54),
                const SizedBox(height: 18),
                _box(height: 18, radius: 8),
                const SizedBox(height: 10),
                _box(height: 54),
                const SizedBox(height: 18),
                _box(height: 18, radius: 8),
                const SizedBox(height: 10),
                _box(height: 54),
                const SizedBox(height: 18),
                _box(height: 18, radius: 8),
                const SizedBox(height: 10),
                _box(height: 74),
                const SizedBox(height: 18),
                _box(height: 18, radius: 8),
                const SizedBox(height: 10),
                _box(height: 74),
                const SizedBox(height: 24),
                _box(height: 54, radius: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}