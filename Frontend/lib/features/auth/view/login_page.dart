// Lib/Features/auth/view/login_page.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/google_web_button/google_button.dart' as google_web_button;

import 'package:flutter/material.dart';
import '../../../app/app.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_snackbars.dart';
import '../data/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleAuthSubscription;

  @override
  void initState() {
    super.initState();
    _setupGoogleWebSignIn();
  }

  Future<void> _setupGoogleWebSignIn() async {
    if (!kIsWeb) return;

    try {
      await _authService.initGoogleSignIn();

      _googleAuthSubscription ??=
          GoogleSignIn.instance.authenticationEvents.listen(
        _handleGoogleWebAuthEvent,
        onError: _handleGoogleWebAuthError,
      );
    } catch (e) {
      if (!mounted) return;

      AppSnackBars.error(context, 'Gagal menyiapkan Google Sign-In: $e');
    }
  }

  Future<void> _handleGoogleWebAuthEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    final GoogleSignInAccount? user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    if (user == null) return;

    final String? idToken = user.authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      if (!mounted) return;

      AppSnackBars.error(
        context,
        'ID Token Google kosong. Cek konfigurasi Google Cloud.',
      );
      return;
    }

    await _continueGoogleLoginWithIdToken(idToken);
  }

  void _handleGoogleWebAuthError(Object error) {
    if (!mounted) return;

    AppSnackBars.error(context, 'Login Google gagal: $error');
  }

  Future<void> _continueGoogleLoginWithIdToken(String idToken) async {
    setState(() {
      _isLoading = true;
    });

    final result = await _authService.loginWithGoogleIdToken(idToken);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    _handleGoogleLoginResult(result);
  }

  void _handleGoogleLoginResult(AuthResult result) {
    if (result.isSuccess) {
      if (result.role == 'dosen') {
        Navigator.pushReplacementNamed(
          context,
          TAssistApp.dashboardDosenRoute,
        );
      } else if (result.role == 'mahasiswa') {
        if (result.needCompleteMahasiswaProfile) {
          Navigator.pushReplacementNamed(
            context,
            TAssistApp.completeStudentProfileRoute,
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            TAssistApp.dashboardRoute,
          );
        }
      } else {
        AppSnackBars.error(context, 'Role pengguna tidak dikenali.');
      }
    } else {
      AppSnackBars.error(context, result.message);
    }
  }

  @override
  void dispose() {
    _googleAuthSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      AppSnackBars.success(context, 'Login berhasil.');

      if (result.role == 'dosen') {
        Navigator.pushReplacementNamed(
          context,
          TAssistApp.dashboardDosenRoute,
        );
      } else if (result.role == 'mahasiswa') {
        Navigator.pushReplacementNamed(
          context,
          TAssistApp.dashboardRoute,
        );
      } else {
        AppSnackBars.error(context, 'Role pengguna tidak dikenali.');
      }
    } else {
      AppSnackBars.error(context, result.message);
    }
  }

  void _showForgotPasswordInfo() {
    AppSnackBars.info(context, 'Fitur forgot password belum tersedia.');
  }

  void _goToLearningPage() {
    Navigator.pushNamed(context, TAssistApp.learningRoute);
  }

  Future<void> _handleGoogleLogin() async {
    if (kIsWeb) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.loginWithGoogle();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    _handleGoogleLoginResult(result);
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = AppTheme.primary;
    final size = MediaQuery.of(context).size;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(
                color: AppTheme.primaryGhost,
              ),
            ),

            _buildFloatingEducationIcons(),

            // Top brand card
            Positioned(
              top: keyboardOpen ? 18 : size.height * 0.065,
              left: 24,
              right: 24,
              child: _buildTopBrandCard(),
            ),

            // Bottom login card
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: double.infinity,
                height: size.height * (keyboardOpen ? 0.82 : 0.70),
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusXl),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 24,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormHeader(),
                        const SizedBox(height: 26),

                        _buildInputField(
                          controller: _emailController,
                          labelText: 'Email',
                          hintText: 'Enter your email',
                          prefixIcon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Email wajib diisi';
                            }

                            final emailRegex =
                                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

                            if (!emailRegex.hasMatch(text)) {
                              return 'Format email tidak valid';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        _buildInputField(
                          controller: _passwordController,
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) {
                            if (!_isLoading) {
                              _handleLogin();
                            }
                          },
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Password wajib diisi';
                            }

                            if (text.length < 6) {
                              return 'Password minimal 6 karakter';
                            }

                            return null;
                          },
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordInfo,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              foregroundColor: AppTheme.primary,
                            ),
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              disabledBackgroundColor:
                                  primaryBlue.withValues(alpha: 0.65),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'CONTINUE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        _buildDividerWithText('or'),

                        const SizedBox(height: 24),

                        if (kIsWeb)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  border: Border.all(
                                    color: AppTheme.cardBorder,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.035),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                    child: Transform.scale(
                                      scaleX: 1.0,
                                      scaleY: 1.16,
                                      child:
                                          google_web_button.buildGoogleWebButton(
                                        width: constraints.maxWidth,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        else
                          _socialButton(
                            label: 'Continue with Google',
                            assetIconPath:
                                'assets/images/google_iconbgnew.png',
                            onTap: _isLoading ? () {} : _handleGoogleLogin,
                          ),

                        const SizedBox(height: 16),

                        _socialButton(
                          label: 'Lanjutkan dengan Learning',
                          icon: Icons.school_outlined,
                          onTap: _goToLearningPage,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingEducationIcons() {
    return IgnorePointer(
      child: Stack(
        children: [
          _floatingEducationIcon(
            top: 24,
            left: 26,
            size: 46,
            opacity: 0.08,
            rotate: -0.22,
          ),
          _floatingEducationIcon(
            top: 52,
            right: 34,
            size: 54,
            opacity: 0.07,
            rotate: 0.18,
          ),
          _floatingEducationIcon(
            top: 136,
            left: 58,
            size: 38,
            opacity: 0.055,
            rotate: 0.28,
          ),
          _floatingEducationIcon(
            top: 148,
            right: 64,
            size: 42,
            opacity: 0.06,
            rotate: -0.18,
          ),
        ],
      ),
    );
  }

  Widget _floatingEducationIcon({
    double? top,
    double? left,
    double? right,
    required double size,
    required double opacity,
    required double rotate,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: rotate,
        child: Icon(
          Icons.school_outlined,
          size: size,
          color: AppTheme.primary.withValues(alpha: opacity),
        ),
      ),
    );
  }

  Widget _buildTopBrandCard() {
    return Center(
      child: Container(
        width: 268,
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 20,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: AppTheme.cardBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TAssist',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Sistem Bimbingan Tugas Akhir',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sign In',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Masuk untuk melanjutkan bimbingan TA-mu.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDividerWithText(String text) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: AppTheme.cardBorder,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: AppTheme.cardBorder,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    String? labelText,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        filled: true,
        fillColor: AppTheme.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(
                prefixIcon,
                color: AppTheme.textSecondary,
              ),
        suffixIcon: suffixIcon,
        labelStyle: const TextStyle(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppTheme.primary,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
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
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.declined),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.declined),
        ),
      ),
    );
  }

  Widget _socialButton({
    required String label,
    String? assetIconPath,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          width: double.infinity,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: AppTheme.cardBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (assetIconPath != null)
                Image.asset(
                  assetIconPath,
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                )
              else if (icon != null)
                Icon(
                  icon,
                  size: 24,
                  color: Colors.black87,
                ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}