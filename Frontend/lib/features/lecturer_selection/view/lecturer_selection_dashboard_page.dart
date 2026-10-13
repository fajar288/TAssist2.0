import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/app.dart';
import '../../auth/data/auth_service.dart';
import '../../notifikasi/widgets/notifikasi_bell_button.dart';
import '../../../mahasiswa/data/mahasiswa_service.dart';
import 'lecturers_page.dart';

class LecturerSelectionDashboardPage extends StatefulWidget {
  const LecturerSelectionDashboardPage({super.key});

  @override
  State<LecturerSelectionDashboardPage> createState() =>
      _LecturerSelectionDashboardPageState();
}

class _LecturerSelectionDashboardPageState
    extends State<LecturerSelectionDashboardPage> {
  final MahasiswaService _mahasiswaService = MahasiswaService();
  final AuthService _authService = AuthService();

  String _studentName = 'Student';

  final List<LecturerCategory> categories = const [
    LecturerCategory(
      title: 'AI & Machine Learning Lecturers',
      keyword: 'Kecerdasan Buatan',
      imageUrl:
          'https://images.unsplash.com/photo-1515879218367-8466d910aaa4?auto=format&fit=crop&w=1200&q=80',
    ),
    LecturerCategory(
      title: 'Software Engineering Lecturers',
      keyword: 'Rekayasa Perangkat Lunak',
      imageUrl:
          'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=1200&q=80',
    ),
    LecturerCategory(
      title: 'Network & Cybersecurity Lecturers',
      keyword: 'Jaringan Komputer',
      imageUrl:
          'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?auto=format&fit=crop&w=1200&q=80',
    ),
    LecturerCategory(
      title: 'Information Systems & Database Lecturers',
      keyword: 'Sistem Informasi',
      imageUrl:
          'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?auto=format&fit=crop&w=1200&q=80',
    ),
    LecturerCategory(
      title: 'Computer Vision Lecturers',
      keyword: 'Computer Vision',
      imageUrl:
          'https://images.unsplash.com/photo-1526379095098-d400fd0bf935?auto=format&fit=crop&w=1200&q=80',
    ),
  ];

  List<Map<String, dynamic>> _permohonanList = [];
  bool _isLoadingPermohonan = true;
  String? _permohonanError;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([
      _loadProfile(),
      _loadPermohonan(),
    ]);
  }

  Future<void> _loadProfile() async {
    try {
      final profileResponse = await _authService.getProfile();

      final profileData = profileResponse?['data'];

      String name = 'Student';

      if (profileData is Map<String, dynamic>) {
        final user = profileData['user'];

        if (user is Map<String, dynamic>) {
          name = user['nama']?.toString() ??
              user['name']?.toString() ??
              'Student';
        }
      }

      if (!mounted) return;

      setState(() {
        _studentName = name;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _studentName = 'Student';
      });
    }
  }

  Future<void> _loadPermohonan() async {
    setState(() {
      _isLoadingPermohonan = true;
      _permohonanError = null;
    });

    try {
      final rows = await _mahasiswaService.getPermohonan(perPage: 20);

      if (!mounted) return;

      setState(() {
        _permohonanList = rows;
        _isLoadingPermohonan = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _permohonanError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingPermohonan = false;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      TAssistApp.loginRoute,
      (route) => false,
    );
  }

  Future<void> _openLecturersPage({String? bidangKeahlian}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LecturersPage(
          initialBidangKeahlian: bidangKeahlian,
        ),
      ),
    );

    if (!mounted) return;

    _loadPermohonan();
  }

  void _showPermohonanDetail(Map<String, dynamic> request) {
    final dosen = request['dosen'] is Map
        ? Map<String, dynamic>.from(request['dosen'])
        : <String, dynamic>{};

    final namaDosen = dosen['nama']?.toString() ?? '-';
    final bidangKeahlian = dosen['bidang_keahlian']?.toString() ?? '-';
    final topikTa = request['topik_ta']?.toString() ?? '-';
    final tanggal = request['tanggal_pengajuan']?.toString() ?? '-';
    final status = request['status']?.toString() ?? '-';
    final catatan = request['catatan_respons']?.toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Counseling Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogLine('Lecturer', namaDosen),
              const SizedBox(height: 8),
              _dialogLine('Expertise', bidangKeahlian),
              const SizedBox(height: 8),
              _dialogLine('Topic', topikTa),
              const SizedBox(height: 8),
              _dialogLine('Submitted', tanggal),
              const SizedBox(height: 8),
              _dialogLine('Status', _formatStatus(status)),
              if (catatan != null && catatan.isNotEmpty) ...[
                const SizedBox(height: 8),
                _dialogLine('Response Note', catatan),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogLine(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Color(0xFF111111),
          fontSize: 14,
          height: 1.35,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
        return 'Waiting';
      case 'diterima':
        return 'Accepted';
      case 'ditolak':
        return 'Rejected';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
        return const Color(0xFFFFA000);
      case 'diterima':
        return const Color(0xFF2E7D32);
      case 'ditolak':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      extendBody: true,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                child: Column(
                  children: [
                    _buildTopCard(),
                    const SizedBox(height: 18),
                    _buildBottomRequestList(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF082E6B), Color(0xFF0D4AA3), Color(0xFF1A65C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('👋  ', style: TextStyle(fontSize: 18)),
                        Text(
                          'Hello There!,',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_studentName!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome to TAssist',
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
                  GestureDetector(
                    onTap: _logout,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.18),
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
                      child: Center(
                        child: Text(
                          _initials(_studentName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Let's choose your lecturer first!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF111111),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          for (int i = 0; i < categories.length; i++) ...[
            _LecturerBannerCard(
              title: categories[i].title,
              imageUrl: categories[i].imageUrl,
              onTap: () => _openLecturersPage(
                bidangKeahlian: categories[i].keyword,
              ),
            ),
            const SizedBox(height: 14),
          ],
          _buildViewAllButton(),
        ],
      ),
    );
  }

  Widget _buildViewAllButton() {
    return InkWell(
      onTap: () => _openLecturersPage(),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'view all lecturers',
              style: TextStyle(
                color: Color(0xFF111111),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 10),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF111111),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomRequestList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isLoadingPermohonan
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : _permohonanError != null
              ? _buildRequestError()
              : _permohonanList.isEmpty
                  ? const SizedBox(
                      height: 100,
                      child: Center(
                        child: Text(
                          "there's nothing here...",
                          style: TextStyle(
                            color: Color(0xFF7D848C),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: _permohonanList
                          .map(
                            (request) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildRequestItem(request),
                            ),
                          )
                          .toList(),
                    ),
    );
  }

  Widget _buildRequestError() {
    return SizedBox(
      height: 130,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 8),
          Text(
            _permohonanError ?? 'Failed to load request.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadPermohonan,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(Map<String, dynamic> request) {
    final dosen = request['dosen'] is Map
        ? Map<String, dynamic>.from(request['dosen'])
        : <String, dynamic>{};

    final namaDosen = dosen['nama']?.toString() ?? '-';
    final bidangKeahlian = dosen['bidang_keahlian']?.toString() ?? '-';
    final status = request['status']?.toString() ?? '-';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showPermohonanDetail(request),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0D4AA3),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D4AA3).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  _initials(namaDosen),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatStatus(status),
                      style: TextStyle(
                        color: _statusColor(status),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'with Mr. $namaDosen',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      bidangKeahlian,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white54,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _LecturerBannerCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final VoidCallback onTap;

  const _LecturerBannerCard({
    required this.title,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.black.withOpacity(0.3),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class LecturerCategory {
  final String title;
  final String keyword;
  final String imageUrl;

  const LecturerCategory({
    required this.title,
    required this.keyword,
    required this.imageUrl,
  });
}