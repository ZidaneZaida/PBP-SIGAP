import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sigap/features/beacon/data/beacon_hardware_service.dart';
import 'package:sigap/features/beacon/domain/beacon_models.dart';
import 'package:sigap/features/beacon/domain/morse_sos_engine.dart';
import 'package:sigap/features/beacon/presentation/screens/emergency_beacon_screen.dart';
import 'package:sigap/features/evacuation/data/evacuation_location_service.dart';

class _FakeBeaconHardwareService implements EmergencyBeaconHardwareService {
  BeaconPermissionSnapshot permissionSnapshot;
  bool torchShouldInitialize;

  int initializeTorchCalls = 0;
  int releaseTorchCalls = 0;
  int stopSpeakingCalls = 0;
  int hapticPulseCalls = 0;
  int requestBluetoothCalls = 0;
  int requestCameraCalls = 0;
  int openSettingsCalls = 0;
  int disposeCalls = 0;

  final List<bool> torchStates = <bool>[];
  final List<String> spokenTexts = <String>[];

  _FakeBeaconHardwareService({
    this.permissionSnapshot = const BeaconPermissionSnapshot(
      cameraGranted: true,
      bluetoothAdvertiseGranted: false,
      bluetoothConnectGranted: false,
      platformSupported: true,
    ),
    this.torchShouldInitialize = true,
  });

  @override
  Future<BeaconPermissionSnapshot> checkPermissions() async =>
      permissionSnapshot;

  @override
  Future<BeaconPermissionSnapshot> requestBluetoothPermissions() async {
    requestBluetoothCalls += 1;
    permissionSnapshot = permissionSnapshot.copyWith(
      bluetoothAdvertiseGranted: true,
      bluetoothConnectGranted: true,
      bluetoothPermanentlyDenied: false,
    );
    return permissionSnapshot;
  }

  @override
  Future<bool> requestCameraPermission() async {
    requestCameraCalls += 1;
    permissionSnapshot = permissionSnapshot.copyWith(
      cameraGranted: true,
      cameraPermanentlyDenied: false,
    );
    return true;
  }

  @override
  Future<bool> openDeviceSettings() async {
    openSettingsCalls += 1;
    return true;
  }

  @override
  Future<bool> initializeTorch() async {
    initializeTorchCalls += 1;
    return torchShouldInitialize;
  }

  @override
  Future<void> setTorch(bool enabled) async {
    torchStates.add(enabled);
  }

  @override
  Future<void> releaseTorch() async {
    releaseTorchCalls += 1;
  }

  @override
  Future<void> speakDistressCall(String text) async {
    spokenTexts.add(text);
  }

  @override
  Future<void> stopSpeaking() async {
    stopSpeakingCalls += 1;
  }

  @override
  Future<void> triggerHapticPulse() async {
    hapticPulseCalls += 1;
  }

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
  }
}

class _FakeEvacuationLocationService implements EvacuationLocationService {
  final EvacuationLocationResult result;

  _FakeEvacuationLocationService(this.result);

  @override
  Future<EvacuationLocationResult> fetchCurrentLocation() async => result;

  @override
  Future<bool> openDeviceAppSettings() async => true;
}

