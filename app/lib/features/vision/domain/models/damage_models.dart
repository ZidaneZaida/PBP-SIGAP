import 'package:flutter/material.dart';
import 'package:sigap/core/theme/app_colors.dart';

/// Kategori tingkat indikasi kerusakan bangunan pada fitur SIGAP-Vision.
enum DamageCategory {
  ringan,
  sedang,
  berat;

  String get label {
    switch (this) {
      case DamageCategory.ringan:
        return 'AMAN (Minor)';
      case DamageCategory.sedang:
        return 'WASPADA (Moderate)';
      case DamageCategory.berat:
        return 'BAHAYA KRITIS (Severe)';
    }
  }

  String get shortLabel {
    switch (this) {
      case DamageCategory.ringan:
        return 'AMAN';
      case DamageCategory.sedang:
        return 'WASPADA';
      case DamageCategory.berat:
        return 'BAHAYA KRITIS';
    }
  }

  /// Nilai `damage_level` sesuai model Django `DamageReport` (Revisi Zidan Bagian 4).
  String get apiDamageLevel {
    switch (this) {
      case DamageCategory.ringan:
        return 'minor';
      case DamageCategory.sedang:
        return 'moderate';
      case DamageCategory.berat:
        return 'critical';
    }
  }

  int get severityLevel {
    switch (this) {
      case DamageCategory.ringan:
        return 1;
      case DamageCategory.sedang:
        return 2;
      case DamageCategory.berat:
        return 3;
    }
  }

  bool get isHighRisk =>
      this == DamageCategory.sedang || this == DamageCategory.berat;

  Color get accentColor {
    switch (this) {
      case DamageCategory.ringan:
        return AppColors.safeGreen;
      case DamageCategory.sedang:
        return AppColors.alertSiaga;
      case DamageCategory.berat:
        return AppColors.alertAwas;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case DamageCategory.ringan:
        return const Color(0xFFECFDF5);
      case DamageCategory.sedang:
        return const Color(0xFFFFF7ED);
      case DamageCategory.berat:
        return const Color(0xFFFEF2F2);
    }
  }

  Color get borderColor {
    switch (this) {
      case DamageCategory.ringan:
        return const Color(0xFFA7F3D0);
      case DamageCategory.sedang:
        return const Color(0xFFFED7AA);
      case DamageCategory.berat:
        return const Color(0xFFFECACA);
    }
  }

  Color get textColor {
    switch (this) {
      case DamageCategory.ringan:
        return const Color(0xFF065F46);
      case DamageCategory.sedang:
        return const Color(0xFF9A3412);
      case DamageCategory.berat:
        return const Color(0xFF991B1B);
    }
  }

  IconData get icon {
    switch (this) {
      case DamageCategory.ringan:
        return Icons.check_circle_outline_rounded;
      case DamageCategory.sedang:
        return Icons.warning_amber_rounded;
      case DamageCategory.berat:
        return Icons.dangerous_rounded;
    }
  }

  static DamageCategory fromName(String? value) {
    final normalized = value?.trim().toLowerCase();
    switch (normalized) {
      case 'sedang':
      case 'moderate':
      case 'crack_structural_wall':
        return DamageCategory.sedang;
      case 'berat':
      case 'severe':
      case 'critical':
      case 'severe_column_failure':
        return DamageCategory.berat;
      case 'ringan':
      case 'minor':
      case 'crack_non_structural':
      default:
        return DamageCategory.ringan;
    }
  }
}

/// Status penyimpanan & sinkronisasi laporan lokal SIGAP-Vision.
/// Catatan: status [synced] hanya boleh digunakan bila sinkronisasi ke backend
/// sungguhan benar-benar berhasil.
enum DamageSyncStatus {
  localOnly,
  pendingSync,
  synced;

  String get label {
    switch (this) {
      case DamageSyncStatus.localOnly:
        return 'Tersimpan Lokal';
      case DamageSyncStatus.pendingSync:
        return 'Antrean Sinkronisasi Lokal';
      case DamageSyncStatus.synced:
        return 'Tersinkronisasi';
    }
  }

  String get shortLabel {
    switch (this) {
      case DamageSyncStatus.localOnly:
        return 'Lokal';
      case DamageSyncStatus.pendingSync:
        return 'Menunggu Sinkronisasi';
      case DamageSyncStatus.synced:
        return 'Tersinkronisasi';
    }
  }

  Color get badgeColor {
    switch (this) {
      case DamageSyncStatus.localOnly:
        return AppColors.primary;
      case DamageSyncStatus.pendingSync:
        return AppColors.alertWaspada;
      case DamageSyncStatus.synced:
        return AppColors.safeGreen;
    }
  }

