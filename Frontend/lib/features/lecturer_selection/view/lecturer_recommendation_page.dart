import 'package:flutter/material.dart';

import '../../../core/helpers/avatar_helper.dart';
import 'package:tassist/features/main_mahasiswa/data/mahasiswa_service.dart';
import '../../../model/lecturer_recommendation_model.dart';
import '../../../theme/app_theme.dart';
import '../../main_mahasiswa/navbar_mahasiswa.dart';
import 'lecturer_detail_page.dart';
import 'lecturers_page.dart';

typedef RecommendationFetcher = Future<LecturerRecommendationResponse> Function(
  String topik,
);

class LecturerRecommendationPage extends StatelessWidget {
  const LecturerRecommendationPage({
    super.key,
    this.initialTopik,
    this.fetcher,
  });

  final String? initialTopik;
  final RecommendationFetcher? fetcher;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Rekomendasi Dosen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LecturerRecommendationView(
        initialTopik: initialTopik,
        fetcher: fetcher,
      ),
      bottomNavigationBar: NavbarMahasiswa(
        currentIndex: 0,
        onTap: (_) {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
    );
  }
}

class LecturerRecommendationView extends StatefulWidget {
  const LecturerRecommendationView({
    super.key,
    this.initialTopik,
    this.fetcher,
  });

  final String? initialTopik;
  final RecommendationFetcher? fetcher;

  @override
  State<LecturerRecommendationView> createState() =>
      _LecturerRecommendationViewState();
}