void main() {
  group('FE-09 — Unit Test Morse SOS & OfflineSosPayload', () {
    test(
      'buildSosMorseSequence menghasilkan 3 titik (S), 3 garis (O), 3 titik (S) dengan durasi standar dan jeda siklus 7 unit',
      () {
        final sequence = buildSosMorseSequence();

        // Total 18 langkah (9 nyala + 9 jeda) dan total 34 unit dasar
        expect(sequence.length, 18);
        expect(calculateTotalMorseUnits(sequence), 34);

        final litSteps = sequence.where((s) => s.isLightOn).toList();
        expect(litSteps.length, 9);

        // 3 titik huruf S (1 unit)
        for (var i = 0; i < 3; i++) {
          expect(litSteps[i].letter, 'S');
          expect(litSteps[i].symbolLabel, '•');
          expect(litSteps[i].durationUnits, 1);
        }

        // 3 garis huruf O (3 unit)
        for (var i = 3; i < 6; i++) {
          expect(litSteps[i].letter, 'O');
          expect(litSteps[i].symbolLabel, '—');
          expect(litSteps[i].durationUnits, 3);
        }

        // 3 titik huruf S kedua (1 unit)
        for (var i = 6; i < 9; i++) {
          expect(litSteps[i].letter, 'S');
          expect(litSteps[i].symbolLabel, '•');
          expect(litSteps[i].durationUnits, 1);
        }

        // Jeda antarhuruf S->O (index 5) dan O->S (index 11) = 3 unit mati
        expect(sequence[5].isLightOn, isFalse);
        expect(sequence[5].durationUnits, 3);
        expect(sequence[5].letter, 'JEDA');

        expect(sequence[11].isLightOn, isFalse);
        expect(sequence[11].durationUnits, 3);
        expect(sequence[11].letter, 'JEDA');

        // Jeda antarsiklus di akhir (index 17) = 7 unit mati
        expect(sequence.last.isLightOn, isFalse);
        expect(sequence.last.durationUnits, 7);
        expect(sequence.last.letter, 'JEDA');
      },
    );

    test(
      'OfflineSosPayload.toCompactPayloadString memformat koordinat dan metadata secara konsisten',
      () {
        final gpsPayload = OfflineSosPayload(
          beaconId: 'SIGAP-PDG-01',
          latitude: -0.949234,
          longitude: 100.354219,
          isFallbackLocation: false,
          generatedAt: DateTime.utc(2026, 11, 27, 8, 5, 9),
          statusText: 'SOS_BUTUH_EVAKUASI',
        );

        expect(
          gpsPayload.toCompactPayloadString(),
          'SIGAP-SOS|ID:SIGAP-PDG-01|LOC:-0.94923,100.35422|SRC:GPS|UTC:2026-11-27T08:05:09Z|MSG:SOS_BUTUH_EVAKUASI',
        );

        final fallbackPayload = OfflineSosPayload(
          beaconId: 'SIGAP-PDG-01',
          latitude: -0.9492,
          longitude: 100.3542,
          isFallbackLocation: true,
          generatedAt: DateTime.utc(2026, 11, 27, 8, 5, 9),
          statusText: 'SIAGA_DARURAT',
        );

        expect(fallbackPayload.toCompactPayloadString(), contains('|SRC:EST|'));
      },
    );
  });

  group('FE-09 — Widget Test EmergencyBeaconScreen', () {
    testWidgets(
      'Aktivasi & deaktivasi Suar SOS menjalankan Morse torch on/off, memanggil TTS, dan mematikan torch + TTS + timer secara bersih',
      (tester) async {
        final fakeHardware = _FakeBeaconHardwareService(
          torchShouldInitialize: true,
        );
        final fakeLocation = _FakeEvacuationLocationService(
          EvacuationLocationResult(
            position: const LatLng(-0.9492, 100.3542),
            isFallback: false,
            sourceLabel: 'GPS Aktif',
            statusMessage: 'Koordinat GPS aktif.',
            fetchedAt: DateTime.utc(2026, 11, 27, 1, 0, 0),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: EmergencyBeaconScreen(
              hardwareService: fakeHardware,
              locationService: fakeLocation,
              morseUnitDuration: const Duration(milliseconds: 50),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('SIAGA'), findsOneWidget);
        expect(find.text('AKTIFKAN SUAR SOS'), findsOneWidget);

        // Aktifkan Suar SOS
        await tester.tap(find.byKey(const ValueKey('master_sos_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 10));

        expect(find.text('SUAR SOS AKTIF'), findsOneWidget);
        expect(find.text('HENTIKAN SUAR SOS'), findsOneWidget);
        expect(fakeHardware.initializeTorchCalls, 1);
        expect(fakeHardware.spokenTexts, isNotEmpty);
        expect(
          fakeHardware.spokenTexts.first,
          EmergencyBeaconScreen.distressSpeechText,
        );

        // Pompa beberapa langkah Morse (50ms per unit): on -> off -> on
        await tester.pump(const Duration(milliseconds: 60));
        await tester.pump(const Duration(milliseconds: 60));
        await tester.pump(const Duration(milliseconds: 60));

        expect(fakeHardware.torchStates, containsAllInOrder([true, false, true]));

        // Hentikan Suar SOS via tombol master
        await tester.tap(find.byKey(const ValueKey('master_sos_button')));
        await tester.pump();

        expect(find.text('SIAGA'), findsOneWidget);
        expect(fakeHardware.torchStates.last, isFalse);
        expect(fakeHardware.releaseTorchCalls, greaterThanOrEqualTo(1));
        expect(fakeHardware.stopSpeakingCalls, greaterThanOrEqualTo(1));

        // Pastikan dispose() bebas pending timer
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        expect(fakeHardware.disposeCalls, 1);
      },
    );

    testWidgets(
      'Status BLE tampil jujur (tidak mengklaim radio BLE aktif) dan tombol izin Bluetooth memanggil requestBluetoothPermissions()',
      (tester) async {
        final fakeHardware = _FakeBeaconHardwareService(
          permissionSnapshot: const BeaconPermissionSnapshot(
            cameraGranted: true,
            bluetoothAdvertiseGranted: false,
            bluetoothConnectGranted: false,
            platformSupported: true,
          ),
        );
        final fakeLocation = _FakeEvacuationLocationService(
          EvacuationLocationResult.fallback(
            statusMessage: 'GPS tidak tersedia, memakai fallback Padang Barat.',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: EmergencyBeaconScreen(
              hardwareService: fakeHardware,
              locationService: fakeLocation,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('IZIN BLUETOOTH BELUM AKTIF'), findsOneWidget);

        final btBtn = find.byKey(const ValueKey('request_ble_permission_button'));
        await tester.ensureVisible(btBtn);
        await tester.pump();
        await tester.tap(btBtn);
        await tester.pumpAndSettle();

        expect(fakeHardware.requestBluetoothCalls, 1);
        // Setelah izin diberikan, tetap jujur bahwa transmisi radio menunggu plugin native
        expect(
          find.text('IZIN BLE SIAP (MENUNGGU PLUGIN RADIO)'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Transmisi Radio BLE Menunggu Integrasi Plugin Native'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Fallback saat torch tidak tersedia tetap menjalankan strobo layar Morse tanpa crash',
      (tester) async {
        final fakeHardware = _FakeBeaconHardwareService(
          torchShouldInitialize: false,
          permissionSnapshot: const BeaconPermissionSnapshot(
            cameraGranted: true,
            platformSupported: true,
          ),
        );
        final fakeLocation = _FakeEvacuationLocationService(
          EvacuationLocationResult.fallback(
            statusMessage: 'Memakai lokasi perkiraan Padang Barat.',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: EmergencyBeaconScreen(
              hardwareService: fakeHardware,
              locationService: fakeLocation,
              morseUnitDuration: const Duration(milliseconds: 50),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('master_sos_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 10));

        expect(fakeHardware.initializeTorchCalls, 1);
        expect(find.text('SUAR SOS AKTIF'), findsOneWidget);
        expect(
          find.textContaining('Flash kamera tidak tersedia pada perangkat ini'),
          findsOneWidget,
        );

        // Saat fase nyala (step 0: S), strobo layar menampilkan 'S O S'
        expect(find.text('S O S'), findsOneWidget);

        // Pompa ke fase jeda (step 1: off) -> strobo layar berganti tanpa crash
        await tester.pump(const Duration(milliseconds: 55));
        expect(find.text('•  —  •'), findsOneWidget);

        // Dispose saat beacon masih aktif harus tetap bebas pending timer
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        expect(fakeHardware.releaseTorchCalls, greaterThanOrEqualTo(1));
        expect(fakeHardware.stopSpeakingCalls, greaterThanOrEqualTo(1));
      },
    );
  });
}
