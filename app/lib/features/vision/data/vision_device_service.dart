import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../domain/models/damage_models.dart';

/// Status izin kamera/galeri yang dinormalisasi agar mudah diuji dan ditampilkan di UI.
enum VisionPermissionState {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unsupported;

  bool get isGranted => this == VisionPermissionState.granted;

  String get label {
    switch (this) {
      case VisionPermissionState.granted:
        return 'Diizinkan';
      case VisionPermissionState.denied:
        return 'Belum Diizinkan';
      case VisionPermissionState.permanentlyDenied:
        return 'Ditolak Permanen';
      case VisionPermissionState.restricted:
        return 'Dibatasi Perangkat';
      case VisionPermissionState.unsupported:
        return 'Tidak Memerlukan Izin Khusus';
    }
  }
}

/// Hasil pemilihan foto dari galeri atau kamera sistem.
class PickedPhotoResult {
  final String? imagePath;
  final bool cancelled;
  final String? errorMessage;

  const PickedPhotoResult({
    this.imagePath,
    this.cancelled = false,
    this.errorMessage,
  });

  bool get hasPhoto => imagePath != null && imagePath!.isNotEmpty;
}

/// Hasil permintaan lokasi GPS opsional.
class LocationFetchResult {
  final VisionLocationData? location;
  final String? errorMessage;
  final bool permissionDenied;
  final bool permanentlyDenied;

  const LocationFetchResult({
    this.location,
    this.errorMessage,
    this.permissionDenied = false,
    this.permanentlyDenied = false,
  });

  bool get isSuccess => location != null;
}

/// Abstraksi layanan perangkat (izin, galeri, kamera sistem, lokasi GPS)
/// agar halaman UI tetap bersih dan mudah diuji secara otomatis.
abstract class VisionDeviceService {
  Future<VisionPermissionState> checkCameraPermission();
  Future<VisionPermissionState> requestCameraPermission();
  Future<VisionPermissionState> checkGalleryPermission();
  Future<VisionPermissionState> requestGalleryPermission();
  Future<bool> openDeviceAppSettings();
  Future<PickedPhotoResult> pickFromGallery();
  Future<PickedPhotoResult> captureWithSystemCamera();
  Future<LocationFetchResult> fetchCurrentLocation();
}

/// Implementasi default [VisionDeviceService] menggunakan plugin Flutter resmi.
class DefaultVisionDeviceService implements VisionDeviceService {
  static final DefaultVisionDeviceService instance =
      DefaultVisionDeviceService();

  final ImagePicker _picker;

  DefaultVisionDeviceService({ImagePicker? imagePicker})
      : _picker = imagePicker ?? ImagePicker();

  bool get _isMobilePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  VisionPermissionState _mapPermission(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return VisionPermissionState.granted;
    }
    if (status.isPermanentlyDenied) {
      return VisionPermissionState.permanentlyDenied;
    }
    if (status.isRestricted) {
      return VisionPermissionState.restricted;
    }
    return VisionPermissionState.denied;
  }

  @override
  Future<VisionPermissionState> checkCameraPermission() async {
    if (!_isMobilePlatform) return VisionPermissionState.unsupported;
    try {
      final status = await Permission.camera.status;
      return _mapPermission(status);
    } catch (_) {
      return VisionPermissionState.unsupported;
    }
  }

  @override
  Future<VisionPermissionState> requestCameraPermission() async {
    if (!_isMobilePlatform) return VisionPermissionState.unsupported;
    try {
      final status = await Permission.camera.request();
      return _mapPermission(status);
    } catch (_) {
      return VisionPermissionState.denied;
    }
  }

  @override
  Future<VisionPermissionState> checkGalleryPermission() async {
    if (!_isMobilePlatform) return VisionPermissionState.unsupported;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return _mapPermission(await Permission.photos.status);
      }
      // Pada Android modern (API 33+), Photo Picker tidak wajib meminta izin storage,
      // namun kita tetap periksa Permission.photos bila tersedia.
      final photosStatus = await Permission.photos.status;
      if (photosStatus.isGranted || photosStatus.isLimited) {
        return VisionPermissionState.granted;
      }
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) {
        return VisionPermissionState.granted;
      }
      return _mapPermission(photosStatus);
    } catch (_) {
      return VisionPermissionState.unsupported;
    }
  }

  @override
  Future<VisionPermissionState> requestGalleryPermission() async {
    if (!_isMobilePlatform) return VisionPermissionState.unsupported;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return _mapPermission(await Permission.photos.request());
      }
      final photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted || photosStatus.isLimited) {
        return VisionPermissionState.granted;
      }
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) {
        return VisionPermissionState.granted;
      }
      return _mapPermission(photosStatus);
    } catch (_) {
      return VisionPermissionState.denied;
    }
  }

  @override
  Future<bool> openDeviceAppSettings() async {
    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<PickedPhotoResult> pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
      );
      if (picked == null) {
        return const PickedPhotoResult(cancelled: true);
      }
      return PickedPhotoResult(imagePath: picked.path);
    } catch (e) {
      return PickedPhotoResult(
        errorMessage:
            'Gagal membuka galeri foto perangkat. Pastikan izin galeri aktif lalu coba lagi.',
      );
    }
  }

  @override
  Future<PickedPhotoResult> captureWithSystemCamera() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
      );
      if (picked == null) {
        return const PickedPhotoResult(cancelled: true);
      }
      return PickedPhotoResult(imagePath: picked.path);
    } catch (_) {
      return const PickedPhotoResult(
        errorMessage:
            'Kamera perangkat tidak tersedia atau gagal dibuka. Anda tetap dapat memilih foto dari galeri.',
      );
    }
  }

  @override
  Future<LocationFetchResult> fetchCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationFetchResult(
          errorMessage:
              'Layanan lokasi (GPS) perangkat sedang nonaktif. Aktifkan GPS untuk mencatat koordinat lokasi.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const LocationFetchResult(
          permissionDenied: true,
          errorMessage:
              'Izin lokasi ditolak. Pemeriksaan tetap dapat dilanjutkan tanpa mencatat lokasi.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationFetchResult(
          permissionDenied: true,
          permanentlyDenied: true,
          errorMessage:
              'Izin lokasi ditolak permanen. Buka Pengaturan aplikasi bila Anda ingin menyertakan koordinat GPS.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final latStr = position.latitude.toStringAsFixed(5);
      final lngStr = position.longitude.toStringAsFixed(5);
      return LocationFetchResult(
        location: VisionLocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          displayLabel: 'GPS Perangkat ($latStr, $lngStr)',
          capturedAt: DateTime.now(),
        ),
      );
    } on TimeoutException {
      return const LocationFetchResult(
        errorMessage:
            'Waktu pengambilan sinyal GPS habis. Anda tetap dapat melanjutkan pemeriksaan tanpa lokasi.',
      );
    } catch (_) {
      return const LocationFetchResult(
        errorMessage:
            'Lokasi GPS tidak tersedia pada perangkat ini. Pemeriksaan tetap dapat dilanjutkan tanpa lokasi.',
      );
    }
  }
}