class _LecturerRecommendationViewState
    extends State<LecturerRecommendationView> {
  static const double _radiusSm = 8;
  static const double _radiusMd = 14;
  static const double _radiusLg = 20;

  static const List<String> _sampleTopics = [
    'Deteksi Penyakit Tanaman Deep Learning',
    'Keamanan Jaringan dan Kriptografi',
    'Sistem Informasi Enterprise Basis Data',
    'Pengembangan Aplikasi Agile Mobile',
  ];

  final MahasiswaService _mahasiswaService = MahasiswaService();
  late final TextEditingController _topicController;

  bool _isLoading = false;
  String? _errorMessage;
  LecturerRecommendationResponse? _response;

  @override
  void initState() {
    super.initState();
    _topicController = TextEditingController(text: widget.initialTopik ?? '');
    if (widget.initialTopik != null && widget.initialTopik!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchRecommendation();
      });
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _searchRecommendation([String? overrideTopic]) async {
    final topic = (overrideTopic ?? _topicController.text).trim();
    if (overrideTopic != null) {
      _topicController.text = overrideTopic;
    }

    if (topic.isEmpty) {
      setState(() {
        _errorMessage = 'Masukkan topik Tugas Akhir terlebih dahulu.';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = widget.fetcher != null
          ? await widget.fetcher!(topic)
          : await _mahasiswaService.getRekomendasiDosen(topik: topic);

      if (!mounted) return;
      setState(() {
        _response = result;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: _buildSearchCard(),
        ),
        Expanded(
          child: _buildBody(),
        ),
      ],
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(radius: _radiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cari Pembimbing Sesuai Topik TA',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sistem mencocokkan topik dengan keahlian dosen, sisa kuota, dan beban bimbingan aktif.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _topicController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchRecommendation(),
                  decoration: InputDecoration(
                    hintText: 'Contoh: Klasifikasi citra medis berbasis CNN...',
                    hintStyle: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_radiusMd),
                      borderSide: const BorderSide(color: AppTheme.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_radiusMd),
                      borderSide: const BorderSide(color: AppTheme.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_radiusMd),
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _searchRecommendation(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_radiusMd),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.surface,
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _sampleTopics.map((sample) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(
                      sample,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: AppTheme.primaryGhost,
                    side: const BorderSide(color: AppTheme.infoBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_radiusSm),
                    ),
                    onPressed:
                        _isLoading ? null : () => _searchRecommendation(sample),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.declinedBg,
              borderRadius: BorderRadius.circular(_radiusMd),
              border: Border.all(color: AppTheme.declinedBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppTheme.declined,
                  size: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _searchRecommendation(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final response = _response;
    if (response == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.manage_search_rounded,
                size: 54,
                color: AppTheme.primaryLight,
              ),
              SizedBox(height: 12),
              Text(
                'Masukkan rencana topik Tugas Akhir Anda untuk mendapatkan peringkat dosen pembimbing terbaik.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (response.rekomendasi.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_off_rounded,
                size: 46,
                color: AppTheme.textMuted,
              ),
              const SizedBox(height: 10),
              const Text(
                'Tidak ada dosen pembimbing yang memiliki sisa kuota saat ini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (response.totalDosenDikecualikanKuotaHabis > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '${response.totalDosenDikecualikanKuotaHabis} dosen dengan kuota penuh otomatis dikecualikan.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: response.rekomendasi.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildMetaHeader(response);
        }

        final rank = index;
        final item = response.rekomendasi[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: RecommendedLecturerCard(
            rank: rank,
            item: item,
            onTap: () {
              final model = LecturerModel.fromJson(item.toLecturerJson());
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LecturerDetailPage(lecturer: model),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMetaHeader(LecturerRecommendationResponse response) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (response.isTopikSingkat && response.catatanKueri != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppTheme.warningBg,
                borderRadius: BorderRadius.circular(_radiusMd),
                border: Border.all(color: AppTheme.warningBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      response.catatanKueri!,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InfoChip(
                icon: Icons.people_alt_outlined,
                label: '${response.totalKandidat} dosen tersedia',
                bg: AppTheme.primaryGhost,
                fg: AppTheme.primary,
                border: AppTheme.infoBorder,
              ),
              if (response.totalDosenDikecualikanKuotaHabis > 0)
                _InfoChip(
                  icon: Icons.block_rounded,
                  label:
                      '${response.totalDosenDikecualikanKuotaHabis} kuota penuh dikecualikan',
                  bg: AppTheme.surfaceVariant,
                  fg: AppTheme.textSecondary,
                  border: AppTheme.cardBorder,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class RecommendedLecturerCard extends StatelessWidget {
  const RecommendedLecturerCard({
    super.key,
    required this.rank,
    required this.item,
    required this.onTap,
  });

  static const double _radiusSm = 8;
  static const double _radiusMd = 14;
  static const double _radiusLg = 20;

  final int rank;
  final RecommendedLecturerModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final comp = item.komponenSkor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_radiusLg),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(_radiusLg),
          border: Border.all(
            color: rank == 1 ? AppTheme.primaryLight : AppTheme.cardBorder,
            width: rank == 1 ? 1.4 : 1,
          ),
          boxShadow: AppTheme.subtleShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: rank == 1
                                  ? AppTheme.primary
                                  : AppTheme.primaryGhost,
                              borderRadius: BorderRadius.circular(_radiusSm),
                            ),
                            child: Text(
                              '#$rank',
                              style: TextStyle(
                                color: rank == 1
                                    ? AppTheme.surface
                                    : AppTheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.acceptedBg,
                              borderRadius: BorderRadius.circular(_radiusSm),
                              border: Border.all(
                                color: AppTheme.acceptedBorder,
                              ),
                            ),
                            child: Text(
                              '${item.skorPersen.toStringAsFixed(1)}% Skor',
                              style: const TextStyle(
                                color: AppTheme.accepted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.infoBg,
                              borderRadius: BorderRadius.circular(_radiusSm),
                            ),
                            child: Text(
                              'Kuota ${item.sisaKuota}/${item.kuotaBimbingan}',
                              style: const TextStyle(
                                color: AppTheme.info,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.bidangKeahlian,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(_radiusMd),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Text(
                item.alasan,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ScoreBarItem(
                    label: 'Topik',
                    value: comp.kemiripanTopik,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ScoreBarItem(
                    label: 'Kuota',
                    value: comp.ketersediaanKuotaTernormalisasi,
                    color: AppTheme.accepted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ScoreBarItem(
                    label: 'Beban Rendah',
                    value: comp.skorBebanRendah,
                    color: AppTheme.info,
                  ),
                ),
              ],
            ),
            if (item.kataKunciCocok.isNotEmpty ||
                item.riwayatTopikCocok > 0) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...item.kataKunciCocok.take(4).map(
                        (kw) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGhost,
                            borderRadius: BorderRadius.circular(_radiusSm),
                          ),
                          child: Text(
                            kw,
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  if (item.riwayatTopikCocok > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.acceptedBg,
                        borderRadius: BorderRadius.circular(_radiusSm),
                      ),
                      child: Text(
                        '${item.riwayatTopikCocok} riwayat TA relevan',
                        style: const TextStyle(
                          color: AppTheme.accepted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radiusMd),
      child: SizedBox(
        width: 56,
        height: 56,
        child: !AvatarHelper.hasAvatar(item.avatar)
            ? Image.asset(
                'assets/images/default_avatar.jpeg',
                fit: BoxFit.cover,
              )
            : Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/default_avatar.jpeg',
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }
}

class _ScoreBarItem extends StatelessWidget {
  const _ScoreBarItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(clamped * 100).round()}%',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 5,
            backgroundColor: AppTheme.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
