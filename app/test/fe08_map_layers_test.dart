import 'package:flutter_test/flutter_test.dart';
import 'package:sigap/features/map/data/map_layer_repository.dart';

void main() {
  group('RiskZoneLayer.fromFeature', () {
    test('membaca Polygon GeoJSON dengan urutan [lng, lat] yang benar', () {
      final zone = RiskZoneLayer.fromFeature({
        'type': 'Feature',
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            [
              [100.35, -0.94],
              [100.36, -0.94],
              [100.36, -0.95],
              [100.35, -0.94],
            ],
          ],
        },
        'properties': {
          'id': 'zone-1',
          'name': 'Zona Merah Padang Barat',
          'hazard_type': 'tsunami',
          'risk_level': 'high',
        },
      });

      expect(zone, isNotNull);
      expect(zone!.name, 'Zona Merah Padang Barat');
      expect(zone.points.length, 4);
      // GeoJSON [lng, lat] harus dipetakan ke LatLng(lat, lng).
      expect(zone.points.first.latitude, -0.94);
      expect(zone.points.first.longitude, 100.35);
    });

    test('membaca cincin pertama MultiPolygon', () {
      final zone = RiskZoneLayer.fromFeature({
        'type': 'Feature',
        'geometry': {
          'type': 'MultiPolygon',
          'coordinates': [
            [
              [
                [100.35, -0.94],
                [100.36, -0.94],
                [100.36, -0.95],
              ],
            ],
          ],
        },
        'properties': {'name': 'Multi'},
      });

      expect(zone?.points.length, 3);
    });

    test('menolak geometri tidak valid tanpa melempar exception', () {
      expect(
        RiskZoneLayer.fromFeature({'geometry': {'type': 'Point', 'coordinates': []}}),
        isNull,
      );
      expect(RiskZoneLayer.fromFeature({'type': 'Feature'}), isNull);
      expect(
        RiskZoneLayer.fromFeature({
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [
                [200.0, 100.0], // lng tidak valid
                [100.36, -0.94],
              ],
            ],
          },
        }),
        isNull,
      );
    });

    test('hanya cincin pertama dipakai (lubang polygon diabaikan)', () {
      final zone = RiskZoneLayer.fromFeature({
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            [
              [100.35, -0.94],
              [100.36, -0.94],
              [100.36, -0.95],
            ],
            [
              [100.355, -0.945],
              [100.356, -0.945],
              [100.356, -0.946],
            ],
          ],
        },
      });

      expect(zone?.points.length, 3);
    });
  });

  group('DamageHeatmapPoint.fromJson', () {
    test('membaca titik valid', () {
      final point = DamageHeatmapPoint.fromJson({
        'latitude': -0.9481,
        'longitude': 100.3529,
        'total': 4,
        'dominant_level': 'critical',
      });

      expect(point, isNotNull);
      expect(point!.total, 4);
      expect(point.dominantLevel, 'critical');
      expect(point.position.latitude, -0.9481);
    });

    test('menolak koordinat di luar rentang bumi', () {
      expect(
        DamageHeatmapPoint.fromJson({'latitude': 91, 'longitude': 100}),
        isNull,
      );
      expect(
        DamageHeatmapPoint.fromJson({'longitude': 100}),
        isNull,
      );
    });
  });
}