  IconData get icon {
    switch (this) {
      case DamageSyncStatus.localOnly:
        return Icons.save_alt_rounded;
      case DamageSyncStatus.pendingSync:
        return Icons.cloud_queue_rounded;
      case DamageSyncStatus.synced:
        return Icons.cloud_done_rounded;
    }
  }

  static DamageSyncStatus fromName(String? value) {
    switch (value) {
      case 'localOnly':
        return DamageSyncStatus.localOnly;
      case 'synced':
        return DamageSyncStatus.synced;
      case 'pendingSync':
      default:
        return DamageSyncStatus.pendingSync;
    }
  }
}

/// Tahapan proses analisis yang ditampilkan secara informatif ke pengguna.
enum DamageAnalysisStep {
  photoSelected,
  checkingImage,
  preparingImage,
  analyzingDamage,
  preparingResult;

  String get label {
    switch (this) {
      case DamageAnalysisStep.photoSelected:
        return 'Foto berhasil dipilih';
      case DamageAnalysisStep.checkingImage:
        return 'Memeriksa gambar';
      case DamageAnalysisStep.preparingImage:
        return 'Mempersiapkan gambar';
      case DamageAnalysisStep.analyzingDamage:
        return 'Menganalisis kerusakan';
      case DamageAnalysisStep.preparingResult:
        return 'Menyiapkan hasil';
    }
  }

  String get subtitle {
    switch (this) {
      case DamageAnalysisStep.photoSelected:
        return 'Berkas foto diterima dan siap divalidasi.';
      case DamageAnalysisStep.checkingImage:
        return 'Memastikan format, ukuran, dan keterbacaan foto.';
      case DamageAnalysisStep.preparingImage:
        return 'Menyesuaikan dimensi gambar untuk pemeriksaan.';
      case DamageAnalysisStep.analyzingDamage:
        return 'Menjalankan klasifikasi indikasi kerusakan bangunan.';
      case DamageAnalysisStep.preparingResult:
        return 'Menyusun ringkasan kategori dan rekomendasi awal.';
    }
  }

  double get progress => (index + 1) / DamageAnalysisStep.values.length;
}

/// Area koordinat relatif (0.0 - 1.0) untuk visualisasi area indikasi kerusakan.
class DamageBoundingBox {
  final double left;
  final double top;
  final double width;
  final double height;
  final String label;
  final double? confidence;

  const DamageBoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.label,
    this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'left': left,
        'top': top,
        'width': width,
        'height': height,
        'label': label,
        'confidence': confidence,
      };

  factory DamageBoundingBox.fromJson(Map<String, dynamic> json) {
    return DamageBoundingBox(
      left: (json['left'] as num?)?.toDouble() ?? 0.2,
      top: (json['top'] as num?)?.toDouble() ?? 0.2,
      width: (json['width'] as num?)?.toDouble() ?? 0.4,
      height: (json['height'] as num?)?.toDouble() ?? 0.4,
      label: json['label'] as String? ?? 'Area Indikasi',
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }
}

/// Masalah yang ditemukan saat validasi teknis kualitas foto secara lokal.
class ImageQualityIssue {
  final String code;
  final String title;
  final String message;
  final bool isBlocking;

  const ImageQualityIssue({
    required this.code,
    required this.title,
    required this.message,
    required this.isBlocking,
  });
}

/// Laporan validasi teknis kualitas foto (non-AI, deterministik di perangkat).
class ImageQualityReport {
  final bool isValid;
  final List<ImageQualityIssue> issues;
  final int fileSizeBytes;
  final int? width;
  final int? height;
  final String format;
  final double? meanBrightness; // 0..255
  final double? sharpnessVariance;

  const ImageQualityReport({
    required this.isValid,
    required this.issues,
    required this.fileSizeBytes,
    this.width,
    this.height,
    required this.format,
    this.meanBrightness,
    this.sharpnessVariance,
  });

  List<ImageQualityIssue> get blockingIssues =>
      issues.where((e) => e.isBlocking).toList();

  List<ImageQualityIssue> get warningIssues =>
      issues.where((e) => !e.isBlocking).toList();

  bool get hasWarnings => warningIssues.isNotEmpty;

  String get resolutionLabel =>
      (width != null && height != null) ? '${width}x$height px' : 'Tidak terbaca';

