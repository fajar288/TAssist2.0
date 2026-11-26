// lib/features/dosen/view/schedule_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tassist/features/dosen/data/dosen_service.dart';

import 'package:tassist/model/models.dart';
import 'package:tassist/theme/app_theme.dart';
import 'package:tassist/widgets/app_empty_state_widget.dart';
import 'package:tassist/widgets/app_error_widget.dart';
import 'package:tassist/widgets/app_loading_widget.dart';
import 'package:tassist/widgets/custom_bottom_nav.dart';
import 'package:tassist/widgets/custom_meeting_card.dart';
import 'availability_management_page.dart';
import 'meeting_detail_screen.dart';

class ScheduleListScreen extends StatefulWidget {
  const ScheduleListScreen({super.key});

  @override
  State<ScheduleListScreen> createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
  final DosenService _dosenService = DosenService();

  bool _isLoading = true;
  String? _errorMessage;
  List<MeetingRequest> _meetings = [];

  String _selectedFilter = 'All';
  final _filters = ['All', 'Pending', 'Confirmed', 'Declined'];

  @override
  void initState() {
    super.initState();
    _loadJadwal();
  }

  Future<void> _loadJadwal() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rows = await _dosenService.getJadwalList(perPage: 50);
      final meetings = rows.map(MeetingRequest.fromJadwalJson).toList();

      if (!mounted) return;

      setState(() {
        _meetings = meetings;
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

  List<MeetingRequest> get _filteredMeetings {
    switch (_selectedFilter) {
      case 'Pending':
        return _meetings.where((m) => m.status == RequestStatus.pending).toList();
      case 'Confirmed':
        return _meetings.where((m) => m.status == RequestStatus.accepted).toList();
      case 'Declined':
        return _meetings.where((m) => m.status == RequestStatus.declined).toList();
      default:
        return _meetings;
    }
  }

  MeetingRequest? get _nextPendingMeeting {
    final pending = _meetings
        .where((m) => m.status == RequestStatus.pending)
        .toList();

    if (pending.isEmpty) return null;

    pending.sort((a, b) => a.meetingDate.compareTo(b.meetingDate));
    return pending.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _loadJadwal,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            if (!_isLoading && _errorMessage == null)
              SliverToBoxAdapter(child: _buildUpcomingBanner(context)),
            SliverToBoxAdapter(child: _buildFilterRow()),
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: AppLoadingWidget(),
                ),
              )
            else if (_errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
                  child: AppErrorWidget(
                    title: 'Failed to load schedule',
                    message: _errorMessage ?? '-',
                    onRetry: _loadJadwal,
                    retryLabel: 'Try Again',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  CustomBottomNav.navBarHeight +
                      CustomBottomNav.bottomPadding +
                      16,
                ),
                sliver: _filteredMeetings.isEmpty
                    ? const SliverToBoxAdapter(
                        child: AppEmptyStateWidget(
                          icon: Icons.event_busy_rounded,
                          title: 'No meeting schedule found',
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final req = _filteredMeetings[i];
                            return MeetingRequestCard(
                              request: req,
                              animationIndex: i,
                              onTap: () => _openDetail(ctx, req),
                            );
                          },
                          childCount: _filteredMeetings.length,
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 26),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage student meeting requests',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Atur Ketersediaan',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AvailabilityManagementPage(),
                    ),
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.05, end: 0),
        ),
      ),
    );
  }

  Widget _buildUpcomingBanner(BuildContext context) {
    final next = _nextPendingMeeting;
    if (next == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        onTap: () => _openDetail(context, next),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryDark, AppTheme.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      next.isProposedByStudent
                          ? 'Next Pending Student Meeting'
                          : 'Waiting Student Confirmation',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      next.studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${next.dayName} • ${next.meetingTime}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white70,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(begin: 0.1, end: 0),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'All Meeting Requests',
              style: GoogleFonts.poppins(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
          ),
          PopupMenuButton<String>(
            initialValue: _selectedFilter,
            onSelected: (value) => setState(() => _selectedFilter = value),
            itemBuilder: (context) => _filters
                .map(
                  (filter) => PopupMenuItem<String>(
                    value: filter,
                    child: Text(filter),
                  ),
                )
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  Text(
                    _selectedFilter,
                    style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, MeetingRequest request) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MeetingDetailScreen(request: request),
      ),
    );

    if (changed == true && mounted) {
      _loadJadwal();
    }
  }
}
