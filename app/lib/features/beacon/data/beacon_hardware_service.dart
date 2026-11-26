import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../domain/beacon_models.dart';

/// Abstraksi layanan perangkat keras untuk Suar SOS Offline (senter flash,
/// panggilan suara TTS, haptic pulse, dan pengecekan izin kamera/Bluetooth)
/// agar UI bersih dan mudah diuji dengan mock/fake service.
abstract class EmergencyBeaconHardwareService {
  Future<BeaconPermissionSnapshot> checkPermissions();
  Future<BeaconPermissionSnapshot> requestBluetoothPermissions();
  Future<bool> requestCameraPermission();
  Future<bool> openDeviceSettings();
  Future<bool> initializeTorch();
  Future<void> setTorch(bool enabled);
  Future<void> releaseTorch();
  Future<void> speakDistressCall(String text);
  Future<void> stopSpeaking();
  Future<void> triggerHapticPulse();
  Future<void> dispose();
}

/// Implementasi default [EmergencyBeaconHardwareService] memanfaatkan plugin
/// yang sudah terpasang (`camera`, `flutter_tts`, `permission_handler`, dan
/// `HapticFeedback`) dengan penanganan error aman agar tidak crash di emulator,
/// test, maupun perangkat tanpa flash.
class DefaultEmergencyBeaconHardwareService
    implements EmergencyBeaconHardwareService {
  CameraController? _cameraController;
  FlutterTts? _tts;
  bool _ttsConfigured = false;

  bool get _isMobilePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<BeaconPermissionSnapshot> checkPermissions() async {
    if (!_isMobilePlatform) {
      return const BeaconPermissionSnapshot(platformSupported: false);
    }

    try {
      final cameraStatus = await Permission.camera.status;
      final btAdvStatus = await Permission.bluetoothAdvertise.status;
      final btConnStatus = await Permission.bluetoothConnect.status;

      return BeaconPermissionSnapshot(
        cameraGranted: cameraStatus.isGranted,
        cameraPermanentlyDenied: cameraStatus.isPermanentlyDenied,
        bluetoothAdvertiseGranted: btAdvStatus.isGranted,
        bluetoothConnectGranted: btConnStatus.isGranted,
        bluetoothPermanentlyDenied:
            btAdvStatus.isPermanentlyDenied || btConnStatus.isPermanentlyDenied,
        platformSupported: true,
      );
    } on MissingPluginException {
      return const BeaconPermissionSnapshot(platformSupported: false);
    } on PlatformException {
      return const BeaconPermissionSnapshot(platformSupported: false);
    } catch (_) {
      return const BeaconPermissionSnapshot(platformSupported: false);
    }
  }

  @override
  Future<BeaconPermissionSnapshot> requestBluetoothPermissions() async {
    if (!_isMobilePlatform) {
      return const BeaconPermissionSnapshot(platformSupported: false);
    }

    try {
      await Permission.bluetoothAdvertise.request();
      await Permission.bluetoothConnect.request();
      return await checkPermissions();
    } on MissingPluginException {
      return const BeaconPermissionSnapshot(platformSupported: false);
    } on PlatformException {
      return await checkPermissions();
    } catch (_) {
      return await checkPermissions();
    }
  }

  @override
  Future<bool> requestCameraPermission() async {
    if (!_isMobilePlatform) {
      return false;
    }

    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> openDeviceSettings() async {
    try {
      return await openAppSettings();
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> initializeTorch() async {
    if (!_isMobilePlatform) {
      return false;
    }

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      return true;
    }

    try {
      final cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        final requested = await Permission.camera.request();
        if (!requested.isGranted) {
          return false;
        }
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return false;
      }

      final rearCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        rearCamera,
        ResolutionPreset.low,
        enableAudio: false,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      _cameraController = controller;
      return true;
    } on CameraException {
      await releaseTorch();
      return false;
    } on MissingPluginException {
      await releaseTorch();
      return false;
    } on PlatformException {
      await releaseTorch();
      return false;
    } catch (_) {
      await releaseTorch();
      return false;
    }
  }

  @override
  Future<void> setTorch(bool enabled) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    try {
      await controller.setFlashMode(enabled ? FlashMode.torch : FlashMode.off);
    } on CameraException {
      // Abaikan secara aman jika perangkat tidak mendukung perubahan flash.
    } on MissingPluginException {
      // Aman di lingkungan test/non-native.
    } on PlatformException {
      // Abaikan kegagalan sementara hardware.
    } catch (_) {
      // Jangan pernah melempar crash saat kondisi darurat.
    }
  }

  @override
  Future<void> releaseTorch() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller == null) {
      return;
    }

    try {
      if (controller.value.isInitialized) {
        await controller.setFlashMode(FlashMode.off);
      }
    } catch (_) {
      // Tetap lanjutkan proses dispose controller.
    }

    try {
      await controller.dispose();
    } catch (_) {
      // Abaikan error dispose pada emulator/test.
    }
  }

  @override
  Future<void> speakDistressCall(String text) async {
    try {
      _tts ??= FlutterTts();
      if (!_ttsConfigured) {
        await _tts!.setLanguage('id-ID');
        await _tts!.setSpeechRate(0.48);
        await _tts!.setVolume(1.0);
        await _tts!.setPitch(1.05);
        _ttsConfigured = true;
      }
      await _tts!.stop();
      await _tts!.speak(text);
    } on MissingPluginException {
      // Aman di lingkungan test tanpa channel TTS.
    } on PlatformException {
      // Abaikan error platform TTS secara aman.
    } catch (_) {
      // Jangan melempar crash saat darurat.
    }
  }

  @override
  Future<void> stopSpeaking() async {
    final tts = _tts;
    if (tts == null) {
      return;
    }
    try {
      await tts.stop();
    } on MissingPluginException {
      // Aman di lingkungan test.
    } on PlatformException {
      // Abaikan error platform.
    } catch (_) {
      // Abaikan error penghentian TTS.
    }
  }

  @override
  Future<void> triggerHapticPulse() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {
      // Abaikan jika haptic tidak tersedia.
    }
  }

  @override
  Future<void> dispose() async {
    await releaseTorch();
    await stopSpeaking();
  }
}
