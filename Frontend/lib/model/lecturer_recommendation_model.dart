import '../core/helpers/avatar_helper.dart';

class RecommendationScoreComponent {
  const RecommendationScoreComponent({
    required this.kemiripanTopik,
    required this.ketersediaanKuotaTernormalisasi,
    required this.bebanAktifTernormalisasi,
    required this.skorBebanRendah,
    required this.sisaKuota,
    required this.kuotaBimbingan,
    required this.bimbinganAktif,
    required this.kontribusiKemiripan,
    required this.kontribusiKuota,
    required this.kontribusiBeban,
  });

  final double kemiripanTopik;
  final double ketersediaanKuotaTernormalisasi;
  final double bebanAktifTernormalisasi;
  final double skorBebanRendah;
  final int sisaKuota;
  final int kuotaBimbingan;
  final int bimbinganAktif;
  final double kontribusiKemiripan;
  final double kontribusiKuota;
  final double kontribusiBeban;

  factory RecommendationScoreComponent.fromJson(Map<String, dynamic> json) {
    final kontribusi = json['kontribusi'] is Map
        ? Map<String, dynamic>.from(json['kontribusi'])
        : <String, dynamic>{};

    double toDouble(dynamic value) =>
        double.tryParse(value?.toString() ?? '') ?? 0.0;
    int toInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

    return RecommendationScoreComponent(
      kemiripanTopik: toDouble(json['kemiripan_topik']),
      ketersediaanKuotaTernormalisasi:
          toDouble(json['ketersediaan_kuota_ternormalisasi']),
      bebanAktifTernormalisasi: toDouble(json['beban_aktif_ternormalisasi']),
      skorBebanRendah: toDouble(json['skor_beban_rendah']),
      sisaKuota: toInt(json['sisa_kuota']),
      kuotaBimbingan: toInt(json['kuota_bimbingan']),
      bimbinganAktif: toInt(json['bimbingan_aktif']),
      kontribusiKemiripan: toDouble(kontribusi['kemiripan']),
      kontribusiKuota: toDouble(kontribusi['kuota']),
      kontribusiBeban: toDouble(kontribusi['beban']),
    );
  }
}

class RecommendedLecturerModel {
  const RecommendedLecturerModel({
    required this.dosenId,
    required this.nama,
    required this.nid,
    required this.bidangKeahlian,
    required this.kuotaBimbingan,
    required this.sisaKuota,
    required this.bimbinganAktif,
    required this.skorTotal,
    required this.skorPersen,
    required this.kataKunciCocok,
    required this.riwayatTopikCocok,
    required this.komponenSkor,
    required this.alasan,
    required this.imageUrl,
    this.email,
    this.avatar,
    this.profilSingkat,
  });

  final String dosenId;
  final String nama;
  final String? email;
  final String? avatar;
  final String imageUrl;
  final String nid;
  final String bidangKeahlian;
  final int kuotaBimbingan;
  final int sisaKuota;
  final int bimbinganAktif;
  final String? profilSingkat;
  final double skorTotal;
  final double skorPersen;
  final List<String> kataKunciCocok;
  final int riwayatTopikCocok;
  final RecommendationScoreComponent komponenSkor;
  final String alasan;

  factory RecommendedLecturerModel.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatar']?.toString();
    final komponenRaw = json['komponen_skor'] is Map
        ? Map<String, dynamic>.from(json['komponen_skor'])
        : <String, dynamic>{};

    final keywordsRaw = json['kata_kunci_cocok'];
    final keywords = keywordsRaw is List
        ? keywordsRaw.map((e) => e.toString()).toList()
        : <String>[];

    return RecommendedLecturerModel(
      dosenId: json['dosen_id']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '-',
      email: json['email']?.toString(),
      avatar: avatar,
      imageUrl: AvatarHelper.getAvatarUrl(avatar: avatar),
      nid: json['nid']?.toString() ?? '-',
      bidangKeahlian: json['bidang_keahlian']?.toString() ?? '-',
      kuotaBimbingan:
          int.tryParse(json['kuota_bimbingan']?.toString() ?? '') ?? 0,
      sisaKuota: int.tryParse(json['sisa_kuota']?.toString() ?? '') ?? 0,
      bimbinganAktif:
          int.tryParse(json['bimbingan_aktif']?.toString() ?? '') ?? 0,
      profilSingkat: json['profil_singkat']?.toString(),
      skorTotal: double.tryParse(json['skor_total']?.toString() ?? '') ?? 0.0,
      skorPersen: double.tryParse(json['skor_persen']?.toString() ?? '') ?? 0.0,
      kataKunciCocok: keywords,
      riwayatTopikCocok:
          int.tryParse(json['riwayat_topik_cocok']?.toString() ?? '') ?? 0,
      komponenSkor: RecommendationScoreComponent.fromJson(komponenRaw),
      alasan: json['alasan']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toLecturerJson() => {
        'dosen_id': dosenId,
        'nama': nama,
        'email': email,
        'avatar': avatar,
        'nid': nid,
        'bidang_keahlian': bidangKeahlian,
        'kuota_bimbingan': kuotaBimbingan,
        'sisa_kuota': sisaKuota,
        'profil_singkat': profilSingkat,
      };
}

class LecturerRecommendationResponse {
  const LecturerRecommendationResponse({
    required this.topik,
    required this.kataKunciStemmed,
    required this.isTopikSingkat,
    required this.totalKandidat,
    required this.totalDosenDikecualikanKuotaHabis,
    required this.rekomendasi,
    this.catatanKueri,
  });

  final String topik;
  final List<String> kataKunciStemmed;
  final bool isTopikSingkat;
  final String? catatanKueri;
  final int totalKandidat;
  final int totalDosenDikecualikanKuotaHabis;
  final List<RecommendedLecturerModel> rekomendasi;

  factory LecturerRecommendationResponse.fromJson(Map<String, dynamic> json) {
    final stemmedRaw = json['kata_kunci_stemmed'];
    final stemmed = stemmedRaw is List
        ? stemmedRaw.map((e) => e.toString()).toList()
        : <String>[];

    final listRaw = json['rekomendasi'];
    final list = listRaw is List
        ? listRaw
            .whereType<Map>()
            .map(
              (item) => RecommendedLecturerModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <RecommendedLecturerModel>[];

    return LecturerRecommendationResponse(
      topik: json['topik']?.toString() ?? '',
      kataKunciStemmed: stemmed,
      isTopikSingkat: json['is_topik_singkat'] == true,
      catatanKueri: json['catatan_kueri']?.toString(),
      totalKandidat:
          int.tryParse(json['total_kandidat']?.toString() ?? '') ?? list.length,
      totalDosenDikecualikanKuotaHabis: int.tryParse(
            json['total_dosen_dikecualikan_kuota_habis']?.toString() ?? '',
          ) ??
          0,
      rekomendasi: list,
    );
  }
}
