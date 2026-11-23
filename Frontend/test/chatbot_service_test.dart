// test/chatbot_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:produk/core/api_client.dart';
import 'package:produk/features/chatbot/data/chatbot_service.dart';

class FakeApiClient implements ApiClient {
  String? lastPath;
  String? lastMethod;
  dynamic lastBody;

  Map<String, dynamic> responseToReturn = {};

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool authenticated = true,
    bool retryOnUnauthorized = true,
    bool expireSessionOnUnauthorized = true,
  }) async {
    lastPath = path;
    lastMethod = 'GET';
    return responseToReturn;
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool authenticated = true,
    bool retryOnUnauthorized = true,
    bool expireSessionOnUnauthorized = true,
  }) async {
    lastPath = path;
    lastMethod = 'POST';
    lastBody = body;
    return responseToReturn;
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool authenticated = true,
    bool retryOnUnauthorized = true,
    bool expireSessionOnUnauthorized = true,
  }) async {
    lastPath = path;
    lastMethod = 'DELETE';
    return responseToReturn;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ChatbotService', () {
    late FakeApiClient fakeClient;
    late ChatbotService service;

    setUp(() {
      fakeClient = FakeApiClient();
      service = ChatbotService(client: fakeClient);
    });

    test('sendMessage sends correct payload and parses response', () async {
      fakeClient.responseToReturn = {
        'success': true,
        'data': {
          'percakapan_id': 88,
          'judul_percakapan': 'Alur Sidang',
          'pesan_user': {
            'pesan_id': 1,
            'role': 'user',
            'konten': 'Apa syarat sidang?',
          },
          'pesan_asisten': {
            'pesan_id': 2,
            'role': 'assistant',
            'konten': 'Syarat sidang adalah...',
            'sumber': [],
            'metadata': {'is_grounded': true},
          },
        },
      };

      final result = await service.sendMessage('Apa syarat sidang?', percakapanId: 88);

      expect(fakeClient.lastPath, '/chatbot/pesan');
      expect(fakeClient.lastMethod, 'POST');
      expect(fakeClient.lastBody, {
        'pesan': 'Apa syarat sidang?',
        'percakapan_id': 88,
      });

      expect(result['percakapan_id'], 88);
      expect(result['judul_percakapan'], 'Alur Sidang');
      expect(result['pesan_user']?.konten, 'Apa syarat sidang?');
      expect(result['pesan_asisten']?.konten, 'Syarat sidang adalah...');
      expect(result['pesan_asisten']?.isGrounded, isTrue);
    });

    test('getConversations parses list of conversations', () async {
      fakeClient.responseToReturn = {
        'success': true,
        'data': [
          {
            'percakapan_id': 1,
            'user_id': 10,
            'judul': 'Konsultasi Judul',
            'created_at': '2026-11-23T08:00:00.000000Z',
          },
          {
            'percakapan_id': 2,
            'user_id': 10,
            'judul': 'Format Penulisan',
            'created_at': '2026-11-23T09:00:00.000000Z',
          },
        ],
      };

      final list = await service.getConversations();

      expect(fakeClient.lastPath, '/chatbot/percakapan');
      expect(fakeClient.lastMethod, 'GET');
      expect(list.length, 2);
      expect(list[0].judul, 'Konsultasi Judul');
      expect(list[1].judul, 'Format Penulisan');
    });

    test('getConversationMessages parses messages of a conversation', () async {
      fakeClient.responseToReturn = {
        'success': true,
        'data': {
          'percakapan_id': 1,
          'pesan': [
            {
              'pesan_id': 10,
              'role': 'user',
              'konten': 'Halo',
            },
            {
              'pesan_id': 11,
              'role': 'assistant',
              'konten': 'Halo! Ada yang bisa saya bantu terkait TA?',
            },
          ],
        },
      };

      final messages = await service.getConversationMessages(1);

      expect(fakeClient.lastPath, '/chatbot/percakapan/1');
      expect(fakeClient.lastMethod, 'GET');
      expect(messages.length, 2);
      expect(messages[0].konten, 'Halo');
      expect(messages[1].isAssistant, isTrue);
    });

    test('deleteConversation invokes DELETE and returns true', () async {
      fakeClient.responseToReturn = {
        'success': true,
      };

      final success = await service.deleteConversation(1);

      expect(fakeClient.lastPath, '/chatbot/percakapan/1');
      expect(fakeClient.lastMethod, 'DELETE');
      expect(success, isTrue);
    });
  });
}
