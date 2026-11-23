// test/chatbot_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:produk/features/chatbot/widget/chat_bubble_widget.dart';
import 'package:produk/features/chatbot/widget/typing_indicator_widget.dart';
import 'package:produk/model/chatbot_model.dart';

void main() {
  group('ChatBubbleWidget', () {
    testWidgets('renders user message bubble correctly', (WidgetTester tester) async {
      final message = ChatbotPesanModel(
        id: 1,
        role: 'user',
        pesan: 'Kapan batas akhir pengumpulan revisi TA?',
        createdAt: DateTime(2026, 11, 23, 14, 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubbleWidget(message: message),
          ),
        ),
      );

      expect(find.text('Kapan batas akhir pengumpulan revisi TA?'), findsOneWidget);
      expect(find.text('14:00'), findsOneWidget);
      // User bubble should not show robot icon
      expect(find.byIcon(Icons.smart_toy_rounded), findsNothing);
    });

    testWidgets('renders assistant message with citations correctly', (WidgetTester tester) async {
      final message = ChatbotPesanModel(
        id: 2,
        role: 'assistant',
        pesan: 'Batas akhir pengumpulan revisi adalah 14 hari kalender setelah sidang.',
        createdAt: DateTime(2026, 11, 23, 14, 1),
        sumber: [
          const ChatbotSumberModel(
            id: 'info_1',
            tipe: 'pedoman',
            judul: 'Buku Panduan TA 2026',
            label: 'Buku Panduan TA 2026 Pasal 12',
          ),
        ],
        metadata: const {
          'is_grounded': true,
          'is_refusal': false,
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubbleWidget(message: message),
          ),
        ),
      );

      expect(find.text('Batas akhir pengumpulan revisi adalah 14 hari kalender setelah sidang.'), findsOneWidget);
      expect(find.text('Buku Panduan TA 2026'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy_rounded), findsOneWidget);
    });

    testWidgets('renders assistant refusal when triggered', (WidgetTester tester) async {
      final message = ChatbotPesanModel(
        id: 3,
        role: 'assistant',
        pesan: 'Pertanyaan ini di luar kewenangan asisten.',
        isRefused: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubbleWidget(message: message),
          ),
        ),
      );

      expect(find.text('Di Luar Cakupan Asisten TA'), findsOneWidget);
      expect(find.text('Pertanyaan ini di luar kewenangan asisten.'), findsOneWidget);
    });
  });

  group('TypingIndicatorWidget', () {
    testWidgets('renders typing animation indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypingIndicatorWidget(),
          ),
        ),
      );

      expect(find.text('Sedang mencari jawaban'), findsOneWidget);
      expect(find.byType(TypingIndicatorWidget), findsOneWidget);
    });
  });
}
