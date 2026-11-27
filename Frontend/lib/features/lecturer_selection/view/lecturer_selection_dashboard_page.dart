import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/app.dart';
import '../../auth/data/auth_service.dart';
import '../../notifikasi/widgets/notifikasi_bell_button.dart';
import 'package:tassist/features/main_mahasiswa/data/mahasiswa_service.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/theme_controller.dart';
import '../../../widgets/app_empty_state_widget.dart';
import '../../../widgets/app_error_widget.dart';
import '../../../widgets/app_loading_widget.dart';
import '../../../widgets/user_avatar_circle.dart';
import 'lecturer_recommendation_page.dart';
import 'lecturers_page.dart';

class LecturerSelectionDashboardPage extends StatefulWidget {
  const LecturerSelectionDashboardPage({super.key});

  @override
  State<LecturerSelectionDashboardPage> createState() =>
      _LecturerSelectionDashboardPageState();
}

class _LecturerSelectionDashboardPageState
    extends State<LecturerSelectionDashboardPage> {
  final MahasiswaService _mahasiswaService = MahasiswaService();
  final AuthService _authService = AuthService();

  String _studentName = 'Student';
  String? _userAvatar;
  Map<String, dynamic>? _profileData;

  final List<LecturerCategory> categories = const [
    LecturerCategory(
      title: 'AI & Machine Learning Lecturers',
      keyword: 'Kecerdasan Buatan',
      icon: Icons.psychology_outlined,
    ),
    LecturerCategory(
      title: 'Software Engineering Lecturers',
      keyword: 'Rekayasa Perangkat Lunak',
      icon: Icons.code_rounded,
    ),
    LecturerCategory(
      title: 'Network & Cybersecurity Lecturers',
      keyword: 'Jaringan Komputer',
      icon: Icons.security_outlined,
    ),
    LecturerCategory(
      title: 'Information Systems & Database Lecturers',
      keyword: 'Sistem Informasi',
      icon: Icons.storage_rounded,
    ),
    LecturerCategory(
      title: 'Computer Vision Lecturers',
      keyword: 'Computer Vision',
      icon: Icons.visibility_outlined,
    ),
  ];

  List<Map<String, dynamic>> _permohonanList = [];
  bool _isLoadingPermohonan = true;
  String? _permohonanError;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([
      _loadProfile(),
      _loadPermohonan(),
    ]);
  }

  Future<void> _loadProfile() async {
    try {
      final profileResponse = await _authService.getProfile();

      final profileData = profileResponse?['data'];

      String name = 'Student';
      String? avatar;
      Map<String, dynamic>? profile;

      if (profileData is Map<String, dynamic>) {
        final user = profileData['user'];

        if (user is Map<String, dynamic>) {
          name = user['nama']?.toString() ??
              user['name']?.toString() ??
              'Student';
          avatar = user['avatar']?.toString();
        }
        if (profileData['profile'] is Map<String, dynamic>) {
          profile = Map<String, dynamic>.from(profileData['profile']);
        }
      }

      if (!mounted) return;

      setState(() {
        _studentName = name;
        _userAvatar = avatar;
        _profileData = profile;
      });
    } catch (e) {
      debugPrint('LecturerSelectionDashboardPage: _loadProfile failed: $e');
      if (!mounted) return;

      setState(() {
        _studentName = 'Student';
      });
    }
  }

  Future<void> _loadPermohonan() async {
    setState(() {
      _isLoadingPermohonan = true;
      _permohonanError = null;
    });

    try {
      final rows = await _mahasiswaService.getPermohonan(perPage: 20);

      if (!mounted) return;

      setState(() {
        _permohonanList = rows;
        _isLoadingPermohonan = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _permohonanError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingPermohonan = false;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      TAssistApp.loginRoute,
      (route) => false,
    );
  }

  Future<void> _openLecturersPage({String? bidangKeahlian}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LecturersPage(
          initialBidangKeahlian: bidangKeahlian,
        ),
      ),
    );

    if (!mounted) return;

    _loadPermohonan();
  }

  void _showPermohonanDetail(Map<String, dynamic> request) {
    final dosen = request['dosen'] is Map
        ? Map<String, dynamic>.from(request['dosen'])
        : <String, dynamic>{};

    final namaDosen = dosen['nama']?.toString() ?? '-';
    final bidangKeahlian = dosen['bidang_keahlian']?.toString() ?? '-';
    final topikTa = request['topik_ta']?.toString() ?? '-';
    final tanggal = request['tanggal_pengajuan']?.toString() ?? '-';
    final status = request['status']?.toString() ?? '-';
    final catatan = request['catatan_respons']?.toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Counseling Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogLine('Lecturer', namaDosen),
              const SizedBox(height: 8),
              _dialogLine('Expertise', bidangKeahlian),
              const SizedBox(height: 8),
              _dialogLine('Topic', topikTa),
              const SizedBox(height: 8),
              _dialogLine('Submitted', tanggal),
              const SizedBox(height: 8),
              _dialogLine('Status', _formatStatus(status)),
              if (catatan != null && catatan.isNotEmpty) ...[
                const SizedBox(height: 8),
                _dialogLine('Response Note', catatan),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogLine(String label, String value) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: AppTheme.textPrimaryOf(context),
          fontSize: 14,
          height: 1.35,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
        return 'Waiting';
      case 'diterima':
        return 'Accepted';
      case 'ditolak':
        return 'Rejected';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOf(context),
      extendBody: true,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                child: Column(
                  children: [
                    _buildTopCard(),
                    const SizedBox(height: 18),
                    _buildBottomRequestList(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 26),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello There!,',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_studentName!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome to TAssist',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Asisten TA',
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.glassSurfaceOnDark,
                      foregroundColor: Colors.white,
                      shape: CircleBorder(
                        side: BorderSide(color: AppTheme.glassBorderOnDark),
                      ),
                      minimumSize: const Size(38, 38),
                      fixedSize: const Size(38, 38),
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 19),
                    onPressed: () {
                      Navigator.pushNamed(context, TAssistApp.chatbotRoute);
                    },
                  ),
                  const SizedBox(width: 8),
                  NotifikasiBellButton(
                    size: 38,
                    iconColor: Colors.white,
                    backgroundColor: AppTheme.glassSurfaceOnDark,
                    borderColor: AppTheme.glassBorderOnDark,
                    pageTitle: 'Notifications',
                  ),
                  const SizedBox(width: 10),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit_profile') {
                        _navigateToEditProfile();
                      } else if (value == 'theme') {
                        ThemeController.showThemeSelectorSheet(context);
                      } else if (value == 'logout') {
                        _logout();
                      }
                    },
                    itemBuilder: (ctx) {
                      final primary = AppTheme.primaryOf(ctx);
                      return [
                        if (_profileData != null)
                          PopupMenuItem<String>(
                            value: 'edit_profile',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 20, color: primary),
                                const SizedBox(width: 12),
                                const Text(
                                  'Edit Profil',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        PopupMenuItem<String>(
                          value: 'theme',
                          child: Row(
                            children: [
                              Icon(ThemeController.instance.icon, size: 20, color: primary),
                              const SizedBox(width: 12),
                              Text(
                                'Tema: ${ThemeController.instance.label}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout_rounded, size: 20, color: AppTheme.declined),
                              SizedBox(width: 12),
                              Text(
                                'Keluar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.declined,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                    child: UserAvatarCircle(
                      name: _studentName,
                      avatar: _userAvatar,
                      size: 52,
                      borderColor: AppTheme.glassBorderOnDark,
                      borderWidth: 1.5,
                      showShadow: false,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToEditProfile() async {
    if (_profileData == null) return;

    final result = await Navigator.pushNamed(
      context,
      TAssistApp.editStudentProfileRoute,
      arguments: <String, dynamic>{
        ..._profileData!,
        'nama': _studentName,
        if (_userAvatar != null) 'avatar': _userAvatar,
      },
    );

    if (result == true && mounted) {
      _loadProfile();
    }
  }

  Widget _buildTopCard() {
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final primary = AppTheme.primaryOf(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: AppTheme.cardDecorationOf(context, radius: AppTheme.radiusLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Let's choose your lecturer first!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LecturerRecommendationPage(),
                ),
              );
              if (!mounted) return;
              _loadPermohonan();
            },
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.primaryGhostOf(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.infoBorderOf(context)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(
                      Icons.person_search_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rekomendasi Dosen by Topik TA',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cocokkan rencana topik TA dengan keahlian & kuota dosen',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < categories.length; i++) ...[
            _LecturerCategoryRow(
              title: categories[i].title,
              icon: categories[i].icon,
              onTap: () => _openLecturersPage(
                bidangKeahlian: categories[i].keyword,
              ),
            ),
            const SizedBox(height: 10),
          ],
          _buildViewAllButton(),
        ],
      ),
    );
  }

  Widget _buildViewAllButton() {
    return TextButton.icon(
      onPressed: () => _openLecturersPage(),
      icon: const Icon(Icons.chevron_right_rounded, size: 18),
      iconAlignment: IconAlignment.end,
      label: const Text('view all lecturers'),
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.primaryOf(context),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBottomRequestList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecorationOf(context, radius: AppTheme.radiusLg),
      child: _isLoadingPermohonan
          ? const SizedBox(
              height: 100,
              child: Center(child: AppLoadingWidget(compact: true)),
            )
          : _permohonanError != null
              ? _buildRequestError()
              : _permohonanList.isEmpty
                  ? const AppEmptyStateWidget(
                      compact: true,
                      icon: Icons.assignment_outlined,
                      title: "there's nothing here...",
                    )
                  : Column(
                      children: _permohonanList
                          .map(
                            (request) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildRequestItem(request),
                            ),
                          )
                          .toList(),
                    ),
    );
  }

  Widget _buildRequestError() {
    return AppErrorWidget(
      compact: true,
      message: _permohonanError ?? 'Failed to load request.',
      retryLabel: 'Try Again',
      onRetry: _loadPermohonan,
    );
  }

  Widget _buildRequestItem(Map<String, dynamic> request) {
    final dosen = request['dosen'] is Map
        ? Map<String, dynamic>.from(request['dosen'])
        : <String, dynamic>{};

    final namaDosen = dosen['nama']?.toString() ?? '-';
    final bidangKeahlian = dosen['bidang_keahlian']?.toString() ?? '-';
    final status = request['status']?.toString() ?? '-';

    final statusKey = status.toLowerCase();
    final Color statusFg = switch (statusKey) {
      'menunggu' => AppTheme.pending,
      'disetujui' || 'diterima' => AppTheme.accepted,
      'ditolak' => AppTheme.declined,
      _ => AppTheme.textSecondaryOf(context),
    };
    final Color statusBg = switch (statusKey) {
      'menunggu' => AppTheme.pendingBgOf(context),
      'disetujui' || 'diterima' => AppTheme.acceptedBgOf(context),
      'ditolak' => AppTheme.declinedBgOf(context),
      _ => AppTheme.surfaceVariantOf(context),
    };
    final Color statusBorder = switch (statusKey) {
      'menunggu' => AppTheme.pendingBorderOf(context),
      'disetujui' || 'diterima' => AppTheme.acceptedBorderOf(context),
      'ditolak' => AppTheme.declinedBorderOf(context),
      _ => AppTheme.cardBorderOf(context),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showPermohonanDetail(request),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceOf(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.cardBorderOf(context)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primary,
                child: Text(
                  _initials(namaDosen),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: statusBorder),
                      ),
                      child: Text(
                        _formatStatus(status),
                        style: TextStyle(
                          color: statusFg,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'with Mr. $namaDosen',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textPrimaryOf(context),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      bidangKeahlian,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textSecondaryOf(context),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMutedOf(context),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _LecturerCategoryRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _LecturerCategoryRow({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceOf(context),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.cardBorderOf(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGhostOf(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryOf(context),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimaryOf(context),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMutedOf(context),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LecturerCategory {
  final String title;
  final String keyword;
  final IconData icon;

  const LecturerCategory({
    required this.title,
    required this.keyword,
    required this.icon,
  });
}