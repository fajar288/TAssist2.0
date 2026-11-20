// lib/model/annotation_model.dart

enum AnnotationType { highlight, komentar, coretan }

enum AnnotationStatus { open, revised, resolved }

class AnnotationReplyModel {
  final int anotasiId;
  final int parentId;
  final int userId;
  final String authorName;
  final String authorRole;
  final String konten;
  final DateTime? createdAt;

  const AnnotationReplyModel({
    required this.anotasiId,
    required this.parentId,
    required this.userId,
    required this.authorName,
    required this.authorRole,
    required this.konten,
    this.createdAt,
  });

  factory AnnotationReplyModel.fromJson(Map<String, dynamic> json) {
    return AnnotationReplyModel(
      anotasiId: json['anotasi_id'] is int
          ? json['anotasi_id'] as int
          : int.tryParse(json['anotasi_id']?.toString() ?? '') ?? 0,
      parentId: json['parent_id'] is int
          ? json['parent_id'] as int
          : int.tryParse(json['parent_id']?.toString() ?? '') ?? 0,
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      authorName: json['user']?['nama']?.toString() ??
          json['author_name']?.toString() ??
          'Pengguna',
      authorRole: json['user']?['role']?.toString() ??
          json['author_role']?.toString() ??
          '',
      konten: json['konten']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class AnnotationModel {
  final int anotasiId;
  final int versiId;
  final int? dosenId;
  final int userId;
  final int? parentId;
  final int halaman;
  final double x;
  final double y;
  final double? lebar;
  final double? tinggi;
  final AnnotationType tipe;
  final String? konten;
  final List<dynamic>? dataCoretan;
  final AnnotationStatus status;
  final DateTime? createdAt;
  final String authorName;
  final String authorRole;
  final List<AnnotationReplyModel> replies;

  const AnnotationModel({
    required this.anotasiId,
    required this.versiId,
    this.dosenId,
    required this.userId,
    this.parentId,
    required this.halaman,
    required this.x,
    required this.y,
    this.lebar,
    this.tinggi,
    required this.tipe,
    this.konten,
    this.dataCoretan,
    required this.status,
    this.createdAt,
    this.authorName = 'Dosen',
    this.authorRole = 'dosen',
    this.replies = const [],
  });

  static AnnotationType _parseType(String? val) {
    switch (val?.toLowerCase()) {
      case 'highlight':
        return AnnotationType.highlight;
      case 'coretan':
        return AnnotationType.coretan;
      default:
        return AnnotationType.komentar;
    }
  }

  static AnnotationStatus _parseStatus(String? val) {
    switch (val?.toLowerCase()) {
      case 'revised':
        return AnnotationStatus.revised;
      case 'resolved':
        return AnnotationStatus.resolved;
      default:
        return AnnotationStatus.open;
    }
  }

  factory AnnotationModel.fromJson(Map<String, dynamic> json) {
    final repliesRaw = json['replies'];
    final List<AnnotationReplyModel> parsedReplies = [];
    if (repliesRaw is List) {
      for (final r in repliesRaw) {
        if (r is Map) {
          parsedReplies
              .add(AnnotationReplyModel.fromJson(Map<String, dynamic>.from(r)));
        }
      }
    }

    return AnnotationModel(
      anotasiId: json['anotasi_id'] is int
          ? json['anotasi_id'] as int
          : int.tryParse(json['anotasi_id']?.toString() ?? '') ?? 0,
      versiId: json['versi_id'] is int
          ? json['versi_id'] as int
          : int.tryParse(json['versi_id']?.toString() ?? '') ?? 0,
      dosenId: json['dosen_id'] != null
          ? int.tryParse(json['dosen_id'].toString())
          : null,
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      parentId: json['parent_id'] != null
          ? int.tryParse(json['parent_id'].toString())
          : null,
      halaman: json['halaman'] is int
          ? json['halaman'] as int
          : int.tryParse(json['halaman']?.toString() ?? '') ?? 1,
      x: json['x'] != null ? (double.tryParse(json['x'].toString()) ?? 0.0) : 0.0,
      y: json['y'] != null ? (double.tryParse(json['y'].toString()) ?? 0.0) : 0.0,
      lebar: json['lebar'] != null ? double.tryParse(json['lebar'].toString()) : null,
      tinggi: json['tinggi'] != null ? double.tryParse(json['tinggi'].toString()) : null,
      tipe: _parseType(json['tipe']?.toString()),
      konten: json['konten']?.toString(),
      dataCoretan: json['data_coretan'] is List ? json['data_coretan'] as List : null,
      status: _parseStatus(json['status']?.toString()),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      authorName: json['dosen']?['user']?['nama']?.toString() ??
          json['user']?['nama']?.toString() ??
          'Dosen Pembimbing',
      authorRole: json['user']?['role']?.toString() ?? 'dosen',
      replies: parsedReplies,
    );
  }
}
