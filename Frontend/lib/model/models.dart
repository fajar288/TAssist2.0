// lib/models/models.dart
import '../theme/app_theme.dart';

export '../theme/app_theme.dart' show RequestStatus;

class CounselingRequest {
  final String id; // data real: permohonan_id
  final String studentName;
  final String nim;
  final String major;
  final String avatarUrl;
  final RequestStatus status;
  final DateTime requestDate;
  final String message;

  const CounselingRequest({
    required this.id,
    required this.studentName,
    required this.nim,
    required this.major,
    required this.avatarUrl,
    required this.status,
    required this.requestDate,
    this.message = '',
  });

  factory CounselingRequest.fromPermohonanJson(Map<String, dynamic> json) {
    final mahasiswaRaw = json['mahasiswa'];
    final mahasiswa = mahasiswaRaw is Map
        ? Map<String, dynamic>.from(mahasiswaRaw)
        : <String, dynamic>{};

    final studentName = mahasiswa['nama']?.toString() ?? '-';

    return CounselingRequest(
      id: json['permohonan_id']?.toString() ?? '',
      studentName: studentName,
      nim: mahasiswa['nim']?.toString() ?? '-',
      major: mahasiswa['prodi']?.toString() ?? '-',
      avatarUrl: '',
      status: _statusFromBackend(json['status']?.toString()),
      requestDate: _parseDate(json['tanggal_pengajuan']?.toString()),
      message: json['topik_ta']?.toString() ?? '',
    );
  }

  String get initials => _initialsFromName(studentName);

  static RequestStatus _statusFromBackend(String? status) {
    switch (status?.toLowerCase()) {
      case 'menunggu':
        return RequestStatus.pending;
      case 'diterima':
        return RequestStatus.accepted;
      case 'ditolak':
        return RequestStatus.declined;
      default:
        return RequestStatus.pending;
    }
  }

  static DateTime _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return DateTime.now();
    }

    try {
      return DateTime.parse(value);
    } catch (_) {
      return DateTime.now();
    }
  }
}

class StudentModel {
  final String id; // data real: bimbingan_id
  final String? mahasiswaId;
  final String name;
  final String nim;
  final String major;
  final String year;
  final String imageInitials;
  final String status;
  final double progress;
  final String counselingSince;
  final String email;
  final String phone;
  final int meetingCount;
  final int taskCount;
  final int taskCompleted;
  final String? topikTa;
  final String? judulTa;

  const StudentModel({
    required this.id,
    this.mahasiswaId,
    required this.name,
    required this.nim,
    required this.major,
    required this.year,
    required this.imageInitials,
    required this.status,
    required this.progress,
    required this.counselingSince,
    required this.email,
    required this.phone,
    required this.meetingCount,
    required this.taskCount,
    required this.taskCompleted,
    this.topikTa,
    this.judulTa,
  });

  int? get bimbinganIdAsInt => int.tryParse(id);
  int? get mahasiswaIdAsInt => int.tryParse(mahasiswaId ?? '');

  factory StudentModel.fromBimbinganJson(Map<String, dynamic> json) {
    final mahasiswaRaw = json['mahasiswa'];
    final mahasiswa = mahasiswaRaw is Map
        ? Map<String, dynamic>.from(mahasiswaRaw)
        : <String, dynamic>{};

    final progresRaw = json['progres_terkini'];
    final progres = progresRaw is Map
        ? Map<String, dynamic>.from(progresRaw)
        : <String, dynamic>{};

    final name = mahasiswa['nama']?.toString() ?? '-';
    final persentaseRaw =
        double.tryParse(progres['persentase']?.toString() ?? '') ?? 0;
    final progressValue = persentaseRaw > 1
        ? (persentaseRaw / 100).clamp(0.0, 1.0)
        : persentaseRaw.clamp(0.0, 1.0);

    return StudentModel(
      id: json['bimbingan_id']?.toString() ?? '',
      mahasiswaId: mahasiswa['mahasiswa_id']?.toString(),
      name: name,
      nim: mahasiswa['nim']?.toString() ?? '-',
      major: mahasiswa['prodi']?.toString() ?? '-',
      year: mahasiswa['angkatan']?.toString() ?? '-',
      imageInitials: _initialsFromName(name),
      status: _mapStatus(json['status_bimbingan']?.toString()),
      progress: progressValue,
      counselingSince: json['tanggal_mulai']?.toString() ?? '-',
      email: '-',
      phone: '-',
      meetingCount: 0,
      taskCount: 0,
      taskCompleted: 0,
      topikTa: mahasiswa['topik_ta']?.toString(),
      judulTa: mahasiswa['judul_ta']?.toString(),
    );
  }

