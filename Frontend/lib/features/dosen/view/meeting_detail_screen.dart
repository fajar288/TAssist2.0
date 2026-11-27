// lib/features/dosen/view/meeting_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tassist/features/dosen/data/dosen_service.dart';

import 'package:tassist/model/models.dart';
import 'package:tassist/theme/app_theme.dart';
import 'package:tassist/widgets/app_snackbars.dart';
import 'package:tassist/widgets/custom_request_card.dart';

class MeetingDetailScreen extends StatefulWidget {
  final MeetingRequest request;

  const MeetingDetailScreen({super.key, required this.request});

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  final DosenService _dosenService = DosenService();

  RequestStatus? _localStatus;
  bool _isProcessing = false;

  RequestStatus get currentStatus => _localStatus ?? widget.request.status;

  bool get isActionable {
    return currentStatus == RequestStatus.pending &&
        widget.request.isProposedByStudent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOf(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.primaryDark,
            leading: IconButton(
              tooltip: 'Kembali',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              'Pengajuan Jadwal',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            flexibleSpace: const ColoredBox(color: AppTheme.primaryDark),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 16),
                  _buildScheduleCard(),
                  const SizedBox(height: 16),

                  if (isActionable) ...[
                    _buildModeSelector(),
                    const SizedBox(height: 16),
                  ],

                  _buildDescriptionCard(),
                  const SizedBox(height: 16),
                  _buildProposerCard(),
                  const SizedBox(height: 28),
                  if (isActionable)
                    _buildActionButtons(context)
                  else
                    _buildStatusBanner(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: AppTheme.cardDecorationOf(context),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: Hero(
              tag: 'meeting-avatar-${widget.request.id}',
              child: Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary,
                ),
                child: Center(
                  child: Text(
                    widget.request.initials,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.request.studentName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: AppTheme.textPrimaryOf(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                _pillTag(widget.request.major),
                const SizedBox(height: 5),
                Text(
                  'NIM: ${widget.request.nim}',
                  style: GoogleFonts.poppins(
                    color: AppTheme.textMutedOf(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(status: currentStatus),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      decoration: AppTheme.cardDecorationOf(context),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: AppTheme.primaryDark,
            child: Row(
              children: [
                const Icon(
                  Icons.event_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Jadwal yang Diajukan',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ScheduleBlock(
                        icon: Icons.calendar_today_outlined,
                        topLabel: 'Tanggal',
                        mainValue: widget.request.meetingDate.day.toString(),
                        subValue:
                            '${_monthName(widget.request.meetingDate.month)} ${widget.request.meetingDate.year}',
                        bottomLabel: widget.request.dayName,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 70,
                      color: AppTheme.cardBorderOf(context),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    Expanded(
                      child: _ScheduleBlock(
                        icon: Icons.schedule_outlined,
                        topLabel: 'Waktu',
                        mainValue: widget.request.meetingTime,
                        subValue: '',
                        bottomLabel: 'WIB (Waktu Lokal)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _InfoTile(
                  icon: Icons.place_outlined,
                  label: 'Mode',
                  value: _formatMode(widget.request.mode),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      decoration: AppTheme.cardDecorationOf(context),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mode Bimbingan',
            style: GoogleFonts.poppins(
              color: AppTheme.textPrimaryOf(context),
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ModeOption(
                  label: 'Daring',
                  icon: Icons.videocam_outlined,
                  selected: _selectedMode == 'online',
                  onTap: () => setState(() => _selectedMode = 'online'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModeOption(
                  label: 'Tatap Muka',
                  icon: Icons.meeting_room_outlined,
                  selected: _selectedMode == 'offline',
                  onTap: () => setState(() => _selectedMode = 'offline'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      decoration: AppTheme.cardDecorationOf(context),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGhostOf(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: AppTheme.primaryOf(context),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Catatan / Deskripsi',
                style: GoogleFonts.poppins(
                  color: AppTheme.textPrimaryOf(context),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantOf(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Text(
              widget.request.description,
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondaryOf(context),
                fontSize: 13,
                height: 1.75,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProposerCard() {
    return Container(
      decoration: AppTheme.cardDecorationOf(context),
      padding: const EdgeInsets.all(18),
      child: _InfoTile(
        icon: Icons.person_pin_circle_outlined,
        label: 'Diajukan Oleh',
        value: '${widget.request.pengajuName} (${widget.request.pengajuRole})',
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _handleAccept(context),
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: Text(_isProcessing ? 'Memproses...' : 'Terima Jadwal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accepted,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              elevation: 0,
              textStyle: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isProcessing ? null : () => _handleDecline(context),
            icon: const Icon(Icons.close_outlined, size: 20),
            label: Text(_isProcessing ? 'Memproses...' : 'Tolak Jadwal'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.declined,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppTheme.declined, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              textStyle: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    final isAccepted = currentStatus == RequestStatus.accepted;
    final isDeclined = currentStatus == RequestStatus.declined;
    final isWaitingStudent = currentStatus == RequestStatus.pending &&
        widget.request.isProposedByDosen;

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String text;

    if (isAccepted) {
      bgColor = AppTheme.acceptedBgOf(context);
      borderColor = AppTheme.acceptedBorderOf(context);
      textColor = AppTheme.accepted;
      icon = Icons.event_available_outlined;
      text = 'Jadwal telah dikonfirmasi.';
    } else if (isDeclined) {
      bgColor = AppTheme.declinedBgOf(context);
      borderColor = AppTheme.declinedBorderOf(context);
      textColor = AppTheme.declined;
      icon = Icons.event_busy_outlined;
      text = 'Jadwal telah ditolak.';
    } else if (isWaitingStudent) {
      bgColor = AppTheme.warningBgOf(context);
      borderColor = AppTheme.warningBorderOf(context);
      textColor = AppTheme.warning;
      icon = Icons.hourglass_top_outlined;
      text = 'Menunggu konfirmasi mahasiswa.';
    } else {
      bgColor = AppTheme.warningBgOf(context);
      borderColor = AppTheme.warningBorderOf(context);
      textColor = AppTheme.warning;
      icon = Icons.info_outline;
      text = 'Jadwal ini masih menunggu konfirmasi.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 22),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primaryGhostOf(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: AppTheme.primaryOf(context),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  String _formatMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'online':
        return 'Online';
      case 'offline':
        return 'Offline';
      default:
        return mode;
    }
  }

  String _selectedMode = 'offline';

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.request.mode.toLowerCase() == 'online'
        ? 'online'
        : 'offline';
  }

  Future<void> _handleAccept(BuildContext context) async {
    final id = int.tryParse(widget.request.id);

    if (id == null) {
      _showError('ID jadwal tidak valid.');
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'Accept Meeting?',
      message: 'Are you sure you want to confirm this meeting schedule?',
      confirmText: 'Accept',
      confirmColor: AppTheme.accepted,
    );

    if (!confirmed || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      await _dosenService.konfirmasiJadwal(
        id,
        statusKonfirmasi: 'dikonfirmasi',
        mode: _selectedMode,
      );

      if (!mounted) return;

      setState(() {
        _localStatus = RequestStatus.accepted;
        _isProcessing = false;
      });

      AppSnackBars.success(context, 'Jadwal berhasil dikonfirmasi.');

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _handleDecline(BuildContext context) async {
    final id = int.tryParse(widget.request.id);

    if (id == null) {
      _showError('ID jadwal tidak valid.');
      return;
    }

    final note = await _showDeclineNoteDialog();
    if (note == null || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      await _dosenService.konfirmasiJadwal(
        id,
        statusKonfirmasi: 'ditolak',
        catatan: note,
      );

      if (!mounted) return;

      setState(() {
        _localStatus = RequestStatus.declined;
        _isProcessing = false;
      });

      AppSnackBars.success(context, 'Jadwal berhasil ditolak.');

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<String?> _showDeclineNoteDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Decline Meeting'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Note',
              hintText: 'Write a note for declining this meeting...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.declined,
                foregroundColor: Colors.white,
              ),
              child: const Text('Decline'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  void _showError(String message) {
    AppSnackBars.error(context, message);
  }
}

class _ModeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryOf(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGhostOf(context) : AppTheme.surfaceOf(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: selected ? primary : AppTheme.cardBorderOf(context),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? primary : AppTheme.textMutedOf(context),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: selected ? primary : AppTheme.textSecondaryOf(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleBlock extends StatelessWidget {
  final IconData icon;
  final String topLabel;
  final String mainValue;
  final String subValue;
  final String bottomLabel;

  const _ScheduleBlock({
    required this.icon,
    required this.topLabel,
    required this.mainValue,
    required this.subValue,
    required this.bottomLabel,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: primary),
            const SizedBox(width: 5),
            Text(
              topLabel,
              style: GoogleFonts.poppins(
                color: AppTheme.textMutedOf(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          mainValue,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: AppTheme.textPrimaryOf(context),
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
        if (subValue.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subValue,
            style: GoogleFonts.poppins(
              color: primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          bottomLabel,
          style: GoogleFonts.poppins(
            color: AppTheme.textSecondaryOf(context),
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGhostOf(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(icon, size: 16, color: AppTheme.primaryOf(context)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: AppTheme.textMutedOf(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: AppTheme.textPrimaryOf(context),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
