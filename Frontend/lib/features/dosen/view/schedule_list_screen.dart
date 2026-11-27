// lib/features/dosen/view/schedule_list_screen.dart
import 'package:flutter/material.dart';
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

  String _selectedFilter = 'Semua';
  final _filters = ['Semua', 'Menunggu', 'Dikonfirmasi', 'Ditolak'];

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
      case 'Menunggu':
        return _meetings.where((m) => m.status == RequestStatus.pending).toList();
      case 'Dikonfirmasi':
        return _meetings.where((m) => m.status == RequestStatus.accepted).toList();
      case 'Ditolak':
        return _meetings.where((m) => m.status == RequestStatus.declined).toList();
      default:
        return _meetings;
    }
  }

  int _countByFilter(String filter) {
    switch (filter) {
      case 'Menunggu':
        return _meetings.where((m) => m.status == RequestStatus.pending).length;
      case 'Dikonfirmasi':
        return _meetings.where((m) => m.status == RequestStatus.accepted).length;
      case 'Ditolak':
        return _meetings.where((m) => m.status == RequestStatus.declined).length;
      default:
        return _meetings.length;
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
      backgroundColor: AppTheme.backgroundOf(context),
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
                    title: 'Gagal memuat jadwal',
                    message: _errorMessage ?? '-',
                    onRetry: _loadJadwal,
                    retryLabel: 'Coba Lagi',
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
                          icon: Icons.event_busy_outlined,
                          title: 'Belum ada jadwal bimbingan',
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jadwal Bimbingan',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kelola pengajuan jadwal bimbingan mahasiswa',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Atur Ketersediaan',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.glassSurfaceOnDark,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(44, 44),
                  fixedSize: const Size(44, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    side: BorderSide(
                      color: AppTheme.glassBorderOnDark,
                      width: 1,
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AvailabilityManagementPage(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.event_available_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingBanner(BuildContext context) {
    final next = _nextPendingMeeting;
    if (next == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDetail(context, next),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: AppTheme.accentGoldOnDark.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.glassSurfaceOnDark,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.glassBorderOnDark),
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppTheme.accentGoldOnDark,
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
                            ? 'Pengajuan Jadwal Berikutnya'
                            : 'Menunggu Konfirmasi Mahasiswa',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.85),
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${next.dayName} • ${next.meetingTime}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_outlined,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    final textPrimary = AppTheme.textPrimaryOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Semua Pengajuan Jadwal',
              style: GoogleFonts.poppins(
                color: textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final selected = _selectedFilter == filter;
                final count = _countByFilter(filter);

                return Semantics(
                  button: true,
                  selected: selected,
                  label: 'Filter $filter ($count)',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selectedFilter = filter),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.surfaceOf(context),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.cardBorderOf(context),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              filter,
                              style: GoogleFonts.poppins(
                                color: selected
                                    ? Colors.white
                                    : AppTheme.textSecondaryOf(context),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : AppTheme.surfaceVariantOf(context),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              child: Text(
                                '$count',
                                style: GoogleFonts.poppins(
                                  color: selected
                                      ? Colors.white
                                      : AppTheme.textSecondaryOf(context),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
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
