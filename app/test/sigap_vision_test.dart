import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigap/core/network/api_client.dart';
import 'package:sigap/features/dashboard/presentation/screens/home_screen.dart';
import 'package:sigap/features/vision/data/damage_report_local_store.dart';
import 'package:sigap/features/vision/data/damage_report_repository.dart';
import 'package:sigap/features/vision/data/image_quality_validator.dart';
import 'package:sigap/features/vision/data/mock_damage_classifier.dart';
import 'package:sigap/features/vision/data/vision_device_service.dart';
import 'package:sigap/features/vision/domain/damage_classifier.dart';
import 'package:sigap/features/vision/domain/models/damage_models.dart';
import 'package:sigap/features/vision/presentation/screens/damage_analysis_screen.dart';
import 'package:sigap/features/vision/presentation/screens/damage_camera_screen.dart';
import 'package:sigap/features/vision/presentation/screens/damage_history_screen.dart';
import 'package:sigap/features/vision/presentation/screens/damage_preview_screen.dart';
import 'package:sigap/features/vision/presentation/screens/damage_result_screen.dart';
import 'package:sigap/features/vision/presentation/screens/sigap_vision_screen.dart';

class _FakeVisionDeviceService implements VisionDeviceService {
  VisionPermissionState cameraPermission;
  VisionPermissionState galleryPermission;
  PickedPhotoResult galleryResult;
  PickedPhotoResult systemCameraResult;
  LocationFetchResult locationResult;
  bool openedAppSettings = false;

  _FakeVisionDeviceService({
    this.cameraPermission = VisionPermissionState.granted,
    this.galleryPermission = VisionPermissionState.granted,
    this.galleryResult = const PickedPhotoResult(cancelled: true),
    this.systemCameraResult = const PickedPhotoResult(cancelled: true),
    this.locationResult = const LocationFetchResult(
      errorMessage: 'Lokasi tidak tersedia',
    ),
  });

  @override
  Future<VisionPermissionState> checkCameraPermission() async =>
      cameraPermission;

  @override
  Future<VisionPermissionState> requestCameraPermission() async =>
      cameraPermission;

  @override
  Future<VisionPermissionState> checkGalleryPermission() async =>
      galleryPermission;

  @override
  Future<VisionPermissionState> requestGalleryPermission() async =>
      galleryPermission;

  @override
  Future<bool> openDeviceAppSettings() async {
    openedAppSettings = true;
    return true;
  }

  @override
  Future<PickedPhotoResult> pickFromGallery() async => galleryResult;

  @override
  Future<PickedPhotoResult> captureWithSystemCamera() async =>
      systemCameraResult;

  @override
  Future<LocationFetchResult> fetchCurrentLocation() async => locationResult;
}

/// Membuat berkas PNG uji valid (tajam, terang seimbang, resolusi 480x360) di direktori sementara.
File _createValidTestImageSync(Directory dir, String name) {
  final image = img.Image(width: 480, height: 360);
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final isLight = ((x ~/ 20) + (y ~/ 20)).isEven;
      final v = isLight ? 190 : 75;
      image.setPixelRgb(x, y, v, v, v);
    }
  }
  final file = File('${dir.path}${Platform.pathSeparator}$name');
  file.writeAsBytesSync(img.encodePng(image));
  return file;
}

/// Membuat berkas PNG sangat gelap (mean luminance < 15) untuk uji peringatan pencahayaan.
File _createDarkTestImageSync(Directory dir, String name) {
  final image = img.Image(width: 300, height: 300);
  img.fill(image, color: img.ColorRgb8(8, 8, 8));
  final file = File('${dir.path}${Platform.pathSeparator}$name');
  file.writeAsBytesSync(img.encodePng(image));
  return file;
}

/// Membuat laporan uji dengan nilai default ringkas.
DamageScanReport _buildReport({
  required String id,
  required DamageSyncStatus status,
  String summary = 'Ringkasan uji.',
  DamageCategory category = DamageCategory.sedang,
}) {
  return DamageScanReport(
    id: id,
    imagePath: '',
    createdAt: DateTime(2026, 11, 21, 10),
    location: VisionLocationData(
      latitude: -0.9492,
      longitude: 100.3542,
      displayLabel: 'Padang Barat',
      capturedAt: DateTime(2026, 11, 21, 10),
    ),
    result: DamageClassificationResult(
      category: category,
      confidenceScore: 0.8,
      summary: summary,
      recommendations: const [],
      isSimulation: true,
      classifierName: 'Mock',
      analyzedAt: DateTime(2026, 11, 21, 10),
    ),
    syncStatus: status,
  );
}

