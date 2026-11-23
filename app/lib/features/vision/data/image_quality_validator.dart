import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../domain/models/damage_models.dart';

/// Validasi teknis kualitas foto secara lokal di perangkat (non-AI).
///
/// Memeriksa:
/// 1. Keberadaan dan keterbacaan berkas.
/// 2. Format gambar yang didukung (JPG, PNG, WEBP).
/// 3. Ukuran berkas (tidak kosong dan tidak melebihi batas wajar).
/// 4. Dimensi/resolusi gambar hasil decode.
/// 5. Tingkat kecerahan rata-rata (mendeteksi foto terlalu gelap / terlalu terang).
/// 6. Estimasi ketajaman lokal berbasis variansi Laplacian (mendeteksi foto buram).
class ImageQualityValidator {
  static const int maxFileSizeBytes = 20 * 1024 * 1024; // 20 MB
  static const int minDimensionPx = 160;
  static const int recommendedDimensionPx = 480;
  static const double minBrightnessThreshold = 28.0;
  static const double maxBrightnessThreshold = 242.0;
  static const double minSharpnessVariance = 22.0;

  final bool useIsolate;

  const ImageQualityValidator({this.useIsolate = true});

  static const Set<String> _allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  /// Memvalidasi berkas foto secara lokal dan deterministik.
  Future<ImageQualityReport> validate(File file) async {
    final issues = <ImageQualityIssue>[];

    bool exists;
    try {
      exists = await file.exists();
    } catch (_) {
      exists = false;
    }

    if (!exists) {
      return const ImageQualityReport(
        isValid: false,
        issues: [
          ImageQualityIssue(
            code: 'FILE_NOT_FOUND',
            title: 'Foto tidak ditemukan',
            message:
                'Berkas foto tidak lagi tersedia di perangkat. Silakan ambil ulang atau pilih foto lain.',
            isBlocking: true,
          ),
        ],
        fileSizeBytes: 0,
        format: 'Tidak diketahui',
      );
    }

    Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      return const ImageQualityReport(
        isValid: false,
        issues: [
          ImageQualityIssue(
            code: 'FILE_UNREADABLE',
            title: 'Foto gagal dibaca',
            message:
                'Aplikasi tidak dapat membaca isi berkas foto ini. Coba pilih foto lain atau ambil foto ulang.',
            isBlocking: true,
          ),
        ],
        fileSizeBytes: 0,
        format: 'Tidak terbaca',
      );
    }

    final fileSize = bytes.length;
    if (fileSize == 0) {
      return const ImageQualityReport(
        isValid: false,
        issues: [
          ImageQualityIssue(
            code: 'EMPTY_FILE',
            title: 'Berkas foto kosong',
            message:
                'Ukuran berkas foto adalah 0 byte. Silakan ambil foto ulang.',
            isBlocking: true,
          ),
        ],
        fileSizeBytes: 0,
        format: 'Kosong',
      );
    }

    final ext = _extractExtension(file.path);
    final detectedFormat = _detectFormatFromBytes(bytes);
    final formatLabel = detectedFormat ?? (ext.isNotEmpty ? ext.toUpperCase() : 'Tidak diketahui');

    if (detectedFormat == null && !_allowedExtensions.contains(ext)) {
      issues.add(
        const ImageQualityIssue(
          code: 'UNSUPPORTED_FORMAT',
          title: 'Format gambar tidak didukung',
          message:
              'Gunakan foto berformat JPG, JPEG, PNG, atau WEBP agar gambar dapat diperiksa.',
          isBlocking: true,
        ),
      );
    }

    if (fileSize > maxFileSizeBytes) {
      issues.add(
        const ImageQualityIssue(
          code: 'FILE_TOO_LARGE',
          title: 'Ukuran berkas terlalu besar',
          message:
              'Ukuran foto melebihi batas 20 MB. Pilih foto dengan ukuran lebih kecil atau kompres terlebih dahulu.',
          isBlocking: true,
        ),
      );
    }

    if (issues.any((i) => i.isBlocking)) {
      return ImageQualityReport(
        isValid: false,
        issues: issues,
        fileSizeBytes: fileSize,
        format: formatLabel,
      );
    }

    // Decode & ukur kualitas teknis gambar pada isolate terpisah agar UI tetap lancar
    final metrics = useIsolate
        ? await compute(_analyzeImageBytes, bytes)
        : _analyzeImageBytes(bytes);

    if (!metrics.decoded) {
      issues.add(
        const ImageQualityIssue(
          code: 'DECODE_FAILED',
          title: 'Gambar rusak atau tidak valid',
          message:
              'Berkas tidak dapat dibuka sebagai gambar yang valid. Silakan ambil foto ulang atau pilih foto lain.',
          isBlocking: true,
        ),
      );
      return ImageQualityReport(
        isValid: false,
        issues: issues,
        fileSizeBytes: fileSize,
        format: formatLabel,
      );
    }

    final width = metrics.width!;
    final height = metrics.height!;

