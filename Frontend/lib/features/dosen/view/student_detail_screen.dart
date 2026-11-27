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
        return 'Active';
      case 'warning':
        return 'Needs Attention';
      case 'completed':
        return 'Completed';
      default:
        return student.status;
    }
  }

  Color get _avatarColor {
    switch (student.status) {
      case 'active':
        return AppTheme.primaryLight;
      case 'warning':
        return AppTheme.pending;
      case 'completed':
        return AppTheme.accepted;
      default:
        return AppTheme.textSecondary;
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
      backgroundColor: AppTheme.background,
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
      backgroundColor: _avatarColor,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 16),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: IconButton(
            icon: const Icon(Icons.more_vert_rounded,
                color: Colors.white, size: 20),
            onPressed: () => _showBottomSheet(context),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
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
                                  color: Colors.white.withOpacity(0.7),
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
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
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
              _miniStat(context, '${student.meetingCount}', 'Meetings',
                  Icons.calendar_today_rounded, AppTheme.primaryLight),
              _divider(),
              _miniStat(context, '${student.taskCompleted}/${student.taskCount}',
                  'Tasks Done', Icons.task_alt_rounded, AppTheme.accepted),
              _divider(),
              _miniStat(context, student.counselingSince, 'Since',
                  Icons.access_time_rounded, AppTheme.pending),
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
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
      color: Colors.grey.shade200,
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
          icon: Icons.badge_rounded,
          accentColor: AppTheme.primaryLight,
        ),
        StudentInfoCard(
          label: 'Major',
          value: student.major,
          icon: Icons.school_rounded,
          accentColor: AppTheme.info,
        ),
        StudentInfoCard(
          label: 'Batch Year',
          value: student.year,
          icon: Icons.calendar_month_rounded,
          accentColor: AppTheme.pending,
        ),
        StudentInfoCard(
          label: 'Counseling Since',
          value: student.counselingSince,
          icon: Icons.handshake_rounded,
          accentColor: AppTheme.accepted,
        ),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
    );
  }

  Widget _buildMenuActions(BuildContext context) {
    return Column(
      children: [
        StudentMenuTile(
          title: 'Progress',
          subtitle: 'View and update thesis progress',
          icon: Icons.trending_up_rounded,
          iconColor: AppTheme.primaryLight,
          onTap: _openProgressPage,
        ),
        StudentMenuTile(
          title: 'Checklist',
          subtitle: 'Manage thesis checklist items',
          icon: Icons.checklist_rounded,
          iconColor: AppTheme.accepted,
          onTap: _openProgressPage,
        ),
        StudentMenuTile(
          title: 'Meetings',
          subtitle: '${student.meetingCount} sessions recorded',
          icon: Icons.video_call_rounded,
          iconColor: AppTheme.info,
          onTap: () => _showSnackBar(context, 'Meetings feature coming soon'),
        ),
        StudentMenuTile(
          title: 'Documents',
          subtitle: 'Uploaded files & feedback',
          icon: Icons.folder_rounded,
          iconColor: AppTheme.pending,
          onTap: _openDocumentsPage,
        ),
        StudentMenuTile(
          title: 'Berita Acara',
          subtitle: 'Generate & approve supervision minutes',
          icon: Icons.assignment_turned_in_rounded,
          iconColor: AppTheme.primary,
          onTap: _openBeritaAcaraPage,
        ),
        StudentMenuTile(
          title: 'Export Riwayat (PDF / Excel)',
          subtitle: 'Download meetings, versions & progress summary',
          icon: Icons.file_download_outlined,
          iconColor: AppTheme.info,
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
                      leading: const Icon(Icons.picture_as_pdf_rounded),
                      title: const Text('Export PDF'),
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
                      leading: const Icon(Icons.table_view_rounded),
                      title: const Text('Export Excel (.xlsx)'),
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
    return Column(
      children: [
        StudentMenuTile(
          title: 'Email',
          subtitle: student.email,
          icon: Icons.email_rounded,
          iconColor: AppTheme.primaryLight,
          onTap: () => _showSnackBar(context, 'Opening email...'),
          trailing: const Icon(Icons.open_in_new_rounded,
              size: 14, color: AppTheme.textMuted),
        ),
        StudentMenuTile(
          title: 'Phone',
          subtitle: student.phone,
          icon: Icons.phone_rounded,
          iconColor: AppTheme.accepted,
          onTap: () => _showSnackBar(context, 'Calling ${student.name}...'),
          trailing: const Icon(Icons.call_rounded,
              size: 16, color: AppTheme.accepted),
        ),
      ],
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.declinedBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.declinedBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.declined, size: 18),
              const SizedBox(width: 7),
              Text(
                'Danger Zone',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.declined,
                      fontSize: 14,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ending counseling will permanently remove this student from your active advisee list. This action cannot be undone.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.declined.withValues(alpha: 0.75),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmEndCounseling(context),
              icon: const Icon(Icons.link_off_rounded, size: 16),
              label: const Text('End Counseling'),
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

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.cardBorder,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit Student Info'),
              onTap: () {
                Navigator.pop(ctx);
                _showSnackBar(context, 'Edit feature coming soon');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share Profile'),
              onTap: () {
                Navigator.pop(ctx);
                _showSnackBar(context, 'Share feature coming soon');
              },
            ),
            ListTile(
              leading: const Icon(Icons.print_rounded),
              title: const Text('Print Report'),
              onTap: () {
                Navigator.pop(ctx);
                _showSnackBar(context, 'Print feature coming soon');
              },
            ),
          ],
        ),
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