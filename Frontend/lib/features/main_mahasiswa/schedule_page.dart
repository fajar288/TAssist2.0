import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:tassist/features/main_mahasiswa/data/mahasiswa_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_empty_state_widget.dart';
import '../../widgets/app_error_widget.dart';
import '../../widgets/app_skeleton_loader.dart';
import '../../widgets/app_snackbars.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

enum ScheduleState { initial, expanded }

class _SchedulePageState extends State<SchedulePage> {
  final MahasiswaService _mahasiswaService = MahasiswaService();
  final TextEditingController _descriptionController = TextEditingController();

  late final FixedExtentScrollController _startHourController;
  late final FixedExtentScrollController _startMinuteController;
  late final FixedExtentScrollController _endHourController;
  late final FixedExtentScrollController _endMinuteController;

  ScheduleState _currentState = ScheduleState.initial;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  Map<String, dynamic>? _activeBimbingan;
  List<Map<String, dynamic>> _scheduleList = [];
  List<Map<String, dynamic>> _weeklyAvailability = [];
  List<Map<String, dynamic>> _exceptionAvailability = [];
  List<Map<String, dynamic>>? _effectiveSlotsForDate;

  DateTime? _selectedDate;

  int _startHour = 9;
  int _startMinute = 0;
  int _endHour = 10;
  int _endMinute = 0;

  String _selectedMode = 'online';

  @override
  void initState() {
    super.initState();

    _startHourController = FixedExtentScrollController(initialItem: _startHour);
    _startMinuteController =
        FixedExtentScrollController(initialItem: _startMinute);
    _endHourController = FixedExtentScrollController(initialItem: _endHour);
    _endMinuteController =
        FixedExtentScrollController(initialItem: _endMinute);

    _loadScheduleData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();

    _startHourController.dispose();
    _startMinuteController.dispose();
    _endHourController.dispose();
    _endMinuteController.dispose();

    super.dispose();
  }

  Future<void> _loadScheduleData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final activeBimbingan = await _mahasiswaService.getActiveBimbingan();
      final schedules = await _mahasiswaService.getJadwal(perPage: 30);

      List<Map<String, dynamic>> weeklyAvail = [];
      List<Map<String, dynamic>> exceptionAvail = [];
      final dosenRaw = activeBimbingan?['dosen'];
      final dosenId = dosenRaw is Map
          ? int.tryParse(dosenRaw['dosen_id']?.toString() ?? '')
          : null;
      if (dosenId != null) {
        try {
          final avail = await _mahasiswaService.getDosenKetersediaan(dosenId);
          final rawW = avail['mingguan'];
          final rawK = avail['khusus'];
          if (rawW is List) {
            weeklyAvail = rawW.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          }
          if (rawK is List) {
            exceptionAvail = rawK.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          }
        } catch (e) {
          debugPrint('SchedulePage: getDosenKetersediaan failed: $e');
        }
      }

      if (!mounted) return;

      setState(() {
        _activeBimbingan = activeBimbingan;
        _scheduleList = schedules;
        _weeklyAvailability = weeklyAvail;
        _exceptionAvailability = exceptionAvail;
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

  Map<String, dynamic>? get _advisor {
    final bimbingan = _activeBimbingan;
    if (bimbingan == null) return null;

    final dosen = bimbingan['dosen'];

    if (dosen is Map<String, dynamic>) return dosen;
    if (dosen is Map) return Map<String, dynamic>.from(dosen);

    return null;
  }

  int? get _activeBimbinganId {
    return int.tryParse(_activeBimbingan?['bimbingan_id']?.toString() ?? '');
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
      _effectiveSlotsForDate = null;
    });

    final dosenId = int.tryParse(_advisor?['dosen_id']?.toString() ?? '');
    if (dosenId != null) {
      try {
        final avail = await _mahasiswaService.getDosenKetersediaan(
          dosenId,
          tanggal: _formatDateForApi(picked),
        );
        final rawEffective = avail['slot_efektif'];
        if (mounted && rawEffective is List) {
          setState(() {
            _effectiveSlotsForDate = rawEffective
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          });
        }
      } catch (e) {
        debugPrint('SchedulePage: getDosenKetersediaan(tanggal) failed: $e');
      }
    }
  }

