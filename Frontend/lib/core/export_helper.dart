import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_client.dart';

/// Downloads supervision history exports (`GET /{role}/bimbingan/{id}/export?format=pdf|excel`)
/// with the active Sanctum bearer token (T-41 / F-DOC-07).
class ExportHelper {
  static Future<void> exportBimbinganHistory(
    BuildContext context, {
    required String rolePrefix, // 'mahasiswa' or 'dosen'
    required int bimbinganId,
    required String format, // 'pdf' or 'excel'
  }) async {
    final token = await ApiClient.instance.tokenStore.read();
    if (token == null || token.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi login tidak ditemukan.')),
        );
      }
      return;
    }

    final url =
        '${ApiClient.instance.baseUrl}/$rolePrefix/bimbingan/$bimbinganId/export?format=$format';

    if (kIsWeb) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unduh melalui endpoint terautentikasi: $url')),
        );
      }
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Gagal mengekspor (${response.statusCode})');
      }

      final dir = await getTemporaryDirectory();
      final ext = format == 'pdf' ? 'pdf' : 'xlsx';
      final file = File('${dir.path}/riwayat_bimbingan_$bimbinganId.$ext');
      await file.writeAsBytes(response.bodyBytes, flush: true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File ekspor tersimpan: ${file.path}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      final uri = Uri.file(file.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor riwayat: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
