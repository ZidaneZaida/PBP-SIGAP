import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap/features/dashboard/presentation/screens/home_screen.dart';
import 'package:sigap/features/evacuation/presentation/screens/evacuation_guide_screen.dart';
import 'package:sigap/features/splash/presentation/screens/splash_screen.dart';

void main() {
  group('FE-06 — Emergency State HomeScreen & Perbaikan SplashScreen', () {
    test('calculateGoldenTimeMinutes menghitung estimasi sesuai rumus distanceKm / 700 * 60', () {
      expect(calculateGoldenTimeMinutes(0), 0.0);
      expect(calculateGoldenTimeMinutes(-10), 0.0);
      expect(calculateGoldenTimeMinutes(350), closeTo(30.0, 0.001));
      expect(calculateGoldenTimeMinutes(175), closeTo(15.0, 0.001));
    });

    testWidgets(
      'SplashScreen(simulateEmergency: true, simulateOffline: true) menavigasi langsung ke Emergency State',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SplashScreen(
              simulateEmergency: true,
              simulateOffline: true,
            ),
          ),
        );

        // Pompa hingga animasi splash (1800ms) & transisi fade (400ms) selesai
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 1800));
        await tester.pump(const Duration(milliseconds: 450));

        expect(find.text('PERINGATAN DARURAT AKTIF'), findsOneWidget);
        expect(find.text('Mode: Darurat'), findsOneWidget);
        expect(find.text('GOLDEN TIME EVAKUASI TSUNAMI'), findsOneWidget);
      },
    );

    testWidgets(
      'HomeScreen(initialEmergencyState: true) menampilkan latar kontras tinggi, Golden Time Countdown + disclaimer, dan 2 tombol darurat raksasa',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(initialEmergencyState: true),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // 1. Verifikasi latar kontras tinggi darurat pada Scaffold
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(scaffold.backgroundColor, const Color(0xFF450A0A));

        // 2. Verifikasi Golden Time Countdown & disclaimer wajib
        expect(find.text('GOLDEN TIME EVAKUASI TSUNAMI'), findsOneWidget);
        expect(find.text('20:00'), findsOneWidget);
        expect(
          find.text(HomeScreen.goldenTimeDisclaimerText),
          findsOneWidget,
        );

        // Verifikasi hitung mundur berjalan 2 detik -> 19:58
        await tester.pump(const Duration(seconds: 2));
        expect(find.text('19:58'), findsOneWidget);

        // 3. Verifikasi kedua tombol darurat raksasa
        expect(find.text('PANDUAN EVAKUASI KE SHELTER TES'), findsOneWidget);
        expect(find.text('AKTIFKAN SUAR SOS OFFLINE'), findsOneWidget);
      },
    );

    testWidgets(
      'Menekan "PANDUAN EVAKUASI KE SHELTER TES" membuka layar EvacuationGuideScreen',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(initialEmergencyState: true),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        final evacBtn = find.text('PANDUAN EVAKUASI KE SHELTER TES');
        await tester.ensureVisible(evacBtn);
        await tester.pump();
        await tester.tap(evacBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 320));

        expect(find.byType(EvacuationGuideScreen), findsOneWidget);
        expect(find.text('Panduan Evakuasi Tsunami'), findsOneWidget);
      },
    );

    testWidgets(
      'Menekan "AKTIFKAN SUAR SOS OFFLINE" membuka sheet akses darurat offline secara fungsional',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(initialEmergencyState: true),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        final beaconBtn = find.text('AKTIFKAN SUAR SOS OFFLINE');
        await tester.ensureVisible(beaconBtn);
        await tester.pump();
        await tester.tap(beaconBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Akses Suar SOS Offline'), findsOneWidget);
        expect(find.textContaining('FE-09'), findsOneWidget);
        expect(find.text('Buka Sirine SOS Darurat'), findsOneWidget);
        expect(find.text('Hubungi Kontak Darurat 112 / BPBD'), findsOneWidget);
      },
    );

    testWidgets(
      'Mematikan toggle tsunami menyembunyikan Golden Time Countdown dan dispose() aman tanpa pending timer',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(initialEmergencyState: true),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('GOLDEN TIME EVAKUASI TSUNAMI'), findsOneWidget);

        // Matikan toggle tsunami -> Golden Time Countdown tersembunyi & timer berhenti
        await tester.tap(find.text('🚨 BERPOTENSI TSUNAMI'));
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('✅ TIDAK BERPOTENSI TSUNAMI'), findsOneWidget);
        expect(find.text('GOLDEN TIME EVAKUASI TSUNAMI'), findsNothing);

        // Aktifkan lagi toggle tsunami lalu langsung dispose saat timer berjalan
        await tester.tap(find.text('✅ TIDAK BERPOTENSI TSUNAMI'));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('GOLDEN TIME EVAKUASI TSUNAMI'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  });
}
