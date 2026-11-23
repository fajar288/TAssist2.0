// test/chatbot_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:produk/model/chatbot_model.dart';

void main() {
  group('ChatbotSumberModel', () {
    test('parses citation JSON correctly', () {
      final json = {
        'id': 'informasi_ta_1',
        'tipe': 'informasi_ta',
        'judul': 'Panduan Format Penulisan TA',
        'label': 'Dokumen Resmi TA - Panduan Format Penulisan TA',
      };

      final source = ChatbotSumberModel.fromJson(json);

      expect(source.id, 'informasi_ta_1');
      expect(source.tipe, 'informasi_ta');
      expect(source.judul, 'Panduan Format Penulisan TA');
      expect(source.label, 'Dokumen Resmi TA - Panduan Format Penulisan TA');

      final serialized = source.toJson();
      expect(serialized['id'], 'informasi_ta_1');
      expect(serialized['tipe'], 'informasi_ta');
    });

    test('handles fallback defaults gracefully', () {
      final source = ChatbotSumberModel.fromJson({});
      expect(source.id, '');
      expect(source.tipe, 'panduan');
      expect(source.judul, 'Dokumen Resmi');
      expect(source.label, 'Dokumen Resmi');
    });
  });

  group('ChatbotPesanModel', () {
    test('parses user message correctly', () {
      final json = {
        'pesan_id': 101,
        'percakapan_id': 5,
        'role': 'user',
        'konten': 'Bagaimana alur sidang TA?',
        'created_at': '2026-11-23T10:00:00.000000Z',
      };

      final msg = ChatbotPesanModel.fromJson(json);

      expect(msg.pesanId, 101);
      expect(msg.percakapanId, 5);
      expect(msg.role, 'user');
      expect(msg.isUser, isTrue);
      expect(msg.isAssistant, isFalse);
      expect(msg.konten, 'Bagaimana alur sidang TA?');
      expect(msg.isGrounded, isFalse);
      expect(msg.isRefusal, isFalse);
      expect(msg.guardrailTriggered, isFalse);
      expect(msg.sumber, isNull);
    });

    test('parses assistant message with sources and metadata correctly', () {
      final json = {
        'pesan_id': 102,
        'percakapan_id': 5,
        'role': 'assistant',
        'konten': 'Alur sidang TA meliputi pengajuan draft dan persetujuan dosen.',
        'sumber': [
          {
            'id': 'info_2',
            'tipe': 'pedoman',
            'judul': 'Buku Panduan TA 2026',
            'label': 'Buku Panduan TA 2026 Bab 3',
          }
        ],
        'metadata': {
          'is_grounded': true,
          'is_refusal': false,
          'guardrail_triggered': false,
          'redacted': false,
          'model_driver': 'gemini-flash',
        },
        'created_at': '2026-11-23T10:00:05.000000Z',
      };

      final msg = ChatbotPesanModel.fromJson(json);

      expect(msg.pesanId, 102);
      expect(msg.role, 'assistant');
      expect(msg.isUser, isFalse);
      expect(msg.isAssistant, isTrue);
      expect(msg.sumber?.length, 1);
      expect(msg.sumber?.first.judul, 'Buku Panduan TA 2026');
      expect(msg.isGrounded, isTrue);
      expect(msg.isRefusal, isFalse);
      expect(msg.guardrailTriggered, isFalse);
      expect(msg.metadata?['model_driver'], 'gemini-flash');
    });

    test('detects refusal and guardrail metadata flags', () {
      final json = {
        'pesan_id': 103,
        'role': 'assistant',
        'konten': 'Mohon maaf, hal tersebut merupakan kewenangan mutlak dosen pembimbing.',
        'metadata': {
          'is_grounded': false,
          'is_refusal': true,
          'guardrail_triggered': true,
        },
      };

      final msg = ChatbotPesanModel.fromJson(json);

      expect(msg.isRefusal, isTrue);
      expect(msg.guardrailTriggered, isTrue);
      expect(msg.isGrounded, isFalse);
    });
  });

  group('ChatbotPercakapanModel', () {
    test('parses conversation JSON with messages list', () {
      final json = {
        'percakapan_id': 12,
        'user_id': 7,
        'judul': 'Konsultasi Syarat Sidang',
        'status': 'aktif',
        'created_at': '2026-11-23T08:30:00.000000Z',
        'pesan': [
          {
            'pesan_id': 201,
            'role': 'user',
            'konten': 'Syarat pendaftaran sidang apa saja?',
          },
          {
            'pesan_id': 202,
            'role': 'assistant',
            'konten': 'Syarat pendaftaran sidang: draft final, bebas tanggungan, dan approval pembimbing.',
          }
        ],
      };

      final conv = ChatbotPercakapanModel.fromJson(json);

      expect(conv.percakapanId, 12);
      expect(conv.userId, 7);
      expect(conv.judul, 'Konsultasi Syarat Sidang');
      expect(conv.status, 'aktif');
      expect(conv.pesan.length, 2);
      expect(conv.pesan[0].role, 'user');
      expect(conv.pesan[1].role, 'assistant');
    });
  });
}
