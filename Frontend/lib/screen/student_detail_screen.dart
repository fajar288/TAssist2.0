// lib/features/dosen/view/student_detail_page.dart

import 'package:flutter/material.dart';
import 'package:produk/model/models.dart';
import 'package:produk/widgets/student_info_card.dart';
import 'package:produk/widgets/student_menu_title.dart';
import 'package:produk/features/dosen/view/dosen_student_documents_page.dart';
import 'package:produk/features/dosen/view/dosen_student_progress_page.dart';

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
        return const Color(0xFF22C55E);
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'completed':
        return const Color(0xFF6366F1);
      default:
        return Colors.grey;
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
        return const Color(0xFF6366F1);
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'completed':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF64748B);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
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
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 16),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_avatarColor, _avatarColor.withOpacity(0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -30,
                top: -20,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
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
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.5), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              student.imageInitials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
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
                                  color: _statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _statusColor.withOpacity(0.4),
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
                                  fontWeight: FontWeight.w800,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                  fontWeight: FontWeight.w800,
                  color: _statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: student.progress,
              backgroundColor: _statusColor.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _miniStat(context, '${student.meetingCount}', 'Meetings',
                  Icons.calendar_today_rounded, const Color(0xFF6366F1)),
              _divider(),
              _miniStat(context, '${student.taskCompleted}/${student.taskCount}',
                  'Tasks Done', Icons.task_alt_rounded, const Color(0xFF22C55E)),
              _divider(),
              _miniStat(context, student.counselingSince, 'Since',
                  Icons.access_time_rounded, const Color(0xFFF59E0B)),
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
          accentColor: const Color(0xFF6366F1),
        ),
        StudentInfoCard(
          label: 'Major',
          value: student.major,
          icon: Icons.school_rounded,
          accentColor: const Color(0xFF0EA5E9),
        ),
        StudentInfoCard(
          label: 'Batch Year',
          value: student.year,
          icon: Icons.calendar_month_rounded,
          accentColor: const Color(0xFFF59E0B),
        ),
        StudentInfoCard(
          label: 'Counseling Since',
          value: student.counselingSince,
          icon: Icons.handshake_rounded,
          accentColor: const Color(0xFF22C55E),
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
          iconColor: const Color(0xFF6366F1),
          onTap: _openProgressPage,
        ),
        StudentMenuTile(
          title: 'Checklist',
          subtitle: 'Manage thesis checklist items',
          icon: Icons.checklist_rounded,
          iconColor: const Color(0xFF22C55E),
          onTap: _openProgressPage,
        ),
        StudentMenuTile(
          title: 'Meetings',
          subtitle: '${student.meetingCount} sessions recorded',
          icon: Icons.video_call_rounded,
          iconColor: const Color(0xFF0EA5E9),
          onTap: () => _showSnackBar(context, 'Meetings feature coming soon'),
        ),
        StudentMenuTile(
          title: 'Documents',
          subtitle: 'Uploaded files & feedback',
          icon: Icons.folder_rounded,
          iconColor: const Color(0xFFF59E0B),
          onTap: _openDocumentsPage,
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
          iconColor: const Color(0xFF6366F1),
          onTap: () => _showSnackBar(context, 'Opening email...'),
          trailing: const Icon(Icons.open_in_new_rounded,
              size: 14, color: Colors.grey),
        ),
        StudentMenuTile(
          title: 'Phone',
          subtitle: student.phone,
          icon: Icons.phone_rounded,
          iconColor: const Color(0xFF22C55E),
          onTap: () => _showSnackBar(context, 'Calling ${student.name}...'),
          trailing: const Icon(Icons.call_rounded,
              size: 16, color: Color(0xFF22C55E)),
        ),
      ],
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCCCC), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444), size: 18),
              const SizedBox(width: 7),
              Text(
                'Danger Zone',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEF4444),
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
              color: const Color(0xFFEF4444).withOpacity(0.75),
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
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Counseling with ${student.name} has been ended.'),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('End Counseling',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}