import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sigap/core/network/api_client.dart';
import 'package:sigap/core/theme/app_colors.dart';
import 'package:sigap/features/evacuation/data/evacuation_location_service.dart';
import 'package:sigap/features/map/data/damage_heatmap_service.dart';
import 'package:sigap/features/map/domain/damage_heatmap_point.dart';
import 'package:sigap/features/map/presentation/screens/peta_screen.dart';
import 'package:sigap/features/vision/data/damage_report_local_store.dart';
import 'package:sigap/features/vision/data/damage_report_repository.dart';
import 'package:sigap/features/vision/domain/models/damage_models.dart';

class _InMemoryLocalStore implements DamageReportLocalStore {
  final List<DamageScanReport> _items;

  _InMemoryLocalStore([List<DamageScanReport>? initial])
      : _items = List<DamageScanReport>.from(initial ?? const []);

  @override
  Future<List<DamageScanReport>> getAll() async => List.unmodifiable(_items);

  @override
  Future<void> upsert(DamageScanReport report) async {
    _items.removeWhere((e) => e.id == report.id);
    _items.insert(0, report);
  }

  @override
  Future<void> deleteById(String reportId) async {
    _items.removeWhere((e) => e.id == reportId);
  }

  @override
  Future<void> markSynced(String reportId, DateTime syncedAt) async {
    final idx = _items.indexWhere((e) => e.id == reportId);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(
        syncStatus: DamageSyncStatus.synced,
        syncedAt: syncedAt,
      );
    }
  }
}

class _FakeLocationService implements EvacuationLocationService {
  final EvacuationLocationResult result;

  _FakeLocationService(this.result);

  @override
  Future<EvacuationLocationResult> fetchCurrentLocation() async => result;

  @override
  Future<bool> openDeviceAppSettings() async => true;
}

DamageScanReport _buildLocalReport({
  required String id,
  required DamageCategory category,
  VisionLocationData? location,
  String summary = 'Retak struktural pada kolom bangunan.',
  double? confidence = 0.88,
}) {
  return DamageScanReport(
    id: id,
    imagePath: '/tmp/$id.jpg',
    createdAt: DateTime(2026, 11, 27, 9, 30),
    location: location,
    result: DamageClassificationResult(
      category: category,
      confidenceScore: confidence,
      summary: summary,
      recommendations: const ['Evakuasi segera'],
      isSimulation: true,
      classifierName: 'MockDamageClassifier',
      analyzedAt: DateTime(2026, 11, 27, 9, 30),
    ),
    syncStatus: DamageSyncStatus.pendingSync,
  );
}

