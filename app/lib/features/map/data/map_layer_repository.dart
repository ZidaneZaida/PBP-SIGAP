import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:sigap/core/network/api_client.dart';
import 'package:sigap/core/network/api_config.dart';

/// Zona risiko (GeoJSON) yang siap digambar sebagai layer peta.
class RiskZoneLayer {
  final String id;
  final String name;
  final String hazardType;
  final String riskLevel;
  final String description;

  /// Cincin pertama polygon; cukup untuk render satu bidang datar.
  final List<LatLng> points;

  const RiskZoneLayer({
    required this.id,
    required this.name,
    required this.hazardType,
    required this.riskLevel,
    required this.description,
    required this.points,
  });

  /// Membangun layer dari satu fitur GeoJSON `GET /api/map/risk-zones/`.
  ///
  /// Mengembalikan `null` bila geometri tidak valid, agar satu data rusak di
  /// server tidak membuat seluruh layer peta gagal tampil.
  static RiskZoneLayer? fromFeature(Map<String, dynamic> feature) {
    final geometry = feature['geometry'];
    if (geometry is! Map<String, dynamic>) return null;

    final points = _firstRingPoints(geometry);
    if (points.length < 3) return null;

    final props = feature['properties'];
    final map = props is Map<String, dynamic> ? props : const <String, dynamic>{};

    return RiskZoneLayer(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Zona Risiko',
      hazardType: map['hazard_type']?.toString() ?? '',
      riskLevel: map['risk_level']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      points: points,
    );
  }

  /// Mengambil cincin pertama dari Polygon/MultiPolygon.
  ///
  /// Struktur GeoJSON: Polygon = `[ring, ...]`, MultiPolygon = `[polygon, ...]`.
  /// Cincin pertama selalu batas luar.
  static List<LatLng> _firstRingPoints(Map<String, dynamic> geometry) {
    final type = geometry['type'];
    var coordinates = geometry['coordinates'];

    if (type == 'MultiPolygon' && coordinates is List && coordinates.isNotEmpty) {
      coordinates = coordinates.first;
    }
    if (coordinates is! List || coordinates.isEmpty) return const [];

    final ring = coordinates.first;
    if (ring is! List) return const [];

    final points = <LatLng>[];
    for (final pair in ring) {
      if (pair is! List || pair.length < 2) continue;
      final lng = (pair[0] as num?)?.toDouble();
      final lat = (pair[1] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      if (!_isValidCoordinate(lat, lng)) continue;
      // GeoJSON memakai [longitude, latitude] — urutan ini sering tertukar.
      points.add(LatLng(lat, lng));
    }
    return points;
  }

  static bool _isValidCoordinate(double lat, double lng) =>
      lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
}

/// Satu titik agregat heatmap kerusakan bangunan.
class DamageHeatmapPoint {
  final LatLng position;
  final int total;
  final String dominantLevel;

  const DamageHeatmapPoint({
    required this.position,
    required this.total,
    required this.dominantLevel,
  });

  static DamageHeatmapPoint? fromJson(Map<String, dynamic> json) {
    final lat = (json['latitude'] as num?)?.toDouble();
    final lng = (json['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;

    return DamageHeatmapPoint(
      position: LatLng(lat, lng),
      total: (json['total'] as num?)?.toInt() ?? 1,
      dominantLevel: json['dominant_level']?.toString() ?? 'minor',
    );
  }
}

/// Data layer peta yang bersumber dari backend.
///
/// Desain sengaja gagal-aman: setiap kegagalan jaringan mengembalikan daftar
/// kosong, sehingga [PetaScreen] dapat tetap memakai data bawaan aplikasi
/// (offline-first) tanpa menampilkan galat ke warga.
class MapLayerRepository {
  static final MapLayerRepository instance = MapLayerRepository();

  final ApiClient? client;

  MapLayerRepository({this.client});

  ApiClient get _api => client ?? ApiClient();

  /// Mengambil zona risiko tsunami dari server.
  ///
  /// Hanya hazard `tsunami` yang diminta: aplikasi SIGAP kini fokus pada gempa
  /// dan tsunami Kota Padang, sehingga layer banjir/longsor diabaikan.
  Future<List<RiskZoneLayer>> fetchTsunamiZones() async {
    try {
      final response = await _api.get(
        ApiConfig.riskZones,
        queryParams: {'hazard_type': 'tsunami'},
        requiresAuth: false,
      );
      final features = _extractFeatures(response);
      return features
          .map(RiskZoneLayer.fromFeature)
          .whereType<RiskZoneLayer>()
          .toList();
    } catch (e) {
      debugPrint('Gagal memuat zona risiko dari server: $e');
      return const [];
    }
  }

  /// Mengambil titik heatmap kerusakan bangunan terverifikasi.
  Future<List<DamageHeatmapPoint>> fetchDamageHeatmap() async {
    try {
      final response = await _api.get(
        ApiConfig.damageReportsHeatmap,
        requiresAuth: false,
      );
      if (response is! Map<String, dynamic>) return const [];
      final points = response['points'];
      if (points is! List) return const [];
      return points
          .whereType<Map<String, dynamic>>()
          .map(DamageHeatmapPoint.fromJson)
          .whereType<DamageHeatmapPoint>()
          .toList();
    } catch (e) {
      debugPrint('Gagal memuat heatmap kerusakan: $e');
      return const [];
    }
  }

  /// Menormalkan respons GeoJSON `FeatureCollection` atau `Feature`.
  static List<Map<String, dynamic>> _extractFeatures(dynamic response) {
    if (response is! Map<String, dynamic>) return const [];
    final features = response['features'];
    if (features is! List) return const [];
    return features.whereType<Map<String, dynamic>>().toList();
  }
}