  bool get _hasPublishedAvailability =>
      _weeklyAvailability.isNotEmpty || _exceptionAvailability.isNotEmpty;

  bool get _isOutsidePublishedAvailability {
    if (!_hasPublishedAvailability || _selectedDate == null) return false;
    final slots = _effectiveSlotsForDate;
    if (slots == null) return false;
    if (slots.isEmpty) return true;

    final startStr = _formatTimeForApi(_startHour, _startMinute);
    final endStr = _formatTimeForApi(_endHour, _endMinute);
    if (startStr.compareTo(endStr) >= 0) return false;

    for (final s in slots) {
      final sStart = s['waktu_mulai']?.toString() ?? '';
      final sEnd = s['waktu_selesai']?.toString() ?? '';
      if (startStr.compareTo(sStart) >= 0 && endStr.compareTo(sEnd) <= 0) {
        return false;
      }
    }
    return true;
  }

  Future<void> _submitSchedule() async {
    final bimbinganId = _activeBimbinganId;

    if (bimbinganId == null) {
      AppSnackBars.error(
        context,
        'Bimbingan aktif tidak ditemukan. Silakan refresh halaman.',
      );
      return;
    }

    if (_selectedDate == null) {
      AppSnackBars.error(context, 'Tanggal wajib dipilih.');
      return;
    }

    final startMinutes = (_startHour * 60) + _startMinute;
    final endMinutes = (_endHour * 60) + _endMinute;

    if (endMinutes <= startMinutes) {
      AppSnackBars.error(context, 'Waktu selesai harus setelah waktu mulai.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _mahasiswaService.ajukanJadwal(
        bimbinganId: bimbinganId,
        tanggal: _formatDateForApi(_selectedDate!),
        waktuMulai: _formatTimeForApi(_startHour, _startMinute),
        waktuSelesai: _formatTimeForApi(_endHour, _endMinute),
        mode: _selectedMode,
        catatan: _descriptionController.text,
      );

      if (!mounted) return;

      AppSnackBars.success(context, 'Jadwal bimbingan berhasil diajukan.');

      setState(() {
        _currentState = ScheduleState.initial;
        _selectedDate = null;
        _selectedMode = 'online';
        _descriptionController.clear();
      });

      await _loadScheduleData();
    } catch (e) {
      if (!mounted) return;

      AppSnackBars.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  String _formatDateForApi(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _formatTimeForApi(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    try {
      return DateTime.parse(value);
    } catch (e) {
      debugPrint('SchedulePage: _parseDate failed for "$value": $e');
      return null;
    }
  }

  String _formatDisplayDate(String? value) {
    final date = _parseDate(value);

    if (date == null) return '-';

    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDisplayTime(String? value) {
    if (value == null || value.trim().isEmpty) return '-';

    final parts = value.split(':');

    if (parts.length < 2) return value;

    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  String _formatStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'menunggu':
        return 'Pending';
      case 'dikonfirmasi':
        return 'Confirmed';
      case 'ditolak':
        return 'Rejected';
      default:
        return status ?? '-';
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'menunggu':
        return AppTheme.pending;
      case 'dikonfirmasi':
        return AppTheme.accepted;
      case 'ditolak':
        return AppTheme.declined;
      default:
        return AppTheme.textMuted;
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(top: 16),
            child: AppSkeletonLoader.list(count: 4),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorPage();
    }

    return GestureDetector(
      onTap: () {
        if (_currentState == ScheduleState.expanded) {
          setState(() => _currentState = ScheduleState.initial);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: RefreshIndicator(
          onRefresh: _loadScheduleData,
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _buildMainContent(),
                  ),
                  const SizedBox(height: 24),
                  _buildScheduleList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPage() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AppErrorWidget(
        title: 'Failed to load schedule page',
        message: _errorMessage ?? '-',
        retryLabel: 'Try Again',
        onRetry: _loadScheduleData,
      ),
    );
  }

  Widget _buildAvailabilityHintCard() {
    final slotsToShow = _selectedDate != null && _effectiveSlotsForDate != null
        ? _effectiveSlotsForDate!
        : _weeklyAvailability.where((s) => s['is_available'] != false).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGhost,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.infoBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedDate != null
                ? 'Ketersediaan Dosen pada ${_formatDateForApi(_selectedDate!)}:'
                : 'Slot Ketersediaan Rutin Dosen:',
            style: const TextStyle(
              color: AppTheme.primaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          if (slotsToShow.isEmpty)
            const Text(
              'Tidak ada slot tersedia pada tanggal ini.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: slotsToShow.map((s) {
                final day = s['hari']?.toString() ?? s['tanggal']?.toString() ?? '';
                final range = '${s['waktu_mulai']} - ${s['waktu_selesai']}';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppTheme.infoBorder),
                  ),
                  child: Text(
                    _selectedDate != null ? range : '$day $range',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final advisorName = _advisor?['nama']?.toString() ?? 'lecturer';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Let's Schedule Your Meet!",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          'with mr. $advisorName',
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    switch (_currentState) {
      case ScheduleState.initial:
        return _buildInitialButton();
      case ScheduleState.expanded:
        return _buildScheduleForm();
    }
  }

  Widget _buildInitialButton() {
    return GestureDetector(
      onTap: () => setState(() => _currentState = ScheduleState.expanded),
      child: Container(
        width: double.infinity,
        decoration: _cardDecoration(),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Set Meeting schedule',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppTheme.primary,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleForm() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set Date',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 10),
            _buildDateField(),
            const SizedBox(height: 20),
            const Text(
              'Set Time',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 10),
            _buildTimePicker(),
            if (_hasPublishedAvailability) ...[
              const SizedBox(height: 14),
              _buildAvailabilityHintCard(),
            ],
            if (_isOutsidePublishedAvailability) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.warningBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppTheme.warning, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Di luar ketersediaan yang dipublikasikan dosen. Anda tetap dapat mengajukan jadwal ini.',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Selected Lecturer',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 10),
            _buildAdvisorField(),
            const SizedBox(height: 20),
            const Text(
              'Meeting Mode',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 10),
            _buildModeSelector(),
            const SizedBox(height: 20),
            const Text(
              'Add Description',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 10),
            _buildDescriptionField(),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : const Text(
                      'Set Meeting Schedule',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
            const SizedBox(height: 15),
            Center(
              child: GestureDetector(
                onTap: () =>
                    setState(() => _currentState = ScheduleState.initial),
                child: const Icon(
                  Icons.keyboard_arrow_up,
                  color: AppTheme.primary,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate == null
                  ? 'DD/MM/YYYY'
                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              style: TextStyle(
                color: _selectedDate == null ? AppTheme.textMuted : AppTheme.textPrimary,
              ),
            ),
            const Icon(
              Icons.calendar_today,
              color: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return Column(
      children: [
        _buildTimePickerBlock(
          title: 'Start Time',
          hourController: _startHourController,
          minuteController: _startMinuteController,
          onHourChanged: (value) {
            setState(() => _startHour = value);
          },
          onMinuteChanged: (value) {
            setState(() => _startMinute = value);
          },
        ),
        const SizedBox(height: 18),
        _buildTimePickerBlock(
          title: 'End Time',
          hourController: _endHourController,
          minuteController: _endMinuteController,
          onHourChanged: (value) {
            setState(() => _endHour = value);
          },
          onMinuteChanged: (value) {
            setState(() => _endMinute = value);
          },
        ),
      ],
    );
  }

  Widget _buildTimePickerBlock({
    required String title,
    required FixedExtentScrollController hourController,
    required FixedExtentScrollController minuteController,
    required ValueChanged<int> onHourChanged,
    required ValueChanged<int> onMinuteChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _timeColumn(
                  label: 'H',
                  count: 24,
                  controller: hourController,
                  onChanged: onHourChanged,
                ),
                const Text(
                  ':',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                _timeColumn(
                  label: 'M',
                  count: 60,
                  controller: minuteController,
                  onChanged: onMinuteChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeColumn({
    required String label,
    required int count,
    required FixedExtentScrollController controller,
    required ValueChanged<int> onChanged,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted)),
          Expanded(
            child: CupertinoPicker(
              scrollController: controller,
              itemExtent: 40,
              onSelectedItemChanged: onChanged,
              children: List.generate(
                count,
                (index) => Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisorField() {
    final advisorName = _advisor?['nama']?.toString() ?? '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.primary,
            child: Text(
              _initials(advisorName),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              advisorName,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildModeOption(
            label: 'Online',
            value: 'online',
            icon: Icons.videocam_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModeOption(
            label: 'Offline',
            value: 'offline',
            icon: Icons.meeting_room_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildModeOption({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedMode == value;

    return InkWell(
      onTap: () => setState(() => _selectedMode = value),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : AppTheme.cardBorder,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected ? AppTheme.primary : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: 3,
      maxLength: 1000,
      decoration: InputDecoration(
        hintText: '....',
        filled: true,
        fillColor: AppTheme.surfaceVariant,
        counterStyle: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(
            color: AppTheme.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    if (_scheduleList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: const AppEmptyStateWidget(
          compact: true,
          icon: Icons.event_busy_rounded,
          title: 'No meeting schedule has been submitted yet.',
        ),
      );
    }

    return Column(
      children: _scheduleList.map(_buildScheduleItem).toList(),
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> schedule) {
    final dosen = schedule['dosen'] is Map
        ? Map<String, dynamic>.from(schedule['dosen'])
        : <String, dynamic>{};

    final dosenName = dosen['nama']?.toString() ?? '-';
    final tanggal = schedule['tanggal']?.toString();
    final mulai = schedule['waktu_mulai']?.toString();
    final selesai = schedule['waktu_selesai']?.toString();
    final status = schedule['status_konfirmasi']?.toString();
    final mode = schedule['mode']?.toString() ?? '-';

    return GestureDetector(
      onTap: () => _showDetailOptions(schedule),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(15),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primary,
              child: Text(
                _initials(dosenName),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatStatus(status),
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Meet with mr. $dosenName',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_formatDisplayDate(tanggal)} at ${_formatDisplayTime(mulai)} - ${_formatDisplayTime(selesai)} • $mode',
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
      ),
    );
  }

  void _showDetailOptions(Map<String, dynamic> schedule) {
    final dosen = schedule['dosen'] is Map
        ? Map<String, dynamic>.from(schedule['dosen'])
        : <String, dynamic>{};

    final dosenName = dosen['nama']?.toString() ?? '-';
    final tanggal = schedule['tanggal']?.toString();
    final mulai = schedule['waktu_mulai']?.toString();
    final selesai = schedule['waktu_selesai']?.toString();
    final mode = schedule['mode']?.toString() ?? '-';
    final status = schedule['status_konfirmasi']?.toString();
    final catatan = schedule['catatan']?.toString();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Opsi Jadwal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Lihat Info Detail'),
                subtitle: Text(
                  '${_formatDisplayDate(tanggal)} at ${_formatDisplayTime(mulai)} - ${_formatDisplayTime(selesai)}',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text('Mr. $dosenName'),
                subtitle: Text('Mode: $mode • Status: ${_formatStatus(status)}'),
              ),
              if (catatan != null && catatan.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.notes_rounded),
                  title: const Text('Catatan'),
                  subtitle: Text(catatan),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  BoxDecoration _cardDecoration() {
    return AppTheme.cardDecoration(radius: AppTheme.radiusLg);
  }
}