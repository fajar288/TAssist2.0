import 'package:flutter/material.dart';
import 'package:produk/features/dosen/data/dosen_service.dart';
import 'package:produk/model/models.dart';

class DosenStudentProgressPage extends StatefulWidget {
  final StudentModel student;

  const DosenStudentProgressPage({
    super.key,
    required this.student,
  });

  @override
  State<DosenStudentProgressPage> createState() =>
      _DosenStudentProgressPageState();
}

class _DosenStudentProgressPageState extends State<DosenStudentProgressPage> {
  final DosenService _dosenService = DosenService();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _progressList = [];

  static const Color _navBlue = Color(0xFF0D4AA3);
  static const Color _navBlueDark = Color(0xFF082E6B);
  static const Color _navBlueLight = Color(0xFF1A65C8);

  StudentModel get student => widget.student;

  Map<String, dynamic>? get _latestProgress {
    if (_progressList.isEmpty) return null;

    final sorted = [..._progressList];

    sorted.sort((a, b) {
      final aDate = _parseDateTime(a['updated_at']?.toString());
      final bDate = _parseDateTime(b['updated_at']?.toString());

      if (aDate != null && bDate != null) {
        return bDate.compareTo(aDate);
      }

      final aId = int.tryParse(a['progress_id']?.toString() ?? '') ?? 0;
      final bId = int.tryParse(b['progress_id']?.toString() ?? '') ?? 0;

      return bId.compareTo(aId);
    });

    return sorted.first;
  }