void main() {
  group('FE-08 — Unit Test DamageHeatmapPoint & DamageHeatmapService', () {
    test(
      'DamageHeatmapPoint.fromServerJson & fromLocalReport memetakan severity, warna/radius, dan menolak laporan tanpa GPS',
      () {
        // 1. Server JSON minor / moderate / critical
        final minorPt = DamageHeatmapPoint.fromServerJson({
          'id': 'srv-1',
          'latitude': -0.9450,
          'longitude': 100.3600,
          'damage_level': 'minor',
          'confidence_score': 0.72,
          'description': 'Retak rambut pada plester.',
          'created_at': '2026-11-27T01:00:00Z',
          'is_verified_by_officer': true,
        });
        expect(minorPt, isNotNull);
        expect(minorPt!.category, DamageCategory.ringan);
        expect(minorPt.overlayColor, AppColors.safeGreen);
        expect(minorPt.circleRadiusMeters, 75.0);
        expect(minorPt.isFromServer, isTrue);
        expect(minorPt.syncStatusLabel, 'Terverifikasi Petugas');

        final moderatePt = DamageHeatmapPoint.fromServerJson({
          'id': 'srv-2',
          'latitude': '-0.9470',
          'longitude': '100.3620',
          'damage_level': 'moderate',
          'confidence_score': 0.81,
        });
        expect(moderatePt, isNotNull);
        expect(moderatePt!.category, DamageCategory.sedang);
        expect(moderatePt.overlayColor, AppColors.alertSiaga);
        expect(moderatePt.circleRadiusMeters, 110.0);

        final criticalPt = DamageHeatmapPoint.fromServerJson({
          'id': 'srv-3',
          'latitude': -0.9500,
          'longitude': 100.3550,
          'damage_level': 'critical',
          'confidence_score': 0.94,
        });
        expect(criticalPt, isNotNull);
        expect(criticalPt!.category, DamageCategory.berat);
        expect(criticalPt.overlayColor, AppColors.alertAwas);
        expect(criticalPt.circleRadiusMeters, 150.0);

        // Koordinat invalid -> null
        expect(
          DamageHeatmapPoint.fromServerJson({'id': 'bad', 'latitude': 999}),
          isNull,
        );

        // 2. Laporan lokal tanpa koordinat GPS -> ditolak (null)
        final noGpsReport = _buildLocalReport(
          id: 'loc-nogps',
          category: DamageCategory.berat,
          location: null,
        );
        expect(DamageHeatmapPoint.fromLocalReport(noGpsReport), isNull);

        // 3. Laporan lokal dengan koordinat GPS valid -> berhasil dikonversi
        final validLocal = _buildLocalReport(
          id: 'loc-valid',
          category: DamageCategory.berat,
          location: VisionLocationData(
            latitude: -0.9485,
            longitude: 100.3560,
            displayLabel: 'GPS Perangkat',
            capturedAt: DateTime(2026, 11, 27, 9, 30),
          ),
        );
        final localPt = DamageHeatmapPoint.fromLocalReport(validLocal);
        expect(localPt, isNotNull);
        expect(localPt!.isFromServer, isFalse);
        expect(localPt.sourceLabel, 'Lokal SQLite');
        expect(localPt.category, DamageCategory.berat);
      },
    );

    test(
      'DamageHeatmapService.loadHeatmapPoints menggabungkan server + lokal dengan deduplikasi ID dan aman saat server offline/404',
      () async {
        final store = _InMemoryLocalStore([
          _buildLocalReport(
            id: 'shared-id-1',
            category: DamageCategory.sedang,
            location: VisionLocationData(
              latitude: -0.9460,
              longitude: 100.3580,
              displayLabel: 'GPS',
              capturedAt: DateTime(2026, 11, 27, 8, 0),
            ),
          ),
          _buildLocalReport(
            id: 'local-only-2',
            category: DamageCategory.berat,
            location: VisionLocationData(
              latitude: -0.9510,
              longitude: 100.3590,
              displayLabel: 'GPS',
              capturedAt: DateTime(2026, 11, 27, 9, 0),
            ),
          ),
          _buildLocalReport(
            id: 'local-no-gps',
            category: DamageCategory.ringan,
            location: null,
          ),
        ]);

        final repo = DamageReportRepository(
          localStore: store,
          autoStartOnUse: false,
        );

        // Skenario 1: Server tersedia & memiliki ID yang sama dengan 1 laporan lokal
        final onlineService = DefaultDamageHeatmapService(
          repository: repo,
          remoteFetcher: () async => [
            {
              'id': 'shared-id-1',
              'latitude': -0.9460,
              'longitude': 100.3580,
              'damage_level': 'moderate',
              'confidence_score': 0.85,
              'description': 'Tersinkron dari server.',
              'created_at': '2026-11-27T08:00:00Z',
            },
            {
              'id': 'server-only-3',
              'latitude': -0.9400,
              'longitude': 100.3650,
              'damage_level': 'minor',
              'confidence_score': 0.77,
              'description': 'Retak ringan terverifikasi.',
              'created_at': '2026-11-27T07:00:00Z',
            },
          ],
        );

        final onlineResult = await onlineService.loadHeatmapPoints();
        expect(onlineResult.serverAvailable, isTrue);
        // Deduplikasi: shared-id-1 + server-only-3 (2 server) + local-only-2 (1 lokal) = 3 titik
        expect(onlineResult.points.length, 3);
        expect(onlineResult.serverCount, 2);
        expect(onlineResult.localCount, 1);

        // Skenario 2: Server melempar 404 / error jaringan -> tetap aman, titik lokal muncul jujur
        final offlineService = DefaultDamageHeatmapService(
          repository: repo,
          remoteFetcher: () async => throw ApiException(
            statusCode: 404,
            code: 'NOT_FOUND',
            message: 'Endpoint belum aktif',
          ),
        );

        final offlineResult = await offlineService.loadHeatmapPoints();
        expect(offlineResult.serverAvailable, isFalse);
        expect(offlineResult.serverCount, 0);
        expect(offlineResult.localCount, 2);
        expect(offlineResult.points.length, 2);
        expect(
          offlineResult.statusMessage,
          contains('endpoint heatmap backend belum aktif'),
        );
      },
    );
  });

  group('FE-08 — Widget Test PetaScreen (GPS Dinamis, Heatmap & Tombol Kembali)', () {
    testWidgets(
      'PetaScreen memperbarui jarak/ETA shelter secara dinamis saat menerima posisi GPS nyata (!isFallback)',
      (tester) async {
        // Posisi GPS nyata di sangat dekat SMPN 1 Padang (-0.9520, 100.3610) -> ~111 meter
        final fakeGps = _FakeLocationService(
          EvacuationLocationResult(
            position: const LatLng(-0.9510, 100.3610),
            isFallback: false,
            sourceLabel: 'GPS Aktif (-0.9510, 100.3610)',
            statusMessage: 'Posisi GPS berhasil diperbarui.',
            fetchedAt: DateTime(2026, 11, 27, 10, 0),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: PetaScreen(
              locationService: fakeGps,
              damageReportRepository: DamageReportRepository(
                localStore: _InMemoryLocalStore(),
                autoStartOnUse: false,
              ),
              heatmapService: DefaultDamageHeatmapService(
                repository: DamageReportRepository(
                  localStore: _InMemoryLocalStore(),
                  autoStartOnUse: false,
                ),
                remoteFetcher: () async => const [],
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Shelter terdekat yang otomatis disorot adalah SMPN 1 Padang (~111 meter)
        expect(find.text('SMPN 1 Padang (Vertical Evac)'), findsOneWidget);
        expect(find.text('400 meter'), findsNothing);
        expect(find.text('111 meter'), findsOneWidget);
        expect(find.textContaining('GPS Aktif (-0.9510, 100.3610)'), findsOneWidget);
      },
    );

    testWidgets(
      'Filter "🔥 Peta Kerusakan" menampilkan titik kerusakan lokal + status jujur, dan mengetuk titik menampilkan detail risiko',
      (tester) async {
        final localStore = _InMemoryLocalStore([
          _buildLocalReport(
            id: 'dmg_padang_1',
            category: DamageCategory.berat,
            summary: 'Kolom beton lantai 1 retak parah di kawasan Padang Barat.',
            confidence: 0.92,
            location: VisionLocationData(
              latitude: -0.9480,
              longitude: 100.3550,
              displayLabel: 'GPS Perangkat',
              capturedAt: DateTime(2026, 11, 27, 9, 45),
            ),
          ),
        ]);
        final repo = DamageReportRepository(
          localStore: localStore,
          autoStartOnUse: false,
        );
        final heatmapService = DefaultDamageHeatmapService(
          repository: repo,
          remoteFetcher: () async => throw ApiException(
            statusCode: 503,
            code: 'OFFLINE',
            message: 'Server offline',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: PetaScreen(
              locationService: _FakeLocationService(
                EvacuationLocationResult.fallback(
                  statusMessage: 'Fallback Padang Barat',
                ),
              ),
              damageReportRepository: repo,
              heatmapService: heatmapService,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Tap filter chip ke-5: "🔥 Peta Kerusakan"
        final heatmapChip = find.text('🔥 Peta Kerusakan');
        await tester.ensureVisible(heatmapChip);
        await tester.pump();
        await tester.tap(heatmapChip);
        await tester.pump(const Duration(milliseconds: 200));

        // Verifikasi banner status jujur & daftar ringkas titik kerusakan muncul
        expect(find.byKey(const ValueKey('heatmap_status_banner')), findsOneWidget);
        expect(find.textContaining('Mode Lokal: 1 titik kerusakan'), findsOneWidget);
        expect(find.text('Peta Sebaran Kerusakan (1 Titik)'), findsOneWidget);

        // Ketuk chip laporan kerusakan -> kartu detail risiko tampil tanpa crash
        final pointChip = find.byKey(const ValueKey('heatmap_chip_dmg_padang_1'));
        await tester.ensureVisible(pointChip);
        await tester.tap(pointChip);
        await tester.pump(const Duration(milliseconds: 150));

        expect(find.text('BAHAYA KRITIS (Severe)'), findsOneWidget);
        expect(find.text('Lokal SQLite'), findsOneWidget);
        expect(find.text('Confidence: 92%'), findsOneWidget);
        expect(
          find.textContaining('Kolom beton lantai 1 retak parah'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Tombol kembali muncul di header PetaScreen saat dibuka via Navigator.push (canPop == true) dan kembali ke layar sebelumnya saat ditekan',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PetaScreen(
                            locationService: _FakeLocationService(
                              EvacuationLocationResult.fallback(
                                statusMessage: 'Fallback',
                              ),
                            ),
                            damageReportRepository: DamageReportRepository(
                              localStore: _InMemoryLocalStore(),
                              autoStartOnUse: false,
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text('Buka Peta'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Buka Peta'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 320));

        expect(find.byType(PetaScreen), findsOneWidget);
        final backBtn = find.byKey(const ValueKey('peta_back_button'));
        expect(backBtn, findsOneWidget);

        await tester.tap(backBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(PetaScreen), findsNothing);
        expect(find.text('Buka Peta'), findsOneWidget);
      },
    );
  });
}
