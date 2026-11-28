import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sigap/core/network/api_client.dart';
import 'package:sigap/core/network/api_config.dart';
import '../domain/evacuation_models.dart';
import 'padang_evacuation_data.dart';

/// Hasil pengambilan posisi GPS untuk panduan evakuasi tsunami.
/// Selalu menyediakan koordinat valid (baik GPS nyata maupun fallback Kota Padang)
/// agar panduan evakuasi tetap dapat bekerja dalam situasi darurat.
class EvacuationLocationResult {
  final LatLng position;
  final bool isFallback;
  final String sourceLabel;
  final String statusMessage;
  final bool serviceDisabled;
  final bool permissionDenied;
  final bool permanentlyDenied;
  final DateTime fetchedAt;

  const EvacuationLocationResult({
    required this.position,
    required this.isFallback,
    required this.sourceLabel,
    required this.statusMessage,
    this.serviceDisabled = false,
    this.permissionDenied = false,
    this.permanentlyDenied = false,
    required this.fetchedAt,
  });

  factory EvacuationLocationResult.fallback({
    required String statusMessage,
    bool serviceDisabled = false,
    bool permissionDenied = false,
    bool permanentlyDenied = false,
  }) {
    return EvacuationLocationResult(
      position: PadangEvacuationData.defaultFallbackLocation,
      isFallback: true,
      sourceLabel: PadangEvacuationData.defaultFallbackAreaLabel,
      statusMessage: statusMessage,
      serviceDisabled: serviceDisabled,
      permissionDenied: permissionDenied,
      permanentlyDenied: permanentlyDenied,
      fetchedAt: DateTime.now(),
    );
  }
}

/// Abstraksi layanan lokasi GPS untuk layar Evakuasi agar mudah diuji (mockable).
abstract class EvacuationLocationService {
  Future<EvacuationLocationResult> fetchCurrentLocation();
  Future<bool> openDeviceAppSettings();
}

/// Implementasi default menggunakan `geolocator` dan `permission_handler`,
/// mengikuti pola pengecekan layanan, izin, dan timeout 8 detik seperti `VisionDeviceService`.
class DefaultEvacuationLocationService implements EvacuationLocationService {
  static final DefaultEvacuationLocationService instance =
      DefaultEvacuationLocationService();

  @override
  Future<bool> openDeviceAppSettings() async {
    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<EvacuationLocationResult> fetchCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return EvacuationLocationResult.fallback(
          serviceDisabled: true,
          statusMessage:
              'Layanan GPS perangkat sedang nonaktif. Menampilkan perkiraan dari Padang Barat; aktifkan GPS lalu tekan "Perbarui GPS".',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return EvacuationLocationResult.fallback(
          permissionDenied: true,
          statusMessage:
              'Izin lokasi belum diberikan. Menggunakan koordinat perkiraan Padang Barat; izinkan GPS agar jarak shelter akurat.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return EvacuationLocationResult.fallback(
          permissionDenied: true,
          permanentlyDenied: true,
          statusMessage:
              'Izin lokasi ditolak permanen. Buka Pengaturan Aplikasi untuk mengaktifkan GPS, atau gunakan panduan dari perkiraan Padang Barat.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final latStr = position.latitude.toStringAsFixed(4);
      final lngStr = position.longitude.toStringAsFixed(4);
      return EvacuationLocationResult(
        position: LatLng(position.latitude, position.longitude),
        isFallback: false,
        sourceLabel: 'GPS Perangkat Aktif ($latStr, $lngStr)',
        statusMessage:
            'Posisi GPS berhasil diperbarui. Rekomendasi dan arah evakuasi dihitung dari koordinat Anda saat ini.',
        fetchedAt: DateTime.now(),
      );
    } on TimeoutException {
      return EvacuationLocationResult.fallback(
        statusMessage:
            'Sinyal GPS membutuhkan waktu terlalu lama (timeout 8 detik). Menggunakan koordinat perkiraan Padang Barat sementara.',
      );
    } catch (_) {
      return EvacuationLocationResult.fallback(
        statusMessage:
            'Lokasi GPS perangkat tidak tersedia saat ini. Menggunakan koordinat perkiraan Padang Barat; tekan "Perbarui GPS" untuk mencoba lagi.',
      );
    }
  }
}

/// Sumber katalog titik evakuasi untuk layar Panduan Evakuasi.
///
/// Strategi offline-first: katalog bawaan aplikasi ([PadangEvacuationData])
/// selalu menjadi cadangan. Data server hanya menggantikan **shelter TES**,
/// karena zona aman horizontal (>10 mdpl) belum tersedia di backend dan tetap
/// dipakai dari data elevasi yang dibundel.
class EvacuationPointRepository {
  static final EvacuationPointRepository instance = EvacuationPointRepository();

  final ApiClient? client;

  EvacuationPointRepository({this.client});

  ApiClient get _api => client ?? ApiClient();

  /// Mengambil shelter TES terverifikasi dari `GET /api/shelters/tsunami/`.
  ///
  /// Mengembalikan daftar kosong bila jaringan gagal, sehingga pemanggil
  /// memakai katalog bawaan tanpa menampilkan galat ke pengguna.
  Future<List<EvacuationPoint>> fetchShelters() async {
    try {
      final response = await _api.get(
        ApiConfig.tsunamiShelters,
        requiresAuth: false,
      );
      if (response is! List) return const [];

      return response
          .whereType<Map<String, dynamic>>()
          .map(_toEvacuationPoint)
          .whereType<EvacuationPoint>()
          .toList();
    } catch (e) {
      debugPrint('Gagal memuat shelter TES dari server: $e');
      return const [];
    }
  }

  /// Menggabungkan shelter server dengan katalog bawaan.
  ///
  /// Shelter server menang bila `id`-nya sama; shelter bawaan yang tidak ada di
  /// server tetap dipertahankan agar panduan evakuasi tidak kehilangan tujuan
  /// saat data server belum lengkap.
  static List<EvacuationPoint> mergeWithDefaults(
    List<EvacuationPoint> serverShelters,
  ) {
    if (serverShelters.isEmpty) return PadangEvacuationData.tesShelters;

    final byId = <String, EvacuationPoint>{
      for (final point in PadangEvacuationData.tesShelters) point.id: point,
      for (final point in serverShelters) point.id: point,
    };
    return byId.values.toList();
  }

  /// Mengonversi satu item `AssistancePoint` menjadi [EvacuationPoint].
  ///
  /// Backend tidak menyimpan elevasi, jadi `elevationMeters` diisi 0 dan label
  /// elevasi tidak diklaim. Kapasitas memakai field `capacity` (bila ada).
  static EvacuationPoint? _toEvacuationPoint(Map<String, dynamic> json) {
    final lat = (json['latitude'] as num?)?.toDouble();
    final lng = (json['longitude'] as num?)?.toDouble();
    final id = json['id']?.toString() ?? '';
    if (lat == null || lng == null || id.isEmpty) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;

    final capacity = (json['capacity'] as num?)?.toInt();
    final address = (json['address'] as String? ?? '').trim();

    return EvacuationPoint(
      id: 'server_$id',
      name: json['name']?.toString() ?? 'Tempat Evakuasi',
      type: EvacuationPointType.verticalTes,
      latitude: lat,
      longitude: lng,
      elevationMeters: 0,
      elevationLabel: 'Elevasi belum terdata',
      capacityLabel: capacity != null ? '$capacity jiwa' : 'Kapasitas belum terdata',
      routeNote: address.isEmpty ? 'Lokasi evakuasi resmi BPBD Kota Padang.' : address,
    );
  }
}
