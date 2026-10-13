import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

import '../../../core/api_config.dart';
import '../../../core/http_client.dart';
import '../../auth/data/auth_service.dart';

class DosenService with AuthInterceptorMixin {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }

    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    if (query == null || query.isEmpty) return uri;

    final cleanQuery = <String, String>{};

    query.forEach((key, value) {
      if (value != null && value.toString().trim().isNotEmpty) {
        cleanQuery[key] = value.toString();
      }
    });

    return uri.replace(queryParameters: cleanQuery);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    dynamic decodedBody;

    try {
      decodedBody = jsonDecode(response.body);
    } catch (_) {
      checkUnauthorized(response);
      throw Exception('Response server tidak valid. Status: ${response.statusCode}');
    }

    if (decodedBody is! Map) {
      throw Exception('Format response server tidak valid.');
    }

    final decoded = Map<String, dynamic>.from(decodedBody);
    final success = decoded['success'] == true;

    if (response.statusCode < 200 || response.statusCode >= 300 || !success) {
      checkUnauthorized(response);
      throw Exception(_errorMessageFromDecoded(decoded));
    }

    return decoded;
  }

  String _errorMessageFromDecoded(Map<String, dynamic> decoded) {
    final message = decoded['message']?.toString() ?? 'Request gagal.';
    final errors = decoded['errors'];

    if (errors is Map && errors.isNotEmpty) {
      final details = <String>[];

      errors.forEach((_, value) {
        if (value is List) {
          details.addAll(value.map((item) => item.toString()));
        } else if (value != null) {
          details.add(value.toString());
        }
      });

      if (details.isNotEmpty) {
        return '$message\n${details.join('\n')}';
      }
    }

    return message;
  }

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

  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      _uri('/dosen/profile'),
      headers: await _headers(),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> getPermohonan({
    String? status,
    int perPage = 50,
  }) async {
    final response = await http.get(
      _uri('/dosen/permohonan', {
        'status': status,
        'per_page': perPage,
      }),
      headers: await _headers(),
    );

    return _decodeResponse(response);
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

  Future<Map<String, dynamic>> terimaPermohonan(int id) async {
    final response = await http.put(
      _uri('/dosen/permohonan/$id/terima'),
      headers: await _headers(),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> tolakPermohonan(
    int id, {
    required String catatanRespons,
  }) async {
    final response = await http.put(
      _uri('/dosen/permohonan/$id/tolak'),
      headers: await _headers(json: true),
      body: jsonEncode({
        'catatan_respons': catatanRespons.trim(),
      }),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> getMahasiswaBimbingan({
    String? status,
    int perPage = 30,
  }) async {
    final response = await http.get(
      _uri('/dosen/mahasiswa-bimbingan', {
        'status': status,
        'per_page': perPage,
      }),
      headers: await _headers(),
    );

    return _decodeResponse(response);
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

  Future<Map<String, dynamic>> getProgresMahasiswa(int bimbinganId) async {
    final response = await http.get(
      _uri('/dosen/mahasiswa-bimbingan/$bimbinganId/progres'),
      headers: await _headers(),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> updateProgresTA({
    required int bimbinganId,
    required double persentase,
    required String statusProgress,
    String? catatan,
  }) async {
    final body = <String, dynamic>{
      'persentase': persentase,
      'status_progress': statusProgress.trim(),
      if (catatan != null && catatan.trim().isNotEmpty)
        'catatan': catatan.trim(),
    };

    final response = await http.put(
      _uri('/dosen/progres/$bimbinganId'),
      headers: await _headers(json: true),
      body: jsonEncode(body),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> tambahChecklistProgress({
    required int progressId,
    required String namaItem,
    bool tglSelesai = false,
    String? tanggalSelesai,
    String? catatan,
  }) async {
    final body = <String, dynamic>{
      'nama_item': namaItem.trim(),
      'tgl_selesai': tglSelesai,
      if (tanggalSelesai != null && tanggalSelesai.trim().isNotEmpty)
        'tanggal_selesai': tanggalSelesai.trim(),
      if (catatan != null && catatan.trim().isNotEmpty)
        'catatan': catatan.trim(),
    };

    final response = await http.post(
      _uri('/dosen/progres/$progressId/checklist'),
      headers: await _headers(json: true),
      body: jsonEncode(body),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> updateChecklistProgress({
    required int checklistId,
    required String namaItem,
    required bool tglSelesai,
    String? tanggalSelesai,
    String? catatan,
  }) async {
    final body = <String, dynamic>{
      'nama_item': namaItem.trim(),
      'tgl_selesai': tglSelesai,
      if (tanggalSelesai != null && tanggalSelesai.trim().isNotEmpty)
        'tanggal_selesai': tanggalSelesai.trim(),
      if (catatan != null && catatan.trim().isNotEmpty)
        'catatan': catatan.trim(),
    };

    final response = await http.put(
      _uri('/dosen/checklist/$checklistId'),
      headers: await _headers(json: true),
      body: jsonEncode(body),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> hapusChecklistProgress(int checklistId) async {
    final response = await http.delete(
      _uri('/dosen/checklist/$checklistId'),
      headers: await _headers(),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> getDokumenMahasiswa({
    required int bimbinganId,
    int perPage = 30,
  }) async {
    final response = await http.get(
      _uri('/dosen/mahasiswa-bimbingan/$bimbinganId/dokumen', {
        'per_page': perPage,
      }),
      headers: await _headers(),
    );

    return _decodeResponse(response);
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
  }) async {
    final response = await http.get(
      _uri('/dosen/dokumen/$dokumenId/versi', {
        'per_page': perPage,
      }),
      headers: await _headers(),
    );

    return _decodeResponse(response);
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

  Future<Map<String, dynamic>> getFeedback() async {
    final response = await http.get(
      _uri('/dosen/feedback'),
      headers: await _headers(),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> storeFeedback({
    required int versiId,
    required String komentar,
    int? halaman,
    String? posisiAnotasi,
  }) async {
    final body = <String, dynamic>{
      'versi_id': versiId,
      'komentar': komentar.trim(),
      if (halaman != null) 'halaman': halaman,
      if (posisiAnotasi != null && posisiAnotasi.trim().isNotEmpty)
        'posisi_anotasi': posisiAnotasi.trim(),
    };

    final response = await http.post(
      _uri('/dosen/feedback'),
      headers: await _headers(json: true),
      body: jsonEncode(body),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> getJadwal({
    String? status,
    int perPage = 50,
  }) async {
    final response = await http.get(
      _uri('/dosen/jadwal', {
        'status': status,
        'per_page': perPage,
      }),
      headers: await _headers(),
    );

    return _decodeResponse(response);
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
  }) async {
    final body = <String, dynamic>{
      'status_konfirmasi': statusKonfirmasi,
      if (mode != null && mode.trim().isNotEmpty) 'mode': mode.trim(),
      if (catatan != null && catatan.trim().isNotEmpty)
        'catatan': catatan.trim(),
    };

    final response = await http.put(
      _uri('/dosen/jadwal/$id/konfirmasi'),
      headers: await _headers(json: true),
      body: jsonEncode(body),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> getNotifikasi() async {
    final response = await http.get(
      _uri('/dosen/notifikasi'),
      headers: await _headers(),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String nama,
    required String kuotaBimbingan,
    String? password,
    String? passwordConfirmation,
    PlatformFile? avatarFile, // Ubah penamaan variabel
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      var uri = Uri.parse('${ApiConfig.baseUrl}/dosen/profile');
      var request = http.MultipartRequest('POST', uri);

      request.fields['_method'] = 'PUT'; 
      
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['nama'] = nama;
      request.fields['kuota_bimbingan'] = kuotaBimbingan;

      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
        request.fields['password_confirmation'] = passwordConfirmation ?? '';
      }

      // Key diubah menjadi 'avatar'
      if (avatarFile != null && avatarFile.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'avatar', 
            avatarFile.bytes!,
            filename: avatarFile.name,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Gagal update profil');
      }
    } catch (e) {
      rethrow;
    }
  }
}
