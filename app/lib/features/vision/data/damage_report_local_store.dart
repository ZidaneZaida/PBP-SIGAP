import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../domain/models/damage_models.dart';

/// Kontrak penyimpanan lokal laporan kerusakan SIGAP-Vision.
///
/// Memungkinkan implementasi utama berbasis SQLite ([SqfliteDamageReportStore])
/// diuji secara terisolasi maupun memiliki fallback aman pada lingkungan
/// pengujian Dart VM tanpa plugin SQLite native.
abstract class DamageReportLocalStore {
  Future<List<DamageScanReport>> getAll();
  Future<void> upsert(DamageScanReport report);
  Future<void> deleteById(String reportId);
  Future<void> markSynced(String reportId, DateTime syncedAt);
}

/// Implementasi penyimpanan lokal berbasis SQLite (`sqflite`) untuk antrean
/// laporan kerusakan offline SIGAP-Vision.
///
/// Database: `sigap_vision.db` (versi 1), tabel: `damage_reports`.
class SqfliteDamageReportStore implements DamageReportLocalStore {
  static const String databaseName = 'sigap_vision.db';
  static const int databaseVersion = 1;
  static const String tableName = 'damage_reports';
  static const String legacySharedPrefsKey = 'sigap_vision_reports_v1';

  static const String createTableSql = '''
CREATE TABLE $tableName (
  id TEXT PRIMARY KEY,
  latitude REAL,
  longitude REAL,
  damage_level TEXT NOT NULL,
  confidence_score REAL NOT NULL,
  description TEXT,
  image_path TEXT NOT NULL,
  sync_status TEXT NOT NULL,
  created_at TEXT NOT NULL,
  synced_at TEXT,
  payload_json TEXT NOT NULL
)
''';

  Database? _database;
  bool _migrationChecked = false;

  /// Mengonversi [DamageScanReport] menjadi baris SQLite `damage_reports`.
  static Map<String, Object?> toDbMap(DamageScanReport report) {
    return {
      'id': report.id,
      'latitude': report.location?.latitude,
      'longitude': report.location?.longitude,
      'damage_level': report.result.category.apiDamageLevel,
      'confidence_score': report.result.confidenceScore ?? 0.0,
      'description': report.result.summary,
      'image_path': report.imagePath,
      'sync_status': report.syncStatus.name,
      'created_at': report.createdAt.toIso8601String(),
      'synced_at': report.syncedAt?.toIso8601String(),
      'payload_json': jsonEncode(report.toJson()),
    };
  }

