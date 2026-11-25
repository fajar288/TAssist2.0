import 'package:file_picker/file_picker.dart';

import '../../../core/api_client.dart';

class MahasiswaService {
  final ApiClient _client = ApiClient.instance;

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> decoded) {
    final rootData = decoded['data'];

    dynamic rows;

    if (rootData is Map<String, dynamic> && rootData['data'] is List) {
      rows = rootData['data'];
    } else if (rootData is List) {
      rows = rootData;
    } else {
      rows = const [];
    }

    return (rows as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  ApiFile _filePart(PlatformFile file) {
    if (file.bytes != null) {
      return ApiFile.fromBytes('file', file.bytes!, file.name);
    }

    if (file.path != null && file.path!.isNotEmpty) {
      return ApiFile.fromPath('file', file.path!, file.name);
    }

    throw const ApiException('File tidak valid atau tidak bisa dibaca.');
  }

  Future<List<Map<String, dynamic>>> getBimbingan({
    int perPage = 10,
  }) async {
    final decoded = await _client.get(
      '/mahasiswa/bimbingan',
      query: {'per_page': perPage},
    );

    return _extractList(decoded);
  }

  Future<Map<String, dynamic>?> getActiveBimbingan() async {
    final bimbinganList = await getBimbingan(perPage: 20);

    for (final item in bimbinganList) {
      final status = item['status_bimbingan']?.toString().toLowerCase();

      if (status == 'aktif') {
        return item;
      }
    }

    return null;
  }

  Future<bool> hasActiveBimbingan() async {
    final activeBimbingan = await getActiveBimbingan();
    return activeBimbingan != null;
  }

  Future<List<Map<String, dynamic>>> getDosen({
    String? bidangKeahlian,
    bool? adaKuota,
    int perPage = 50,
  }) async {
    final query = <String, dynamic>{
      'per_page': perPage,
    };

    if (bidangKeahlian != null && bidangKeahlian.trim().isNotEmpty) {
      query['bidang_keahlian'] = bidangKeahlian.trim();
    }

    if (adaKuota != null) {
      query['ada_kuota'] = adaKuota ? 1 : 0;
    }

    final decoded = await _client.get('/mahasiswa/dosen', query: query);

    return _extractList(decoded);
  }

  Future<List<Map<String, dynamic>>> getPermohonan({
    int perPage = 20,
  }) async {
    final decoded = await _client.get(
      '/mahasiswa/permohonan',
      query: {'per_page': perPage},
    );

    return _extractList(decoded);
  }

  Future<Map<String, dynamic>> ajukanPermohonan({
    required int dosenId,
    required String topikTa,
    ApiFile? proposalFile,
  }) async {
    final Map<String, dynamic> decoded;
    if (proposalFile != null) {
      decoded = await _client.multipart(
        'POST',
        '/mahasiswa/permohonan',
        fields: {
          'dosen_id': dosenId.toString(),
          'topik_ta': topikTa.trim(),
        },
        files: [proposalFile],
      );
    } else {
      decoded = await _client.post(
        '/mahasiswa/permohonan',
        body: {
          'dosen_id': dosenId,
          'topik_ta': topikTa.trim(),
        },
      );
    }

    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    return {};
  }

  Future<Map<String, dynamic>> getDosenKetersediaan(
    int dosenId, {
    String? tanggal,
  }) async {
    final decoded = await _client.get(
      '/mahasiswa/dosen/$dosenId/ketersediaan',
      query: tanggal != null ? {'tanggal': tanggal} : null,
    );

    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {};
  }

  Future<List<Map<String, dynamic>>> getJadwal({
    int perPage = 20,
  }) async {
    final decoded = await _client.get(
      '/mahasiswa/jadwal',
      query: {'per_page': perPage},
    );

    return _extractList(decoded);
  }

  Future<Map<String, dynamic>> ajukanJadwal({
    required int bimbinganId,
    required String tanggal,
    required String waktuMulai,
    required String waktuSelesai,
    required String mode,
    String? catatan,
  }) async {
    final decoded = await _client.post(
      '/mahasiswa/jadwal',
      body: {
        'bimbingan_id': bimbinganId,
        'tanggal': tanggal,
        'waktu_mulai': waktuMulai,
        'waktu_selesai': waktuSelesai,
        'mode': mode,
        'catatan': catatan?.trim().isEmpty == true ? null : catatan?.trim(),
      },
    );

    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    return {};
  }

  Future<Map<String, dynamic>> getProgres({
    int perPage = 5,
  }) async {
    final decoded = await _client.get(
      '/mahasiswa/progres',
      query: {'per_page': perPage},
    );

    final rootData = decoded['data'];

    if (rootData is! Map<String, dynamic>) {
      return {
        'bimbingan_id': null,
        'status_bimbingan': null,
        'progres': <Map<String, dynamic>>[],
      };
    }

    final progresRaw = rootData['progres'];

    List<Map<String, dynamic>> progresList = [];

    if (progresRaw is Map<String, dynamic> && progresRaw['data'] is List) {
      progresList = (progresRaw['data'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } else if (progresRaw is List) {
      progresList = progresRaw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return {
      'bimbingan_id': rootData['bimbingan_id'],
      'status_bimbingan': rootData['status_bimbingan'],
      'progres': progresList,
    };
  }

  Future<List<Map<String, dynamic>>> getDokumen({
    int perPage = 20,
  }) async {
    final decoded = await _client.get(
      '/mahasiswa/dokumen',
      query: {'per_page': perPage},
    );

    return _extractList(decoded);
  }

  Future<Map<String, dynamic>> uploadDokumen({
    required String jenisDokumen,
    required String judulDokumen,
    String? deskripsi,
    String? catatanRevisi,
    required PlatformFile file,
  }) async {
    final decoded = await _client.multipart(
      'POST',
      '/mahasiswa/dokumen',
      fields: {
        'jenis_dokumen': jenisDokumen.trim(),
        'judul_dokumen': judulDokumen.trim(),
        if (deskripsi != null && deskripsi.trim().isNotEmpty)
          'deskripsi': deskripsi.trim(),
        if (catatanRevisi != null && catatanRevisi.trim().isNotEmpty)
          'catatan_revisi': catatanRevisi.trim(),
      },
      files: [_filePart(file)],
    );

    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    return {};
  }

  Future<Map<String, dynamic>> getRiwayatVersiDokumen({
    required int dokumenId,
    int perPage = 20,
  }) async {
    final decoded = await _client.get(
      '/mahasiswa/dokumen/$dokumenId/versi',
      query: {'per_page': perPage},
    );

    final rootData = decoded['data'];

    if (rootData is! Map<String, dynamic>) {
      return {
        'dokumen': null,
        'versi': <Map<String, dynamic>>[],
      };
    }

    final versiRaw = rootData['versi'];

    List<Map<String, dynamic>> versiList = [];

    if (versiRaw is Map<String, dynamic> && versiRaw['data'] is List) {
      versiList = (versiRaw['data'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } else if (versiRaw is List) {
      versiList = versiRaw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return {
      'dokumen': rootData['dokumen'],
      'versi': versiList,
    };
  }

  Future<Map<String, dynamic>> uploadVersiDokumen({
    required int dokumenId,
    String? catatanRevisi,
    required PlatformFile file,
  }) async {
    final decoded = await _client.multipart(
      'POST',
      '/mahasiswa/dokumen/$dokumenId/versi',
      fields: {
        if (catatanRevisi != null && catatanRevisi.trim().isNotEmpty)
          'catatan_revisi': catatanRevisi.trim(),
      },
      files: [_filePart(file)],
    );

    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    return {};
  }
}
