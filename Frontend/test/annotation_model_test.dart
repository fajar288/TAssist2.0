// test/annotation_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:tassist/model/annotation_model.dart';

void main() {
  group('AnnotationModel', () {
    test('parses annotation JSON with normalized coordinates and replies', () {
      final json = {
        'anotasi_id': 12,
        'versi_id': 34,
        'dosen_id': 5,
        'user_id': 2,
        'parent_id': null,
        'halaman': 2,
        'x': 0.45,
        'y': 0.65,
        'lebar': 0.20,
        'tinggi': 0.05,
        'tipe': 'komentar',
        'konten': 'Tolong tambahkan referensi pada bab ini.',
        'status': 'open',
        'created_at': '2026-11-20T10:00:00.000000Z',
        'dosen': {
          'dosen_id': 5,
          'user': {'nama': 'Dr. Pembimbing'},
        },
        'user': {
          'nama': 'Dr. Pembimbing',
          'role': 'dosen',
        },
        'replies': [
          {
            'anotasi_id': 13,
            'parent_id': 12,
            'user_id': 10,
            'konten': 'Baik pak, sudah diperbaiki.',
            'created_at': '2026-11-20T11:00:00.000000Z',
            'user': {
              'nama': 'Mahasiswa Bimbingan',
              'role': 'mahasiswa',
            },
          }
        ],
      };

      final annotation = AnnotationModel.fromJson(json);

      expect(annotation.anotasiId, 12);
      expect(annotation.versiId, 34);
      expect(annotation.halaman, 2);
      expect(annotation.x, 0.45);
      expect(annotation.y, 0.65);
      expect(annotation.tipe, AnnotationType.komentar);
      expect(annotation.status, AnnotationStatus.open);
      expect(annotation.konten, 'Tolong tambahkan referensi pada bab ini.');
      expect(annotation.authorName, 'Dr. Pembimbing');
      expect(annotation.replies.length, 1);

      final reply = annotation.replies.first;
      expect(reply.anotasiId, 13);
      expect(reply.parentId, 12);
      expect(reply.konten, 'Baik pak, sudah diperbaiki.');
      expect(reply.authorName, 'Mahasiswa Bimbingan');
      expect(reply.authorRole, 'mahasiswa');
    });

    test('parses status revised and resolved correctly', () {
      final jsonRevised = {
        'anotasi_id': 1,
        'versi_id': 1,
        'user_id': 1,
        'halaman': 1,
        'x': 0.1,
        'y': 0.2,
        'tipe': 'highlight',
        'status': 'revised',
      };
      final annotationRevised = AnnotationModel.fromJson(jsonRevised);
      expect(annotationRevised.status, AnnotationStatus.revised);
      expect(annotationRevised.tipe, AnnotationType.highlight);

      final jsonResolved = {
        'anotasi_id': 2,
        'versi_id': 1,
        'user_id': 1,
        'halaman': 1,
        'x': 0.1,
        'y': 0.2,
        'tipe': 'coretan',
        'status': 'resolved',
      };
      final annotationResolved = AnnotationModel.fromJson(jsonResolved);
      expect(annotationResolved.status, AnnotationStatus.resolved);
      expect(annotationResolved.tipe, AnnotationType.coretan);
    });
  });
}
