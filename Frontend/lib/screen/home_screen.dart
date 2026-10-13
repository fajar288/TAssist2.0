import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:produk/features/dosen/data/dosen_service.dart';

import '../features/notifikasi/widgets/notifikasi_bell_button.dart';
import '../features/dosen/view/dosen_edit_profile_page.dart';
import '../model/models.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/custom_request_card.dart';
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

  static const Color _navBlue = Color(0xFF0D4AA3);
  static const Color _navBlueDark = Color(0xFF082E6B);
  static const Color _navBlueLight = Color(0xFF1A65C8);

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
      backgroundColor: AppTheme.background,
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
                child: Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                  child: _buildErrorCard(),
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
                    ? const SliverToBoxAdapter(child: _EmptyState())
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

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            'Failed to load requests',
            style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ?? '-',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
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
        gradient: LinearGradient(
          colors: [_navBlueDark, _navBlue, _navBlueLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
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
                        Row(
                          children: [
                            const Text(
                              '👋  ',
                              style: TextStyle(fontSize: 18),
                            ),
                            Text(
                              'Hello There!,',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
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
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
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
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const NotifikasiBellButton(
                        size: 38,
                        iconColor: Colors.white,
                        backgroundColor: Colors.white24,
                        borderColor: Colors.white38,
                        pageTitle: 'Notifications',
                      ),
                      const SizedBox(width: 10),
                      PopupMenuButton<String>(
                        offset: const Offset(0, 60), // Menurunkan dropdown agar pas
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                          } else if (value == 'logout') {
                            _logout();
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'edit_profile',
                            child: Row(
                              children: [
                                Icon(Icons.person_outline, size: 20, color: Color(0xFF1E293B)),
                                SizedBox(width: 12),
                                Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
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
                        ],
                        // UI Container asli
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Container(
                              width: 56,
                              height: 56,
                              color: Colors.white24,
                              child: Center(
                                child: Text(
                                  avatarText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
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
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
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
          color: selected ? const Color(0xFF0D4AA3) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF0D4AA3) : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_rounded,
              size: 48,
              color: Color(0xFF0D4AA3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No requests found',
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'There are no requests matching\nthis filter right now.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: const Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}