import 'package:file_picker/file_picker.dart';

import '../../../core/api_client.dart';

class DosenService {
  final ApiClient _client = ApiClient.instance;

  List<Map<String, dynamic>> _extractPaginatorList(Map<String, dynamic> decoded) {
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

  Future<Map<String, dynamic>> getProfile() {
    return _client.get('/dosen/profile');
  }

  Future<Map<String, dynamic>> getPermohonan({
    String? status,
    int perPage = 50,
  }) {
    return _client.get(
      '/dosen/permohonan',
      query: {
        'status': status,
        'per_page': perPage,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getPermohonanList({
    String? status,
    int perPage = 50,
  }) async {
    final decoded = await getPermohonan(
      status: status,
      perPage: perPage,
    );

    return _extractPaginatorList(decoded);
  }

  Future<Map<String, dynamic>> terimaPermohonan(int id) {
    return _client.put('/dosen/permohonan/$id/terima');
  }

  Future<Map<String, dynamic>> tolakPermohonan(
    int id, {
    required String catatanRespons,
  }) {
    return _client.put(
      '/dosen/permohonan/$id/tolak',
      body: {
        'catatan_respons': catatanRespons.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> getMahasiswaBimbingan({
    String? status,
    int perPage = 30,
  }) {
    return _client.get(
      '/dosen/mahasiswa-bimbingan',
      query: {
        'status': status,
        'per_page': perPage,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getMahasiswaBimbinganList({
    String? status,
    int perPage = 30,
  }) async {
    final decoded = await getMahasiswaBimbingan(
      status: status,
      perPage: perPage,
    );

    return _extractPaginatorList(decoded);
  }

  Future<Map<String, dynamic>> getProgresMahasiswa(int bimbinganId) {
    return _client.get('/dosen/mahasiswa-bimbingan/$bimbinganId/progres');
  }

  Future<Map<String, dynamic>> updateProgresTA({
    required int bimbinganId,
    double? persentase,
    required String statusProgress,
    bool? isOverride,
    String? catatan,
  }) {
    return _client.put(
      '/dosen/progres/$bimbinganId',
      body: {
        if (persentase != null) 'persentase': persentase,
        'status_progress': statusProgress.trim(),
        if (isOverride != null) 'is_override': isOverride,
        if (catatan != null && catatan.trim().isNotEmpty)
          'catatan': catatan.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> tambahChecklistProgress({
    required int progressId,
    required String namaItem,
    bool isSelesai = false,
    double bobot = 1.0,
    String? tanggalSelesai,
    String? catatan,
  }) {
    return _client.post(
      '/dosen/progres/$progressId/checklist',
      body: {
        'nama_item': namaItem.trim(),
        'is_selesai': isSelesai,
        'bobot': bobot,
        if (tanggalSelesai != null && tanggalSelesai.trim().isNotEmpty)
          'tanggal_selesai': tanggalSelesai.trim(),
        if (catatan != null && catatan.trim().isNotEmpty)
          'catatan': catatan.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> updateChecklistProgress({
    required int checklistId,
    required String namaItem,
    required bool isSelesai,
    double? bobot,
    String? tanggalSelesai,
    String? catatan,
  }) {
    return _client.put(
      '/dosen/checklist/$checklistId',
      body: {
        'nama_item': namaItem.trim(),
        'is_selesai': isSelesai,
        if (bobot != null) 'bobot': bobot,
        if (tanggalSelesai != null && tanggalSelesai.trim().isNotEmpty)
          'tanggal_selesai': tanggalSelesai.trim(),
        if (catatan != null && catatan.trim().isNotEmpty)
          'catatan': catatan.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> hapusChecklistProgress(int checklistId) {
    return _client.delete('/dosen/checklist/$checklistId');
  }

  Future<List<Map<String, dynamic>>> getKetersediaan() async {
    final decoded = await _client.get('/dosen/ketersediaan');
    final data = decoded['data'];
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createKetersediaan({
    required String tipe,
    String? hari,
    String? tanggal,
    required String waktuMulai,
    required String waktuSelesai,
    bool isAvailable = true,
    String? catatan,
  }) {
    return _client.post(
      '/dosen/ketersediaan',
      body: {
        'tipe': tipe,
        if (hari != null) 'hari': hari,
        if (tanggal != null) 'tanggal': tanggal,
        'waktu_mulai': waktuMulai,
        'waktu_selesai': waktuSelesai,
        'is_available': isAvailable,
        if (catatan != null && catatan.trim().isNotEmpty) 'catatan': catatan.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> updateKetersediaan({
    required int ketersediaanId,
    String? tipe,
    String? hari,
    String? tanggal,
    String? waktuMulai,
    String? waktuSelesai,
    bool? isAvailable,
    String? catatan,
  }) {
    return _client.put(
      '/dosen/ketersediaan/$ketersediaanId',
      body: {
        if (tipe != null) 'tipe': tipe,
        if (hari != null) 'hari': hari,
        if (tanggal != null) 'tanggal': tanggal,
        if (waktuMulai != null) 'waktu_mulai': waktuMulai,
        if (waktuSelesai != null) 'waktu_selesai': waktuSelesai,
        if (isAvailable != null) 'is_available': isAvailable,
        if (catatan != null) 'catatan': catatan.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> deleteKetersediaan(int ketersediaanId) {
    return _client.delete('/dosen/ketersediaan/$ketersediaanId');
  }

  Future<Map<String, dynamic>> getDokumenMahasiswa({
    required int bimbinganId,
    int perPage = 30,
  }) {
    return _client.get(
      '/dosen/mahasiswa-bimbingan/$bimbinganId/dokumen',
      query: {'per_page': perPage},
    );
  }

  Future<List<Map<String, dynamic>>> getDokumenMahasiswaList({
    required int bimbinganId,
    int perPage = 30,
  }) async {
    final decoded = await getDokumenMahasiswa(
      bimbinganId: bimbinganId,
      perPage: perPage,
    );

    final rootData = decoded['data'];

    if (rootData is Map<String, dynamic>) {
      final dokumenRaw = rootData['dokumen'];

      if (dokumenRaw is Map<String, dynamic> && dokumenRaw['data'] is List) {
        return (dokumenRaw['data'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      if (dokumenRaw is List) {
        return dokumenRaw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    return [];
  }

  Future<Map<String, dynamic>> getRiwayatVersiDokumen({
    required int dokumenId,
    int perPage = 30,
  }) {
    return _client.get(
      '/dosen/dokumen/$dokumenId/versi',
      query: {'per_page': perPage},
    );
  }

  Future<List<Map<String, dynamic>>> getRiwayatVersiDokumenList({
    required int dokumenId,
    int perPage = 30,
  }) async {
    final decoded = await getRiwayatVersiDokumen(
      dokumenId: dokumenId,
      perPage: perPage,
    );

    final rootData = decoded['data'];

    if (rootData is Map<String, dynamic>) {
      final versiRaw = rootData['versi'];

      if (versiRaw is Map<String, dynamic> && versiRaw['data'] is List) {
        return (versiRaw['data'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      if (versiRaw is List) {
        return versiRaw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    return [];
  }

  Future<Map<String, dynamic>> getFeedback() {
    return _client.get('/dosen/feedback');
  }

  Future<Map<String, dynamic>> storeFeedback({
    required int versiId,
    required String komentar,
    int? halaman,
    String? posisiAnotasi,
  }) {
    return _client.post(
      '/dosen/feedback',
      body: {
        'versi_id': versiId,
        'komentar': komentar.trim(),
        if (halaman != null) 'halaman': halaman,
        if (posisiAnotasi != null && posisiAnotasi.trim().isNotEmpty)
          'posisi_anotasi': posisiAnotasi.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> getJadwal({
    String? status,
    int perPage = 50,
  }) {
    return _client.get(
      '/dosen/jadwal',
      query: {
        'status': status,
        'per_page': perPage,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getJadwalList({
    String? status,
    int perPage = 50,
  }) async {
    final decoded = await getJadwal(
      status: status,
      perPage: perPage,
    );

    return _extractPaginatorList(decoded);
  }

  Future<Map<String, dynamic>> konfirmasiJadwal(
    int id, {
    required String statusKonfirmasi,
    String? mode,
    String? catatan,
  }) {
    return _client.put(
      '/dosen/jadwal/$id/konfirmasi',
      body: {
        'status_konfirmasi': statusKonfirmasi,
        if (mode != null && mode.trim().isNotEmpty) 'mode': mode.trim(),
        if (catatan != null && catatan.trim().isNotEmpty)
          'catatan': catatan.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> getNotifikasi() {
    return _client.get('/dosen/notifikasi');
  }

  Future<Map<String, dynamic>> updateProfile({
    required String nama,
    required String kuotaBimbingan,
    String? password,
    String? passwordConfirmation,
    PlatformFile? avatarFile, // Ubah penamaan variabel
  }) {
    final hasPassword = password != null && password.isNotEmpty;

    return _client.multipart(
      'POST',
      '/dosen/profile',
      fields: {
        '_method': 'PUT',
        'nama': nama,
        'kuota_bimbingan': kuotaBimbingan,
        if (hasPassword) 'password': password,
        if (hasPassword) 'password_confirmation': passwordConfirmation ?? '',
      },
      // Key diubah menjadi 'avatar'
      files: [
        if (avatarFile != null && avatarFile.bytes != null)
          ApiFile.fromBytes('avatar', avatarFile.bytes!, avatarFile.name),
      ],
    );
  }
}
