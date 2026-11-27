// lib/features/dosen/view/student_detail_page.dart

import 'package:flutter/material.dart';
import 'package:tassist/core/export_helper.dart';
import 'package:tassist/model/models.dart';
import 'package:tassist/theme/app_theme.dart';
import 'package:tassist/widgets/app_snackbars.dart';
import 'package:tassist/widgets/student_info_card.dart';
import 'package:tassist/widgets/student_menu_title.dart';
import 'package:tassist/features/dosen/view/dosen_student_documents_page.dart';
import 'package:tassist/features/dosen/view/dosen_student_progress_page.dart';
import 'package:tassist/features/berita_acara/view/berita_acara_management_page.dart';

class StudentDetailPage extends StatefulWidget {
  final StudentModel student;

  const StudentDetailPage({super.key, required this.student});

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  StudentModel get student => widget.student;

  Color get _statusColor {
    switch (student.status) {
      case 'active':
        return AppTheme.accepted;
      case 'warning':
        return AppTheme.pending;
      case 'completed':
        return AppTheme.primaryLight;
      default:
        return AppTheme.textMuted;
    }
  }

  String get _statusLabel {
    switch (student.status) {
      case 'active':
        return 'Aktif';
      case 'warning':
        return 'Perlu Perhatian';
      case 'completed':
        return 'Selesai';
      default:
        return student.status;
    }
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
  
  void _openDocumentsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DosenStudentDocumentsPage(student: student),
      ),
    );
  }

  void _openProgressPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DosenStudentProgressPage(student: student),
      ),
    );
  }

  void _openBeritaAcaraPage() {
    final bimbinganId = student.bimbinganIdAsInt;
    if (bimbinganId == null) {
      _showSnackBar(context, 'ID bimbingan tidak valid.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BeritaAcaraManagementPage(
          bimbinganId: bimbinganId,
          studentName: student.name,
          judulTa: student.judulTa ?? student.topikTa ?? '-',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOf(context),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildProgressSection(context),
                      const SizedBox(height: 20),
                      _buildInfoGrid(context),
                      const SizedBox(height: 24),
                      _buildSectionLabel(context, 'Quick Actions'),
                      const SizedBox(height: 10),
                      _buildMenuActions(context),
                      const SizedBox(height: 24),
                      _buildSectionLabel(context, 'Contact'),
                      const SizedBox(height: 10),
                      _buildContactSection(context),
                      const SizedBox(height: 32),
                      _buildDangerZone(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppTheme.primaryDark,
      leading: IconButton(
        tooltip: 'Kembali',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_ios_new_outlined,
          color: Colors.white,
          size: 20,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppTheme.primaryDark,
          child: Stack(
            children: [
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Avatar
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              student.imageInitials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 24,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                  border: Border.all(
                                    color: _statusColor.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _statusLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        student.status == 'active' || student.status == 'warning'
                                            ? Colors.white
                                            : _statusColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                student.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                student.nim,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecorationOf(context, radius: AppTheme.radiusMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progres Keseluruhan',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
              ),
              Text(
                '${(student.progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: LinearProgressIndicator(
              value: student.progress,
              backgroundColor: _statusColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _miniStat(context, '${student.meetingCount}', 'Pertemuan',
                  Icons.calendar_today_outlined, AppTheme.primaryLight),
              _divider(),
              _miniStat(context, '${student.taskCompleted}/${student.taskCount}',
                  'Tugas Selesai', Icons.task_alt_outlined, AppTheme.accepted),
              _divider(),
              _miniStat(context, student.counselingSince, 'Sejak',
                  Icons.schedule_outlined, AppTheme.pending),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(BuildContext context, String value, String label,
      IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 40,
      color: AppTheme.cardBorderOf(context),
    );
  }

  Widget _buildInfoGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        StudentInfoCard(
          label: 'NIM',
          value: student.nim,
          icon: Icons.badge_outlined,
          accentColor: AppTheme.primaryLight,
        ),
        StudentInfoCard(
          label: 'Program Studi',
          value: student.major,
          icon: Icons.school_outlined,
          accentColor: AppTheme.info,
        ),
        StudentInfoCard(
          label: 'Angkatan',
          value: student.year,
          icon: Icons.calendar_month_outlined,
          accentColor: AppTheme.pending,
        ),
        StudentInfoCard(
          label: 'Mulai Bimbingan',
          value: student.counselingSince,
          icon: Icons.handshake_outlined,
          accentColor: AppTheme.accepted,
        ),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
    );
  }

  Widget _buildMenuActions(BuildContext context) {
    final primary = AppTheme.primaryOf(context);
    return Column(
      children: [
        StudentMenuTile(
          title: 'Progres & Checklist',
          subtitle: 'Pantau persentase progres dan item checklist TA',
          icon: Icons.trending_up_outlined,
          iconColor: primary,
          onTap: _openProgressPage,
        ),
        StudentMenuTile(
          title: 'Dokumen TA',
          subtitle: 'Berkas unggahan, anotasi & masukan dosen',
          icon: Icons.folder_outlined,
          iconColor: primary,
          onTap: _openDocumentsPage,
        ),
        StudentMenuTile(
          title: 'Berita Acara',
          subtitle: 'Buat & sahkan catatan resmi bimbingan',
          icon: Icons.fact_check_outlined,
          iconColor: primary,
          onTap: _openBeritaAcaraPage,
        ),
        StudentMenuTile(
          title: 'Ekspor Riwayat (PDF / Excel)',
          subtitle: 'Unduh ringkasan jadwal, versi & progres',
          icon: Icons.file_download_outlined,
          iconColor: primary,
          onTap: () {
            final bimbinganId = student.bimbinganIdAsInt;
            if (bimbinganId == null) {
              _showSnackBar(context, 'ID bimbingan tidak valid.');
              return;
            }
            showModalBottomSheet<void>(
              context: context,
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: const Text('Ekspor PDF'),
                      onTap: () {
                        Navigator.pop(ctx);
                        ExportHelper.exportBimbinganHistory(
                          context,
                          rolePrefix: 'dosen',
                          bimbinganId: bimbinganId,
                          format: 'pdf',
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.table_chart_outlined),
                      title: const Text('Ekspor Excel (.xlsx)'),
                      onTap: () {
                        Navigator.pop(ctx);
                        ExportHelper.exportBimbinganHistory(
                          context,
                          rolePrefix: 'dosen',
                          bimbinganId: bimbinganId,
                          format: 'excel',
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    final primary = AppTheme.primaryOf(context);
    return Column(
      children: [
        StudentMenuTile(
          title: 'Email',
          subtitle: student.email,
          icon: Icons.email_outlined,
          iconColor: primary,
          onTap: () {},
        ),
        StudentMenuTile(
          title: 'Telepon',
          subtitle: student.phone,
          icon: Icons.phone_outlined,
          iconColor: primary,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.declinedBgOf(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.declinedBorderOf(context), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_outlined,
                  color: AppTheme.declined, size: 18),
              const SizedBox(width: 7),
              Text(
                'Zona Berbahaya',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.declined,
                      fontSize: 14,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mengakhiri bimbingan akan menghapus mahasiswa ini dari daftar bimbingan aktif Anda secara permanen.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimaryOf(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmEndCounseling(context),
              icon: const Icon(Icons.link_off_outlined, size: 16),
              label: const Text('Akhiri Bimbingan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.declined,
                side: const BorderSide(color: AppTheme.declined, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmEndCounseling(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        title: const Text('End Counseling?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to end counseling for ${student.name}? This cannot be undone.',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              AppSnackBars.error(
                context,
                'Counseling with ${student.name} has been ended.',
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.declined),
            child: const Text('End Counseling',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    AppSnackBars.info(context, message);
  }
}