  static String _mapStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'aktif':
        return 'active';
      case 'selesai':
        return 'completed';
      case 'dibatalkan':
        return 'warning';
      default:
        return 'active';
    }
  }
}

class MeetingRequest {
  final String id; // data real: jadwal_id
  final String studentName;
  final String nim;
  final String major;
  final String avatarUrl;
  final DateTime meetingDate;
  final String meetingTime;
  final String description;
  final RequestStatus status;
  final String mode;
  final String pengajuRole;
  final String pengajuName;
  final String waktuMulai;
  final String waktuSelesai;
  final String? catatan;

  const MeetingRequest({
    required this.id,
    required this.studentName,
    required this.nim,
    required this.major,
    required this.avatarUrl,
    required this.meetingDate,
    required this.meetingTime,
    required this.description,
    required this.status,
    this.mode = 'offline',
    this.pengajuRole = '-',
    this.pengajuName = '-',
    this.waktuMulai = '-',
    this.waktuSelesai = '-',
    this.catatan,
  });

  factory MeetingRequest.fromJadwalJson(Map<String, dynamic> json) {
    final mahasiswaRaw = json['mahasiswa'];
    final mahasiswa = mahasiswaRaw is Map
        ? Map<String, dynamic>.from(mahasiswaRaw)
        : <String, dynamic>{};

    final pengajuRaw = json['pengaju'];
    final pengaju = pengajuRaw is Map
        ? Map<String, dynamic>.from(pengajuRaw)
        : <String, dynamic>{};

    final studentName = mahasiswa['nama']?.toString() ?? '-';
    final tanggal = json['tanggal']?.toString();
    final mulai = json['waktu_mulai']?.toString() ?? '-';
    final selesai = json['waktu_selesai']?.toString() ?? '-';
    final mode = json['mode']?.toString() ?? 'offline';
    final catatan = json['catatan']?.toString();
    final pengajuRole = pengaju['role']?.toString() ?? '-';
    final pengajuName = pengaju['nama']?.toString() ?? '-';

    return MeetingRequest(
      id: json['jadwal_id']?.toString() ?? '',
      studentName: studentName,
      nim: mahasiswa['nim']?.toString() ?? '-',
      // Response backend jadwal dosen belum membawa prodi, jadi jangan dipaksa.
      major: 'Mahasiswa Bimbingan',
      avatarUrl: '',
      meetingDate: _parseDate(tanggal),
      meetingTime: '${_formatTime(mulai)} - ${_formatTime(selesai)}',
      description: catatan == null || catatan.trim().isEmpty
          ? 'No note provided.'
          : catatan,
      status: _statusFromBackend(json['status_konfirmasi']?.toString()),
      mode: mode,
      pengajuRole: pengajuRole,
      pengajuName: pengajuName,
      waktuMulai: mulai,
      waktuSelesai: selesai,
      catatan: catatan,
    );
  }

  bool get isProposedByStudent => pengajuRole.toLowerCase() == 'mahasiswa';
  bool get isProposedByDosen => pengajuRole.toLowerCase() == 'dosen';

  String get initials => _initialsFromName(studentName);

  String get dayName {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[meetingDate.weekday - 1];
  }

  String get formattedDate {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '$dayName, ${meetingDate.day} ${months[meetingDate.month - 1]} ${meetingDate.year}';
  }

  static RequestStatus _statusFromBackend(String? status) {
    switch (status?.toLowerCase()) {
      case 'menunggu':
        return RequestStatus.pending;
      case 'dikonfirmasi':
        return RequestStatus.accepted;
      case 'ditolak':
        return RequestStatus.declined;
      default:
        return RequestStatus.pending;
    }
  }

  static DateTime _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return DateTime.now();
    }

    try {
      return DateTime.parse(value);
    } catch (_) {
      return DateTime.now();
    }
  }

  static String _formatTime(String? value) {
    if (value == null || value.trim().isEmpty) return '-';

    final parts = value.split(':');
    if (parts.length < 2) return value;

    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }
}

String _initialsFromName(String name) {
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
