import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tassist/features/dosen/data/dosen_service.dart';

import 'package:tassist/app/app.dart';
import 'package:tassist/features/notifikasi/widgets/notifikasi_bell_button.dart';
import 'dosen_edit_profile_page.dart';
import 'package:tassist/model/models.dart';
import 'package:tassist/theme/app_theme.dart';
import 'package:tassist/theme/theme_controller.dart';
import 'package:tassist/widgets/app_empty_state_widget.dart';
import 'package:tassist/widgets/app_error_widget.dart';
import 'package:tassist/widgets/app_skeleton_loader.dart';
import 'package:tassist/widgets/custom_bottom_nav.dart';
import 'package:tassist/widgets/custom_request_card.dart';
import 'counseling_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DosenService _dosenService = DosenService();

  bool _isLoading = true;
  String? _errorMessage;

  _DosenHeaderData _headerData = const _DosenHeaderData(
    nama: 'Dosen',
    subtitle: 'Dosen Pembimbing',
    avatarText: 'D',
  );

  Map<String, dynamic>? _rawProfileData;

  List<CounselingRequest> _requests = [];

  String _selectedFilter = 'All';
  final _filters = ['All', 'Pending', 'Accepted', 'Declined'];

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
      final profileResponse = await _dosenService.getProfile();
      final permohonanRows = await _dosenService.getPermohonanList(
        perPage: 50,
      );

      final requests = permohonanRows
          .map(CounselingRequest.fromPermohonanJson)
          .toList();

      if (!mounted) return;

      setState(() {
        _rawProfileData = profileResponse;
        _headerData = _parseProfileResponse(profileResponse);
        _requests = requests;
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

  List<CounselingRequest> get _filteredRequests {
    if (_selectedFilter == 'All') return _requests;

    final status = RequestStatus.values.firstWhere(
      (s) => s.label == _selectedFilter,
    );

    return _requests.where((r) => r.status == status).toList();
  }

  int _countByStatus(RequestStatus status) {
    return _requests.where((r) => r.status == status).length;
  }

  void _logout() {
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOf(context),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(
                context,
                nama: _headerData.nama,
                subtitle: _headerData.subtitle,
                avatarText: _headerData.avatarText,
              ),
            ),

            SliverToBoxAdapter(child: _buildFilterRow()),

            if (_isLoading)
              const SliverToBoxAdapter(
                child: AppSkeletonLoader.card(count: 3),
              )
            else if (_errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
                  child: AppErrorWidget(
                    title: 'Failed to load requests',
                    message: _errorMessage ?? '-',
                    onRetry: _loadDashboardData,
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
                sliver: _filteredRequests.isEmpty
                    ? const SliverToBoxAdapter(
                        child: AppEmptyStateWidget(
                          icon: Icons.inbox_rounded,
                          title: 'No requests found',
                          subtitle:
                              'There are no requests matching\nthis filter right now.',
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final request = _filteredRequests[i];

                            return CounselingRequestCard(
                              request: request,
                              animationIndex: i,
                              onTap: () => _openDetail(ctx, request),
                            );
                          },
                          childCount: _filteredRequests.length,
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  _DosenHeaderData _parseProfileResponse(Map<String, dynamic>? response) {
    if (response == null) {
      return const _DosenHeaderData(
        nama: 'Dosen',
        subtitle: 'Dosen Pembimbing',
        avatarText: 'D',
      );
    }

    final data = response['data'];

    Map<String, dynamic>? user;
    Map<String, dynamic>? profile;

    if (data is Map<String, dynamic>) {
      final rawUser = data['user'];
      final rawProfile = data['profile'];

      if (rawUser is Map<String, dynamic>) {
        user = rawUser;
      }

      if (rawProfile is Map<String, dynamic>) {
        profile = rawProfile;
      }
    }

    final nama = user?['nama']?.toString() ??
        user?['name']?.toString() ??
        'Dosen';

    final bidangKeahlian = profile?['bidang_keahlian']?.toString();

    final subtitle = bidangKeahlian != null && bidangKeahlian.isNotEmpty
        ? bidangKeahlian
        : 'Dosen Pembimbing';

    final avatarText = _getInitials(nama);

    return _DosenHeaderData(
      nama: nama,
      subtitle: subtitle,
      avatarText: avatarText,
    );
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'D';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _buildHeader(
    BuildContext context, {
    required String nama,
    required String subtitle,
    required String avatarText,
  }) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                        )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideX(begin: -0.1, end: 0),
                        const SizedBox(height: 2),
                        Text(
                          '$nama!',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 100.ms)
                            .slideX(begin: -0.1, end: 0),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                        offset: const Offset(0, 60), // Menurunkan dropdown agar pas
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        onSelected: (value) async {
                          if (value == 'edit_profile') {
                            // Menggabungkan data dari tabel user dan dosen untuk dikirim ke UI Edit Profil
                            final userData = _rawProfileData?['data']?['user'] as Map<String, dynamic>? ?? {};
                            final dosenData = _rawProfileData?['data']?['dosen'] as Map<String, dynamic>? ?? {};
                            
                            final combinedProfile = {
                              'nama': userData['nama'] ?? userData['name'] ?? '',
                              'email': userData['email'] ?? '',
                              'avatar': userData['avatar'],
                              'kuota_bimbingan': dosenData['kuota_bimbingan'] ?? 0,
                            };

                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DosenEditProfilePage(initialProfile: combinedProfile),
                              ),
                            );

                            // Jika profil disimpan, refresh halaman dashboard untuk menarik foto/nama terbaru
                            if (result == true && mounted) {
                              _loadDashboardData();
                            }
                          } else if (value == 'theme') {
                            await ThemeController.showThemeSelectorSheet(context);
                          } else if (value == 'logout') {
                            _logout();
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          final menuTextColor = AppTheme.textPrimaryOf(context);
                          return [
                            PopupMenuItem<String>(
                              value: 'edit_profile',
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline, size: 20, color: menuTextColor),
                                  const SizedBox(width: 12),
                                  Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.w600, color: menuTextColor)),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'theme',
                              child: Row(
                                children: [
                                  Icon(ThemeController.instance.icon, size: 20, color: AppTheme.primaryOf(context)),
                                  const SizedBox(width: 12),
                                  Text('Tema: ${ThemeController.instance.label}', style: TextStyle(fontWeight: FontWeight.w600, color: menuTextColor)),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout_rounded, size: 20, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ];
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.glassSurfaceOnDark,
                            border: Border.all(
                              color: AppTheme.glassBorderOnDark,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              avatarText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 200.ms)
                          .scale(begin: const Offset(0.8, 0.8)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _StatChip(
                    label: 'Pending',
                    count: _countByStatus(RequestStatus.pending),
                    color: AppTheme.pending,
                  ),
                  const SizedBox(width: 10),
                  _StatChip(
                    label: 'Accepted',
                    count: _countByStatus(RequestStatus.accepted),
                    color: AppTheme.accepted,
                  ),
                  const SizedBox(width: 10),
                  _StatChip(
                    label: 'Declined',
                    count: _countByStatus(RequestStatus.declined),
                    color: AppTheme.declined,
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Counseling Requests',
              style: GoogleFonts.poppins(
                color: AppTheme.textPrimaryOf(context),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ..._filters.skip(1).map(
                (f) => _FilterChip(
                  label: f,
                  selected: _selectedFilter == f,
                  onTap: () => setState(() {
                    _selectedFilter = _selectedFilter == f ? 'All' : f;
                  }),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _openDetail(
    BuildContext context,
    CounselingRequest request,
  ) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CounselingDetailScreen(request: request),
      ),
    );

    if (changed == true && mounted) {
      _loadDashboardData();
    }
  }
}

class _DosenHeaderData {
  final String nama;
  final String subtitle;
  final String avatarText;

  const _DosenHeaderData({
    required this.nama,
    required this.subtitle,
    required this.avatarText,
  });
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.glassSurfaceOnDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.glassBorderOnDark,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
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
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surfaceOf(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.cardBorderOf(context),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: selected ? Colors.white : AppTheme.textSecondaryOf(context),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}