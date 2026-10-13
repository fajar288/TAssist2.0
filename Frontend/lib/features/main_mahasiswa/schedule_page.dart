import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../mahasiswa/data/mahasiswa_service.dart';

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

      if (!mounted) return;

      setState(() {
        _activeBimbingan = activeBimbingan;
        _scheduleList = schedules;
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
    });
  }

  Future<void> _submitSchedule() async {
    final bimbinganId = _activeBimbinganId;

    if (bimbinganId == null) {
      _showSnackBar(
        'Bimbingan aktif tidak ditemukan. Silakan refresh halaman.',
        isError: true,
      );
      return;
    }

    if (_selectedDate == null) {
      _showSnackBar('Tanggal wajib dipilih.', isError: true);
      return;
    }

    final startMinutes = (_startHour * 60) + _startMinute;
    final endMinutes = (_endHour * 60) + _endMinute;

    if (endMinutes <= startMinutes) {
      _showSnackBar(
        'Waktu selesai harus setelah waktu mulai.',
        isError: true,
      );
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

      _showSnackBar('Jadwal bimbingan berhasil diajukan.');

      setState(() {
        _currentState = ScheduleState.initial;
        _selectedDate = null;
        _selectedMode = 'online';
        _descriptionController.clear();
      });

      await _loadScheduleData();
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    } catch (_) {
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
        return Colors.orange;
      case 'dikonfirmasi':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      default:
        return Colors.grey;
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
        backgroundColor: Color(0xFFEEF2F6),
        body: Center(
          child: CircularProgressIndicator(),
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
        backgroundColor: const Color(0xFFEEF2F6),
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
      backgroundColor: const Color(0xFFEEF2F6),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 46,
              ),
              const SizedBox(height: 14),
              const Text(
                'Failed to load schedule page',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF2D3238),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? '-',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _loadScheduleData,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
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
            color: Color(0xFF333333),
          ),
        ),
        Text(
          'with mr. $advisorName',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
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
                color: const Color(0xFF0D47A1),
                borderRadius: BorderRadius.circular(12),
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
              color: Color(0xFF0D47A1),
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
                backgroundColor: const Color(0xFF0D47A1),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                  color: Color(0xFF0D47A1),
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
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate == null
                  ? 'DD/MM/YYYY'
                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              style: TextStyle(
                color: _selectedDate == null ? Colors.grey : Colors.black,
              ),
            ),
            const Icon(
              Icons.calendar_today,
              color: Color(0xFF0D47A1),
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0D47A1),
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
          Text(label, style: const TextStyle(color: Colors.grey)),
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF0D47A1),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0D47A1).withOpacity(0.1)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0D47A1)
                : Colors.grey.shade300,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade700,
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
        fillColor: const Color(0xFFF8FAFC),
        counterStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF0D47A1),
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
        child: const Center(
          child: Text(
            'No meeting schedule has been submitted yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
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
              backgroundColor: const Color(0xFF0D47A1),
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
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_formatDisplayDate(tanggal)} at ${_formatDisplayTime(mulai)} - ${_formatDisplayTime(selesai)} • $mode',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    backgroundColor: const Color(0xFF0D47A1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}