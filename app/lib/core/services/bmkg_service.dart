import 'dart:convert';
import 'package:http/http.dart' as http;

/// Model data gempa resmi BMKG
class BmkgGempa {
  final String tanggal;
  final String jam;
  final String coordinates;
  final String lintang;
  final String bujur;
  final String magnitude;
  final String kedalaman;
  final String wilayah;
  final String potensi;
  final String dirasakan;
  final String? shakemapUrl;
  final bool isLiveFromApi;
  final double latitude;
  final double longitude;

  const BmkgGempa({
    required this.tanggal,
    required this.jam,
    required this.coordinates,
    required this.lintang,
    required this.bujur,
    required this.magnitude,
    required this.kedalaman,
    required this.wilayah,
    required this.potensi,
    required this.dirasakan,
    this.shakemapUrl,
    this.isLiveFromApi = false,
    required this.latitude,
    required this.longitude,
  });

  factory BmkgGempa.fromJson(Map<String, dynamic> json, {bool isLive = true}) {
    final coords = (json['Coordinates'] ?? '-0.95,100.35').toString().split(',');
    double lat = -0.95;
    double lon = 100.35;
    if (coords.length >= 2) {
      lat = double.tryParse(coords[0].trim()) ?? -0.95;
      lon = double.tryParse(coords[1].trim()) ?? 100.35;
    }

    final shakemap = json['Shakemap']?.toString();
    final shakemapFullUrl = shakemap != null && shakemap.isNotEmpty
        ? 'https://data.bmkg.go.id/DataMKG/TEWS/$shakemap'
        : null;

    return BmkgGempa(
      tanggal: json['Tanggal'] ?? 'Hari Ini',
      jam: json['Jam'] ?? '08:42 WIB',
      coordinates: json['Coordinates'] ?? '-0.95,100.35',
      lintang: json['Lintang'] ?? '0.95 LS',
      bujur: json['Bujur'] ?? '100.35 BT',
      magnitude: json['Magnitude'] ?? '5.8',
      kedalaman: json['Kedalaman'] ?? '10 km',
      wilayah: json['Wilayah'] ?? '24 km Barat Daya Padang, Sumbar',
      potensi: json['Potensi'] ?? 'Tidak berpotensi tsunami',
      dirasakan: json['Dirasakan'] ?? 'III-IV MMI di Padang',
      shakemapUrl: shakemapFullUrl,
      isLiveFromApi: isLive,
      latitude: lat,
      longitude: lon,
    );
  }

  /// Data fallback default (Wilayah Padang M5.8) jika offline atau gagal koneksi
  static BmkgGempa get fallbackPadang => const BmkgGempa(
        tanggal: '27 Okt 2026',
        jam: '08:42 WIB',
        coordinates: '-0.95,100.35',
        lintang: '0.95 LS',
        bujur: '100.35 BT',
        magnitude: '5.8',
        kedalaman: '10 km',
        wilayah: '24 km Barat Daya Padang, Sumbar',
        potensi: 'Tidak berpotensi tsunami',
        dirasakan: 'III-IV Padang, II-III Pariaman',
        isLiveFromApi: false,
        latitude: -0.95,
        longitude: 100.35,
      );
}

/// Service untuk mengambil data resmi dari Open Data API BMKG
class BmkgService {
  static const String _autoGempaUrl = 'https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json';

  /// Mengambil data gempa bumi terkini langsung dari BMKG
  static Future<BmkgGempa> fetchLatestGempa() async {
    try {
      final response = await http
          .get(Uri.parse(_autoGempaUrl))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        final gempaJson = decoded['Infogempa']?['gempa'];
        if (gempaJson != null && gempaJson is Map<String, dynamic>) {
          return BmkgGempa.fromJson(gempaJson, isLive: true);
        }
      }
    } catch (_) {
      // Jika offline, timeout, atau format bermasalah, gunakan fallback Padang
    }
    return BmkgGempa.fallbackPadang;
  }
}
