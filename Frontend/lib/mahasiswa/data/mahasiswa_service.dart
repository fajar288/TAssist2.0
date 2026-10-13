import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../../../core/api_config.dart';
import '../../../core/http_client.dart';
import '../../features/auth/data/auth_service.dart';

class MahasiswaService with AuthInterceptorMixin {
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

    if (query == null || query.isEmpty) {
      return uri;
    }

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
      // Check for 401 before throwing parse errors.
      checkUnauthorized(response);
      throw Exception(
        'Response server tidak valid. Status: ${response.statusCode}',
      );
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

  Future<void> _attachFileToRequest({
    required http.MultipartRequest request,
    required PlatformFile file,
  }) async {
    if (file.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ),
      );
      return;
    }

    if (file.path != null && file.path!.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: file.name,
        ),
      );
      return;
    }

    throw Exception('File tidak valid atau tidak bisa dibaca.');
  }

  Future<List<Map<String, dynamic>>> getBimbingan({
    int perPage = 10,
  }) async {
    final response = await http.get(
      _uri('/mahasiswa/bimbingan', {
        'per_page': perPage,
      }),
      headers: await _headers(),
    );

    final decoded = _decodeResponse(response);
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

    final response = await http.get(
      _uri('/mahasiswa/dosen', query),
      headers: await _headers(),
    );

    final decoded = _decodeResponse(response);
    return _extractList(decoded);
  }

  Future<List<Map<String, dynamic>>> getPermohonan({
    int perPage = 20,
  }) async {
    final response = await http.get(
      _uri('/mahasiswa/permohonan', {
        'per_page': perPage,
      }),
      headers: await _headers(),
    );

    final decoded = _decodeResponse(response);
    return _extractList(decoded);
  }

  Future<Map<String, dynamic>> ajukanPermohonan({
    required int dosenId,
    required String topikTa,
  }) async {
    final response = await http.post(
      _uri('/mahasiswa/permohonan'),
      headers: await _headers(json: true),
      body: jsonEncode({
        'dosen_id': dosenId,
        'topik_ta': topikTa.trim(),
      }),
    );

    final decoded = _decodeResponse(response);

    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    return {};
  }

  Future<List<Map<String, dynamic>>> getJadwal({
    int perPage = 20,
  }) async {
    final response = await http.get(
      _uri('/mahasiswa/jadwal', {
        'per_page': perPage,
      }),
      headers: await _headers(),
    );

    final decoded = _decodeResponse(response);
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
    final response = await http.post(
      _uri('/mahasiswa/jadwal'),
      headers: await _headers(json: true),
      body: jsonEncode({
        'bimbingan_id': bimbinganId,
        'tanggal': tanggal,
        'waktu_mulai': waktuMulai,
        'waktu_selesai': waktuSelesai,
        'mode': mode,
        'catatan': catatan?.trim().isEmpty == true ? null : catatan?.trim(),
      }),
    );

    final decoded = _decodeResponse(response);

    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    return {};
  }

  Future<Map<String, dynamic>> getProgres({
    int perPage = 5,
  }) async {
    final response = await http.get(
      _uri('/mahasiswa/progres', {
        'per_page': perPage,
      }),
      headers: await _headers(),
    );

    final decoded = _decodeResponse(response);
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
    final response = await http.get(
      _uri('/mahasiswa/dokumen', {
        'per_page': perPage,
      }),
      headers: await _headers(),
    );

    final decoded = _decodeResponse(response);
    return _extractList(decoded);
  }

  Future<Map<String, dynamic>> uploadDokumen({
    required String jenisDokumen,
    required String judulDokumen,
    String? deskripsi,
    String? catatanRevisi,
    required PlatformFile file,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/mahasiswa/dokumen'),
    );

    request.headers.addAll(await _headers());

    request.fields['jenis_dokumen'] = jenisDokumen.trim();
    request.fields['judul_dokumen'] = judulDokumen.trim();

    if (deskripsi != null && deskripsi.trim().isNotEmpty) {
      request.fields['deskripsi'] = deskripsi.trim();
    }

    if (catatanRevisi != null && catatanRevisi.trim().isNotEmpty) {
      request.fields['catatan_revisi'] = catatanRevisi.trim();
    }

    await _attachFileToRequest(
      request: request,
      file: file,
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final decoded = _decodeResponse(response);

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
    final response = await http.get(
      _uri('/mahasiswa/dokumen/$dokumenId/versi', {
        'per_page': perPage,
      }),
      headers: await _headers(),
    );

    final decoded = _decodeResponse(response);
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
    final request = http.MultipartRequest(
      'POST',
      _uri('/mahasiswa/dokumen/$dokumenId/versi'),
    );

    request.headers.addAll(await _headers());

    if (catatanRevisi != null && catatanRevisi.trim().isNotEmpty) {
      request.fields['catatan_revisi'] = catatanRevisi.trim();
    }

    await _attachFileToRequest(
      request: request,
      file: file,
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final decoded = _decodeResponse(response);

    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    return {};
  }
}
