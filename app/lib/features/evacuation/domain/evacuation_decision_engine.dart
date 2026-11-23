import 'dart:math' as math;
import 'evacuation_models.dart';

/// Radius rata-rata bumi dalam meter untuk kalkulasi Haversine.
const double kEarthRadiusMeters = 6371000.0;

/// Kecepatan jalan cepat darurat pascagempa (~4,5 km/jam = 1,25 m/detik).
/// Diasumsikan berjalan kaki karena risiko kemacetan parah dan retakan jalan.
const double kEmergencyWalkingSpeedMps = 1.25;

/// Margin keamanan minimal sebelum estimasi gelombang tsunami tiba (menit).
const double kGoldenTimeSafetyMarginMinutes = 3.0;

double _degreesToRadians(double degrees) => degrees * math.pi / 180.0;
double _radiansToDegrees(double radians) => radians * 180.0 / math.pi;

/// Menghitung jarak garis lurus (Haversine) antara dua koordinat GPS dalam meter.
double calculateHaversineDistanceMeters(
  double startLat,
  double startLng,
  double endLat,
  double endLng,
) {
  final dLat = _degreesToRadians(endLat - startLat);
  final dLng = _degreesToRadians(endLng - startLng);
  final lat1 = _degreesToRadians(startLat);
  final lat2 = _degreesToRadians(endLat);

  final sinHalfLat = math.sin(dLat / 2.0);
  final sinHalfLng = math.sin(dLng / 2.0);

  final a =
      sinHalfLat * sinHalfLat +
      math.cos(lat1) * math.cos(lat2) * sinHalfLng * sinHalfLng;
  final clampedA = a.clamp(0.0, 1.0);
  final c = 2.0 * math.atan2(math.sqrt(clampedA), math.sqrt(1.0 - clampedA));
  return kEarthRadiusMeters * c;
}

/// Menghitung sudut arah (forward bearing) dari titik awal menuju titik tujuan
/// dalam rentang 0 hingga <360 derajat (0° = Utara, 90° = Timur, 180° = Selatan, 270° = Barat).
double calculateBearingDegrees(
  double startLat,
  double startLng,
  double endLat,
  double endLng,
) {
  if (startLat == endLat && startLng == endLng) {
    return 0.0;
  }

  final lat1 = _degreesToRadians(startLat);
  final lat2 = _degreesToRadians(endLat);
  final dLng = _degreesToRadians(endLng - startLng);

  final y = math.sin(dLng) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  final rawDegrees = _radiansToDegrees(math.atan2(y, x));
  final normalized = (rawDegrees + 360.0) % 360.0;
  return normalized == 360.0 ? 0.0 : normalized;
}

/// Mengonversi sudut bearing (0-360°) menjadi 8 arah mata angin Bahasa Indonesia.
String bearingToCardinalDirection(double bearingDegrees) {
  const directions = <String>[
    'Utara',
    'Timur Laut',
    'Timur',
    'Tenggara',
    'Selatan',
    'Barat Daya',
    'Barat',
    'Barat Laut',
  ];
  final normalized = ((bearingDegrees % 360.0) + 360.0) % 360.0;
  final index = ((normalized + 22.5) ~/ 45.0) % 8;
  return directions[index];
}

/// Menghitung estimasi waktu tempuh jalan cepat darurat dalam menit.
double estimateEmergencyWalkingMinutes(
  double distanceMeters, {
  double walkingSpeedMps = kEmergencyWalkingSpeedMps,
}) {
  if (distanceMeters <= 0 || walkingSpeedMps <= 0) {
    return 0.0;
  }
  return (distanceMeters / walkingSpeedMps) / 60.0;
}

/// Memformat jarak meter menjadi teks ringkas Bahasa Indonesia (`350 meter` atau `1.8 km`).
String formatEvacuationDistance(double distanceMeters) {
  if (distanceMeters < 0) return '0 meter';
  if (distanceMeters < 1000.0) {
    return '${distanceMeters.round()} meter';
  }
  return '${(distanceMeters / 1000.0).toStringAsFixed(1)} km';
}

/// Memformat estimasi waktu menit menjadi label yang mudah dibaca saat darurat.
String formatEtaMinutes(double etaMinutes) {
  if (etaMinutes <= 0.5) return '< 1 mnt';
  return '~${etaMinutes.ceil()} mnt';
}