Future<void> _flushRealIo(WidgetTester tester, {int cycles = 6}) async {
  for (int i = 0; i < cycles; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  late Directory tempDir;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('sigap_vision_test_');
  });

  tearDown(() {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (_) {}
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {
      // Pada Windows, handle berkas cache gambar kadang baru dilepas setelah test selesai
    }
  });

  group('Unit Tests — Validator, Classifier, dan Repository', () {
    test('ImageQualityValidator menolak berkas tidak ditemukan & rusak', () async {
      const validator = ImageQualityValidator(useIsolate: false);

      final missingFile =
          File('${tempDir.path}${Platform.pathSeparator}hilang.jpg');
      final missingReport = await validator.validate(missingFile);
      expect(missingReport.isValid, isFalse);
      expect(missingReport.blockingIssues.first.code, 'FILE_NOT_FOUND');

      final corruptFile =
          File('${tempDir.path}${Platform.pathSeparator}rusak.jpg');
      corruptFile.writeAsBytesSync([1, 2, 3, 4, 5, 6, 7]);
      final corruptReport = await validator.validate(corruptFile);
      expect(corruptReport.isValid, isFalse);
      expect(corruptReport.blockingIssues.first.code, 'DECODE_FAILED');
    });

    test('ImageQualityValidator meloloskan foto valid & memberi peringatan foto gelap', () async {
      const validator = ImageQualityValidator(useIsolate: false);

      final validFile = _createValidTestImageSync(tempDir, 'valid.png');
      final validReport = await validator.validate(validFile);
      expect(validReport.isValid, isTrue);
      expect(validReport.width, 480);
      expect(validReport.height, 360);

      final darkFile = _createDarkTestImageSync(tempDir, 'gelap.png');
      final darkReport = await validator.validate(darkFile);
      expect(darkReport.isValid, isTrue);
      expect(
        darkReport.warningIssues.any((i) => i.code == 'IMAGE_TOO_DARK'),
        isTrue,
      );
    });

    test('MockDamageClassifier deterministik (foto sama -> hasil identik) dan berlabel simulasi', () async {
      final validFile = _createValidTestImageSync(tempDir, 'bangunan.png');
      final quality =
          await const ImageQualityValidator(useIsolate: false).validate(validFile);
      const classifier = MockDamageClassifier(stepDelay: Duration.zero);

      final steps = <DamageAnalysisStep>[];
      final res1 = await classifier.classify(
        imageFile: validFile,
        qualityReport: quality,
        onStepChanged: steps.add,
      );
      final res2 = await classifier.classify(
        imageFile: validFile,
        qualityReport: quality,
      );

      expect(steps, equals(DamageAnalysisStep.values));
      expect(res1.isSimulation, isTrue);
      expect(res1.category, equals(res2.category));
      expect(res1.confidenceScore, equals(res2.confidenceScore));
      expect(res1.summary, equals(res2.summary));
    });

    test('DamageReportRepository menyimpan, memuat, mengecek sinkronisasi offline, dan menghapus laporan', () async {
      final validFile = _createValidTestImageSync(tempDir, 'laporan.png');
      final repo = DamageReportRepository(
        directoryProvider: () async => tempDir,
        internetChecker: () async => false,
      );

      final report = DamageScanReport(
        id: 'rep_1',
        imagePath: validFile.path,
        createdAt: DateTime(2026, 11, 21, 19, 30),
        location: VisionLocationData(
          latitude: -0.9492,
          longitude: 100.3542,
          displayLabel: 'Padang Barat',
          capturedAt: DateTime(2026, 11, 21, 19, 30),
        ),
        result: DamageClassificationResult(
          category: DamageCategory.sedang,
          confidenceScore: 0.82,
          summary: 'Ringkasan simulasi.',
          recommendations: const ['Jauhi area retak.'],
          urgentWarning: 'Peringatan bahaya.',
          isSimulation: true,
          classifierName: 'MockDamageClassifier',
          analyzedAt: DateTime(2026, 11, 21, 19, 30),
        ),
        syncStatus: DamageSyncStatus.synced, // Harus diturunkan jadi pendingSync
      );

      final saved = await repo.saveReport(report);
      expect(saved.syncStatus, DamageSyncStatus.pendingSync);

      final loaded = await repo.loadReports();
      expect(loaded.length, 1);
      expect(loaded.first.id, 'rep_1');

      final syncCheck = await repo.checkAndAttemptSync();
      expect(syncCheck.hasInternet, isFalse);
      expect(syncCheck.pendingCount, 1);
      expect(syncCheck.message, contains('offline'));

      await repo.deleteReport('rep_1');
      final afterDelete = await repo.loadReports();
      expect(afterDelete, isEmpty);
    });

    test('buildSyncPayload menyertakan client_report_id agar retry idempoten', () {
      final report = DamageScanReport(
        id: 'vision_1730000000000',
        imagePath: '/tmp/a.jpg',
        createdAt: DateTime(2026, 11, 21),
        location: VisionLocationData(
          latitude: -0.9492,
          longitude: 100.3542,
          displayLabel: 'Padang Barat',
          capturedAt: DateTime(2026, 11, 21),
        ),
        result: DamageClassificationResult(
          category: DamageCategory.sedang,
          confidenceScore: 0.8,
          summary: 'Ringkasan.',
          recommendations: const [],
          isSimulation: true,
          classifierName: 'Mock',
          analyzedAt: DateTime(2026, 11, 21),
        ),
        syncStatus: DamageSyncStatus.pendingSync,
      );

      final payload = DamageReportRepository.buildSyncPayload(report);
      expect(payload?['client_report_id'], 'vision_1730000000000');

      // Laporan tanpa koordinat GPS tidak boleh dikirim (tidak ada lokasi palsu).
      final withoutLocation = DamageScanReport(
        id: report.id,
        imagePath: report.imagePath,
        createdAt: report.createdAt,
        result: report.result,
        syncStatus: report.syncStatus,
      );
      expect(
        DamageReportRepository.buildSyncPayload(withoutLocation),
        isNull,
      );
    });

    test('mergeServerReports tidak menimpa laporan lokal yang belum terkirim', () async {
      final repo = DamageReportRepository(
        directoryProvider: () async => tempDir,
        internetChecker: () async => true,
        localStore: SharedPrefsFallbackDamageReportStore(),
        autoStartOnUse: false,
      );

      await repo.saveReport(
        _buildReport(
          id: 'vision_pending',
          status: DamageSyncStatus.pendingSync,
          summary: 'Ringkasan lokal asli.',
        ),
      );

      final merged = await repo.mergeServerReports([
        {
          'id': 'server-1',
          'client_report_id': 'vision_pending',
          'damage_level': 'critical',
          'confidence_score': 0.95,
          'latitude': -0.9492,
          'longitude': 100.3542,
          'description': 'Versi server.',
          'image_url': 'https://example.com/a.jpg',
          'is_verified_by_officer': null,
          'created_at': '2026-11-21T12:00:00Z',
        },
        {
          'id': 'server-2',
          'client_report_id': 'vision_lain',
          'damage_level': 'minor',
          'confidence_score': 0.7,
          'latitude': -0.95,
          'longitude': 100.35,
          'description': 'Hanya ada di server.',
          'image_url': '',
          'is_verified_by_officer': true,
          'created_at': '2026-11-20T12:00:00Z',
        },
      ]);

      final pending = merged.firstWhere((r) => r.id == 'vision_pending');
      expect(pending.syncStatus, DamageSyncStatus.pendingSync);
      expect(pending.result.summary, 'Ringkasan lokal asli.');

      final remoteOnly = merged.firstWhere((r) => r.id == 'vision_lain');
      expect(remoteOnly.syncStatus, DamageSyncStatus.synced);
      expect(remoteOnly.isRemoteOnly, isFalse, reason: 'tanpa image_url');
      expect(
        merged.any((r) => r.id == 'vision_pending' && r.isRemoteOnly),
        isFalse,
      );
    });

    test('fetchRemoteReports meminta login bila token tidak tersedia', () async {
      final repo = DamageReportRepository(
        directoryProvider: () async => tempDir,
        internetChecker: () async => true,
        accessTokenProvider: () async => null,
        autoStartOnUse: false,
      );

      expect(
        () => repo.fetchRemoteReports(),
        throwsA(
          isA<DamageSyncException>().having(
            (e) => e.needsLogin,
            'needsLogin',
            isTrue,
          ),
        ),
      );
    });

    test('DamageCategory.fromName mengenali nilai lama maupun spesifikasi revisi Zidan', () {
      expect(DamageCategory.ringan.label, 'AMAN (Minor)');
      expect(DamageCategory.ringan.shortLabel, 'AMAN');
      expect(DamageCategory.sedang.label, 'WASPADA (Moderate)');
      expect(DamageCategory.sedang.shortLabel, 'WASPADA');
      expect(DamageCategory.berat.label, 'BAHAYA KRITIS (Severe)');
      expect(DamageCategory.berat.shortLabel, 'BAHAYA KRITIS');

      expect(DamageCategory.fromName('ringan'), DamageCategory.ringan);
      expect(DamageCategory.fromName('minor'), DamageCategory.ringan);
      expect(
        DamageCategory.fromName('crack_non_structural'),
        DamageCategory.ringan,
      );

      expect(DamageCategory.fromName('sedang'), DamageCategory.sedang);
      expect(DamageCategory.fromName('moderate'), DamageCategory.sedang);
      expect(
        DamageCategory.fromName('crack_structural_wall'),
        DamageCategory.sedang,
      );

      expect(DamageCategory.fromName('berat'), DamageCategory.berat);
      expect(DamageCategory.fromName('severe'), DamageCategory.berat);
      expect(DamageCategory.fromName('critical'), DamageCategory.berat);
      expect(
        DamageCategory.fromName('severe_column_failure'),
        DamageCategory.berat,
      );
    });

    test('SqfliteDamageReportStore.toDbMap & fromDbMap memetakan damage_level dan menjaga seluruh metadata', () {
      final createdAt = DateTime(2026, 11, 22, 16, 45);
      final syncedAt = DateTime(2026, 11, 22, 16, 50);

      for (final entry in {
        DamageCategory.ringan: 'minor',
        DamageCategory.sedang: 'moderate',
        DamageCategory.berat: 'critical',
      }.entries) {
        final report = DamageScanReport(
          id: 'db_${entry.key.name}',
          imagePath: '/local/sigap_vision_reports/sample.png',
          createdAt: createdAt,
          location: VisionLocationData(
            latitude: -0.9471,
            longitude: 100.3658,
            displayLabel: 'Padang Barat',
            capturedAt: createdAt,
          ),
          result: DamageClassificationResult(
            category: entry.key,
            confidenceScore: 0.87,
            summary: 'Ringkasan ${entry.value}',
            recommendations: const ['Langkah 1', 'Langkah 2'],
            urgentWarning: entry.key.isHighRisk ? 'Waspada' : null,
            isSimulation: true,
            classifierName: 'MockDamageClassifier',
            analyzedAt: createdAt,
            detectedRegions: const [
              DamageBoundingBox(
                left: 0.1,
                top: 0.2,
                width: 0.5,
                height: 0.4,
                label: 'Area Retak',
                confidence: 0.87,
              ),
            ],
          ),
          syncStatus: DamageSyncStatus.synced,
          syncedAt: syncedAt,
        );

        final row = SqfliteDamageReportStore.toDbMap(report);
        expect(row['id'], report.id);
        expect(row['damage_level'], entry.value);
        expect(row['latitude'], -0.9471);
        expect(row['longitude'], 100.3658);
        expect(row['confidence_score'], 0.87);
        expect(row['sync_status'], 'synced');
        expect(row['synced_at'], syncedAt.toIso8601String());

        final restored = SqfliteDamageReportStore.fromDbMap(row);
        expect(restored.id, report.id);
        expect(restored.result.category, entry.key);
        expect(restored.result.confidenceScore, 0.87);
        expect(restored.result.recommendations, equals(['Langkah 1', 'Langkah 2']));
        expect(restored.result.detectedRegions.length, 1);
        expect(restored.location?.displayLabel, 'Padang Barat');
        expect(restored.syncStatus, DamageSyncStatus.synced);
        expect(restored.syncedAt, syncedAt);
      }
    });

    test('Auto-sync via connectivityStream menyinkronkan laporan ke synced & mengisi syncedAt saat online', () async {
      final validFile = _createValidTestImageSync(tempDir, 'autosync_ok.png');
      final controller = StreamController<List<ConnectivityResult>>.broadcast();
      final uploadedPayloads = <Map<String, dynamic>>[];

      final repo = DamageReportRepository(
        directoryProvider: () async => tempDir,
        internetChecker: () async => true,
        connectivityStream: controller.stream,
        accessTokenProvider: () async => 'jwt_valid_token',
        syncUploader: (report, payload) async {
          uploadedPayloads.add(payload);
        },
        autoStartOnUse: false,
      );

      final report = DamageScanReport(
        id: 'auto_1',
        imagePath: validFile.path,
        createdAt: DateTime(2026, 11, 22, 16, 55),
        location: VisionLocationData(
          latitude: -0.9492,
          longitude: 100.3542,
          displayLabel: 'Padang Barat',
          capturedAt: DateTime(2026, 11, 22, 16, 55),
        ),
        result: DamageClassificationResult(
          category: DamageCategory.berat,
          confidenceScore: 0.91,
          summary: 'Retak struktur berat.',
          recommendations: const ['Evakuasi segera.'],
          urgentWarning: 'Bahaya!',
          isSimulation: true,
          classifierName: 'MockDamageClassifier',
          analyzedAt: DateTime(2026, 11, 22, 16, 55),
        ),
        syncStatus: DamageSyncStatus.pendingSync,
      );

      await repo.saveReport(report);
      repo.startAutoSync();
      expect(repo.isAutoSyncActive, isTrue);

      controller.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(uploadedPayloads.length, 1);
      expect(uploadedPayloads.first['damage_level'], 'critical');
      expect(uploadedPayloads.first['latitude'], -0.9492);
      expect(uploadedPayloads.first['longitude'], 100.3542);

      final updated = await repo.loadReports();
      expect(updated.single.syncStatus, DamageSyncStatus.synced);
      expect(updated.single.syncedAt, isNotNull);

      await repo.stopAutoSync();
      await controller.close();
    });

    test('Kegagalan sync (404/503) & kondisi offline menjaga status pendingSync dan syncedAt tetap null', () async {
      final validFile = _createValidTestImageSync(tempDir, 'sync_fail_404.png');
      final repo404 = DamageReportRepository(
        directoryProvider: () async => tempDir,
        internetChecker: () async => true,
        accessTokenProvider: () async => 'jwt_valid_token',
        syncUploader: (report, payload) async {
          throw ApiException(
            statusCode: 404,
            code: 'NOT_FOUND',
            message: 'Endpoint tidak ditemukan.',
          );
        },
        autoStartOnUse: false,
      );

      final report = DamageScanReport(
        id: 'fail_404',
        imagePath: validFile.path,
        createdAt: DateTime(2026, 11, 22, 17, 0),
        location: VisionLocationData(
          latitude: -0.9500,
          longitude: 100.3500,
          displayLabel: 'Padang Selatan',
          capturedAt: DateTime(2026, 11, 22, 17, 0),
        ),
        result: DamageClassificationResult(
          category: DamageCategory.sedang,
          confidenceScore: 0.80,
          summary: 'Retak dinding sedang.',
          recommendations: const ['Hindari dinding retak.'],
          isSimulation: true,
          classifierName: 'MockDamageClassifier',
          analyzedAt: DateTime(2026, 11, 22, 17, 0),
        ),
        syncStatus: DamageSyncStatus.pendingSync,
      );

      await repo404.saveReport(report);
      final res404 = await repo404.checkAndAttemptSync();
      expect(res404.hasInternet, isTrue);
      expect(res404.backendEndpointAvailable, isFalse);
      expect(res404.pendingCount, 1);

      final stored = await repo404.loadReports();
      expect(stored.single.syncStatus, DamageSyncStatus.pendingSync);
      expect(stored.single.syncedAt, isNull);
    });

    test('Guard _isSyncing mencegah panggilan sync ganda saat event konektivitas datang berturut-turut', () async {
      final validFile = _createValidTestImageSync(tempDir, 'sync_guard.png');
      final controller = StreamController<List<ConnectivityResult>>.broadcast();
      final uploadCompleter = Completer<void>();
      int uploadCalls = 0;

      final repo = DamageReportRepository(
        directoryProvider: () async => tempDir,
        internetChecker: () async => true,
        connectivityStream: controller.stream,
        accessTokenProvider: () async => 'jwt_valid_token',
        syncUploader: (report, payload) async {
          uploadCalls++;
          await uploadCompleter.future;
        },
        autoStartOnUse: false,
      );

      await repo.saveReport(
        DamageScanReport(
          id: 'guard_1',
          imagePath: validFile.path,
          createdAt: DateTime(2026, 11, 22, 17, 5),
          location: VisionLocationData(
            latitude: -0.9400,
            longitude: 100.3600,
            displayLabel: 'Padang Utara',
            capturedAt: DateTime(2026, 11, 22, 17, 5),
          ),
          result: DamageClassificationResult(
            category: DamageCategory.ringan,
            confidenceScore: 0.82,
            summary: 'Retak plester.',
            recommendations: const ['Pantau kondisi.'],
            isSimulation: true,
            classifierName: 'MockDamageClassifier',
            analyzedAt: DateTime(2026, 11, 22, 17, 5),
          ),
          syncStatus: DamageSyncStatus.pendingSync,
        ),
      );

      repo.startAutoSync();

      // Kirim beberapa event online berturut-turut secara cepat
      controller.add([ConnectivityResult.mobile]);
      controller.add([ConnectivityResult.wifi]);
      controller.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repo.isSyncing, isTrue);
      expect(uploadCalls, 1);

      uploadCompleter.complete();
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(repo.isSyncing, isFalse);
      expect(uploadCalls, 1);
      final finalList = await repo.loadReports();
      expect(finalList.single.syncStatus, DamageSyncStatus.synced);

      await repo.stopAutoSync();
      await controller.close();
    });
  });

  group('Widget Tests — Alur SIGAP-Vision & Edge Cases', () {
    testWidgets('Beranda menampilkan kartu SIGAP-Vision dan mengarahkan ke halaman SIGAP-Vision', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump(const Duration(milliseconds: 150));

      expect(
        find.text('SIGAP-Vision — Pindai Kerusakan Bangunan'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Periksa indikasi kerusakan bangunan setelah gempa melalui foto.',
        ),
        findsOneWidget,
      );

      final startBtn = find.text('Mulai Pemindaian');
      await tester.ensureVisible(startBtn);
      await tester.tap(startBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('SIGAP-Vision'), findsOneWidget);
      expect(find.text('Buka Kamera Pemindaian'), findsOneWidget);
      expect(find.text('Pilih Foto dari Galeri'), findsOneWidget);
    });

    testWidgets('Pengguna membatalkan pemilihan galeri ditangani dengan aman', (tester) async {
      final fakeDevice = _FakeVisionDeviceService(
        galleryResult: const PickedPhotoResult(cancelled: true),
      );
      final repo =
          DamageReportRepository(directoryProvider: () async => tempDir);

      await tester.pumpWidget(
        MaterialApp(
          home: SigapVisionScreen(
            deviceService: fakeDevice,
            repository: repo,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Pilih Foto dari Galeri'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('Pemilihan foto dari galeri dibatalkan.'),
        findsOneWidget,
      );
    });

    testWidgets('Izin kamera ditolak permanen menampilkan status izin & tombol Pengaturan', (tester) async {
      final fakeDevice = _FakeVisionDeviceService(
        cameraPermission: VisionPermissionState.permanentlyDenied,
        galleryPermission: VisionPermissionState.denied,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DamageCameraScreen(
            deviceService: fakeDevice,
            disableNativeCameraForTest: true,
          ),
        ),
      );
      await _flushRealIo(tester);

      expect(find.text('Izin Kamera Diperlukan'), findsOneWidget);
      expect(find.text('Buka Pengaturan Aplikasi'), findsOneWidget);
      expect(find.textContaining('Izin Kamera: Ditolak Permanen'), findsOneWidget);

      await tester.tap(find.text('Buka Pengaturan Aplikasi'));
      await tester.pump();
      expect(fakeDevice.openedAppSettings, isTrue);
    });

    testWidgets('Foto tidak valid pada pratinjau menonaktifkan tombol Analisis Kerusakan', (tester) async {
      final badFile = File('${tempDir.path}${Platform.pathSeparator}bad.jpg');
      badFile.writeAsBytesSync([10, 20, 30]);

      await tester.pumpWidget(
        MaterialApp(
          home: DamagePreviewScreen(
            photoData: CapturedPhotoData(
              imagePath: badFile.path,
              sourceLabel: 'Galeri Perangkat',
              capturedAt: DateTime(2026, 11, 21, 19, 30),
            ),
            validator: const ImageQualityValidator(useIsolate: false),
          ),
        ),
      );
      await _flushRealIo(tester);

      expect(find.text('Foto Tidak Memenuhi Syarat Teknis'), findsOneWidget);
      expect(find.text('Ambil Ulang'), findsOneWidget);
      expect(find.text('Pilih Foto Lain'), findsOneWidget);

      final analyzeBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Analisis Kerusakan'),
      );
      expect(analyzeBtn.onPressed, isNull);
    });

    testWidgets('Alur penuh: Pratinjau -> Analisis -> Hasil (Berat) -> Simpan Laporan -> Riwayat -> Hapus', (tester) async {
      final validFile = _createValidTestImageSync(tempDir, 'retak_berat.png');
      final repo = DamageReportRepository(
        directoryProvider: () async => tempDir,
        internetChecker: () async => false,
      );
      final fakeDevice = _FakeVisionDeviceService(
        locationResult: LocationFetchResult(
          location: VisionLocationData(
            latitude: -0.9471,
            longitude: 100.4172,
            displayLabel: 'GPS Perangkat (-0.94710, 100.41720)',
            capturedAt: DateTime(2026, 11, 21, 19, 40),
          ),
        ),
      );
      const classifier = MockDamageClassifier(
        stepDelay: Duration.zero,
        forcedCategory: DamageCategory.berat,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DamagePreviewScreen(
            photoData: CapturedPhotoData(
              imagePath: validFile.path,
              sourceLabel: 'Kamera SIGAP-Vision',
              capturedAt: DateTime(2026, 11, 21, 19, 40),
            ),
            classifier: classifier,
            repository: repo,
            deviceService: fakeDevice,
            validator: const ImageQualityValidator(useIsolate: false),
          ),
        ),
      );
      await _flushRealIo(tester);

      // Aktifkan lokasi opsional
      await tester.ensureVisible(find.byType(Switch));
      await tester.tap(find.byType(Switch));
      await _flushRealIo(tester);
      expect(find.textContaining('GPS Perangkat'), findsOneWidget);

      // Mulai Analisis Kerusakan -> otomatis masuk ke DamageResultScreen
      await tester.tap(find.text('Analisis Kerusakan'));
      await _flushRealIo(tester);
      await _flushRealIo(tester);

      // Verifikasi gerbang disclaimer AI wajib tampil terlebih dahulu sebelum 3 detik
      expect(find.text('Disclaimer AI Wajib'), findsOneWidget);
      expect(find.text('BAHAYA KRITIS (Severe)'), findsNothing);

      // Tunggu 3 detik sampai disclaimer selesai dan kartu hasil muncul
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 350));

      // Verifikasi DamageResultScreen lengkap
      expect(find.text('Hasil Analisis'), findsOneWidget);
      expect(find.text('Mode Simulasi Pengujian'), findsOneWidget);
      expect(find.text('BAHAYA KRITIS (Severe)'), findsOneWidget);
      expect(find.text('Peringatan Keselamatan Segera'), findsOneWidget);
      expect(find.text('Disclaimer Penting'), findsOneWidget);
      expect(find.text('Cari Titik Kumpul / Shelter Terdekat'), findsOneWidget);

      // Simpan Laporan
      final saveBtn = find.text('Simpan Laporan');
      await tester.ensureVisible(saveBtn);
      await tester.pump();
      await tester.tap(saveBtn);
      await _flushRealIo(tester, cycles: 8);

      expect(find.text('Laporan Tersimpan Lokal'), findsOneWidget);
      final savedList = await tester.runAsync(() => repo.loadReports());
      expect(savedList?.length, 1);

      // Buka Riwayat Pemindaian dan hapus laporan dengan konfirmasi
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: DamageHistoryScreen(
            classifier: classifier,
            repository: repo,
            deviceService: fakeDevice,
          ),
        ),
      );
      await _flushRealIo(tester);

      expect(find.text('BAHAYA KRITIS (Severe)'), findsOneWidget);
      expect(find.text('Menunggu Sinkronisasi'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Hapus Laporan Ini?'), findsOneWidget);

      await tester.tap(find.text('Ya, Hapus'));
      await _flushRealIo(tester);

      expect(find.text('Belum Ada Riwayat Pemindaian'), findsOneWidget);
    });

    testWidgets('Analisis gagal & kondisi offline server menampilkan error state dengan tombol Coba Lagi', (tester) async {
      final validFile = _createValidTestImageSync(tempDir, 'offline_test.png');
      final quality = await tester.runAsync(
        () => const ImageQualityValidator(useIsolate: false).validate(validFile),
      );
      final repo = DamageReportRepository(
        directoryProvider: () async => tempDir,
        internetChecker: () async => false,
      );
      const offlineClassifier = MockDamageClassifier(
        stepDelay: Duration.zero,
        simulateNetworkRequirement: true,
        hasInternetConnection: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DamageAnalysisScreen(
            photoData: CapturedPhotoData(
              imagePath: validFile.path,
              sourceLabel: 'Galeri',
              capturedAt: DateTime.now(),
              qualityReport: quality,
            ),
            classifier: offlineClassifier,
            repository: repo,
          ),
        ),
      );
      await _flushRealIo(tester);

      expect(find.text('Koneksi Internet Diperlukan'), findsOneWidget);
      expect(find.text('Coba Analisis Lagi'), findsOneWidget);
      expect(find.text('Kembali ke Pratinjau Foto'), findsOneWidget);
    });

    testWidgets('Penyimpanan gagal menampilkan pesan error tanpa menandai tersimpan', (tester) async {
      final validFile = _createValidTestImageSync(tempDir, 'storage_fail.png');
      final failingRepo = DamageReportRepository(
        directoryProvider: () async => tempDir,
        simulateStorageFailure: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DamageResultScreen(
            photoData: CapturedPhotoData(
              imagePath: validFile.path,
              sourceLabel: 'Galeri',
              capturedAt: DateTime.now(),
            ),
            result: DamageClassificationResult(
              category: DamageCategory.ringan,
              confidenceScore: 0.85,
              summary: 'Simulasi ringan.',
              recommendations: const ['Pantau retakan.'],
              isSimulation: true,
              classifierName: 'MockDamageClassifier',
              analyzedAt: DateTime.now(),
            ),
            repository: failingRepo,
          ),
        ),
      );
      // Lewati gerbang disclaimer wajib 3 detik
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 350));

      final saveBtn = find.text('Simpan Laporan');
      await tester.ensureVisible(saveBtn);
      await tester.pump();
      await tester.tap(saveBtn);
      await _flushRealIo(tester);

      expect(find.textContaining('Gagal menyimpan laporan'), findsOneWidget);
      expect(find.text('Simpan Laporan'), findsOneWidget);
    });

    testWidgets('Disclaimer 3 detik non-dismissible, mode riwayat langsung tampil, tombol shelter membuka PetaScreen, dan dispose aman tanpa pending timer', (tester) async {
      final validFile = _createValidTestImageSync(tempDir, 'fe04_gate.png');
      final sampleResult = DamageClassificationResult(
        category: DamageCategory.sedang,
        confidenceScore: 0.84,
        summary: 'Indikasi retak dinding sedang.',
        recommendations: const ['Batasi akses ruangan.'],
        urgentWarning: 'Waspada gempa susulan.',
        isSimulation: true,
        classifierName: 'MockDamageClassifier',
        analyzedAt: DateTime(2026, 11, 22, 16, 20),
      );

      // 1. Mode hasil baru: disclaimer tampil dan kartu hasil belum muncul sebelum 3 detik
      await tester.pumpWidget(
        MaterialApp(
          home: DamageResultScreen(
            photoData: CapturedPhotoData(
              imagePath: validFile.path,
              sourceLabel: 'Kamera SIGAP-Vision',
              capturedAt: DateTime(2026, 11, 22, 16, 20),
            ),
            result: sampleResult,
          ),
        ),
      );

      expect(find.text('Disclaimer AI Wajib'), findsOneWidget);
      expect(
        find.text(DamageResultScreen.mandatoryAiDisclaimerText),
        findsOneWidget,
      );
      expect(find.text('WASPADA (Moderate)'), findsNothing);

      // Setelah 2 detik, gerbang masih aktif dan kartu hasil belum muncul
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Disclaimer AI Wajib'), findsOneWidget);
      expect(find.text('WASPADA (Moderate)'), findsNothing);

      // Setelah 1 detik lagi (total 3 detik), kartu hasil tampil normal
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Disclaimer AI Wajib'), findsNothing);
      expect(find.text('WASPADA (Moderate)'), findsOneWidget);
      expect(find.text('AMAN'), findsOneWidget);
      expect(find.text('WASPADA'), findsOneWidget);
      expect(find.text('BAHAYA KRITIS'), findsOneWidget);

      // 2. Tombol "Cari Titik Kumpul / Shelter Terdekat" membuka PetaScreen
      final shelterBtn = find.text('Cari Titik Kumpul / Shelter Terdekat');
      expect(shelterBtn, findsOneWidget);
      await tester.ensureVisible(shelterBtn);
      await tester.pump();
      await tester.tap(shelterBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Peta Siaga & Evakuasi'), findsOneWidget);

      // 3. Mode riwayat langsung tampil tanpa menunggu 3 detik
      final savedReport = DamageScanReport(
        id: 'hist_fe04',
        imagePath: validFile.path,
        createdAt: DateTime(2026, 11, 22, 16, 20),
        result: sampleResult,
        syncStatus: DamageSyncStatus.pendingSync,
      );
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: DamageResultScreen(
            existingReport: savedReport,
            isFromHistory: true,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Disclaimer AI Wajib'), findsNothing);
      expect(find.text('Detail Laporan'), findsOneWidget);
      expect(find.text('WASPADA (Moderate)'), findsOneWidget);
      expect(find.text('Cari Titik Kumpul / Shelter Terdekat'), findsOneWidget);

      // 4. Dispose di tengah countdown (detik ke-1) tidak meninggalkan pending timer
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: DamageResultScreen(
            photoData: CapturedPhotoData(
              imagePath: validFile.path,
              sourceLabel: 'Galeri',
              capturedAt: DateTime(2026, 11, 22, 16, 20),
            ),
            result: sampleResult,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('Analisis gagal umum & navigasi kembali ke halaman sebelumnya bekerja dengan benar', (tester) async {
      final validFile = _createValidTestImageSync(tempDir, 'error_back.png');
      final quality = await tester.runAsync(
        () => const ImageQualityValidator(useIsolate: false).validate(validFile),
      );
      final fakeDevice = _FakeVisionDeviceService(
        systemCameraResult: PickedPhotoResult(imagePath: validFile.path),
      );
      const failingClassifier = MockDamageClassifier(
        stepDelay: Duration.zero,
        simulatedException: DamageClassifierException(
          code: 'INFERENCE_ERROR',
          message: 'Gagal menjalankan inferensi gambar.',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DamageCameraScreen(
            deviceService: fakeDevice,
            classifier: failingClassifier,
            disableNativeCameraForTest: true,
          ),
        ),
      );
      await _flushRealIo(tester);

      // Uji fallback kamera sistem -> membuka Pratinjau Foto -> lalu kembali ke Kamera
      await tester.tap(find.text('Ambil Foto (Kamera Sistem)'));
      await _flushRealIo(tester);
      expect(find.text('Pratinjau Foto'), findsOneWidget);

      await tester.tap(find.text('Ulangi Foto'));
      await _flushRealIo(tester);
      expect(find.text('Kamera Pemindaian'), findsOneWidget);

      // Uji error analisis umum pada DamageAnalysisScreen
      await tester.pumpWidget(
        MaterialApp(
          home: DamageAnalysisScreen(
            photoData: CapturedPhotoData(
              imagePath: validFile.path,
              sourceLabel: 'Kamera Sistem',
              capturedAt: DateTime.now(),
              qualityReport: quality,
            ),
            classifier: failingClassifier,
          ),
        ),
      );
      await _flushRealIo(tester);

      expect(find.text('Analisis Gagal Diproses'), findsOneWidget);
      expect(find.text('Gagal menjalankan inferensi gambar.'), findsOneWidget);
    });
  });
}
