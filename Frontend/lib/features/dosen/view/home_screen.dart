import 'package:flutter/material.dart';
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
import 'package:tassist/widgets/user_avatar_circle.dart';
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

  String _selectedFilter = 'Semua';
  final _filters = ['Semua', 'Menunggu', 'Diterima', 'Ditolak'];

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
    switch (_selectedFilter) {
      case 'Menunggu':
        return _requests
            .where((r) => r.status == RequestStatus.pending)
            .toList();
      case 'Diterima':
        return _requests
            .where((r) => r.status == RequestStatus.accepted)
            .toList();
      case 'Ditolak':
        return _requests
            .where((r) => r.status == RequestStatus.declined)
            .toList();
      default:
        return _requests;
    }
  }

  int _countByFilter(String filter) {
    switch (filter) {
      case 'Menunggu':
        return _countByStatus(RequestStatus.pending);
      case 'Diterima':
        return _countByStatus(RequestStatus.accepted);
      case 'Ditolak':
        return _countByStatus(RequestStatus.declined);
      default:
        return _requests.length;
    }
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
                avatarUrl: _headerData.avatarUrl,
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
                    title: 'Gagal memuat permohonan',
                    message: _errorMessage ?? '-',
                    onRetry: _loadDashboardData,
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
                sliver: _filteredRequests.isEmpty
                    ? const SliverToBoxAdapter(
                        child: AppEmptyStateWidget(
                          icon: Icons.inbox_outlined,
                          title: 'Belum ada permohonan',
                          subtitle:
                              'Tidak ada permohonan bimbingan yang sesuai filter saat ini.',
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
    final avatarUrl = user?['avatar']?.toString();

    return _DosenHeaderData(
      nama: nama,
      subtitle: subtitle,
      avatarText: avatarText,
      avatarUrl: avatarUrl,
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
    String? avatarUrl,
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
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
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
                          'Selamat datang,',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: AppTheme.accentGoldOnDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Asisten TA',
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.glassSurfaceOnDark,
                          foregroundColor: Colors.white,
                          shape: CircleBorder(
                            side: BorderSide(color: AppTheme.glassBorderOnDark),
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
                        iconColor: Colors.white,
                        backgroundColor: AppTheme.glassSurfaceOnDark,
                        borderColor: AppTheme.glassBorderOnDark,
                        pageTitle: 'Notifikasi',
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        tooltip: 'Menu akun',
                        offset: const Offset(0, 60),
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
                                  Icon(Icons.logout_outlined, size: 20, color: AppTheme.declined),
                                  SizedBox(width: 12),
                                  Text('Keluar', style: TextStyle(color: AppTheme.declined, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ];
                        },
                        child: UserAvatarCircle(
                          name: nama,
                          avatar: avatarUrl,
                          size: 48,
                          borderColor: AppTheme.accentGoldOnDark.withValues(alpha: 0.75),
                          borderWidth: 1.5,
                          showShadow: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Permohonan Bimbingan',
              style: GoogleFonts.poppins(
                color: AppTheme.textPrimaryOf(context),
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
                final f = _filters[index];
                return _FilterChip(
                  label: f,
                  count: _countByFilter(f),
                  selected: _selectedFilter == f,
                  onTap: () => setState(() {
                    _selectedFilter = _selectedFilter == f ? 'Semua' : f;
                  }),
                );
              },
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
  final String? avatarUrl;

  const _DosenHeaderData({
    required this.nama,
    required this.subtitle,
    required this.avatarText,
    this.avatarUrl,
  });
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Filter $label ($count)',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : AppTheme.surfaceOf(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(
                  color: selected
                      ? AppTheme.primary
                      : AppTheme.cardBorderOf(context),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
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
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
      ),
    );
  }
}