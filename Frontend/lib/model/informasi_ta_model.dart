// lib/model/informasi_ta_model.dart

class InformasiTAModel {
  final int infoId;
  final String kategori;
  final String judul;
  final String? kontenOrFile;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final String penulis;

  const InformasiTAModel({
    required this.infoId,
    required this.kategori,
    required this.judul,
    this.kontenOrFile,
    this.publishedAt,
    this.createdAt,
    this.penulis = 'Admin TA',
  });

  factory InformasiTAModel.fromJson(Map<String, dynamic> json) {
    return InformasiTAModel(
      infoId: json['info_id'] is int
          ? json['info_id'] as int
          : int.tryParse(json['info_id']?.toString() ?? '') ?? 0,
      kategori: json['kategori']?.toString() ?? 'Pengumuman',
      judul: json['judul']?.toString() ?? '',
      kontenOrFile: json['konten_or_file']?.toString(),
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      penulis: json['penulis']?.toString() ?? 'Admin TA',
    );
  }
}
