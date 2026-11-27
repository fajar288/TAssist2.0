import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/helpers/avatar_helper.dart';
import '../../main_mahasiswa/navbar_mahasiswa.dart';
import 'package:tassist/features/main_mahasiswa/data/mahasiswa_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_empty_state_widget.dart';
import '../../../widgets/app_error_widget.dart';
import '../../../widgets/app_loading_widget.dart';
import 'lecturer_detail_page.dart';
import 'lecturer_recommendation_page.dart';

class LecturersPage extends StatefulWidget {
  const LecturersPage({
    super.key,
    this.initialBidangKeahlian,
  });

  final String? initialBidangKeahlian;

  @override
  State<LecturersPage> createState() => _LecturersPageState();
}

class _LecturersPageState extends State<LecturersPage> {
  final TextEditingController _searchController = TextEditingController();
  final MahasiswaService _mahasiswaService = MahasiswaService();

  late String? _selectedBidangKeahlian;
  LecturerViewType _selectedView = LecturerViewType.standard;

  bool _showFilterDropdown = false;
  bool _showViewDropdown = false;
  bool _isRecommendationMode = false;

  List<LecturerModel> _allLecturers = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _bidangOptions = const [
    'Kecerdasan Buatan dan Machine Learning',
    'Rekayasa Perangkat Lunak',
    'Jaringan Komputer dan Keamanan Siber',
    'Sistem Informasi dan Basis Data',
    'Computer Vision dan Pengolahan Citra',
  ];

