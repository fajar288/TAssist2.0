import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_config.dart';
import '../../../core/http_client.dart';
import '../../auth/data/auth_service.dart';

class NotifikasiService with AuthInterceptorMixin {
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

  List<Map<String, dynamic>> extractNotifikasiList(Map<String, dynamic> decoded) {
    final rootData = decoded['data'];

    if (rootData is Map<String, dynamic>) {
      final notifikasiRaw = rootData['notifikasi'];

      if (notifikasiRaw is Map<String, dynamic> && notifikasiRaw['data'] is List) {
        return (notifikasiRaw['data'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      if (notifikasiRaw is List) {
        return notifikasiRaw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    return [];
  }

  int extractUnreadCount(Map<String, dynamic> decoded) {
    final rootData = decoded['data'];

    if (rootData is Map<String, dynamic>) {
      final unreadCount = rootData['unread_count'];

      if (unreadCount is int) return unreadCount;
      return int.tryParse(unreadCount?.toString() ?? '') ?? 0;
    }

    return 0;
  }

  Future<Map<String, dynamic>> getNotifikasi({
    bool unreadOnly = false,
    int perPage = 30,
  }) async {
    final response = await http.get(
      _uri('/notifikasi', {
        'unread_only': unreadOnly ? 1 : null,
        'per_page': perPage,
      }),
      headers: await _headers(),
    );

    return _decodeResponse(response);
  }

  Future<List<Map<String, dynamic>>> getNotifikasiList({
    bool unreadOnly = false,
    int perPage = 30,
  }) async {
    final decoded = await getNotifikasi(
      unreadOnly: unreadOnly,
      perPage: perPage,
    );

    return extractNotifikasiList(decoded);
  }

  Future<int> getUnreadCount() async {
    final decoded = await getNotifikasi(perPage: 1);
    return extractUnreadCount(decoded);
  }

  Future<Map<String, dynamic>> markAsRead(int notifikasiId) async {
    final response = await http.put(
      _uri('/notifikasi/$notifikasiId/read'),
      headers: await _headers(),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> markAllAsRead() async {
    final response = await http.put(
      _uri('/notifikasi/read-all'),
      headers: await _headers(),
    );

    return _decodeResponse(response);
  }
}