  String get fileSizeLabel {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    final kb = fileSizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(2)} MB';
  }

  String get brightnessLabel {
    final b = meanBrightness;
    if (b == null) return 'Tidak tersedia';
    if (b < 32) return 'Terlalu Gelap';
    if (b > 240) return 'Terlalu Terang';
    return 'Cukup Baik';
  }

  String get sharpnessLabel {
    final s = sharpnessVariance;
    if (s == null) return 'Tidak tersedia';
    if (s < 25) return 'Agak Buram';
    return 'Cukup Jelas';
  }
}

/// Data lokasi opsional yang dicatat hanya dengan persetujuan pengguna.
class VisionLocationData {
  final double latitude;
  final double longitude;
  final String displayLabel;
  final DateTime capturedAt;

  const VisionLocationData({
    required this.latitude,
    required this.longitude,
    required this.displayLabel,
    required this.capturedAt,
  });

  String get coordinatesText =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'displayLabel': displayLabel,
        'capturedAt': capturedAt.toIso8601String(),
      };

  factory VisionLocationData.fromJson(Map<String, dynamic> json) {
    return VisionLocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      displayLabel: json['displayLabel'] as String? ?? 'Koordinat GPS',
      capturedAt: DateTime.tryParse(json['capturedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Payload data foto yang diteruskan antar halaman agar data tidak hilang saat navigasi.
class CapturedPhotoData {
  final String imagePath;
  final String sourceLabel;
  final DateTime capturedAt;
  final ImageQualityReport? qualityReport;
  final VisionLocationData? location;

  const CapturedPhotoData({
    required this.imagePath,
    required this.sourceLabel,
    required this.capturedAt,
    this.qualityReport,
    this.location,
  });

  CapturedPhotoData copyWith({
    String? imagePath,
    String? sourceLabel,
    DateTime? capturedAt,
    ImageQualityReport? qualityReport,
    VisionLocationData? location,
    bool clearLocation = false,
  }) {
    return CapturedPhotoData(
      imagePath: imagePath ?? this.imagePath,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      capturedAt: capturedAt ?? this.capturedAt,
      qualityReport: qualityReport ?? this.qualityReport,
      location: clearLocation ? null : (location ?? this.location),
    );
  }
}

/// Hasil terstruktur dari classifier (baik [MockDamageClassifier] maupun model ML asli nanti).
class DamageClassificationResult {
  final DamageCategory category;

  /// Skor keyakinan dalam rentang 0.0 - 1.0. Bernilai `null` jika classifier
  /// tidak menyediakan skor keyakinan (UI tidak akan menampilkan skor fiktif).
  final double? confidenceScore;
  final String summary;
  final List<String> recommendations;
  final String? urgentWarning;
  final bool isSimulation;
  final String classifierName;
  final DateTime analyzedAt;
  final List<DamageBoundingBox> detectedRegions;

  const DamageClassificationResult({
    required this.category,
    this.confidenceScore,
    required this.summary,
    required this.recommendations,
    this.urgentWarning,
    required this.isSimulation,
    required this.classifierName,
    required this.analyzedAt,
    this.detectedRegions = const [],
  });

  String? get confidencePercentLabel {
    final score = confidenceScore;
    if (score == null) return null;
    final clamped = score.clamp(0.0, 1.0);
    return '${(clamped * 100).toStringAsFixed(1)}%';
  }

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'confidenceScore': confidenceScore,
        'summary': summary,
        'recommendations': recommendations,
        'urgentWarning': urgentWarning,
        'isSimulation': isSimulation,
        'classifierName': classifierName,
        'analyzedAt': analyzedAt.toIso8601String(),
        'detectedRegions': detectedRegions.map((e) => e.toJson()).toList(),
      };

  factory DamageClassificationResult.fromJson(Map<String, dynamic> json) {
    final rawRecs = json['recommendations'];
    final rawRegions = json['detectedRegions'];
    return DamageClassificationResult(
      category: DamageCategory.fromName(json['category'] as String?),
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble(),
      summary: json['summary'] as String? ?? '',
      recommendations: rawRecs is List
          ? rawRecs.map((e) => e.toString()).toList()
          : const [],
      urgentWarning: json['urgentWarning'] as String?,
      isSimulation: json['isSimulation'] as bool? ?? true,
      classifierName: json['classifierName'] as String? ?? 'Classifier',
      analyzedAt: DateTime.tryParse(json['analyzedAt'] as String? ?? '') ??
          DateTime.now(),
      detectedRegions: rawRegions is List
          ? rawRegions
              .whereType<Map<String, dynamic>>()
              .map(DamageBoundingBox.fromJson)
              .toList()
          : const [],
    );
  }
}

/// Laporan pemeriksaan kerusakan yang tersimpan di penyimpanan lokal perangkat.
class DamageScanReport {
  final String id;
  final String imagePath;
  final DateTime createdAt;
  final VisionLocationData? location;
  final DamageClassificationResult result;
  final DamageSyncStatus syncStatus;
  final DateTime? syncedAt;

  /// URL foto di server (diisi hanya untuk laporan yang dibaca dari backend).
  ///
  /// Bernilai `null` untuk laporan lokal yang fotonya masih di perangkat.
  final String? imageUrl;

  const DamageScanReport({
    required this.id,
    required this.imagePath,
    required this.createdAt,
    this.location,
    required this.result,
    required this.syncStatus,
    this.syncedAt,
    this.imageUrl,
  });

  /// Bernilai `true` bila laporan hanya ada di server (belum ada salinan lokal).
  bool get isRemoteOnly => imagePath.isEmpty && (imageUrl?.isNotEmpty ?? false);

  DamageScanReport copyWith({
    String? id,
    String? imagePath,
    DateTime? createdAt,
    VisionLocationData? location,
    DamageClassificationResult? result,
    DamageSyncStatus? syncStatus,
    DateTime? syncedAt,
    String? imageUrl,
    bool clearSyncedAt = false,
  }) {
    return DamageScanReport(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
      result: result ?? this.result,
      syncStatus: syncStatus ?? this.syncStatus,
      syncedAt: clearSyncedAt ? null : (syncedAt ?? this.syncedAt),
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'createdAt': createdAt.toIso8601String(),
        'location': location?.toJson(),
        'result': result.toJson(),
        'syncStatus': syncStatus.name,
        if (syncedAt != null) 'syncedAt': syncedAt!.toIso8601String(),
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

  /// Membangun laporan dari payload backend `GET /api/damage-reports/my/`.
  ///
  /// Laporan server tidak membawa saran tindakan (`recommendations`), karena
  /// teks itu hanya dihasilkan di perangkat. Field tersebut dikosongkan agar UI
  /// tidak menampilkan rekomendasi palsu.
  factory DamageScanReport.fromServerJson(Map<String, dynamic> json) {
    final lat = (json['latitude'] as num?)?.toDouble();
    final lng = (json['longitude'] as num?)?.toDouble();
    final createdAt =
        DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now();
    final damageLevel = DamageCategory.fromName(
      json['damage_level'] as String?,
    );
    final imageUrl = (json['image_url'] as String? ?? '').trim();
    final clientId = (json['client_report_id'] as String? ?? '').trim();
    final serverId = json['id'] as String? ?? '';
    final verified = json['is_verified_by_officer'] as bool?;

    return DamageScanReport(
      // Pakai ID aplikasi bila ada agar cocok dengan salinan lokal.
      id: clientId.isNotEmpty ? clientId : serverId,
      imagePath: '',
      imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
      createdAt: createdAt,
      location: (lat != null && lng != null)
          ? VisionLocationData(
              latitude: lat,
              longitude: lng,
              displayLabel:
                  'GPS Perangkat (${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)})',
              capturedAt: createdAt,
            )
          : null,
      result: DamageClassificationResult(
        category: damageLevel,
        confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
        summary: json['description'] as String? ?? '',
        recommendations: const [],
        // Verifikasi petugas BPBD bukan hasil AI, jadi bukan simulasi.
        isSimulation: verified == null,
        classifierName: verified == true
            ? 'Terverifikasi Petugas BPBD'
            : 'Classifier On-Device',
        analyzedAt: createdAt,
      ),
      syncStatus: DamageSyncStatus.synced,
      syncedAt: createdAt,
    );
  }

  factory DamageScanReport.fromJson(Map<String, dynamic> json) {
    final locJson = json['location'];
    final rawSyncedAt = json['syncedAt'] as String?;
    return DamageScanReport(
      id: json['id'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      location: locJson is Map<String, dynamic>
          ? VisionLocationData.fromJson(locJson)
          : null,
      result: DamageClassificationResult.fromJson(
        (json['result'] as Map<String, dynamic>?) ?? const {},
      ),
      syncStatus: DamageSyncStatus.fromName(json['syncStatus'] as String?),
      syncedAt: rawSyncedAt != null ? DateTime.tryParse(rawSyncedAt) : null,
      imageUrl: _nonEmpty(json['imageUrl'] as String?),
    );
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// Format tanggal dan waktu ramah bahasa Indonesia (contoh: `21 Nov 2026 • 19:20 WIB`).
String formatIndonesianDateTime(DateTime dt) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  final local = dt.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = months[(local.month - 1).clamp(0, 11)];
  final year = local.year;
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day $month $year • $hour:$minute WIB';
}