  /// Mengonversi baris SQLite `damage_reports` kembali menjadi [DamageScanReport].
  ///
  /// Memulihkan metadata lengkap UI dari `payload_json` lalu menyelaraskan
  /// kolom-kolom utama SQLite agar selalu konsisten setelah update parsial.
  static DamageScanReport fromDbMap(Map<String, Object?> row) {
    final rawPayload = row['payload_json'] as String?;
    DamageScanReport? baseReport;
    if (rawPayload != null && rawPayload.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawPayload);
        if (decoded is Map<String, dynamic>) {
          baseReport = DamageScanReport.fromJson(decoded);
        }
      } catch (_) {
        baseReport = null;
      }
    }

    final id = (row['id'] as String?) ?? baseReport?.id ?? '';
    final imagePath =
        (row['image_path'] as String?) ?? baseReport?.imagePath ?? '';
    final createdAt = DateTime.tryParse((row['created_at'] as String?) ?? '') ??
        baseReport?.createdAt ??
        DateTime.now();
    final rawSyncedAt = row['synced_at'] as String?;
    final syncedAt = rawSyncedAt != null
        ? DateTime.tryParse(rawSyncedAt)
        : baseReport?.syncedAt;
    final syncStatus = row['sync_status'] != null
        ? DamageSyncStatus.fromName(row['sync_status'] as String?)
        : (baseReport?.syncStatus ?? DamageSyncStatus.pendingSync);

    final lat = (row['latitude'] as num?)?.toDouble();
    final lng = (row['longitude'] as num?)?.toDouble();
    VisionLocationData? location = baseReport?.location;
    if (lat != null && lng != null) {
      location = VisionLocationData(
        latitude: lat,
        longitude: lng,
        displayLabel: baseReport?.location?.displayLabel ??
            'GPS Perangkat (${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)})',
        capturedAt: baseReport?.location?.capturedAt ?? createdAt,
      );
    }

    final category = row['damage_level'] != null
        ? DamageCategory.fromName(row['damage_level'] as String?)
        : (baseReport?.result.category ?? DamageCategory.ringan);

    final baseResult = baseReport?.result;
    final result = DamageClassificationResult(
      category: category,
      confidenceScore: baseResult != null
          ? baseResult.confidenceScore
          : (row['confidence_score'] as num?)?.toDouble(),
      summary: (row['description'] as String?) ?? baseResult?.summary ?? '',
      recommendations: baseResult?.recommendations ?? const [],
      urgentWarning: baseResult?.urgentWarning,
      isSimulation: baseResult?.isSimulation ?? true,
      classifierName: baseResult?.classifierName ?? 'Classifier',
      analyzedAt: baseResult?.analyzedAt ?? createdAt,
      detectedRegions: baseResult?.detectedRegions ?? const [],
    );

    return DamageScanReport(
      id: id,
      imagePath: imagePath,
      createdAt: createdAt,
      location: location,
      result: result,
      syncStatus: syncStatus,
      syncedAt: syncedAt,
      imageUrl: baseReport?.imageUrl,
    );
  }

  Future<Database> _openDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _migrateLegacySharedPrefsIfNeeded(_database!);
      return _database!;
    }

    final dbRootPath = await getDatabasesPath();
    final fullPath = p.join(dbRootPath, databaseName);

    final db = await openDatabase(
      fullPath,
      version: databaseVersion,
      onCreate: (database, version) async {
        await database.execute(createTableSql);
      },
    );

    _database = db;
    await _migrateLegacySharedPrefsIfNeeded(db);
    return db;
  }

  /// Migrasi satu kali: memindahkan data lama dari `SharedPreferences`
  /// (`sigap_vision_reports_v1`) ke tabel SQLite `damage_reports` jika tabel
  /// masih kosong, lalu membersihkan key lama agar tidak terduplikasi.
  Future<void> _migrateLegacySharedPrefsIfNeeded(Database db) async {
    if (_migrationChecked) return;
    _migrationChecked = true;

    try {
      final countResult =
          await db.rawQuery('SELECT COUNT(*) AS cnt FROM $tableName');
      final existingCount = Sqflite.firstIntValue(countResult) ?? 0;
      if (existingCount > 0) return;

      final prefs = await SharedPreferences.getInstance();
      final rawLegacy = prefs.getString(legacySharedPrefsKey);
      if (rawLegacy == null || rawLegacy.isEmpty) return;

      final decoded = jsonDecode(rawLegacy);
      if (decoded is! List) return;

      final legacyReports = decoded
          .whereType<Map<String, dynamic>>()
          .map(DamageScanReport.fromJson)
          .where((r) => r.id.isNotEmpty)
          .toList();

      if (legacyReports.isEmpty) {
        await prefs.remove(legacySharedPrefsKey);
        return;
      }

      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final report in legacyReports) {
          batch.insert(
            tableName,
            toDbMap(report),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });

      await prefs.remove(legacySharedPrefsKey);
    } catch (_) {
      // Jangan gagalkan akses SQLite bila pembacaan key migrasi lama bermasalah
    }
  }

  @override
  Future<List<DamageScanReport>> getAll() async {
    final db = await _openDatabase();
    final rows = await db.query(
      tableName,
      orderBy: 'created_at DESC',
    );
    return rows.map(fromDbMap).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> upsert(DamageScanReport report) async {
    final db = await _openDatabase();
    await db.insert(
      tableName,
      toDbMap(report),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteById(String reportId) async {
    final db = await _openDatabase();
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [reportId],
    );
  }

  @override
  Future<void> markSynced(String reportId, DateTime syncedAt) async {
    final db = await _openDatabase();
    final existingRows = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [reportId],
      limit: 1,
    );
    if (existingRows.isEmpty) return;

    final current = fromDbMap(existingRows.first);
    final updated = current.copyWith(
      syncStatus: DamageSyncStatus.synced,
      syncedAt: syncedAt,
    );
    await db.update(
      tableName,
      toDbMap(updated),
      where: 'id = ?',
      whereArgs: [reportId],
    );
  }
}

