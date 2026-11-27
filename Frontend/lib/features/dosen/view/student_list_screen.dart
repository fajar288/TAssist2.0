import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tassist/features/analytics/data/analytics_service.dart';
import 'package:tassist/features/analytics/model/risk_snapshot_model.dart';
import 'package:tassist/features/dosen/data/dosen_service.dart';
import 'package:tassist/model/models.dart';
import 'package:tassist/theme/app_theme.dart';
import 'package:tassist/widgets/app_empty_state_widget.dart';
import 'package:tassist/widgets/app_error_widget.dart';
import 'package:tassist/widgets/app_skeleton_loader.dart';
import 'package:tassist/widgets/custom_bottom_nav.dart';
import 'package:tassist/widgets/student_card.dart';

import 'student_detail_screen.dart';

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final DosenService _dosenService = DosenService();
  final AnalyticsService _analyticsService = AnalyticsService();

  List<StudentModel> _allStudents = [];
  List<StudentModel> _filteredStudents = [];
  final Map<String, RiskSnapshotModel> _riskMap = {};

  String _selectedFilter = 'All';
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _headerAnimController;
  late Animation<double> _headerFadeAnim;

  final List<String> _filters = ['All', 'Active', 'Warning', 'Completed'];

  @override
  void initState() {
    super.initState();

    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFadeAnim = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOut,
    );
    _headerAnimController.forward();

    _searchController.addListener(_onSearchChanged);
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rows = await _dosenService.getMahasiswaBimbinganList(perPage: 50);
      final students = rows
          .map((item) => StudentModel.fromBimbinganJson(item))
          .toList();

      try {
        final riskItems = await _analyticsService.getDosenRiskIndicators();
        for (final item in riskItems) {
          _riskMap[item.bimbinganId.toString()] = item.risiko;
        }
      } catch (_) {
        // Fallback jika belum ada kalkulasi risiko atau offline
      }

      if (!mounted) return;

      setState(() {
        _allStudents = students;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() => _applyFilters();

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredStudents = _allStudents.where((s) {
        final matchesSearch = s.name.toLowerCase().contains(query) ||
            s.nim.contains(query) ||
            s.major.toLowerCase().contains(query);
        final matchesFilter = _selectedFilter == 'All' ||
            s.status == _selectedFilter.toLowerCase();
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    _applyFilters();
  }

  int _countByStatus(String status) {
    if (status == 'All') return _allStudents.length;
    return _allStudents.where((s) => s.status == status.toLowerCase()).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOf(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeTransition(
            opacity: _headerFadeAnim,
            child: _buildHeader(context),
          ),
          _buildSearchBar(context),
          const SizedBox(height: 12),
          _buildFilterRow(context),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const SingleChildScrollView(
                    child: AppSkeletonLoader.card(count: 4),
                  )
                : _errorMessage != null
                    ? AppErrorWidget(
                        title: 'Failed to load students',
                        message: _errorMessage ?? '-',
                        onRetry: _loadStudents,
                        retryLabel: 'Try Again',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadStudents,
                        child: _filteredStudents.isEmpty
                            ? _buildEmptyState(context)
                            : ListView.builder(
                                padding: EdgeInsets.only(
                                  top: 4,
                                  bottom: CustomBottomNav.navBarHeight +
                                      CustomBottomNav.bottomPadding +
                                      16,
                                ),
                                itemCount: _filteredStudents.length,
                                itemBuilder: (context, index) {
                                  final student = _filteredStudents[index];

                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: Duration(
                                      milliseconds:
                                          300 + (index * 60).clamp(0, 400),
                                    ),
                                    curve: Curves.easeOut,
                                    builder: (context, value, child) => Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: child,
                                      ),
                                    ),
                                    child: StudentCard(
                                      student: student,
                                      risk: _riskMap[student.id],
                                      onTap: () => _navigateToDetail(
                                        context,
                                        student,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final active = _countByStatus('Active');
    final warning = _countByStatus('Warning');
    final completed = _countByStatus('Completed');

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
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Students Overview',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your advisee students',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.glassSurfaceOnDark,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: AppTheme.accentGoldOnDark.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.groups_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _headerStatChip('$active Aktif', const Color(0xFF34D399)),
                  _headerStatChip('$warning Perhatian', AppTheme.accentGoldOnDark),
                  _headerStatChip('$completed Selesai', const Color(0xFF93C5FD)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.glassSurfaceOnDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.glassBorderOnDark, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final muted = AppTheme.textMutedOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: 14, color: AppTheme.textPrimaryOf(context)),
        decoration: InputDecoration(
          hintText: 'Search by name, NIM, or major...',
          hintStyle: TextStyle(color: muted, fontSize: 13),
          prefixIcon: Icon(
            Icons.search_outlined,
            color: muted,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                  icon: Icon(
                    Icons.close_outlined,
                    color: muted,
                    size: 18,
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        ),
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          final count = _countByStatus(filter);

          return Semantics(
            button: true,
            selected: isSelected,
            label: 'Filter $filter ($count)',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onFilterChanged(filter),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.surfaceOf(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.cardBorderOf(context),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        filter,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondaryOf(context),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : AppTheme.surfaceVariantOf(context),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondaryOf(context),
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
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        AppEmptyStateWidget(
          icon: Icons.search_off_outlined,
          title: 'Mahasiswa tidak ditemukan',
          subtitle: 'Coba ubah kata kunci pencarian atau filter',
          actionLabel: 'Atur ulang filter',
          onAction: () {
            _searchController.clear();
            _onFilterChanged('All');
          },
        ),
      ],
    );
  }

  void _navigateToDetail(BuildContext context, StudentModel student) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            StudentDetailPage(student: student),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}
