// Lib/Features/auth/view/login_page.dart
import 'dart:async';
import 'dart:ui';

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
    final isDark = AppTheme.isDark(context);
    final primaryNavy = AppTheme.primaryOf(context);
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final sheetTint = isDark
        ? AppTheme.darkSurface.withValues(alpha: 0.92)
        : AppTheme.surface.withValues(alpha: 0.92);
    final backdropColor = isDark ? AppTheme.darkBackground : AppTheme.primaryDark;

    return Scaffold(
      backgroundColor: backdropColor,
      body: ColoredBox(
        color: backdropColor,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  keyboardOpen ? 10 : 20,
                  24,
                  keyboardOpen ? 10 : 20,
                ),
                child: _buildTopBrandCard(),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusXl),
                    ),
                    boxShadow: AppTheme.floatingShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusXl),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                        decoration: BoxDecoration(
                          color: sheetTint,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppTheme.radiusXl),
                          ),
                          border: Border(
                            top: BorderSide(
                              color: AppTheme.accentGoldOnDark.withValues(alpha: 0.38),
                              width: 1.4,
                            ),
                          ),
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFormHeader(),
                                const SizedBox(height: 20),

                                _buildInputField(
                                  controller: _emailController,
                                  labelText: 'Email',
                                  hintText: 'Masukkan email Anda',
                                  prefixIcon: Icons.alternate_email_outlined,
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

                                const SizedBox(height: 16),

                                _buildInputField(
                                  controller: _passwordController,
                                  labelText: 'Kata Sandi',
                                  hintText: 'Masukkan kata sandi Anda',
                                  prefixIcon: Icons.lock_outlined,
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
                                        horizontal: 6,
                                        vertical: 8,
                                      ),
                                      minimumSize: const Size(44, 44),
                                      foregroundColor: primaryNavy,
                                    ),
                                    child: const Text(
                                      'Lupa kata sandi?',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      disabledBackgroundColor:
                                          primaryNavy.withValues(alpha: 0.6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(AppTheme.radiusMd),
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
                                            'Lanjutkan',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15.5,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                _buildDividerWithText('atau'),

                                const SizedBox(height: 20),

                                if (kIsWeb)
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Container(
                                        width: double.infinity,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: AppTheme.surfaceOf(context),
                                          borderRadius: BorderRadius.circular(
                                              AppTheme.radiusMd),
                                          border: Border.all(
                                            color: AppTheme.inputBorderOf(context),
                                          ),
                                        ),
                                        child: Center(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                                AppTheme.radiusMd),
                                            child: Transform.scale(
                                              scaleX: 1.0,
                                              scaleY: 1.16,
                                              child: google_web_button
                                                  .buildGoogleWebButton(
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
                                    label: 'Lanjutkan dengan Google',
                                    assetIconPath:
                                        'assets/images/google_iconbgnew.png',
                                    onTap: _isLoading ? () {} : _handleGoogleLogin,
                                  ),

                                const SizedBox(height: 12),

                                _socialButton(
                                  label: 'Portal Learning (Segera hadir)',
                                  icon: Icons.school_outlined,
                                  onTap: _goToLearningPage,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBrandCard() {
    final isDark = AppTheme.isDark(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkSurface.withValues(alpha: 0.92)
                    : AppTheme.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                border: Border.all(
                  color: AppTheme.accentGoldOnDark.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: AppTheme.floatingShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TAssist',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.primaryOf(context),
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sistem Bimbingan Tugas Akhir',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondaryOf(context),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
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

  Widget _buildFormHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Masuk',
          style: TextStyle(
            color: AppTheme.textPrimaryOf(context),
            fontSize: 23,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Masuk untuk melanjutkan bimbingan TA.',
          style: TextStyle(
            color: AppTheme.textSecondaryOf(context),
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildDividerWithText(String text) {
    final border = AppTheme.inputBorderOf(context).withValues(alpha: 0.45);
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: border,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            text,
            style: TextStyle(
              color: AppTheme.textSecondaryOf(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: border,
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
    final border = AppTheme.inputBorderOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final accent = AppTheme.primaryOf(context);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: TextStyle(
        color: textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        filled: true,
        fillColor: AppTheme.surfaceOf(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(
                prefixIcon,
                color: textSecondary,
              ),
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(
          color: textSecondary,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: AppTheme.textMutedOf(context),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(
            color: AppTheme.isDark(context) ? accent : AppTheme.primaryLight,
            width: 1.5,
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
    final textPrimary = AppTheme.textPrimaryOf(context);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppTheme.surfaceOf(context),
        foregroundColor: textPrimary,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(color: AppTheme.inputBorderOf(context)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
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
              size: 22,
              color: textPrimary,
            ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}