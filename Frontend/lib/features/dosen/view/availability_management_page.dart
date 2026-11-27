import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_error_widget.dart';
import '../../../widgets/app_loading_widget.dart';
import '../../../widgets/app_snackbars.dart';
import '../data/dosen_service.dart';

/// T-76 (F-SCH-04): Supervisor Availability Management screen for Dosen.
class AvailabilityManagementPage extends StatefulWidget {
  const AvailabilityManagementPage({super.key});

  @override
  State<AvailabilityManagementPage> createState() =>
      _AvailabilityManagementPageState();
}

class _AvailabilityManagementPageState
    extends State<AvailabilityManagementPage> {
  final DosenService _dosenService = DosenService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _slots = [];

  static const List<String> _days = [
    'senin',
    'selasa',
    'rabu',
    'kamis',
    'jumat',
    'sabtu',
  ];

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _dosenService.getKetersediaan();
      if (!mounted) return;
      setState(() {
        _slots = list;
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

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  Future<void> _openSlotSheet({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    String tipe = existing?['tipe']?.toString() ?? 'mingguan';
    String hari = existing?['hari']?.toString() ?? 'senin';
    DateTime? tanggal = existing?['tanggal'] != null
        ? DateTime.tryParse(existing!['tanggal'].toString())
        : DateTime.now().add(const Duration(days: 1));
    TimeOfDay startTime = _parseTime(existing?['waktu_mulai']?.toString()) ??
        const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = _parseTime(existing?['waktu_selesai']?.toString()) ??
        const TimeOfDay(hour: 11, minute: 0);
    bool isAvailable = existing?['is_available'] != false;
    final catatanCtrl = TextEditingController(
      text: existing?['catatan']?.toString() ?? '',
    );

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBorderOf(ctx),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isEdit ? 'Edit Slot Ketersediaan' : 'Tambah Slot Ketersediaan',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryOf(ctx),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'mingguan',
                          label: Text('Rutin Mingguan'),
                          icon: Icon(Icons.repeat_rounded),
                        ),
                        ButtonSegment(
                          value: 'khusus',
                          label: Text('Tanggal Khusus'),
                          icon: Icon(Icons.event_rounded),
                        ),
                      ],
                      selected: {tipe},
                      onSelectionChanged: (sel) {
                        setSheetState(() => tipe = sel.first);
                      },
                    ),
                    const SizedBox(height: 14),
                    if (tipe == 'mingguan')
                      DropdownButtonFormField<String>(
                        initialValue: hari,
                        decoration: const InputDecoration(
                          labelText: 'Hari',
                          border: OutlineInputBorder(),
                        ),
                        items: _days
                            .map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(_capitalize(d)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setSheetState(() => hari = v);
                        },
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: tanggal ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setSheetState(() => tanggal = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today_rounded),
                        label: Text(
                          tanggal != null
                              ? 'Tanggal: ${_fmtDate(tanggal!)}'
                              : 'Pilih Tanggal',
                        ),
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: ctx,
                                initialTime: startTime,
                              );
                              if (picked != null) {
                                setSheetState(() => startTime = picked);
                              }
                            },
                            icon: const Icon(Icons.access_time_rounded),
                            label: Text('Mulai: ${_fmtTime(startTime)}'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: ctx,
                                initialTime: endTime,
                              );
                              if (picked != null) {
                                setSheetState(() => endTime = picked);
                              }
                            },
                            icon: const Icon(Icons.access_time_filled_rounded),
                            label: Text('Selesai: ${_fmtTime(endTime)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isAvailable,
                      activeThumbColor: AppTheme.primary,
                      title: Text(
                        isAvailable
                            ? 'Tersedia untuk bimbingan'
                            : 'Blokir (Tidak tersedia)',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onChanged: (val) => setSheetState(() => isAvailable = val),
                    ),
                    TextField(
                      controller: catatanCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (opsional)',
                        hintText: 'Contoh: Khusus persiapan sidang',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Slot'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (saved != true || !mounted) {
      catatanCtrl.dispose();
      return;
    }

    final startStr = _fmtTime(startTime);
    final endStr = _fmtTime(endTime);
    final catatan = catatanCtrl.text.trim();
    catatanCtrl.dispose();

    if (startStr.compareTo(endStr) >= 0) {
      _showSnack('Waktu selesai harus setelah waktu mulai.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (isEdit) {
        final id = int.parse(existing['ketersediaan_id'].toString());
        await _dosenService.updateKetersediaan(
          ketersediaanId: id,
          tipe: tipe,
          hari: tipe == 'mingguan' ? hari : null,
          tanggal: tipe == 'khusus' && tanggal != null ? _fmtDate(tanggal!) : null,
          waktuMulai: startStr,
          waktuSelesai: endStr,
          isAvailable: isAvailable,
          catatan: catatan,
        );
      } else {
        await _dosenService.createKetersediaan(
          tipe: tipe,
          hari: tipe == 'mingguan' ? hari : null,
          tanggal: tipe == 'khusus' && tanggal != null ? _fmtDate(tanggal!) : null,
          waktuMulai: startStr,
          waktuSelesai: endStr,
          isAvailable: isAvailable,
          catatan: catatan,
        );
      }
      if (!mounted) return;
      _showSnack('Slot ketersediaan berhasil disimpan.');
      await _loadSlots();
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteSlot(Map<String, dynamic> slot) async {
    final id = int.tryParse(slot['ketersediaan_id']?.toString() ?? '');
    if (id == null) return;

    setState(() => _isSaving = true);
    try {
      await _dosenService.deleteKetersediaan(id);
      if (!mounted) return;
      _showSnack('Slot dihapus.');
      await _loadSlots();
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  TimeOfDay? _parseTime(String? raw) {
    if (raw == null || !raw.contains(':')) return null;
    final parts = raw.split(':');
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _showSnack(String msg, {bool isError = false}) {
    if (isError) {
      AppSnackBars.error(context, msg);
    } else {
      AppSnackBars.success(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekly = _slots.where((s) => s['tipe'] == 'mingguan').toList();
    final exceptions = _slots.where((s) => s['tipe'] == 'khusus').toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundOf(context),
      appBar: AppBar(
        title: const Text('Ketersediaan Bimbingan'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : () => _openSlotSheet(),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Slot'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSlots,
        child: _isLoading
            ? const AppLoadingWidget()
            : _errorMessage != null
                ? AppErrorWidget(
                    message: _errorMessage!,
                    onRetry: _loadSlots,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    children: [
                      _sectionTitle('Jadwal Rutin Mingguan', weekly.length),
                      const SizedBox(height: 8),
                      if (weekly.isEmpty)
                        _emptyCard('Belum ada slot mingguan.')
                      else
                        ...weekly.map(_buildSlotCard),
                      const SizedBox(height: 20),
                      _sectionTitle('Pengecualian / Tanggal Khusus', exceptions.length),
                      const SizedBox(height: 8),
                      if (exceptions.isEmpty)
                        _emptyCard('Belum ada pengecualian tanggal khusus.')
                      else
                        ...exceptions.map(_buildSlotCard),
                    ],
                  ),
      ),
    );
  }

  Widget _sectionTitle(String title, int count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryOf(context),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryGhostOf(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: AppTheme.primaryOf(context),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecorationOf(context),
      child: Text(text, style: TextStyle(color: AppTheme.textSecondaryOf(context))),
    );
  }

  Widget _buildSlotCard(Map<String, dynamic> slot) {
    final isMingguan = slot['tipe'] == 'mingguan';
    final available = slot['is_available'] != false;
    final label = isMingguan
        ? _capitalize(slot['hari']?.toString() ?? '-')
        : (slot['tanggal']?.toString() ?? '-');
    final timeRange =
        '${slot['waktu_mulai'] ?? '-'} - ${slot['waktu_selesai'] ?? '-'}';
    final catatan = slot['catatan']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecorationOf(context),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: available
                  ? AppTheme.accepted.withValues(alpha: 0.12)
                  : AppTheme.declined.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(
              available ? Icons.event_available_rounded : Icons.event_busy_rounded,
              color: available ? AppTheme.accepted : AppTheme.declined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label · $timeRange',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryOf(context),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  available ? 'Tersedia' : 'Tidak tersedia (Diblokir)',
                  style: TextStyle(
                    color: available ? AppTheme.accepted : AppTheme.declined,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (catatan != null && catatan.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    catatan,
                    style: TextStyle(
                      color: AppTheme.textSecondaryOf(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: _isSaving ? null : () => _openSlotSheet(existing: slot),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.declined, size: 20),
            onPressed: _isSaving ? null : () => _deleteSlot(slot),
          ),
        ],
      ),
    );
  }
}