    if (width < minDimensionPx || height < minDimensionPx) {
      issues.add(
        ImageQualityIssue(
          code: 'RESOLUTION_TOO_LOW',
          title: 'Resolusi foto terlalu kecil',
          message:
              'Resolusi foto hanya ${width}x$height px (minimal ${minDimensionPx}x$minDimensionPx px). Ambil foto lebih dekat atau gunakan kamera utama.',
          isBlocking: true,
        ),
      );
    } else if (width < recommendedDimensionPx || height < recommendedDimensionPx) {
      issues.add(
        ImageQualityIssue(
          code: 'RESOLUTION_LOW_WARNING',
          title: 'Resolusi foto relatif rendah',
          message:
              'Resolusi foto ${width}x$height px. Foto dengan resolusi lebih tinggi membantu memperjelas detail retakan.',
          isBlocking: false,
        ),
      );
    }

    final brightness = metrics.meanBrightness;
    if (brightness != null) {
      if (brightness < minBrightnessThreshold) {
        issues.add(
          const ImageQualityIssue(
            code: 'IMAGE_TOO_DARK',
            title: 'Foto terlalu gelap',
            message:
                'Pencahayaan foto sangat rendah sehingga detail dinding atau struktur sulit terlihat. Aktifkan flash atau ambil foto di tempat lebih terang.',
            isBlocking: false,
          ),
        );
      } else if (brightness > maxBrightnessThreshold) {
        issues.add(
          const ImageQualityIssue(
            code: 'IMAGE_TOO_BRIGHT',
            title: 'Foto terlalu terang / silau',
            message:
                'Cahaya terlalu kuat sehingga tekstur bangunan tampak memudar. Hindari menyorot sumber cahaya secara langsung.',
            isBlocking: false,
          ),
        );
      }
    }

    final sharpness = metrics.sharpnessVariance;
    if (sharpness != null && sharpness < minSharpnessVariance) {
      issues.add(
        const ImageQualityIssue(
          code: 'IMAGE_BLURRY',
          title: 'Foto terdeteksi kurang tajam / buram',
          message:
              'Tepi gambar tampak kurang fokus (pemeriksaan ketajaman lokal non-AI). Pegang ponsel stabil saat memotret agar retakan terlihat jelas.',
          isBlocking: false,
        ),
      );
    }

    final hasBlocking = issues.any((i) => i.isBlocking);
    return ImageQualityReport(
      isValid: !hasBlocking,
      issues: issues,
      fileSizeBytes: fileSize,
      width: width,
      height: height,
      format: formatLabel,
      meanBrightness: brightness,
      sharpnessVariance: sharpness,
    );
  }

  static String _extractExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '';
    return path.substring(dot + 1).toLowerCase();
  }

  static String? _detectFormatFromBytes(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'JPEG';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'PNG';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'WEBP';
    }
    return null;
  }
}

class _DecodedImageMetrics {
  final bool decoded;
  final int? width;
  final int? height;
  final double? meanBrightness;
  final double? sharpnessVariance;

  const _DecodedImageMetrics({
    required this.decoded,
    this.width,
    this.height,
    this.meanBrightness,
    this.sharpnessVariance,
  });
}

_DecodedImageMetrics _analyzeImageBytes(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return const _DecodedImageMetrics(decoded: false);
  }

  final originalWidth = decoded.width;
  final originalHeight = decoded.height;

  // Downsample ke lebar maks 160px untuk kalkulasi kecerahan & ketajaman cepat
  final sample = decoded.width > 160 || decoded.height > 160
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? 160 : null,
          height: decoded.height > decoded.width ? 160 : null,
          interpolation: img.Interpolation.average,
        )
      : decoded;

  final w = sample.width;
  final h = sample.height;
  final gray = Float64List(w * h);

  double lumaSum = 0.0;
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final p = sample.getPixel(x, y);
      final luma = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      gray[y * w + x] = luma;
      lumaSum += luma;
    }
  }
  final meanBrightness = gray.isEmpty ? 0.0 : lumaSum / gray.length;

  // Variansi Laplacian sederhana (kernel 4-tetangga) untuk estimasi ketajaman
  double lapSum = 0.0;
  double lapSqSum = 0.0;
  int count = 0;

  if (w >= 3 && h >= 3) {
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final center = gray[y * w + x];
        final lap = gray[(y - 1) * w + x] +
            gray[(y + 1) * w + x] +
            gray[y * w + (x - 1)] +
            gray[y * w + (x + 1)] -
            (4.0 * center);
        lapSum += lap;
        lapSqSum += lap * lap;
        count++;
      }
    }
  }

  final meanLap = count > 0 ? lapSum / count : 0.0;
  final variance =
      count > 0 ? math.max(0.0, (lapSqSum / count) - (meanLap * meanLap)) : 0.0;

  return _DecodedImageMetrics(
    decoded: true,
    width: originalWidth,
    height: originalHeight,
    meanBrightness: meanBrightness,
    sharpnessVariance: variance,
  );
}
