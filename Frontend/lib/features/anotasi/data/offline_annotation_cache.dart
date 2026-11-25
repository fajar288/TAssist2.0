import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../model/annotation_model.dart';
import 'annotation_service.dart';

class OfflineSyncResult {
  final int syncedCount;
  final int newFromOthersCount;

  const OfflineSyncResult({
    required this.syncedCount,
    required this.newFromOthersCount,
  });
}

/// T-45 (F-DOC-08): Local SQLite + file cache for PDF documents and offline
/// annotation drafts. Guarded by `kIsWeb` so Flutter Web degrades safely.
class OfflineAnnotationCache {
  OfflineAnnotationCache._();

  static final OfflineAnnotationCache instance = OfflineAnnotationCache._();

  Database? _db;

  Future<Database?> _getDb() async {
    if (kIsWeb) return null;
    if (_db != null) return _db;

    final dbRoot = await getDatabasesPath();
    final dbPath = '$dbRoot/tassist_offline_cache.db';

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_pdfs (
            versi_id INTEGER PRIMARY KEY,
            file_path TEXT NOT NULL,
            cached_at TEXT NOT NULL,
            last_sync_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE cached_annotations (
            anotasi_id INTEGER PRIMARY KEY,
            versi_id INTEGER NOT NULL,
            payload_json TEXT NOT NULL,
            updated_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE draft_annotations (
            local_id INTEGER PRIMARY KEY AUTOINCREMENT,
            versi_id INTEGER NOT NULL,
            halaman INTEGER NOT NULL,
            x REAL NOT NULL,
            y REAL NOT NULL,
            tipe TEXT NOT NULL,
            konten TEXT NOT NULL,
            created_at TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );

    return _db;
  }

  Future<String?> cachePdfFromUrl(int versiId, String signedUrl) async {
    if (kIsWeb) return null;

    try {
      final response = await http
          .get(Uri.parse(signedUrl))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/offline_pdfs');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final file = File('${cacheDir.path}/versi_$versiId.pdf');
      await file.writeAsBytes(response.bodyBytes, flush: true);

      final db = await _getDb();
      await db?.insert(
        'cached_pdfs',
        {
          'versi_id': versiId,
          'file_path': file.path,
          'cached_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return file.path;
    } catch (e) {
      debugPrint('OfflineAnnotationCache: cachePdfFromUrl failed: $e');
      return null;
    }
  }

  Future<String?> getCachedPdfPath(int versiId) async {
    if (kIsWeb) return null;

    try {
      final db = await _getDb();
      if (db == null) return null;

      final rows = await db.query(
        'cached_pdfs',
        where: 'versi_id = ?',
        whereArgs: [versiId],
        limit: 1,
      );

      if (rows.isEmpty) return null;

      final path = rows.first['file_path']?.toString();
      if (path == null || path.isEmpty) return null;

      final file = File(path);
      if (!await file.exists()) return null;

      return path;
    } catch (e) {
      debugPrint('OfflineAnnotationCache: getCachedPdfPath failed: $e');
      return null;
    }
  }

  Future<void> saveServerAnnotations(
    int versiId,
    List<AnnotationModel> annotations,
  ) async {
    if (kIsWeb) return;

    final db = await _getDb();
    if (db == null) return;

    final batch = db.batch();
    batch.delete('cached_annotations', where: 'versi_id = ?', whereArgs: [versiId]);

    for (final item in annotations) {
      batch.insert(
        'cached_annotations',
        {
          'anotasi_id': item.anotasiId,
          'versi_id': versiId,
          'payload_json': jsonEncode(item.toJson()),
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    await db.update(
      'cached_pdfs',
      {'last_sync_at': DateTime.now().toIso8601String()},
      where: 'versi_id = ?',
      whereArgs: [versiId],
    );
  }

  Future<List<AnnotationModel>> getCachedAnnotations(int versiId) async {
    if (kIsWeb) return [];

    final db = await _getDb();
    if (db == null) return [];

    final rows = await db.query(
      'cached_annotations',
      where: 'versi_id = ?',
      whereArgs: [versiId],
    );

    final list = <AnnotationModel>[];
    for (final row in rows) {
      try {
        final decoded = jsonDecode(row['payload_json'].toString());
        if (decoded is Map) {
          list.add(AnnotationModel.fromJson(Map<String, dynamic>.from(decoded)));
        }
      } catch (e) {
        debugPrint('OfflineAnnotationCache: parse cached annotation failed: $e');
      }
    }

    return list;
  }

  Future<int> saveDraftAnnotation({
    required int versiId,
    required int halaman,
    required double x,
    required double y,
    required String tipe,
    required String konten,
  }) async {
    if (kIsWeb) return -1;

    final db = await _getDb();
    if (db == null) return -1;

    return db.insert('draft_annotations', {
      'versi_id': versiId,
      'halaman': halaman,
      'x': x,
      'y': y,
      'tipe': tipe,
      'konten': konten,
      'created_at': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  Future<List<AnnotationModel>> getPendingDraftModels(int versiId) async {
    if (kIsWeb) return [];

    final db = await _getDb();
    if (db == null) return [];

    final rows = await db.query(
      'draft_annotations',
      where: 'versi_id = ? AND synced = 0',
      whereArgs: [versiId],
      orderBy: 'local_id ASC',
    );

    return rows.map((row) {
      final localId = int.tryParse(row['local_id']?.toString() ?? '') ?? 0;
      return AnnotationModel(
        anotasiId: -localId,
        versiId: versiId,
        userId: 0,
        halaman: int.tryParse(row['halaman']?.toString() ?? '') ?? 1,
        x: double.tryParse(row['x']?.toString() ?? '') ?? 0.0,
        y: double.tryParse(row['y']?.toString() ?? '') ?? 0.0,
        tipe: _parseType(row['tipe']?.toString()),
        konten: row['konten']?.toString(),
        status: AnnotationStatus.open,
        createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
        authorName: 'Draft Offline',
        authorRole: 'dosen',
        isLocalDraft: true,
      );
    }).toList();
  }

  Future<OfflineSyncResult> syncDraftsAndCheckConflicts({
    required int versiId,
    required AnnotationService service,
    required bool isDosen,
  }) async {
    if (kIsWeb) {
      return const OfflineSyncResult(syncedCount: 0, newFromOthersCount: 0);
    }

    final db = await _getDb();
    if (db == null) {
      return const OfflineSyncResult(syncedCount: 0, newFromOthersCount: 0);
    }

    final previouslyCached = await getCachedAnnotations(versiId);
    final cachedIds = previouslyCached.map((a) => a.anotasiId).toSet();

    final serverBefore = isDosen
        ? await service.getAnnotationsForDosen(versiId)
        : await service.getAnnotationsForMahasiswa(versiId);

    final newFromOthersCount = previouslyCached.isEmpty
        ? 0
        : serverBefore.where((a) => !cachedIds.contains(a.anotasiId)).length;

    int syncedCount = 0;

    if (isDosen) {
      final pendingRows = await db.query(
        'draft_annotations',
        where: 'versi_id = ? AND synced = 0',
        whereArgs: [versiId],
        orderBy: 'local_id ASC',
      );

      for (final row in pendingRows) {
        final localId = row['local_id'] as int;
        await service.createAnnotation(
          versiId: versiId,
          halaman: (row['halaman'] as num).toInt(),
          x: (row['x'] as num).toDouble(),
          y: (row['y'] as num).toDouble(),
          tipe: row['tipe'].toString(),
          konten: row['konten'].toString(),
        );

        await db.update(
          'draft_annotations',
          {'synced': 1},
          where: 'local_id = ?',
          whereArgs: [localId],
        );
        syncedCount++;
      }
    }

    final refreshed = isDosen
        ? await service.getAnnotationsForDosen(versiId)
        : await service.getAnnotationsForMahasiswa(versiId);
    await saveServerAnnotations(versiId, refreshed);

    return OfflineSyncResult(
      syncedCount: syncedCount,
      newFromOthersCount: newFromOthersCount,
    );
  }

  AnnotationType _parseType(String? val) {
    switch (val?.toLowerCase()) {
      case 'highlight':
        return AnnotationType.highlight;
      case 'coretan':
        return AnnotationType.coretan;
      default:
        return AnnotationType.komentar;
    }
  }
}
