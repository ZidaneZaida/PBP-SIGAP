import 'dart:io';
import 'models/damage_models.dart';

/// Exception terstruktur untuk kegagalan proses klasifikasi SIGAP-Vision.
class DamageClassifierException implements Exception {
  final String code;
  final String message;
  final bool isOfflineError;
  final bool isTimeout;
  final bool isCancelled;

  const DamageClassifierException({
    required this.code,
    required this.message,
    this.isOfflineError = false,
    this.isTimeout = false,
    this.isCancelled = false,
  });

  @override
  String toString() => message;
}

/// Kontrak (interface) classifier untuk deteksi awal kerusakan bangunan.
///
/// Dirancang agar implementasi simulasi ([MockDamageClassifier]) dapat diganti
/// di kemudian hari dengan model on-device (TFLite) atau integrasi API backend
/// tanpa perlu mengubah halaman UI.
abstract class DamageClassifier {
  /// Nama identitas classifier yang ditampilkan secara transparan pada hasil.
  String get name;

  /// Bernilai `true` bila hasil masih merupakan simulasi pengujian frontend.
  bool get isSimulation;

  /// Bernilai `true` bila classifier membutuhkan koneksi internet (misalnya API backend).
  bool get requiresInternet;

  /// Menjalankan analisis indikasi kerusakan bangunan dari [imageFile].
  ///
  /// - [onStepChanged] melaporkan progres setiap tahapan ke UI.
  /// - [isCancelled] diperiksa secara berkala agar pembatalan oleh pengguna
  ///   segera menghentikan proses dengan aman.
  Future<DamageClassificationResult> classify({
    required File imageFile,
    required ImageQualityReport qualityReport,
    void Function(DamageAnalysisStep step)? onStepChanged,
    bool Function()? isCancelled,
  });
}
