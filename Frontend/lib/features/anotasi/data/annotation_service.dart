// lib/features/anotasi/data/annotation_service.dart

import '../../../../core/api_client.dart';
import '../../../../model/annotation_model.dart';

class AnnotationService {
  final ApiClient _client = ApiClient.instance;

  /// Fetch signed URL for viewing document version PDF
  Future<String> getSignedUrl(int versiId) async {
    final response = await _client.get('/dokumen/signed-url/$versiId');
    final data = response['data'];
    if (data is Map && data['url'] != null) {
      return data['url'].toString();
    }
    throw Exception('Gagal mendapatkan signed URL dokumen.');
  }

  /// Fetch annotations for Mahasiswa
  Future<List<AnnotationModel>> getAnnotationsForMahasiswa(
    int versiId, {
    String? status,
    String? tipe,
  }) async {
    final queryParams = <String, String>{};
    if (status != null && status != 'all') queryParams['status'] = status;
    if (tipe != null && tipe != 'all') queryParams['tipe'] = tipe;

    final queryStr = queryParams.isNotEmpty ? '?${Uri(queryParameters: queryParams).query}' : '';
    final response = await _client.get('/mahasiswa/dokumen/$versiId/anotasi$queryStr');

    final List<dynamic> list = response['data'] is List ? response['data'] as List : [];
    return list
        .map((item) => AnnotationModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  /// Fetch annotations for Dosen
  Future<List<AnnotationModel>> getAnnotationsForDosen(
    int versiId, {
    String? status,
    String? tipe,
  }) async {
    final queryParams = <String, String>{};
    if (status != null && status != 'all') queryParams['status'] = status;
    if (tipe != null && tipe != 'all') queryParams['tipe'] = tipe;

    final queryStr = queryParams.isNotEmpty ? '?${Uri(queryParameters: queryParams).query}' : '';
    final response = await _client.get('/dosen/dokumen/$versiId/anotasi$queryStr');

    final List<dynamic> list = response['data'] is List ? response['data'] as List : [];
    return list
        .map((item) => AnnotationModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  /// Dosen creates an annotation
  Future<AnnotationModel> createAnnotation({
    required int versiId,
    required int halaman,
    required double x,
    required double y,
    double? lebar,
    double? tinggi,
    required String tipe,
    String? konten,
    List<dynamic>? dataCoretan,
  }) async {
    final response = await _client.post(
      '/dosen/anotasi',
      body: {
        'versi_id': versiId,
        'halaman': halaman,
        'x': x,
        'y': y,
        'lebar': lebar,
        'tinggi': tinggi,
        'tipe': tipe,
        'konten': konten,
        'data_coretan': dataCoretan,
      },
    );

    return AnnotationModel.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  /// Mahasiswa marks annotation as revised
  Future<void> markRevised(int anotasiId) async {
    await _client.put('/mahasiswa/anotasi/$anotasiId/revised');
  }

  /// Dosen marks annotation as resolved
  Future<void> markResolved(int anotasiId) async {
    await _client.put('/dosen/anotasi/$anotasiId/resolved');
  }

  /// Reply to an annotation
  Future<AnnotationReplyModel> reply({
    required int anotasiId,
    required String konten,
    required bool isDosen,
  }) async {
    final endpoint = isDosen
        ? '/dosen/anotasi/$anotasiId/reply'
        : '/mahasiswa/anotasi/$anotasiId/reply';

    final response = await _client.post(endpoint, body: {'konten': konten});
    return AnnotationReplyModel.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  /// Fetch cross-version annotation summary
  Future<Map<String, dynamic>> getCrossVersionSummary(int dokumenId) async {
    final response = await _client.get('/dokumen/$dokumenId/anotasi-summary');
    return Map<String, dynamic>.from(response['data'] as Map);
  }
}
