import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sigap/features/dashboard/presentation/screens/home_screen.dart';
import 'package:sigap/features/evacuation/data/evacuation_location_service.dart';
import 'package:sigap/features/evacuation/data/padang_evacuation_data.dart';
import 'package:sigap/features/evacuation/domain/evacuation_decision_engine.dart';
import 'package:sigap/features/evacuation/domain/evacuation_models.dart';
import 'package:sigap/features/evacuation/presentation/screens/evacuation_guide_screen.dart';
import 'package:sigap/features/map/presentation/screens/peta_screen.dart';

class _FakeLocationService implements EvacuationLocationService {
  final EvacuationLocationResult result;
  int fetchCount = 0;
  int openSettingsCount = 0;

  _FakeLocationService(this.result);

  @override
  Future<EvacuationLocationResult> fetchCurrentLocation() async {
    fetchCount += 1;
    return result;
  }

  @override
  Future<bool> openDeviceAppSettings() async {
    openSettingsCount += 1;
    return true;
  }
}

void main() {
  group('FE-07 — Unit Test Mesin Keputusan, Haversine & Bearing', () {
    test(
      'calculateHaversineDistanceMeters menghitung jarak akurat (titik sama = 0, Padang Barat ke SMPN 1 ~817m)',
      () {
        expect(
          calculateHaversineDistanceMeters(-0.9492, 100.3542, -0.9492, 100.3542),
          closeTo(0.0, 0.001),
        );

        // 1 derajat lintang di sekitar ekuator ~ 111.195 km
        final oneDegLat = calculateHaversineDistanceMeters(
          0.0,
          100.0,
          1.0,
          100.0,
        );
        expect(oneDegLat, closeTo(111195.0, 250.0));

        // Dari fallback Padang Barat (-0.9492, 100.3542) ke SMPN 1 Padang (-0.9520, 100.3610)
        final toSmp1 = calculateHaversineDistanceMeters(
          -0.9492,
          100.3542,
          -0.9520,
          100.3610,
        );
        expect(toSmp1, inInclusiveRange(780.0, 860.0));
      },
    );

    test(
      'calculateBearingDegrees & bearingToCardinalDirection mengonversi 8 arah mata angin Indonesia dengan tepat',
      () {
        // Utara (lat naik)
        final north = calculateBearingDegrees(-0.95, 100.35, -0.90, 100.35);
        expect(north, closeTo(0.0, 1.0));
        expect(bearingToCardinalDirection(north), 'Utara');

        // Timur (lng naik)
        final east = calculateBearingDegrees(-0.95, 100.35, -0.95, 100.40);
        expect(east, closeTo(90.0, 1.0));
        expect(bearingToCardinalDirection(east), 'Timur');

        // Selatan (lat turun)
        final south = calculateBearingDegrees(-0.90, 100.35, -0.95, 100.35);
        expect(south, closeTo(180.0, 1.0));
        expect(bearingToCardinalDirection(south), 'Selatan');

        // Barat (lng turun)
        final west = calculateBearingDegrees(-0.95, 100.40, -0.95, 100.35);
        expect(west, closeTo(270.0, 1.0));
        expect(bearingToCardinalDirection(west), 'Barat');

        // Cek 8 arah utama & sudut batas
        expect(bearingToCardinalDirection(0), 'Utara');
        expect(bearingToCardinalDirection(359), 'Utara');
        expect(bearingToCardinalDirection(45), 'Timur Laut');
        expect(bearingToCardinalDirection(90), 'Timur');
        expect(bearingToCardinalDirection(135), 'Tenggara');
        expect(bearingToCardinalDirection(180), 'Selatan');
        expect(bearingToCardinalDirection(225), 'Barat Daya');
        expect(bearingToCardinalDirection(270), 'Barat');
        expect(bearingToCardinalDirection(315), 'Barat Laut');
      },
    );

    test(
      'Skenario Golden Time mepet di pesisir memilih Evakuasi Vertikal (TES terdekat) dengan pesan tegas revisi Zidan',
      () {
        // Posisi pesisir Padang Barat dekat UNP (-0.8995, 100.3510) dengan sisa 12 menit
        final decision = EvacuationDecisionEngine.evaluate(
          userLat: -0.8995,
          userLng: 100.3510,
          remainingGoldenTimeMinutes: 12.0,
          tesShelters: PadangEvacuationData.tesShelters,
          horizontalSafeZones: PadangEvacuationData.horizontalSafeZones,
        );

        expect(decision.recommendedType, EvacuationPointType.verticalTes);
        expect(decision.isVerticalRecommended, isTrue);
        expect(decision.primaryTarget.id, 'shelter_unp');
        expect(decision.nearestTes.id, 'shelter_unp');
        expect(
          decision.headline,
          startsWith(
            'Evakuasi Horizontal Tidak Memungkinkan! Evakuasi Vertikal ke TES Terdekat: Gedung TES UNP (',
          ),
        );
        expect(decision.steps, isNotEmpty);
      },
    );

    test(
      'Skenario Golden Time cukup & dekat dataran tinggi timur memilih Evakuasi Horizontal',
      () {
        // Posisi dekat Bypass Timur Padang (-0.9380, 100.3940) -> ~460m (~6 mnt jalan kaki)
        // Sisa Golden Time 20 menit (+ margin 3 menit = 9 <= 20) -> Horizontal aman
        final decision = EvacuationDecisionEngine.evaluate(
          userLat: -0.9380,
          userLng: 100.3940,
          remainingGoldenTimeMinutes: 20.0,
          tesShelters: PadangEvacuationData.tesShelters,
          horizontalSafeZones: PadangEvacuationData.horizontalSafeZones,
        );

        expect(
          decision.recommendedType,
          EvacuationPointType.horizontalSafeZone,
        );
        expect(decision.isVerticalRecommended, isFalse);
        expect(decision.primaryTarget.id, 'zone_bypass_timur');
        expect(decision.nearestHorizontalZone.id, 'zone_bypass_timur');
        expect(decision.etaToHorizontalMinutes + 3.0, lessThanOrEqualTo(20.0));
        expect(decision.headline, contains('Bypass Timur Padang'));
        expect(decision.rationale, contains(decision.nearestTes.name));
      },
    );
  });

  group('FE-07 — Widget Test EvacuationGuideScreen', () {
    testWidgets(
      'Menampilkan Golden Time Countdown + disclaimer wajib, kartu keputusan vertikal, kompas arah GPS Utara, dan dispose aman tanpa pending timer',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: EvacuationGuideScreen(
              initialRemainingSeconds: 900, // 15:00
              initialPositionOverride: LatLng(-0.8995, 100.3510),
              autoStartTimer: true,
            ),
          ),
        );
        await tester.pump();

        // 1. Verifikasi Golden Time Countdown & disclaimer wajib
        expect(find.text('SISA GOLDEN TIME EVAKUASI'), findsOneWidget);
        expect(find.text('15:00'), findsOneWidget);
        expect(
          find.text(HomeScreen.goldenTimeDisclaimerText),
          findsOneWidget,
        );

        // Hitung mundur berkurang setelah 2 detik -> 14:58
        await tester.pump(const Duration(seconds: 2));
        expect(find.text('14:58'), findsOneWidget);

        // 2. Verifikasi kartu keputusan Evakuasi Vertikal (TES)
        expect(find.text('EVAKUASI VERTIKAL (TES)'), findsOneWidget);
        expect(
          find.textContaining(
            'Evakuasi Horizontal Tidak Memungkinkan! Evakuasi Vertikal ke TES Terdekat: Gedung TES UNP',
          ),
          findsOneWidget,
        );

        // 3. Verifikasi kompas penunjuk arah & keterangan jujur acuan Utara
        expect(
          find.byKey(const ValueKey('evacuation_compass_card')),
          findsOneWidget,
        );
        expect(
          find.text('Penunjuk arah berdasarkan koordinat GPS (Acuan Utara)'),
          findsOneWidget,
        );

        // 4. Verifikasi dispose() bebas pending timer error
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets(
      'Menangani fallback lokasi saat GPS ditolak permanen (menampilkan status fallback, Perbarui GPS, dan Buka Pengaturan)',
      (tester) async {
        final fakeService = _FakeLocationService(
          EvacuationLocationResult.fallback(
            permissionDenied: true,
            permanentlyDenied: true,
            statusMessage:
                'Izin lokasi ditolak permanen. Buka Pengaturan Aplikasi untuk mengaktifkan GPS.',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: EvacuationGuideScreen(
              initialRemainingSeconds: 1200,
              locationService: fakeService,
              autoStartTimer: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(fakeService.fetchCount, 1);
        expect(find.text('Lokasi Perkiraan (Fallback Padang)'), findsOneWidget);
        expect(
          find.textContaining('Izin lokasi ditolak permanen'),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('refresh_gps_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('open_app_settings_button')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey('open_app_settings_button')));
        await tester.pump();
        expect(fakeService.openSettingsCount, 1);
      },
    );

    testWidgets(
      'Menekan tombol "Lihat di Peta Siaga" membuka PetaScreen',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: EvacuationGuideScreen(
              initialRemainingSeconds: 1200,
              initialPositionOverride: LatLng(-0.9380, 100.3940),
              autoStartTimer: false,
            ),
          ),
        );
        await tester.pump();

        // Sekaligus verifikasi rekomendasi Horizontal tampil untuk posisi dekat Bypass Timur
        expect(find.text('EVAKUASI HORIZONTAL (ZONA AMAN)'), findsOneWidget);

        final mapBtn = find.byKey(const ValueKey('open_peta_siaga_button'));
        await tester.ensureVisible(mapBtn);
        await tester.pump();
        await tester.tap(mapBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 320));

        expect(find.byType(PetaScreen), findsOneWidget);
      },
    );
  });
}
