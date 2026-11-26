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
import '../../widgets/app_error_widget.dart';
import '../../widgets/app_skeleton_loader.dart';

class DashboardMainMahasiswaPage extends StatefulWidget {
  const DashboardMainMahasiswaPage({super.key});

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

  String _studentName = 'Student';
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
          _studentName = user['nama']?.toString() ?? 'Student';
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
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
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
        return 'Pending';
      case 'dikonfirmasi':
        return 'Confirmed';
      case 'ditolak':
        return 'Rejected';
      case 'aktif':
        return 'Active';
      case 'selesai':
        return 'Completed';
      case 'dibatalkan':
        return 'Canceled';
      default:
        return status ?? '-';
    }
  }

  Color _scheduleStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'menunggu':
        return AppTheme.pending;
      case 'dikonfirmasi':
        return AppTheme.accepted;
      case 'ditolak':
        return AppTheme.declined;
      default:
        return Colors.white70;
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
      return _buildErrorPage();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 120),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  _buildInformasiTACard(),
                  const SizedBox(height: 12),
                  _buildBeritaAcaraCard(),
                  const SizedBox(height: 12),
                  _buildExportHistoryCard(),
                  const SizedBox(height: 12),
                  _buildChatbotCard(),
                  const SizedBox(height: 18),
                  _buildAdvisorCard(),
                  const SizedBox(height: 18),
                  _buildMeetingSchedule(),
                  const SizedBox(height: 18),
                  _buildGoalStatistics(),
                  const SizedBox(height: 18),
                  _buildTargetThisWeek(),
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
      backgroundColor: AppTheme.background,
      body: AppErrorWidget(
        title: 'Failed to load dashboard',
        message: _errorMessage ?? '-',
        retryLabel: 'Try Again',
        onRetry: _loadDashboardData,
      ),
    );
  }

  Widget _buildHeader() {
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
                  'Hi, $_studentName!',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Welcome to TAssist',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
                backgroundColor: AppTheme.surface,
                foregroundColor: AppTheme.primary,
                shape: const CircleBorder(),
                minimumSize: const Size(38, 38),
                fixedSize: const Size(38, 38),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.smart_toy_rounded, size: 20),
              onPressed: () {
                Navigator.pushNamed(context, TAssistApp.chatbotRoute);
              },
            ),
            const SizedBox(width: 8),
            const NotifikasiBellButton(
              size: 38,
              iconColor: AppTheme.primary,
              backgroundColor: AppTheme.surface,
              borderColor: AppTheme.surface,
              pageTitle: 'Notifications',
            ),
            const SizedBox(width: 10),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit_profile') {
                  _navigateToEditProfile();
                } else if (value == 'logout') {
                  _logout();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'edit_profile',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 20, color: AppTheme.primary),
                      SizedBox(width: 12),
                      Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 20, color: AppTheme.declined),
                      SizedBox(width: 12),
                      Text('Keluar', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.declined)),
                    ],
                  ),
                ),
              ],
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary,
                  border: Border.all(color: AppTheme.surface, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _initials(_studentName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
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
      arguments: _profileData,
    );

    if (result == true && mounted) {
      _loadDashboardData();
    }
  }

  Widget _buildInformasiTACard() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InformasiTAPage()),
        );
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.infoBorder),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGhost,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(
                Icons.campaign_rounded,
                color: AppTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi & Pengumuman TA',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Cek jadwal sidang, panduan format & syarat TA',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeritaAcaraCard() {
    final bimbinganId = _activeBimbingan?['bimbingan_id'] is int
        ? _activeBimbingan!['bimbingan_id'] as int
        : int.tryParse(_activeBimbingan?['bimbingan_id']?.toString() ?? '');

    if (bimbinganId == null) return const SizedBox.shrink();

    return InkWell(
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
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.cardBorder),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGhost,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(
                Icons.assignment_turned_in_rounded,
                color: AppTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Berita Acara Bimbingan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Lihat dan unduh Berita Acara yang disahkan dosen',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportHistoryCard() {
    final bimbinganId = _activeBimbingan?['bimbingan_id'] is int
        ? _activeBimbingan!['bimbingan_id'] as int
        : int.tryParse(_activeBimbingan?['bimbingan_id']?.toString() ?? '');

    if (bimbinganId == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryGhost,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Icon(
              Icons.file_download_outlined,
              color: AppTheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ekspor Riwayat Bimbingan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Unduh ringkasan jadwal, dokumen & progres',
                  style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => ExportHelper.exportBimbinganHistory(
              context,
              rolePrefix: 'mahasiswa',
              bimbinganId: bimbinganId,
              format: 'pdf',
            ),
            child: const Text('PDF'),
          ),
          TextButton(
            onPressed: () => ExportHelper.exportBimbinganHistory(
              context,
              rolePrefix: 'mahasiswa',
              bimbinganId: bimbinganId,
              format: 'excel',
            ),
            child: const Text('Excel'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatbotCard() {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, TAssistApp.chatbotRoute);
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.cardBorder),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGhost,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: AppTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asisten TA Virtual (AI)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tanya alur, syarat sidang, format berkas, & panduan TA',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppTheme.textMuted,
            ),
          ],
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
        gradient: const LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Text(
              _initials(advisorName),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Academic Advisor',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  advisorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  expertise,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            ),
            child: Text(
              _formatStatus(status),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingSchedule() {
    final schedules = _upcomingSchedules;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _whiteCardDecoration(),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(
                Icons.alarm_on_rounded,
                color: AppTheme.primary,
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Next Meeting Schedule',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (schedules.isEmpty)
            _buildEmptyCardMessage(
              icon: Icons.event_busy_rounded,
              message: 'No upcoming meeting schedule yet.',
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: Colors.white.withValues(alpha: 0.22),
            child: Text(
              _initials(dosenName),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatDate(tanggal)} at ${_formatTime(mulai)} - ${_formatTime(selesai)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$mode with Mr. $dosenName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _formatStatus(status),
            style: TextStyle(
              color: _scheduleStatusColor(status),
              fontSize: 11,
              fontWeight: FontWeight.w900,
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
          const Text(
            'Goal Percentage',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 140,
            width: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(240, 120),
                  painter: ArcPainter(percentage: _overallProgressValue),
                ),
                Positioned(
                  bottom: 10,
                  child: Text(
                    '$_overallProgressPercent%',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (latest == null)
            _buildEmptyCardMessage(
              icon: Icons.track_changes_rounded,
              message: 'No thesis progress has been recorded yet.',
            )
          else ...[
            if (latest['status_progress'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  latest['status_progress'].toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (checklist.isEmpty)
              _buildProgressBar('OVERALL PROGRESS', _overallProgressValue)
            else
              ...checklist.map((item) {
                final label = item['nama_item']?.toString() ?? 'Checklist';
                final done = _isChecklistDone(item);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildProgressBar(
                    label.toUpperCase(),
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
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
        ),
        FractionallySizedBox(
          widthFactor: safeProgress,
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
              ),
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
                          : AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _whiteCardDecoration(),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(
                Icons.track_changes_rounded,
                color: AppTheme.primary,
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Target this Week',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (targets.isEmpty)
            _buildEmptyCardMessage(
              icon: Icons.check_circle_outline_rounded,
              message: 'No unfinished checklist target yet.',
            )
          else
            ...targets.map(_buildTargetItem),
        ],
      ),
    );
  }

  Widget _buildTargetItem(Map<String, dynamic> target) {
    final title = target['nama_item']?.toString() ?? 'Checklist item';
    final note = target['catatan']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.warningBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.warningBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              note == null || note.isEmpty ? title : '$title\n$note',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
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
              Icons.priority_high_rounded,
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
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryLight,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _whiteCardDecoration() {
    return AppTheme.cardDecoration(radius: AppTheme.radiusLg);
  }
}

class ArcPainter extends CustomPainter {
  final double percentage;

  ArcPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final safePercentage = percentage.clamp(0.0, 1.0);
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2.2;
    const strokeWidth = 24.0;

    final bgPaint = Paint()
      ..color = AppTheme.primaryLight.withValues(alpha: 0.45)
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
      ..color = AppTheme.primary
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
  }

  @override
  bool shouldRepaint(covariant ArcPainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}