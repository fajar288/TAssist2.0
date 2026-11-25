import 'package:flutter_test/flutter_test.dart';
import 'package:produk/core/fcm_service.dart';
import 'package:produk/model/annotation_model.dart';
import 'package:produk/model/models.dart';

void main() {
  group('Wave 5 models and services', () {
    test('CounselingRequest parses file_proposal and proposal_url', () {
      final req = CounselingRequest.fromPermohonanJson({
        'permohonan_id': 42,
        'topik_ta': 'Sistem Monitoring TA',
        'tanggal_pengajuan': '2026-11-25',
        'status': 'menunggu',
        'file_proposal': 'proposal_ta.pdf',
        'proposal_url': 'https://example.test/api/v1/permohonan/42/proposal-file?signature=abc',
        'mahasiswa': {
          'nama': 'Budi',
          'nim': '3312201001',
          'prodi': 'Teknik Informatika',
        },
      });

      expect(req.id, '42');
      expect(req.fileProposal, 'proposal_ta.pdf');
      expect(req.proposalUrl, contains('/permohonan/42/proposal-file'));
    });

    test('AnnotationModel round-trips toJson and fromJson for offline cache', () {
      final original = AnnotationModel(
        anotasiId: 7,
        versiId: 12,
        dosenId: 3,
        userId: 9,
        halaman: 2,
        x: 0.45,
        y: 0.65,
        tipe: AnnotationType.komentar,
        konten: 'Perbaiki sitasi Bab 2',
        status: AnnotationStatus.open,
        authorName: 'Dr. Ani',
        authorRole: 'dosen',
        createdAt: DateTime.parse('2026-11-25T08:00:00Z'),
        isLocalDraft: true,
      );

      final encoded = original.toJson();
      final decoded = AnnotationModel.fromJson(encoded);

      expect(decoded.anotasiId, 7);
      expect(decoded.versiId, 12);
      expect(decoded.halaman, 2);
      expect(decoded.x, closeTo(0.45, 0.001));
      expect(decoded.y, closeTo(0.65, 0.001));
      expect(decoded.konten, 'Perbaiki sitasi Bab 2');
      expect(decoded.isLocalDraft, isTrue);
    });

    test('FcmService.init degrades safely without Firebase native config', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await FcmService.instance.init();
      expect(FcmService.instance.isFirebaseReady, isFalse);
    });
  });
}