/// Mesin keputusan Smart Tsunami Evacuation (Vertikal TES vs Horizontal Zona Aman)
/// berdasarkan Revisi Zidan v2.1-Finalized Bagian 2.3.C, 7.1, dan 7.2.
class EvacuationDecisionEngine {
  /// Menghitung jarak, ETA, dan arah ke seluruh daftar titik lalu mengurutkannya
  /// dari jarak terdekat ke terjauh.
  static List<EvacuationCandidate> rankCandidates({
    required double userLat,
    required double userLng,
    required List<EvacuationPoint> points,
    double walkingSpeedMps = kEmergencyWalkingSpeedMps,
  }) {
    final candidates = points.map((point) {
      final distance = calculateHaversineDistanceMeters(
        userLat,
        userLng,
        point.latitude,
        point.longitude,
      );
      final eta = estimateEmergencyWalkingMinutes(
        distance,
        walkingSpeedMps: walkingSpeedMps,
      );
      final bearing = calculateBearingDegrees(
        userLat,
        userLng,
        point.latitude,
        point.longitude,
      );
      final cardinal = bearingToCardinalDirection(bearing);
      return EvacuationCandidate(
        point: point,
        distanceMeters: distance,
        etaMinutes: eta,
        bearingDegrees: bearing,
        cardinalDirection: cardinal,
      );
    }).toList();

    candidates.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return candidates;
  }

