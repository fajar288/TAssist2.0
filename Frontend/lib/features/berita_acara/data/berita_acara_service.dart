// lib/features/berita_acara/data/berita_acara_service.dart

import 'dart:typed_data';

import '../../../../core/api_client.dart';
import '../../../../model/berita_acara_model.dart';

class BeritaAcaraService {
  final ApiClient _client = ApiClient.instance;

  /// Fetch Berita Acara list for Mahasiswa
  Future<List<BeritaAcaraModel>> getBeritaAcaraMahasiswa(int bimbinganId) async {
    final response = await _client.get('/mahasiswa/bimbingan/$bimbinganId/berita-acara');
    final dynamic data = response['data'];
    if (data is List) {
      return data
          .map((item) => BeritaAcaraModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return [];
  }

  /// Fetch Berita Acara list for Dosen
  Future<List<BeritaAcaraModel>> getBeritaAcaraDosen(int bimbinganId) async {
    final response = await _client.get('/dosen/bimbingan/$bimbinganId/berita-acara');
    final dynamic data = response['data'];
    if (data is List) {
      return data
          .map((item) => BeritaAcaraModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return [];
  }

  /// Generate draft Berita Acara for a period (Dosen)
  Future<BeritaAcaraModel> generateBeritaAcara(
    int bimbinganId, {
    required DateTime periodeMulai,
    required DateTime periodeSelesai,
  }) async {
    String formatDate(DateTime dt) {
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }

    final response = await _client.post(
      '/dosen/bimbingan/$bimbinganId/berita-acara',
      body: {
        'periode_mulai': formatDate(periodeMulai),
        'periode_selesai': formatDate(periodeSelesai),
      },
    );

    final dynamic data = response['data'];
    if (data is Map) {
      return BeritaAcaraModel.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Respons pembuatan Berita Acara tidak valid.');
  }

  /// Approve Berita Acara via PIN (Dosen)
  Future<BeritaAcaraModel> approveWithPin(int beritaAcaraId, String pin) async {
    final response = await _client.put(
      '/dosen/berita-acara/$beritaAcaraId/approve',
      body: {
        'metode': 'pin',
        'pin': pin,
      },
    );

    final dynamic data = response['data'];
    if (data is Map) {
      return BeritaAcaraModel.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Respons persetujuan Berita Acara tidak valid.');
  }

  /// Approve Berita Acara via drawn signature (Dosen)
  Future<BeritaAcaraModel> approveWithSignature(
    int beritaAcaraId,
    Uint8List signatureBytes,
  ) async {
    final response = await _client.multipart(
      'POST',
      '/dosen/berita-acara/$beritaAcaraId/approve',
      fields: {
        '_method': 'PUT',
        'metode': 'tanda_tangan',
      },
      files: [
        ApiFile(
          field: 'tanda_tangan',
          filename: 'signature_$beritaAcaraId.png',
          bytes: signatureBytes,
        ),
      ],
    );

    final dynamic data = response['data'];
    if (data is Map) {
      return BeritaAcaraModel.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Respons persetujuan tanda tangan tidak valid.');
  }

  /// Get signed URL for downloading Berita Acara PDF
  Future<String> getDownloadSignedUrl(int beritaAcaraId) async {
    final response = await _client.get('/berita-acara/$beritaAcaraId/download');
    final dynamic data = response['data'];
    if (data is Map && data['url'] != null) {
      return data['url'].toString();
    }
    throw Exception('Gagal mendapatkan URL unduhan Berita Acara.');
  }
}
