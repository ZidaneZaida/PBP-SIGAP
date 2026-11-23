import 'package:latlong2/latlong.dart';
import '../domain/evacuation_models.dart';

/// Katalog statis titik evakuasi tsunami Kota Padang (siap bekerja 100% offline):
/// 1. 4 Shelter TES Vertikal (konsisten dengan data `peta_screen.dart`).
/// 2. 5 Titik referensi Zona Aman Dataran Tinggi Timur (>10 mdpl)
///    sesuai Revisi Zidan v2.1-Finalized Bagian 6.2 & 7.1.
class PadangEvacuationData {
  /// Koordinat default fallback Kota Padang (Padang Barat — konsisten dengan PetaScreen & HomeScreen).
  static const LatLng defaultFallbackLocation = LatLng(-0.9492, 100.3542);
  static const String defaultFallbackAreaLabel =
      'Padang Barat (Koordinat Perkiraan Default)';

  /// 4 Shelter Tempat Evakuasi Sementara (TES) Vertikal Kota Padang.
  static const List<EvacuationPoint> tesShelters = <EvacuationPoint>[
    EvacuationPoint(
      id: 'shelter_unp',
      name: 'Gedung TES UNP',
      type: EvacuationPointType.verticalTes,
      latitude: -0.8970,
      longitude: 100.3520,
      elevationMeters: 18,
      elevationLabel: '18 mdpl (Zona Aman Tsunami)',
      capacityLabel: '4.000 jiwa',
      routeNote: 'Lewat Jl. Prof. Hamka ke arah Timur menjauhi pantai.',
    ),
    EvacuationPoint(
      id: 'shelter_ulak_karang',
      name: 'TES Escape Building Ulak Karang',
      type: EvacuationPointType.verticalTes,
      latitude: -0.9125,
      longitude: 100.3530,
      elevationMeters: 16,
      elevationLabel: '16 mdpl (Aman Tsunami)',
      capacityLabel: '3.000 jiwa',
      routeNote: 'Lewat Jl. Bahari lurus ke arah bukit/Utara.',
    ),
    EvacuationPoint(
      id: 'shelter_masjid_raya',
      name: 'Masjid Raya Sumatera Barat',
      type: EvacuationPointType.verticalTes,
      latitude: -0.9242,
      longitude: 100.3625,
      elevationMeters: 15,
      elevationLabel: '>15 mdpl (Zona Hijau)',
      capacityLabel: '10.000 jiwa',
      routeNote: 'Jl. Khatib Sulaiman jalur evakuasi utama.',
    ),
    EvacuationPoint(
      id: 'shelter_smp1',
      name: 'SMPN 1 Padang (Vertical Evac)',
      type: EvacuationPointType.verticalTes,
      latitude: -0.9520,
      longitude: 100.3610,
      elevationMeters: 15,
      elevationLabel: 'Lt. 3 & 4 (15 mdpl)',
      capacityLabel: '1.500 jiwa',
      routeNote: 'Gedung diperkuat konstruksi tahan gempa megathrust.',
    ),
  ];

  /// 5 Zona Aman Dataran Tinggi Timur / Perbukitan (>10 mdpl) Kota Padang.
  static const List<EvacuationPoint> horizontalSafeZones = <EvacuationPoint>[
    EvacuationPoint(
      id: 'zone_bypass_timur',
      name: 'Bypass Timur Padang',
      type: EvacuationPointType.horizontalSafeZone,
      latitude: -0.9370,
      longitude: 100.3980,
      elevationMeters: 16,
      elevationLabel: '16 mdpl (>10 mdpl Zona Hijau)',
      capacityLabel: 'Koridor Evakuasi Terbuka',
      routeNote:
          'Bergerak lurus ke arah Timur melintasi rel kereta menuju koridor Jl. By Pass Padang.',
    ),
    EvacuationPoint(
      id: 'zone_bukit_lampu',
      name: 'Bukit Lampu',
      type: EvacuationPointType.horizontalSafeZone,
      latitude: -0.9960,
      longitude: 100.3865,
      elevationMeters: 45,
      elevationLabel: '45 mdpl (Perbukitan Selatan)',
      capacityLabel: 'Dataran Tinggi Terbuka',
      routeNote:
          'Ikuti Jl. Raya Padang–Painan ke arah Tenggara menanjak menuju kawasan perbukitan Bukit Lampu.',
    ),
    EvacuationPoint(
      id: 'zone_indarung',
      name: 'Indarung',
      type: EvacuationPointType.horizontalSafeZone,
      latitude: -0.9565,
      longitude: 100.4360,
      elevationMeters: 110,
      elevationLabel: '110 mdpl (Perbukitan Timur)',
      capacityLabel: 'Kawasan Aman Luas',
      routeNote:
          'Ikuti Jl. Raya Indarung lurus ke arah Timur menjauhi pesisir hingga dataran tinggi Lubuk Kilangan.',
    ),
    EvacuationPoint(
      id: 'zone_limau_manis',
      name: 'Limau Manis',
      type: EvacuationPointType.horizontalSafeZone,
      latitude: -0.9165,
      longitude: 100.4580,
      elevationMeters: 160,
      elevationLabel: '160 mdpl (Perbukitan Pauh)',
      capacityLabel: 'Dataran Tinggi Aman Luas',
      routeNote:
          'Melalui Jl. Dr. Moh. Hatta menuju Timur Laut ke kawasan perbukitan Limau Manis (Pauh).',
    ),
    EvacuationPoint(
      id: 'zone_bukit_gado_gado',
      name: 'Bukit Gado-Gado',
      type: EvacuationPointType.horizontalSafeZone,
      latitude: -0.9745,
      longitude: 100.3620,
      elevationMeters: 38,
      elevationLabel: '38 mdpl (Perbukitan Pesisir Selatan)',
      capacityLabel: 'Dataran Tinggi Pesisir',
      routeNote:
          'Menuju arah Selatan melewati Seberang Padang lalu mendaki langsung lereng Bukit Gado-Gado.',
    ),
  ];

  static List<EvacuationPoint> get allPoints => <EvacuationPoint>[
        ...tesShelters,
        ...horizontalSafeZones,
      ];
}