  /// Mengevaluasi strategi evakuasi terbaik (Vertikal vs Horizontal)
  /// dengan membandingkan estimasi waktu tempuh ke zona aman dataran tinggi timur
  /// terhadap sisa Golden Time ditambah margin aman.
  static EvacuationDecision evaluate({
    required double userLat,
    required double userLng,
    required double remainingGoldenTimeMinutes,
    required List<EvacuationPoint> tesShelters,
    required List<EvacuationPoint> horizontalSafeZones,
    double walkingSpeedMps = kEmergencyWalkingSpeedMps,
    double safetyMarginMinutes = kGoldenTimeSafetyMarginMinutes,
  }) {
    assert(tesShelters.isNotEmpty, 'Daftar shelter TES tidak boleh kosong.');
    assert(
      horizontalSafeZones.isNotEmpty,
      'Daftar zona aman horizontal tidak boleh kosong.',
    );

    final rankedTes = rankCandidates(
      userLat: userLat,
      userLng: userLng,
      points: tesShelters,
      walkingSpeedMps: walkingSpeedMps,
    );
    final rankedHorizontal = rankCandidates(
      userLat: userLat,
      userLng: userLng,
      points: horizontalSafeZones,
      walkingSpeedMps: walkingSpeedMps,
    );

    final nearestTes = rankedTes.first;
    final nearestHorizontal = rankedHorizontal.first;

    final safeRemainingMinutes =
        remainingGoldenTimeMinutes < 0 ? 0.0 : remainingGoldenTimeMinutes;

    // Keputusan Revisi Bagian 2.3.C:
    // Jika ETA ke zona aman timur + margin aman > sisa Golden Time (atau Golden Time habis),
    // rekomendasikan EVAKUASI VERTIKAL ke TES terdekat.
    final bool horizontalFeasible =
        safeRemainingMinutes > 0 &&
        (nearestHorizontal.etaMinutes + safetyMarginMinutes) <=
            safeRemainingMinutes;

    final String tesDistText = formatEvacuationDistance(
      nearestTes.distanceMeters,
    );
    final String horizontalDistText = formatEvacuationDistance(
      nearestHorizontal.distanceMeters,
    );
    final String speedKmh = (walkingSpeedMps * 3.6).toStringAsFixed(1);

    if (!horizontalFeasible) {
      final bearingText =
          '${nearestTes.bearingDegrees.round().toString().padLeft(3, '0')}° (${nearestTes.cardinalDirection})';
      final headline =
          'Evakuasi Horizontal Tidak Memungkinkan! Evakuasi Vertikal ke TES Terdekat: ${nearestTes.point.name} ($tesDistText).';
      final rationale =
          'Estimasi jalan cepat darurat ($speedKmh km/jam) ke zona aman timur '
          '(${nearestHorizontal.point.name}, $horizontalDistText) membutuhkan '
          '${formatEtaMinutes(nearestHorizontal.etaMinutes)} (+${safetyMarginMinutes.round()} mnt margin), '
          'melebihi sisa Golden Time (${safeRemainingMinutes.toStringAsFixed(0)} mnt). '
          'Segera evakuasi vertikal ke ${nearestTes.point.name} (${formatEtaMinutes(nearestTes.etaMinutes)}).';

      final steps = <String>[
        'Bergerak cepat berjalan kaki ke arah ${nearestTes.cardinalDirection} ($bearingText) menuju ${nearestTes.point.name} ($tesDistText).',
        'Rute disarankan: ${nearestTes.point.routeNote}',
        'Hindari kendaraan bermotor di jalan macet; jauhi jembatan pantai dan muara sungai.',
        'Setibanya di ${nearestTes.point.name}, segera naik ke lantai aman minimal Lantai 3 (${nearestTes.point.elevationLabel}) melalui tangga darurat.',
      ];

      return EvacuationDecision(
        recommendedType: EvacuationPointType.verticalTes,
        primaryTarget: nearestTes.point,
        nearestTes: nearestTes.point,
        nearestHorizontalZone: nearestHorizontal.point,
        distanceToPrimaryMeters: nearestTes.distanceMeters,
        etaToPrimaryMinutes: nearestTes.etaMinutes,
        distanceToTesMeters: nearestTes.distanceMeters,
        etaToTesMinutes: nearestTes.etaMinutes,
        distanceToHorizontalMeters: nearestHorizontal.distanceMeters,
        etaToHorizontalMinutes: nearestHorizontal.etaMinutes,
        bearingDegrees: nearestTes.bearingDegrees,
        cardinalDirection: nearestTes.cardinalDirection,
        headline: headline,
        rationale: rationale,
        steps: steps,
      );
    }

    final bearingText =
        '${nearestHorizontal.bearingDegrees.round().toString().padLeft(3, '0')}° (${nearestHorizontal.cardinalDirection})';
    final headline =
        'Evakuasi Horizontal Memungkinkan! Segera Menuju Zona Aman Timur: ${nearestHorizontal.point.name} ($horizontalDistText).';
    final rationale =
        'Estimasi jalan cepat darurat ($speedKmh km/jam) ke dataran tinggi '
        '${nearestHorizontal.point.name} (${nearestHorizontal.point.elevationLabel}) adalah '
        '${formatEtaMinutes(nearestHorizontal.etaMinutes)}, masih dalam batas aman sisa Golden Time '
        '(${safeRemainingMinutes.toStringAsFixed(0)} mnt dengan margin ${safetyMarginMinutes.round()} mnt). '
        'Cadangan TES vertikal terdekat bila jalur macet: ${nearestTes.point.name} ($tesDistText).';

    final steps = <String>[
      'Bergerak cepat menjauhi pesisir ke arah ${nearestHorizontal.cardinalDirection} ($bearingText) menuju ${nearestHorizontal.point.name} ($horizontalDistText).',
      'Rute disarankan: ${nearestHorizontal.point.routeNote}',
      'Prioritaskan berjalan kaki di jalur bebas reruntuhan karena kemacetan kendaraan sering terjadi pascagempa.',
      'Jika jalur timur terhambat total, segera alihkan ke shelter vertikal cadangan ${nearestTes.point.name} ($tesDistText) dan naik minimal Lantai 3.',
    ];

    return EvacuationDecision(
      recommendedType: EvacuationPointType.horizontalSafeZone,
      primaryTarget: nearestHorizontal.point,
      nearestTes: nearestTes.point,
      nearestHorizontalZone: nearestHorizontal.point,
      distanceToPrimaryMeters: nearestHorizontal.distanceMeters,
      etaToPrimaryMinutes: nearestHorizontal.etaMinutes,
      distanceToTesMeters: nearestTes.distanceMeters,
      etaToTesMinutes: nearestTes.etaMinutes,
      distanceToHorizontalMeters: nearestHorizontal.distanceMeters,
      etaToHorizontalMinutes: nearestHorizontal.etaMinutes,
      bearingDegrees: nearestHorizontal.bearingDegrees,
      cardinalDirection: nearestHorizontal.cardinalDirection,
      headline: headline,
      rationale: rationale,
      steps: steps,
    );
  }
}
