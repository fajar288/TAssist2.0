// lib/features/chatbot/data/chatbot_service.dart

import '../../../core/api_client.dart';
import '../../../model/chatbot_model.dart';

class ChatbotService {
  final ApiClient _client;

  ChatbotService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  /// Send a message to the Chatbot (T-31, T-33, T-34, T-35)
  Future<Map<String, dynamic>> sendMessage(String pesan, {int? percakapanId}) async {
    final Map<String, dynamic> body = {
      'pesan': pesan,
    };
    if (percakapanId != null) {
      body['percakapan_id'] = percakapanId;
    }

    final response = await _client.post(
      '/chatbot/pesan',
      body: body,
    );

    final dynamic data = response['data'];
    if (data is Map<String, dynamic>) {
      return {
        'percakapan_id': data['percakapan_id'] is int ? data['percakapan_id'] as int : int.tryParse(data['percakapan_id']?.toString() ?? '0') ?? 0,
        'judul_percakapan': data['judul_percakapan']?.toString() ?? 'Percakapan',
        'pesan_user': data['pesan_user'] is Map ? ChatbotPesanModel.fromJson(Map<String, dynamic>.from(data['pesan_user'] as Map)) : null,
        'pesan_asisten': data['pesan_asisten'] is Map ? ChatbotPesanModel.fromJson(Map<String, dynamic>.from(data['pesan_asisten'] as Map)) : null,
      };
    }

    throw Exception('Format respons chatbot tidak valid.');
  }

  /// List user conversations (T-33, F-BOT-03)
  Future<List<ChatbotPercakapanModel>> getConversations() async {
    final response = await _client.get('/chatbot/percakapan');
    final dynamic data = response['data'];
    if (data is List) {
      return data
          .map((item) => ChatbotPercakapanModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return [];
  }

  /// Get messages of a conversation (T-33, F-BOT-03)
  Future<List<ChatbotPesanModel>> getConversationMessages(int percakapanId) async {
    final response = await _client.get('/chatbot/percakapan/$percakapanId');
    final dynamic data = response['data'];
    if (data is Map && data['pesan'] is List) {
      return (data['pesan'] as List)
          .map((item) => ChatbotPesanModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return [];
  }

  /// Delete a conversation (T-33, F-BOT-03)
  Future<bool> deleteConversation(int percakapanId) async {
    final response = await _client.delete('/chatbot/percakapan/$percakapanId');
    return response['success'] == true;
  }
}
