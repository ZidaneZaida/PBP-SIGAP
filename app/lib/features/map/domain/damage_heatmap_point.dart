import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:sigap/core/theme/app_colors.dart';
import 'package:sigap/features/vision/domain/models/damage_models.dart';

/// Satu titik agregat / laporan kerusakan bangunan untuk layer Heatmap
/// SIGAP-Vision pada [PetaScreen] (FE-08).
class DamageHeatmapPoint {
  final String id;
  final double latitude;
  final double longitude;
  final DamageCategory category;
  final double? confidenceScore;
  final String description;
  final DateTime reportedAt;
  final bool isFromServer;
  final String syncStatusLabel;

  const DamageHeatmapPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.confidenceScore,
    required this.description,
    required this.reportedAt,
    required this.isFromServer,
    required this.syncStatusLabel,
  });

  LatLng get position => LatLng(latitude, longitude);

  /// Warna overlay heatmap sesuai tingkat keparahan kerusakan.
  Color get overlayColor {
    switch (category) {
      case DamageCategory.ringan:
        return AppColors.safeGreen;
      case DamageCategory.sedang:
        return AppColors.alertSiaga;
      case DamageCategory.berat:
        return AppColors.alertAwas;
    }
  }

  /// Radius lingkaran overlay dalam meter untuk [CircleLayer].
  double get circleRadiusMeters {
    switch (category) {
      case DamageCategory.ringan:
        return 75.0;
      case DamageCategory.sedang:
        return 110.0;
      case DamageCategory.berat:
        return 150.0;
    }
  }

  String get sourceLabel => isFromServer ? 'Server BPBD' : 'Lokal SQLite';

  String get confidenceLabel {
    final score = confidenceScore;
    if (score == null) return 'Tidak tersedia';
    return '${(score.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%';
  }

  /// Mem-parsing objek JSON dari kontrak Django `GET /api/damage-reports/heatmap/`.
  /// Mengembalikan `null` jika koordinat tidak valid.
  static DamageHeatmapPoint? fromServerJson(Map<String, dynamic> json) {
    final lat = _parseDouble(json['latitude'] ?? json['lat']);
    final lng = _parseDouble(json['longitude'] ?? json['lng'] ?? json['lon']);
    if (lat == null || lng == null) return null;
    if (lat < -90.0 || lat > 90.0 || lng < -180.0 || lng > 180.0) {
      return null;
    }

    final rawLevel =
        (json['damage_level'] ?? json['damageLevel'] ?? json['category'])
            ?.toString();
    final category = DamageCategory.fromName(rawLevel);
    final confidence = _parseDouble(
      json['confidence_score'] ?? json['confidenceScore'],
    );
    final rawDesc =
        (json['description'] ?? json['summary'])?.toString().trim();
    final description = (rawDesc != null && rawDesc.isNotEmpty)
        ? rawDesc
        : 'Laporan kerusakan tingkat ${category.shortLabel}.';

    final rawDate =
        (json['created_at'] ?? json['reported_at'] ?? json['reportedAt'])
            ?.toString();
    final reportedAt =
        (rawDate != null ? DateTime.tryParse(rawDate) : null) ?? DateTime.now();

    final rawId = json['id']?.toString().trim();
    final id = (rawId != null && rawId.isNotEmpty)
        ? rawId
        : 'srv_${lat.toStringAsFixed(5)}_${lng.toStringAsFixed(5)}_${category.name}';

    final isVerified = json['is_verified_by_officer'] == true;
    final syncLabel = isVerified
        ? 'Terverifikasi Petugas'
        : 'Tersinkron Server';

    return DamageHeatmapPoint(
      id: id,
      latitude: lat,
      longitude: lng,
      category: category,
      confidenceScore: confidence,
      description: description,
      reportedAt: reportedAt,
      isFromServer: true,
      syncStatusLabel: syncLabel,
    );
  }

  /// Mengonversi laporan lokal SIGAP-Vision menjadi titik heatmap.
  /// Mengembalikan `null` bila laporan belum memiliki koordinat GPS valid
  /// agar peta tidak pernah menampilkan lokasi fiktif.
  static DamageHeatmapPoint? fromLocalReport(DamageScanReport report) {
    final loc = report.location;
    if (loc == null) return null;

    return DamageHeatmapPoint(
      id: report.id,
      latitude: loc.latitude,
      longitude: loc.longitude,
      category: report.result.category,
      confidenceScore: report.result.confidenceScore,
      description: report.result.summary.trim().isNotEmpty
          ? report.result.summary.trim()
          : 'Laporan pemindaian SIGAP-Vision (${report.result.category.shortLabel}).',
      reportedAt: report.createdAt,
      isFromServer: false,
      syncStatusLabel: report.syncStatus.label,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }
}

/// Hasil pemuatan gabungan titik kerusakan (server + lokal SQLite) secara jujur.
class DamageHeatmapLoadResult {
  final List<DamageHeatmapPoint> points;
  final int serverCount;
  final int localCount;
  final bool serverAvailable;
  final String statusMessage;

  const DamageHeatmapLoadResult({
    required this.points,
    required this.serverCount,
    required this.localCount,
    required this.serverAvailable,
    required this.statusMessage,
  });

  bool get isEmpty => points.isEmpty;
}
