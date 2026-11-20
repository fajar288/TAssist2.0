import '../../../core/api_client.dart';

class NotifikasiService {
  final ApiClient _client = ApiClient.instance;

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
  }) {
    return _client.get(
      '/notifikasi',
      query: {
        'unread_only': unreadOnly ? 1 : null,
        'per_page': perPage,
      },
    );
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

  Future<Map<String, dynamic>> markAsRead(int notifikasiId) {
    return _client.put('/notifikasi/$notifikasiId/read');
  }

  Future<Map<String, dynamic>> markAllAsRead() {
    return _client.put('/notifikasi/read-all');
  }
}