  List<Map<String, dynamic>> get _latestChecklist {
    final latest = _latestProgress;
    if (latest == null) return [];

    final raw = latest['checklist'];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  double get _latestPercentValue {
    final latest = _latestProgress;
    if (latest == null) return 0;

    final raw = double.tryParse(latest['persentase']?.toString() ?? '') ?? 0;
    return raw.clamp(0, 100).toDouble();
  }

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final bimbinganId = student.bimbinganIdAsInt;

    if (bimbinganId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ID bimbingan tidak valid.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final decoded = await _dosenService.getProgresMahasiswa(bimbinganId);
      final rootData = decoded['data'];

      final data = rootData is Map<String, dynamic>
          ? rootData
          : <String, dynamic>{};

      final progresRaw = data['progres'];

      final progres = progresRaw is List
          ? progresRaw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        _data = data;
        _progressList = progres;
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

  DateTime? _parseDateTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  String _formatDateTime(String? value) {
    final date = _parseDateTime(value);
    if (date == null) return '-';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  bool _isDone(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is int) return raw == 1;

    final text = raw?.toString().toLowerCase();
    return text == 'true' || text == '1';
  }

  int? _progressId(Map<String, dynamic>? progress) {
    return int.tryParse(progress?['progress_id']?.toString() ?? '');
  }

  int? _checklistId(Map<String, dynamic> checklist) {
    return int.tryParse(checklist['checklist_id']?.toString() ?? '');
  }

  String _studentTitle() {
    final mahasiswaRaw = _data?['mahasiswa'];

    if (mahasiswaRaw is Map) {
      final mahasiswa = Map<String, dynamic>.from(mahasiswaRaw);
      final judul = mahasiswa['judul_ta']?.toString();

      if (judul != null && judul.trim().isNotEmpty) {
        return judul;
      }
    }

    return student.judulTa?.isNotEmpty == true ? student.judulTa! : '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: RefreshIndicator(
        onRefresh: _loadProgress,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildErrorState(),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                  child: Column(
                    children: [
                      _buildProgressOverview(),
                      const SizedBox(height: 14),
                      _buildActionButtons(),
                      const SizedBox(height: 18),
                      _buildChecklistSection(),
                      const SizedBox(height: 18),
                      _buildHistorySection(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    final taTitle = _studentTitle();

    return SliverAppBar(
      expandedHeight: taTitle == '-' ? 185 : 220,
      pinned: true,
      backgroundColor: _navBlue,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_navBlueDark, _navBlue, _navBlueLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  left: 20,
                  right: 20,
                  top: 54,
                  child: const Text(
                    'Progress & Checklist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                      height: 1.05,
                    ),
                  ),
                ),

                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${student.nim} • ${student.major}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.76),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),

                      if (taTitle != '-') ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.13),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.article_rounded,
                                color: Colors.white.withOpacity(0.85),
                                size: 15,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  taTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
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
            'Failed to load progress',
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
          ElevatedButton.icon(
            onPressed: _loadProgress,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverview() {
    final latest = _latestProgress;
    final status = latest?['status_progress']?.toString() ?? 'No progress yet';
    final catatan = latest?['catatan']?.toString();
    final updatedAt = latest?['updated_at']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Progress',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_latestPercentValue.round()}%',
                style: const TextStyle(
                  color: _navBlue,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: LinearProgressIndicator(
                    value: _latestPercentValue / 100,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(_navBlue),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoLine(
            icon: Icons.flag_rounded,
            label: 'Status',
            value: status,
          ),
          if (catatan != null && catatan.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoLine(
              icon: Icons.notes_rounded,
              label: 'Catatan',
              value: catatan,
            ),
          ],
          if (updatedAt != null) ...[
            const SizedBox(height: 10),
            _InfoLine(
              icon: Icons.update_rounded,
              label: 'Last Update',
              value: _formatDateTime(updatedAt),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _showUpdateProgressSheet,
            icon: const Icon(Icons.trending_up_rounded),
            label: const Text('Update Progress'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _navBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isSubmitting ? null : () => _showChecklistSheet(),
            icon: const Icon(Icons.playlist_add_check_rounded),
            label: const Text('Add Checklist'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _navBlue,
              side: const BorderSide(color: _navBlue, width: 1.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistSection() {
    final checklist = _latestChecklist;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Latest Checklist',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${checklist.where((item) => _isDone(item['tgl_selesai'])).length}/${checklist.length}',
                style: const TextStyle(
                  color: _navBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_latestProgress == null)
            _emptyMessage(
              icon: Icons.checklist_rounded,
              message: 'No checklist yet. Add a checklist to create an initial 0% progress target.',
            )
          else if (checklist.isEmpty)
            _emptyMessage(
              icon: Icons.checklist_rounded,
              message: 'No checklist item yet.',
            )
          else
            ...checklist.map(_buildChecklistItem),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(Map<String, dynamic> item) {
    final id = _checklistId(item);
    final title = item['nama_item']?.toString() ?? 'Checklist item';
    final note = item['catatan']?.toString();
    final done = _isDone(item['tgl_selesai']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: done,
            activeColor: _navBlue,
            onChanged: id == null || _isSubmitting
                ? null
                : (value) => _toggleChecklist(item, value == true),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF1E293B),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (note != null && note.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    note,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showChecklistSheet(existing: item);
              } else if (value == 'delete') {
                _confirmDeleteChecklist(item);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress History',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (_progressList.isEmpty)
            _emptyMessage(
              icon: Icons.history_rounded,
              message: 'No progress history yet.',
            )
          else
            ..._progressList.map(_buildHistoryItem),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final percent = double.tryParse(item['persentase']?.toString() ?? '') ?? 0;
    final status = item['status_progress']?.toString() ?? '-';
    final note = item['catatan']?.toString();
    final updatedAt = item['updated_at']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _navBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${percent.round()}%',
                style: const TextStyle(
                  color: _navBlue,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                if (note != null && note.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(updatedAt),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateProgressSheet() async {
    final latest = _latestProgress;

    final percentController = TextEditingController(
      text: latest?['persentase']?.toString() ?? '0',
    );
    final statusController = TextEditingController(
      text: latest?['status_progress']?.toString() ?? '',
    );
    final catatanController = TextEditingController(
      text: latest?['catatan']?.toString() ?? '',
    );

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            16,
            18,
            MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              const Text(
                'Update Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: percentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Persentase',
                  suffixText: '%',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: statusController,
                decoration: const InputDecoration(
                  labelText: 'Status Progress',
                  hintText: 'Contoh: Bab 2 selesai',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: catatanController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  hintText: 'Tambahkan catatan untuk mahasiswa...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save Progress'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != true || !mounted) {
      percentController.dispose();
      statusController.dispose();
      catatanController.dispose();
      return;
    }

    final percent = double.tryParse(percentController.text.trim());
    final status = statusController.text.trim();
    final catatan = catatanController.text.trim();

    percentController.dispose();
    statusController.dispose();
    catatanController.dispose();

    if (percent == null || percent < 0 || percent > 100) {
      _showError('Persentase harus berupa angka 0 sampai 100.');
      return;
    }

    if (status.isEmpty) {
      _showError('Status progress wajib diisi.');
      return;
    }

    await _submitProgress(
      percent: percent,
      status: status,
      catatan: catatan,
    );
  }

  Future<void> _submitProgress({
    required double percent,
    required String status,
    required String catatan,
  }) async {
    final bimbinganId = student.bimbinganIdAsInt;

    if (bimbinganId == null) {
      _showError('ID bimbingan tidak valid.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _dosenService.updateProgresTA(
        bimbinganId: bimbinganId,
        persentase: percent,
        statusProgress: status,
        catatan: catatan,
      );

      if (!mounted) return;

      _showSuccess('Progress berhasil diperbarui.');
      await _loadProgress();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showChecklistSheet({
    Map<String, dynamic>? existing,
  }) async {
    final isEdit = existing != null;

    final titleController = TextEditingController(
      text: existing?['nama_item']?.toString() ?? '',
    );
    final catatanController = TextEditingController(
      text: existing?['catatan']?.toString() ?? '',
    );

    bool done = _isDone(existing?['tgl_selesai']);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                16,
                18,
                MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 16),
                  Text(
                    isEdit ? 'Edit Checklist' : 'Add Checklist',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Item',
                      hintText: 'Contoh: Revisi Bab 2',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: catatanController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Catatan',
                      hintText: 'Tambahkan catatan checklist...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: done,
                    onChanged: (value) {
                      setSheetState(() => done = value == true);
                    },
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tandai selesai'),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: _navBlue,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(isEdit ? 'Save Checklist' : 'Add Checklist'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != true || !mounted) {
      titleController.dispose();
      catatanController.dispose();
      return;
    }

    final title = titleController.text.trim();
    final catatan = catatanController.text.trim();

    titleController.dispose();
    catatanController.dispose();

    if (title.isEmpty) {
      _showError('Nama item checklist wajib diisi.');
      return;
    }

    if (isEdit) {
      await _submitEditChecklist(
        existing: existing,
        namaItem: title,
        done: done,
        catatan: catatan,
      );
    } else {
      await _submitAddChecklist(
        namaItem: title,
        done: done,
        catatan: catatan,
      );
    }
  }

  Future<int> _ensureProgressIdForChecklist() async {
    final existingProgressId = _progressId(_latestProgress);

    if (existingProgressId != null) {
      return existingProgressId;
    }

    final bimbinganId = student.bimbinganIdAsInt;

    if (bimbinganId == null) {
      throw Exception('ID bimbingan tidak valid.');
    }

    final decoded = await _dosenService.updateProgresTA(
      bimbinganId: bimbinganId,
      persentase: 0,
      statusProgress: 'Target awal bimbingan',
      catatan: 'Progress awal dibuat otomatis untuk checklist target mahasiswa.',
    );

    final rootData = decoded['data'];

    if (rootData is Map<String, dynamic>) {
      final progressId = int.tryParse(rootData['progress_id']?.toString() ?? '');

      if (progressId != null) {
        return progressId;
      }
    }

    if (rootData is Map) {
      final data = Map<String, dynamic>.from(rootData);
      final progressId = int.tryParse(data['progress_id']?.toString() ?? '');

      if (progressId != null) {
        return progressId;
      }
    }

    throw Exception('Gagal membuat progress awal untuk checklist.');
  }

  Future<void> _submitAddChecklist({
    required String namaItem,
    required bool done,
    required String catatan,
  }) async {
    setState(() => _isSubmitting = true);

    try {
      final progressId = await _ensureProgressIdForChecklist();

      await _dosenService.tambahChecklistProgress(
        progressId: progressId,
        namaItem: namaItem,
        tglSelesai: done,
        tanggalSelesai: done
            ? DateTime.now().toIso8601String().split('T').first
            : null,
        catatan: catatan,
      );

      if (!mounted) return;

      _showSuccess('Checklist berhasil ditambahkan.');
      await _loadProgress();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitEditChecklist({
    required Map<String, dynamic> existing,
    required String namaItem,
    required bool done,
    required String catatan,
  }) async {
    final id = _checklistId(existing);

    if (id == null) {
      _showError('Checklist ID tidak valid.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _dosenService.updateChecklistProgress(
        checklistId: id,
        namaItem: namaItem,
        tglSelesai: done,
        tanggalSelesai: done
            ? DateTime.now().toIso8601String().split('T').first
            : null,
        catatan: catatan,
      );

      if (!mounted) return;

      _showSuccess('Checklist berhasil diperbarui.');
      await _loadProgress();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _toggleChecklist(
    Map<String, dynamic> item,
    bool done,
  ) async {
    final id = _checklistId(item);

    if (id == null) {
      _showError('Checklist ID tidak valid.');
      return;
    }

    final title = item['nama_item']?.toString() ?? '';
    if (title.trim().isEmpty) {
      _showError('Nama item checklist tidak valid.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _dosenService.updateChecklistProgress(
        checklistId: id,
        namaItem: title,
        tglSelesai: done,
        tanggalSelesai: done
            ? DateTime.now().toIso8601String().split('T').first
            : null,
        catatan: item['catatan']?.toString(),
      );

      if (!mounted) return;

      _showSuccess(
        done ? 'Checklist ditandai selesai.' : 'Checklist ditandai belum selesai.',
      );

      await _loadProgress();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _confirmDeleteChecklist(Map<String, dynamic> item) async {
    final id = _checklistId(item);

    if (id == null) {
      _showError('Checklist ID tidak valid.');
      return;
    }

    final title = item['nama_item']?.toString() ?? 'checklist ini';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Checklist?'),
          content: Text('Hapus item "$title"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      await _dosenService.hapusChecklistProgress(id);

      if (!mounted) return;

      _showSuccess('Checklist berhasil dihapus.');
      await _loadProgress();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _sheetHandle() {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  Widget _emptyMessage({
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF94A3B8), size: 30),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.black.withOpacity(0.04)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.035),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF0D4AA3), size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}