/// Fallback store berbasis `SharedPreferences` untuk lingkungan pengujian Dart VM
/// (`flutter test`) atau platform tanpa plugin SQLite native.
class SharedPrefsFallbackDamageReportStore implements DamageReportLocalStore {
  final String storageKey;

  const SharedPrefsFallbackDamageReportStore({
    this.storageKey = SqfliteDamageReportStore.legacySharedPrefsKey,
  });

  @override
  Future<List<DamageScanReport>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(storageKey);
    if (rawJson == null || rawJson.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawJson);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(DamageScanReport.fromJson)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> upsert(DamageScanReport report) async {
    final existing = await getAll();
    final updated = <DamageScanReport>[
      report,
      ...existing.where((r) => r.id != report.id),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(
      storageKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
    if (!ok) {
      throw StateError('Penyimpanan fallback menolak penulisan laporan.');
    }
  }

  @override
  Future<void> deleteById(String reportId) async {
    final existing = await getAll();
    final updated = existing.where((r) => r.id != reportId).toList();
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(
      storageKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
    if (!ok) {
      throw StateError('Penyimpanan fallback gagal memperbarui daftar laporan.');
    }
  }

  @override
  Future<void> markSynced(String reportId, DateTime syncedAt) async {
    final existing = await getAll();
    final updated = existing.map((item) {
      if (item.id != reportId) return item;
      return item.copyWith(
        syncStatus: DamageSyncStatus.synced,
        syncedAt: syncedAt,
      );
    }).toList();

    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(
      storageKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
    if (!ok) {
      throw StateError('Penyimpanan fallback gagal menandai status sinkron.');
    }
  }
}

/// Wrapper adaptif: memakai [SqfliteDamageReportStore] secara utama di perangkat
/// nyata, dan beralih aman ke [SharedPrefsFallbackDamageReportStore] bila plugin
/// SQLite native tidak tersedia (misalnya saat `flutter test` di Dart VM).
class ResilientDamageReportStore implements DamageReportLocalStore {
  final SqfliteDamageReportStore _primary;
  final SharedPrefsFallbackDamageReportStore _fallback;
  bool _useFallback = false;

  ResilientDamageReportStore({
    SqfliteDamageReportStore? primary,
    SharedPrefsFallbackDamageReportStore? fallback,
  })  : _primary = primary ?? SqfliteDamageReportStore(),
        _fallback = fallback ?? const SharedPrefsFallbackDamageReportStore();

  bool get isUsingFallback => _useFallback;

  Future<T> _runWithFallback<T>(
    Future<T> Function(DamageReportLocalStore store) action,
  ) async {
    if (_useFallback) {
      return action(_fallback);
    }
    try {
      return await action(_primary);
    } on MissingPluginException {
      _useFallback = true;
      return action(_fallback);
    } on UnsupportedError {
      _useFallback = true;
      return action(_fallback);
    } on StateError catch (e) {
      // sqflite dapat melempar StateError bila databaseFactory belum diinisialisasi di VM
      if (e.message.toLowerCase().contains('databasefactory')) {
        _useFallback = true;
        return action(_fallback);
      }
      rethrow;
    }
  }

  @override
  Future<List<DamageScanReport>> getAll() =>
      _runWithFallback((store) => store.getAll());

  @override
  Future<void> upsert(DamageScanReport report) =>
      _runWithFallback((store) => store.upsert(report));

  @override
  Future<void> deleteById(String reportId) =>
      _runWithFallback((store) => store.deleteById(reportId));

  @override
  Future<void> markSynced(String reportId, DateTime syncedAt) =>
      _runWithFallback((store) => store.markSynced(reportId, syncedAt));
}
