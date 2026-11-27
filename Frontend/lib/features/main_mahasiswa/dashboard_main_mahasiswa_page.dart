import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../core/export_helper.dart';
import '../auth/data/auth_service.dart';
import '../notifikasi/widgets/notifikasi_bell_button.dart';
import 'package:tassist/features/main_mahasiswa/data/mahasiswa_service.dart';
import '../informasi_ta/view/informasi_ta_page.dart';
import '../berita_acara/view/berita_acara_list_page.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/app_error_widget.dart';
import '../../widgets/app_skeleton_loader.dart';
import '../../widgets/user_avatar_circle.dart';

class DashboardMainMahasiswaPage extends StatefulWidget {
  const DashboardMainMahasiswaPage({
    super.key,
    this.onOpenSchedule,
  });

  final VoidCallback? onOpenSchedule;

  @override
  State<DashboardMainMahasiswaPage> createState() =>
      _DashboardMainMahasiswaPageState();
}

class _DashboardMainMahasiswaPageState
    extends State<DashboardMainMahasiswaPage> {
  final AuthService _authService = AuthService();
  final MahasiswaService _mahasiswaService = MahasiswaService();

  bool _isLoading = true;
  String? _errorMessage;

  String _studentName = 'Mahasiswa';
  String? _userAvatar;
  Map<String, dynamic>? _activeBimbingan;
  List<Map<String, dynamic>> _jadwalList = [];
  List<Map<String, dynamic>> _progresList = [];
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileResponse = await _authService.getProfile();
      final activeBimbingan = await _mahasiswaService.getActiveBimbingan();
      final jadwal = await _mahasiswaService.getJadwal(perPage: 30);

      Map<String, dynamic> progresPackage = {
        'progres': <Map<String, dynamic>>[],
      };

      try {
        progresPackage = await _mahasiswaService.getProgres(perPage: 5);
      } catch (e) {
        debugPrint('DashboardMainMahasiswaPage: getProgres failed: $e');
        progresPackage = {
          'progres': <Map<String, dynamic>>[],
        };
      }

      final profileData = profileResponse?['data'];
      if (profileData is Map<String, dynamic>) {
        final user = profileData['user'];
        if (user is Map<String, dynamic>) {
          _studentName = user['nama']?.toString() ?? 'Mahasiswa';
          _userAvatar = user['avatar']?.toString();
        }
        _profileData = profileData['profile'];
      }

      final progresRaw = progresPackage['progres'];
      final progresList = progresRaw is List
          ? progresRaw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        _activeBimbingan = activeBimbingan;
        _jadwalList = jadwal;
        _progresList = progresList;
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

  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      TAssistApp.loginRoute,
      (route) => false,
    );
  }

  Map<String, dynamic>? get _advisor {
    final bimbingan = _activeBimbingan;
    if (bimbingan == null) return null;

    final dosen = bimbingan['dosen'];
    if (dosen is Map<String, dynamic>) return dosen;
    if (dosen is Map) return Map<String, dynamic>.from(dosen);

    return null;
  }

  Map<String, dynamic>? get _latestProgress {
    if (_progresList.isEmpty) return null;
    return _progresList.first;
  }

  List<Map<String, dynamic>> get _upcomingSchedules {
    final now = DateTime.now();

    final filtered = _jadwalList.where((item) {
      final status = item['status_konfirmasi']?.toString().toLowerCase();
      if (status == 'ditolak') return false;

      final date = _parseDate(item['tanggal']?.toString());
      if (date == null) return false;

      final scheduleDate = DateTime(date.year, date.month, date.day);
      final today = DateTime(now.year, now.month, now.day);

      return scheduleDate.isAtSameMomentAs(today) || scheduleDate.isAfter(today);
    }).toList();

    filtered.sort((a, b) {
      final aDate = _parseScheduleDateTime(a);
      final bDate = _parseScheduleDateTime(b);

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return aDate.compareTo(bDate);
    });

    return filtered.take(3).toList();
  }

  List<Map<String, dynamic>> get _latestChecklist {
    final latest = _latestProgress;
    if (latest == null) return [];

    final checklist = latest['checklist'];

    if (checklist is List) {
      return checklist
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  List<Map<String, dynamic>> get _unfinishedChecklist {
    return _latestChecklist.where((item) {
      return !_isChecklistDone(item);
    }).toList();
  }

  double get _overallProgressValue {
    final latest = _latestProgress;
    if (latest == null) return 0;

    final raw = double.tryParse(latest['persentase']?.toString() ?? '') ?? 0;

    if (raw > 1) {
      return (raw / 100).clamp(0.0, 1.0);
    }

    return raw.clamp(0.0, 1.0);
  }

  int get _overallProgressPercent {
    return (_overallProgressValue * 100).round();
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    try {
      return DateTime.parse(value);
    } catch (e) {
      debugPrint('DashboardMainMahasiswaPage: _parseDate failed for "$value": $e');
      return null;
    }
  }

  DateTime? _parseScheduleDateTime(Map<String, dynamic> item) {
    final date = _parseDate(item['tanggal']?.toString());
    if (date == null) return null;

    final rawTime = item['waktu_mulai']?.toString() ?? '00:00:00';
    final parts = rawTime.split(':');

    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String _formatDate(String? value) {
    final date = _parseDate(value);
    if (date == null) return '-';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(String? value) {
    if (value == null || value.trim().isEmpty) return '-';

    final parts = value.split(':');

    if (parts.length < 2) return value;

    return '${parts[0].padLeft(2, '0')}.${parts[1].padLeft(2, '0')}';
  }

  String _formatStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'menunggu':
        return 'Menunggu';
      case 'dikonfirmasi':
        return 'Dikonfirmasi';
      case 'ditolak':
        return 'Ditolak';
      case 'aktif':
        return 'Aktif';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status ?? '-';
    }
  }

  bool _isChecklistDone(Map<String, dynamic> item) {
    final raw = item['is_selesai'] ?? item['tgl_selesai'];

    if (raw is bool) return raw;
    if (raw is int) return raw == 1;

    final text = raw?.toString().toLowerCase();

    return text == 'true' || text == '1';
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

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.backgroundOf(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: const SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(top: 16),
            child: AppSkeletonLoader.card(count: 4),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorPage();
    }

    return Scaffold(
      backgroundColor: bg,
      extendBody: true,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildAdvisorCard(),
                  const SizedBox(height: 16),
                  _buildMeetingSchedule(),
                  const SizedBox(height: 16),
                  _buildGoalStatistics(),
                  const SizedBox(height: 16),
                  _buildTargetThisWeek(),
                  const SizedBox(height: 16),
                  _buildQuickActionGrid(),
                  const SizedBox(height: 12),
                  _buildChatbotCard(),
                  const SizedBox(height: 12),
                  _buildExportHistoryCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPage() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOf(context),
      body: AppErrorWidget(
        title: 'Gagal memuat beranda',
        message: _errorMessage ?? '-',
        retryLabel: 'Coba Lagi',
        onRetry: _loadDashboardData,
      ),
    );
  }

  Widget _buildHeader() {
    final surface = AppTheme.surfaceOf(context);
    final primary = AppTheme.primaryOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $_studentName',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Selamat datang di TAssist',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Asisten TA',
              style: IconButton.styleFrom(
                backgroundColor: surface,
                foregroundColor: primary,
                shape: CircleBorder(
                  side: BorderSide(color: AppTheme.cardBorderOf(context)),
                ),
                minimumSize: const Size(44, 44),
                fixedSize: const Size(44, 44),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              onPressed: () {
                Navigator.pushNamed(context, TAssistApp.chatbotRoute);
              },
            ),
            const SizedBox(width: 8),
            NotifikasiBellButton(
              size: 44,
              iconColor: primary,
              backgroundColor: surface,
              borderColor: AppTheme.cardBorderOf(context),
              pageTitle: 'Notifikasi',
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: 'Menu akun',
              onSelected: (value) {
                if (value == 'edit_profile') {
                  _navigateToEditProfile();
                } else if (value == 'theme') {
                  ThemeController.showThemeSelectorSheet(context);
                } else if (value == 'logout') {
                  _logout();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'edit_profile',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20, color: primary),
                      const SizedBox(width: 12),
                      const Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.w600)),
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
                      Icon(Icons.logout_outlined, size: 20, color: AppTheme.declined),
                      SizedBox(width: 12),
                      Text('Keluar', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.declined)),
                    ],
                  ),
                ),
              ],
              child: UserAvatarCircle(
                name: _studentName,
                avatar: _userAvatar,
                size: 56,
                borderColor: AppTheme.cardBorderOf(context),
                borderWidth: 1.5,
                showShadow: false,
              ),
            ),
          ],
        )
      ],
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
      _loadDashboardData();
    }
  }

  Widget _buildMenuIconBox(IconData icon) {
    return Container(
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
    );
  }

  Widget _buildQuickActionGrid() {
    final bimbinganId = _activeBimbingan?['bimbingan_id'] is int
        ? _activeBimbingan!['bimbingan_id'] as int
        : int.tryParse(_activeBimbingan?['bimbingan_id']?.toString() ?? '');

    if (bimbinganId == null) {
      return _buildQuickActionTile(
        icon: Icons.campaign_outlined,
        title: 'Informasi TA',
        subtitle: 'Jadwal sidang & syarat',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InformasiTAPage()),
          );
        },
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildQuickActionTile(
            icon: Icons.campaign_outlined,
            title: 'Informasi TA',
            subtitle: 'Jadwal & panduan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InformasiTAPage()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionTile(
            icon: Icons.fact_check_outlined,
            title: 'Berita Acara',
            subtitle: 'Dokumen sah dosen',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BeritaAcaraListPage(
                    bimbinganId: bimbinganId,
                    studentName: _studentName,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.cardDecorationOf(context, radius: AppTheme.radiusMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMenuIconBox(icon),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportHistoryCard() {
    final bimbinganId = _activeBimbingan?['bimbingan_id'] is int
        ? _activeBimbingan!['bimbingan_id'] as int
        : int.tryParse(_activeBimbingan?['bimbingan_id']?.toString() ?? '');

    if (bimbinganId == null) return const SizedBox.shrink();

    final primary = AppTheme.primaryOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final border = AppTheme.cardBorderOf(context);
    final surface = AppTheme.surfaceOf(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppTheme.cardDecorationOf(context, radius: AppTheme.radiusMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildMenuIconBox(Icons.file_download_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ekspor Riwayat Bimbingan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Unduh ringkasan jadwal, dokumen & progres',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ExportHelper.exportBimbinganHistory(
                    context,
                    rolePrefix: 'mahasiswa',
                    bimbinganId: bimbinganId,
                    format: 'pdf',
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('PDF'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: surface,
                    foregroundColor: primary,
                    side: BorderSide(color: border),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ExportHelper.exportBimbinganHistory(
                    context,
                    rolePrefix: 'mahasiswa',
                    bimbinganId: bimbinganId,
                    format: 'excel',
                  ),
                  icon: const Icon(Icons.table_chart_outlined, size: 18),
                  label: const Text('Excel'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: surface,
                    foregroundColor: primary,
                    side: BorderSide(color: border),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
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

  Widget _buildChatbotCard() {
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, TAssistApp.chatbotRoute);
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration:
              AppTheme.cardDecorationOf(context, radius: AppTheme.radiusMd),
          child: Row(
            children: [
              _buildMenuIconBox(Icons.chat_bubble_outline),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asisten TA',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tanya alur, syarat sidang, format berkas, & panduan TA',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_outlined,
                size: 20,
                color: textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvisorCard() {
    final advisor = _advisor;
    final advisorName = advisor?['nama']?.toString() ?? '-';
    final expertise = advisor?['bidang_keahlian']?.toString() ?? '-';
    final status = _activeBimbingan?['status_bimbingan']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: AppTheme.accentGoldOnDark.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: AppTheme.floatingShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.glassSurfaceOnDark,
              border: Border.all(
                color: AppTheme.accentGoldOnDark.withValues(alpha: 0.8),
                width: 1.4,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(advisorName),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Academic Advisor',
                        style: TextStyle(
                          color: AppTheme.accentGoldOnDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.glassSurfaceOnDark,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppTheme.glassBorderOnDark),
                      ),
                      child: Text(
                        _formatStatus(status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  advisorName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  expertise,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingSchedule() {
    final schedules = _upcomingSchedules;
    final textPrimary = AppTheme.textPrimaryOf(context);
    final primary = AppTheme.primaryOf(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _whiteCardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.event_note_outlined,
                color: primary,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Jadwal Bimbingan Berikutnya',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (schedules.isEmpty)
            _buildEmptyCardMessage(
              icon: Icons.event_busy_outlined,
              message: 'Belum ada jadwal bimbingan mendatang.',
              actionLabel: widget.onOpenSchedule != null ? 'Ajukan Jadwal' : null,
              onAction: widget.onOpenSchedule,
            )
          else
            ...schedules.map(_buildScheduleItem),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> schedule) {
    final dosen = schedule['dosen'] is Map
        ? Map<String, dynamic>.from(schedule['dosen'])
        : <String, dynamic>{};

    final dosenName = dosen['nama']?.toString() ?? '-';
    final status = schedule['status_konfirmasi']?.toString();
    final tanggal = schedule['tanggal']?.toString();
    final mulai = schedule['waktu_mulai']?.toString();
    final selesai = schedule['waktu_selesai']?.toString();
    final mode = schedule['mode']?.toString() ?? '-';

    final statusKey = status?.toLowerCase();
    final Color statusFg = switch (statusKey) {
      'menunggu' => AppTheme.pending,
      'dikonfirmasi' => AppTheme.accepted,
      'ditolak' => AppTheme.declined,
      _ => AppTheme.textSecondaryOf(context),
    };
    final Color statusBg = switch (statusKey) {
      'menunggu' => AppTheme.pendingBgOf(context),
      'dikonfirmasi' => AppTheme.acceptedBgOf(context),
      'ditolak' => AppTheme.declinedBgOf(context),
      _ => AppTheme.surfaceVariantOf(context),
    };
    final Color statusBorder = switch (statusKey) {
      'menunggu' => AppTheme.pendingBorderOf(context),
      'dikonfirmasi' => AppTheme.acceptedBorderOf(context),
      'ditolak' => AppTheme.declinedBorderOf(context),
      _ => AppTheme.cardBorderOf(context),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantOf(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: AppTheme.primaryGhostOf(context),
            child: Text(
              _initials(dosenName),
              style: TextStyle(
                color: AppTheme.primaryOf(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatDate(tanggal)}, ${_formatTime(mulai)} - ${_formatTime(selesai)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textPrimaryOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$mode dengan $dosenName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textSecondaryOf(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: statusBorder),
            ),
            child: Text(
              _formatStatus(status),
              style: TextStyle(
                color: statusFg,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStatistics() {
    final latest = _latestProgress;
    final checklist = _latestChecklist;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _whiteCardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.donut_large_outlined,
                color: AppTheme.primaryOf(context),
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Progres Tugas Akhir',
                  style: TextStyle(
                    color: AppTheme.textPrimaryOf(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            width: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(240, 120),
                  painter: ArcPainter(
                    percentage: _overallProgressValue,
                    isDark: AppTheme.isDark(context),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  child: Text(
                    '$_overallProgressPercent%',
                    style: TextStyle(
                      color: AppTheme.textPrimaryOf(context),
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (latest == null)
            _buildEmptyCardMessage(
              icon: Icons.trending_up_outlined,
              message: 'Belum ada catatan progres tugas akhir.',
            )
          else ...[
            if (latest['status_progress'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  latest['status_progress'].toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondaryOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (checklist.isEmpty)
              _buildProgressBar('Progres keseluruhan', _overallProgressValue)
            else
              ...checklist.map((item) {
                final label = item['nama_item']?.toString() ?? 'Checklist';
                final done = _isChecklistDone(item);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildProgressBar(
                    label,
                    done ? 1.0 : 0.0,
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double progress) {
    final safeProgress = progress.clamp(0.0, 1.0);
    final percent = (safeProgress * 100).round();

    return Stack(
      children: [
        Container(
          height: 38,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariantOf(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: AppTheme.cardBorderOf(context)),
          ),
        ),
        FractionallySizedBox(
          widthFactor: safeProgress,
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: safeProgress > 0.45
                          ? Colors.white
                          : AppTheme.primaryOf(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$percent%',
                  style: TextStyle(
                    color: safeProgress > 0.9
                        ? Colors.white
                        : AppTheme.primaryOf(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetThisWeek() {
    final targets = _unfinishedChecklist.take(4).toList();
    final primary = AppTheme.primaryOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _whiteCardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.checklist_outlined,
                color: primary,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Target Minggu Ini',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (targets.isEmpty)
            _buildEmptyCardMessage(
              icon: Icons.task_alt_outlined,
              message: 'Belum ada target checklist yang tersisa.',
            )
          else
            ...targets.map(_buildTargetItem),
        ],
      ),
    );
  }

  Widget _buildTargetItem(Map<String, dynamic> target) {
    final title = target['nama_item']?.toString() ?? 'Item checklist';
    final note = target['catatan']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.warningBgOf(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.warningBorderOf(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              note == null || note.isEmpty ? title : '$title\n$note',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textPrimaryOf(context),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppTheme.declined,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.priority_high_outlined,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCardMessage({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantOf(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryOf(context),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondaryOf(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryOf(context),
                side: BorderSide(color: AppTheme.cardBorderOf(context)),
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }

  BoxDecoration _whiteCardDecoration() {
    return AppTheme.cardDecorationOf(context, radius: AppTheme.radiusLg);
  }
}

class ArcPainter extends CustomPainter {
  final double percentage;
  final bool isDark;

  ArcPainter({required this.percentage, this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final safePercentage = percentage.clamp(0.0, 1.0);
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2.2;
    const strokeWidth = 24.0;

    final bgPaint = Paint()
      ..color = isDark ? AppTheme.darkSurfaceVariant : AppTheme.primaryGhost
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    final activePaint = Paint()
      ..color = isDark ? AppTheme.darkPrimary : AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * safePercentage,
      false,
      activePaint,
    );

    if (safePercentage > 0.02) {
      final angle = math.pi + math.pi * safePercentage;
      final tipCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawCircle(
        tipCenter,
        5,
        Paint()..color = AppTheme.accentGoldOnDark,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ArcPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.isDark != isDark;
  }
}