  @override
  void initState() {
    super.initState();
    _selectedBidangKeahlian = widget.initialBidangKeahlian;
    _loadLecturers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLecturers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rows = await _mahasiswaService.getDosen(
        bidangKeahlian: _selectedBidangKeahlian,
        adaKuota: false,
        perPage: 50,
      );

      final lecturers = rows
          .map((item) => LecturerModel.fromJson(item))
          .toList();

      if (!mounted) return;

      setState(() {
        _allLecturers = lecturers;
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

  List<LecturerModel> get _filteredLecturers {
    final query = _searchController.text.trim().toLowerCase();

    return _allLecturers.where((lecturer) {
      if (query.isEmpty) return true;

      final name = lecturer.name.toLowerCase();
      final bidang = lecturer.bidangKeahlian.toLowerCase();
      final nid = lecturer.nid.toLowerCase();

      return name.contains(query) ||
          bidang.contains(query) ||
          nid.contains(query);
    }).toList();
  }

  int get _activeFilterCount {
    return _selectedBidangKeahlian != null ? 1 : 0;
  }

  int _getCrossAxisCount(double width) {
    if (_selectedView == LecturerViewType.extraLarge) {
      return 1;
    }

    if (_selectedView == LecturerViewType.large) {
      return width < 700 ? 1 : 2;
    }

    if (width < 430) {
      return 2;
    }

    if (width < 900) {
      return 3;
    }

    return 4;
  }

  double _getGridItemHeight(double width) {
    if (_selectedView == LecturerViewType.extraLarge) {
      return 150;
    }

    if (_selectedView == LecturerViewType.large) {
      return 250;
    }

    return 240;
  }

  bool get _isOverlayVisible {
    return _showFilterDropdown || _showViewDropdown;
  }

  void _toggleFilterDropdown() {
    setState(() {
      _showFilterDropdown = !_showFilterDropdown;

      if (_showFilterDropdown) {
        _showViewDropdown = false;
      }
    });
  }

  void _toggleViewDropdown() {
    setState(() {
      _showViewDropdown = !_showViewDropdown;

      if (_showViewDropdown) {
        _showFilterDropdown = false;
      }
    });
  }

  void _closeAllDropdowns() {
    setState(() {
      _showFilterDropdown = false;
      _showViewDropdown = false;
    });
  }

  void _selectBidangKeahlian(String? bidang) {
    setState(() {
      _selectedBidangKeahlian = bidang;
      _showFilterDropdown = false;
    });

    _loadLecturers();
  }

  void _selectView(LecturerViewType viewType) {
    setState(() {
      _selectedView = viewType;
      _showViewDropdown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lecturers = _filteredLecturers;

    return Scaffold(
      backgroundColor: AppTheme.backgroundOf(context),
      extendBody: true,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
                    child: Column(
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 14),
                        _buildModeSwitcher(),
                        const SizedBox(height: 14),
                        if (_isRecommendationMode)
                          const Expanded(
                            child: LecturerRecommendationView(),
                          )
                        else ...[
                          _buildTopControls(),
                          const SizedBox(height: 18),
                          Expanded(
                            child: _isLoading
                                ? const Center(
                                    child: AppLoadingWidget(),
                                  )
                                : _errorMessage != null
                                    ? _buildErrorState()
                                    : lecturers.isEmpty
                                        ? _buildEmptyState()
                                        : _buildLecturerGrid(lecturers),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_isOverlayVisible) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeAllDropdowns,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 155,
                left: 14,
                right: 14,
                child: _showFilterDropdown
                    ? _buildFilterDropdown()
                    : _buildViewDropdown(),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: NavbarMahasiswa(
        currentIndex: 0,
        onTap: (index) {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryOf(context);
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: textPrimary,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Text(
            'Lecturers',
            style: TextStyle(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.cardBorderOf(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeTabButton(
              icon: Icons.grid_view_rounded,
              label: 'Semua Dosen',
              isSelected: !_isRecommendationMode,
              onTap: () {
                setState(() {
                  _isRecommendationMode = false;
                });
              },
            ),
          ),
          Expanded(
            child: _ModeTabButton(
              icon: Icons.person_search_outlined,
              label: 'Rekomendasi Topik',
              isSelected: _isRecommendationMode,
              onTap: () {
                setState(() {
                  _isRecommendationMode = true;
                  _showFilterDropdown = false;
                  _showViewDropdown = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);
    final dividerColor = AppTheme.cardBorderOf(context);

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search name, expertise, or NID',
                        hintStyle: TextStyle(
                          color: textMuted,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildControlTab(
            flex: 2,
            icon: Icons.tune_rounded,
            label: 'Filters',
            onTap: _toggleFilterDropdown,
            showBadge: _activeFilterCount > 0,
            hasBorder: true,
          ),
          _buildControlTab(
            flex: 2,
            icon: Icons.view_agenda_rounded,
            label: 'View',
            onTap: _toggleViewDropdown,
          ),
        ],
      ),
    );
  }

  Widget _buildControlTab({
    required int flex,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool showBadge = false,
    bool hasBorder = false,
  }) {
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final dividerColor = AppTheme.cardBorderOf(context);

    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: hasBorder
                ? Border(
                    right: BorderSide(
                      color: dividerColor,
                      width: 1,
                    ),
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showBadge) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$_activeFilterCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLecturerGrid(List<LecturerModel> lecturers) {
    final screenWidth = MediaQuery.of(context).size.width;
    final gridWidth = screenWidth - 28;

    return RefreshIndicator(
      onRefresh: _loadLecturers,
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: lecturers.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(gridWidth),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          mainAxisExtent: _getGridItemHeight(gridWidth),
        ),
        itemBuilder: (context, index) {
          return _LecturerCard(
            lecturer: lecturers[index],
            viewType: _selectedView,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LecturerDetailPage(
                    lecturer: lecturers[index],
                  ),
                ),
              ).then((_) => setState(() {}));
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return _buildBaseDropdown(
      children: [
        _DropdownRadioTile(
          title: 'All Fields',
          isSelected: _selectedBidangKeahlian == null,
          onTap: () => _selectBidangKeahlian(null),
        ),
        ..._bidangOptions.map(
          (bidang) {
            return _DropdownRadioTile(
              title: bidang,
              isSelected: _selectedBidangKeahlian == bidang ||
                  (_selectedBidangKeahlian != null &&
                      bidang.toLowerCase().contains(
                            _selectedBidangKeahlian!.toLowerCase(),
                          )),
              onTap: () => _selectBidangKeahlian(bidang),
            );
          },
        ),
      ],
    );
  }

  Widget _buildViewDropdown() {
    return _buildBaseDropdown(
      children: LecturerViewType.values.map(
        (view) {
          return _DropdownRadioTile(
            title: view.label,
            isSelected: _selectedView == view,
            onTap: () => _selectView(view),
          );
        },
      ).toList(),
    );
  }

  Widget _buildBaseDropdown({required List<Widget> children}) {
    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 360),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceOf(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.cardBorderOf(context)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const AppEmptyStateWidget(
      icon: Icons.person_search_rounded,
      title: 'No lecturers found.',
      subtitle: 'Coba ubah kata kunci pencarian atau filter bidang keahlian.',
    );
  }

  Widget _buildErrorState() {
    return AppErrorWidget(
      title: 'Failed to load lecturers',
      message: _errorMessage ?? '-',
      retryLabel: 'Try Again',
      onRetry: _loadLecturers,
    );
  }
}

class _LecturerCard extends StatelessWidget {
  const _LecturerCard({
    required this.lecturer,
    required this.viewType,
    required this.onTap,
  });

  final LecturerModel lecturer;
  final LecturerViewType viewType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isExtraLarge = viewType == LecturerViewType.extraLarge;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration:
              AppTheme.cardDecorationOf(context, radius: AppTheme.radiusMd),
          child: isExtraLarge
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: SizedBox(
                        width: 110,
                        height: 110,
                        child: _buildAvatar(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildLecturerInfo(context),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 7,
                      child: _buildAvatar(context),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      flex: 3,
                      child: _buildLecturerInfo(context),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppTheme.radiusMd);

    Widget image;

    if (!AvatarHelper.hasAvatar(lecturer.avatar)) {
      image = Image.asset(
        'assets/images/default_avatar.jpeg',
        fit: BoxFit.cover,
      );
    } else {
      image = Image.network(
        lecturer.imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }

          return Image.asset(
            'assets/images/default_avatar.jpeg',
            fit: BoxFit.cover,
          );
        },
        errorBuilder: (_, __, ___) {
          return Image.asset(
            'assets/images/default_avatar.jpeg',
            fit: BoxFit.cover,
          );
        },
      );
    }

    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: AppTheme.surfaceVariantOf(context),
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: AspectRatio(
            aspectRatio: 1,
            child: image,
          ),
        ),
      ),
    );
  }

  Widget _buildLecturerInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                lecturer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textPrimaryOf(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryGhostOf(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                '${lecturer.quotaLeft}',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryOf(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          lecturer.bidangKeahlian,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.textSecondaryOf(context),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DropdownRadioTile extends StatelessWidget {
  const _DropdownRadioTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: isSelected
                  ? AppTheme.primaryOf(context)
                  : AppTheme.textMutedOf(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LecturerModel {
  const LecturerModel({
    required this.id,
    required this.name,
    required this.bidangKeahlian,
    required this.imageUrl,
    required this.quotaLeft,
    required this.nid,
    this.email,
    this.profilSingkat,
    this.avatar,
  });

  final String id;
  final String name;
  final String bidangKeahlian;
  final String imageUrl;
  final int quotaLeft;
  final String nid;
  final String? email;
  final String? profilSingkat;
  final String? avatar;

  String get displayName => name;

  factory LecturerModel.fromJson(Map<String, dynamic> json) {
    final dosenId = json['dosen_id']?.toString() ?? '';
    final avatar = json['avatar']?.toString();

    return LecturerModel(
      id: dosenId,
      name: json['nama']?.toString() ?? '-',
      bidangKeahlian: json['bidang_keahlian']?.toString() ?? '-',
      nid: json['nid']?.toString() ?? '-',
      quotaLeft: int.tryParse(json['sisa_kuota']?.toString() ?? '') ?? 0,
      email: json['email']?.toString(),
      profilSingkat: json['profil_singkat']?.toString(),
      avatar: avatar,
      imageUrl: AvatarHelper.getAvatarUrl(
        avatar: avatar,
      ),
    );
  }
}

enum LecturerViewType {
  extraLarge,
  large,
  standard,
}

extension LecturerViewTypeX on LecturerViewType {
  String get label {
    switch (this) {
      case LecturerViewType.extraLarge:
        return 'Medium List';
      case LecturerViewType.large:
        return 'Large List';
      case LecturerViewType.standard:
        return 'Standard List';
    }
  }
}

class _ModeTabButton extends StatelessWidget {
  const _ModeTabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : AppTheme.textSecondaryOf(context),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : AppTheme.textSecondaryOf(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}