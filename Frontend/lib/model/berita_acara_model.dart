// lib/model/berita_acara_model.dart

enum BeritaAcaraStatus { draft, disetujui }

class BeritaAcaraModel {
  final int beritaAcaraId;
  final int bimbinganId;
  final String nomor;
  final DateTime? periodeMulai;
  final DateTime? periodeSelesai;
  final Map<String, dynamic> dataSnapshot;
  final String filePath;
  final String fileHash;
  final String tokenVerifikasi;
  final BeritaAcaraStatus statusPersetujuan;
  final String? metodePersetujuan;
  final String? tandaTanganPath;
  final DateTime? approvedAt;
  final String? approvedHash;
  final DateTime? createdAt;
  final String? downloadUrl;

  const BeritaAcaraModel({
    required this.beritaAcaraId,
    required this.bimbinganId,
    required this.nomor,
    this.periodeMulai,
    this.periodeSelesai,
    this.dataSnapshot = const {},
    required this.filePath,
    required this.fileHash,
    required this.tokenVerifikasi,
    this.statusPersetujuan = BeritaAcaraStatus.draft,
    this.metodePersetujuan,
    this.tandaTanganPath,
    this.approvedAt,
    this.approvedHash,
    this.createdAt,
    this.downloadUrl,
  });

  bool get isDraft => statusPersetujuan == BeritaAcaraStatus.draft;
  bool get isDisetujui => statusPersetujuan == BeritaAcaraStatus.disetujui;

  String get activeHash => approvedHash?.isNotEmpty == true ? approvedHash! : fileHash;

  String get studentName =>
      dataSnapshot['mahasiswa']?['nama']?.toString() ?? 'Mahasiswa';

  String get studentNim =>
      dataSnapshot['mahasiswa']?['nim']?.toString() ?? '-';

  String get professorName =>
      dataSnapshot['dosen']?['nama']?.toString() ?? 'Dosen Pembimbing';

  String get professorNid =>
      dataSnapshot['dosen']?['nid']?.toString() ?? '-';

  int get totalSessions {
    final dynamic total = dataSnapshot['total_sesi'];
    if (total is int) return total;
    if (total != null) return int.tryParse(total.toString()) ?? 0;
    final dynamic list = dataSnapshot['sesi_bimbingan'];
    if (list is List) return list.length;
    return 0;
  }

  factory BeritaAcaraModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    BeritaAcaraStatus parseStatus(dynamic value) {
      final str = value?.toString().toLowerCase().trim() ?? 'draft';
      if (str == 'disetujui') return BeritaAcaraStatus.disetujui;
      return BeritaAcaraStatus.draft;
    }

    Map<String, dynamic> parseSnapshot(dynamic val) {
      if (val is Map) {
        return Map<String, dynamic>.from(val);
      }
      return {};
    }

    return BeritaAcaraModel(
      beritaAcaraId: json['berita_acara_id'] is int
          ? json['berita_acara_id'] as int
          : int.tryParse(json['berita_acara_id']?.toString() ?? '') ?? 0,
      bimbinganId: json['bimbingan_id'] is int
          ? json['bimbingan_id'] as int
          : int.tryParse(json['bimbingan_id']?.toString() ?? '') ?? 0,
      nomor: json['nomor']?.toString() ?? '',
      periodeMulai: parseDate(json['periode_mulai']),
      periodeSelesai: parseDate(json['periode_selesai']),
      dataSnapshot: parseSnapshot(json['data_snapshot']),
      filePath: json['file_path']?.toString() ?? '',
      fileHash: json['file_hash']?.toString() ?? '',
      tokenVerifikasi: json['token_verifikasi']?.toString() ?? '',
      statusPersetujuan: parseStatus(json['status_persetujuan']),
      metodePersetujuan: json['metode_persetujuan']?.toString(),
      tandaTanganPath: json['tanda_tangan_path']?.toString(),
      approvedAt: parseDate(json['approved_at']),
      approvedHash: json['approved_hash']?.toString(),
      createdAt: parseDate(json['created_at']),
      downloadUrl: json['download_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'berita_acara_id': beritaAcaraId,
      'bimbingan_id': bimbinganId,
      'nomor': nomor,
      'periode_mulai': periodeMulai?.toIso8601String(),
      'periode_selesai': periodeSelesai?.toIso8601String(),
      'data_snapshot': dataSnapshot,
      'file_path': filePath,
      'file_hash': fileHash,
      'token_verifikasi': tokenVerifikasi,
      'status_persetujuan': statusPersetujuan.name,
      'metode_persetujuan': metodePersetujuan,
      'tanda_tangan_path': tandaTanganPath,
      'approved_at': approvedAt?.toIso8601String(),
      'approved_hash': approvedHash,
      'created_at': createdAt?.toIso8601String(),
      'download_url': downloadUrl,
    };
  }
}
