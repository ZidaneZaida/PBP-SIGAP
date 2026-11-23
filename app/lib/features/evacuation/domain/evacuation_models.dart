import 'package:latlong2/latlong.dart';

/// Jenis titik tujuan evakuasi tsunami Kota Padang.
enum EvacuationPointType {
  verticalTes,
  horizontalSafeZone;

  String get badgeLabel {
    switch (this) {
      case EvacuationPointType.verticalTes:
        return 'EVAKUASI VERTIKAL (TES)';
      case EvacuationPointType.horizontalSafeZone:
        return 'EVAKUASI HORIZONTAL (ZONA AMAN)';
    }
  }

  String get shortTag {
    switch (this) {
      case EvacuationPointType.verticalTes:
        return 'TES Vertikal';
      case EvacuationPointType.horizontalSafeZone:
        return 'Zona Aman Timur';
    }
  }
}

/// Representasi satu titik evakuasi (Shelter TES Vertikal atau Zona Aman Dataran Tinggi).
class EvacuationPoint {
  final String id;
  final String name;
  final EvacuationPointType type;
  final double latitude;
  final double longitude;
  final int elevationMeters;
  final String elevationLabel;
  final String capacityLabel;
  final String routeNote;

  const EvacuationPoint({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.elevationMeters,
    required this.elevationLabel,
    required this.capacityLabel,
    required this.routeNote,
  });

  LatLng get latLng => LatLng(latitude, longitude);
}

/// Kandidat titik evakuasi yang telah dihitung jarak, waktu tempuh, dan arahnya
/// relatif terhadap koordinat pengguna saat ini.
class EvacuationCandidate {
  final EvacuationPoint point;
  final double distanceMeters;
  final double etaMinutes;
  final double bearingDegrees;
  final String cardinalDirection;

  const EvacuationCandidate({
    required this.point,
    required this.distanceMeters,
    required this.etaMinutes,
    required this.bearingDegrees,
    required this.cardinalDirection,
  });
}

/// Hasil evaluasi Smart Tsunami Evacuation & Golden Time Matrix.
class EvacuationDecision {
  final EvacuationPointType recommendedType;
  final EvacuationPoint primaryTarget;
  final EvacuationPoint nearestTes;
  final EvacuationPoint nearestHorizontalZone;
  final double distanceToPrimaryMeters;
  final double etaToPrimaryMinutes;
  final double distanceToTesMeters;
  final double etaToTesMinutes;
  final double distanceToHorizontalMeters;
  final double etaToHorizontalMinutes;
  final double bearingDegrees;
  final String cardinalDirection;
  final String headline;
  final String rationale;
  final List<String> steps;

  const EvacuationDecision({
    required this.recommendedType,
    required this.primaryTarget,
    required this.nearestTes,
    required this.nearestHorizontalZone,
    required this.distanceToPrimaryMeters,
    required this.etaToPrimaryMinutes,
    required this.distanceToTesMeters,
    required this.etaToTesMinutes,
    required this.distanceToHorizontalMeters,
    required this.etaToHorizontalMinutes,
    required this.bearingDegrees,
    required this.cardinalDirection,
    required this.headline,
    required this.rationale,
    required this.steps,
  });

  bool get isVerticalRecommended =>
      recommendedType == EvacuationPointType.verticalTes;
}
