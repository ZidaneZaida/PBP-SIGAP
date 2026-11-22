import 'dart:io';
import '../domain/damage_classifier.dart';
import '../domain/models/damage_models.dart';

/// Implementasi classifier simulasi yang deterministik untuk pengujian frontend.
///
/// PENTING:
/// - Bukan model Machine Learning / AI sungguhan.
/// - Tidak menghasilkan angka acak; foto yang sama akan selalu menghasilkan
///   kategori, skor simulasi, dan penjelasan yang konsisten.
/// - Siap diganti oleh implementasi model TFLite atau API backend melalui
///   kontrak [DamageClassifier].
class MockDamageClassifier implements DamageClassifier {
  final Duration stepDelay;
  final DamageCategory? forcedCategory;
  final DamageClassifierException? simulatedException;
  final bool simulateNetworkRequirement;
  final bool hasInternetConnection;

  const MockDamageClassifier({
    this.stepDelay = const Duration(milliseconds: 420),
    this.forcedCategory,
    this.simulatedException,
    this.simulateNetworkRequirement = false,
    this.hasInternetConnection = true,
  });

  @override
  String get name => 'MockDamageClassifier (Simulasi Pengujian)';

  @override
  bool get isSimulation => true;

  @override
  bool get requiresInternet => simulateNetworkRequirement;

  @override
  Future<DamageClassificationResult> classify({
    required File imageFile,
    required ImageQualityReport qualityReport,
    void Function(DamageAnalysisStep step)? onStepChanged,
    bool Function()? isCancelled,
  }) async {
    Future<void> advanceStep(DamageAnalysisStep step) async {
      if (isCancelled?.call() == true) {
        throw const DamageClassifierException(
          code: 'CANCELLED',
          message: 'Proses analisis dibatalkan oleh pengguna.',
          isCancelled: true,
        );
      }
      onStepChanged?.call(step);
      if (stepDelay > Duration.zero) {
        await Future<void>.delayed(stepDelay);
      }
      if (isCancelled?.call() == true) {
        throw const DamageClassifierException(
          code: 'CANCELLED',
          message: 'Proses analisis dibatalkan oleh pengguna.',
          isCancelled: true,
        );
      }
    }

    await advanceStep(DamageAnalysisStep.photoSelected);

    if (requiresInternet && !hasInternetConnection) {
      throw const DamageClassifierException(
        code: 'OFFLINE_UNAVAILABLE',
        message:
            'Model analisis ini membutuhkan koneksi internet. Periksa sambungan internet Anda lalu coba lagi.',
        isOfflineError: true,
      );
    }

    await advanceStep(DamageAnalysisStep.checkingImage);

    if (!await imageFile.exists()) {
      throw const DamageClassifierException(
        code: 'IMAGE_MISSING',
        message:
            'Berkas foto tidak ditemukan saat analisis dimulai. Silakan pilih atau ambil foto ulang.',
      );
    }

    if (!qualityReport.isValid) {
      throw const DamageClassifierException(
        code: 'INVALID_IMAGE',
        message:
            'Foto tidak memenuhi syarat teknis untuk dianalisis. Silakan ganti dengan foto yang lebih jelas.',
      );
    }

    await advanceStep(DamageAnalysisStep.preparingImage);

    if (simulatedException != null) {
      throw simulatedException!;
    }

    // Hitung fingerprint deterministik dari konten berkas agar hasil selalu konsisten
    final bytes = await imageFile.readAsBytes();
    final fingerprint = _computeDeterministicFingerprint(bytes, qualityReport);

    await advanceStep(DamageAnalysisStep.analyzingDamage);

    final category = forcedCategory ?? _pickDeterministicCategory(fingerprint);
    final confidence = _computeDeterministicConfidence(category, fingerprint);

    await advanceStep(DamageAnalysisStep.preparingResult);

    return _buildConsistentResult(
      category: category,
      confidenceScore: confidence,
    );
  }

  /// Menghitung nilai hash deterministik (FNV-1a sampling) dari berkas gambar
  /// sehingga foto identik selalu menghasilkan output yang sama persis.
  int _computeDeterministicFingerprint(
    List<int> bytes,
    ImageQualityReport report,
  ) {
    int hash = 2166136261;
    final step = bytes.length > 512 ? bytes.length ~/ 512 : 1;
    for (int i = 0; i < bytes.length; i += step) {
      hash ^= bytes[i];
      hash = (hash * 16777619) & 0x7FFFFFFF;
    }
    hash ^= (report.width ?? 0) * 31;
    hash ^= (report.height ?? 0) * 17;
    return hash.abs();
  }

  DamageCategory _pickDeterministicCategory(int fingerprint) {
    final bucket = fingerprint % 3;
    switch (bucket) {
      case 0:
        return DamageCategory.ringan;
      case 1:
        return DamageCategory.sedang;
      case 2:
      default:
        return DamageCategory.berat;
    }
  }

  double _computeDeterministicConfidence(
    DamageCategory category,
    int fingerprint,
  ) {
    // Rentang konsisten dan deterministik (tidak acak) per kategori untuk pengujian UI
    final offset = ((fingerprint % 13) / 100.0); // 0.00 .. 0.12
    switch (category) {
      case DamageCategory.ringan:
        return 0.78 + offset; // 78% .. 90%
      case DamageCategory.sedang:
        return 0.74 + offset; // 74% .. 86%
      case DamageCategory.berat:
        return 0.81 + offset; // 81% .. 93%
    }
  }

  DamageClassificationResult _buildConsistentResult({
    required DamageCategory category,
    required double confidenceScore,
  }) {
    switch (category) {
      case DamageCategory.ringan:
        return DamageClassificationResult(
          category: DamageCategory.ringan,
          confidenceScore: confidenceScore,
          summary:
              'Simulasi pengujian mengindikasikan pola kerusakan ringan seperti retak rambut pada plester atau pengelupasan cat permukaan tanpa indikasi pergeseran struktur utama pada foto.',
          recommendations: const [
            'Tetap waspada terhadap kemungkinan gempa susulan di wilayah Kota Padang.',
            'Periksa bagian dinding, plafon, dan sambungan pipa/listrik di sekitar area yang difoto.',
            'Dokumentasikan kondisi bangunan secara berkala jika muncul retakan baru atau retakan melebar.',
            'Jika ragu terhadap kondisi kolom atau balok utama, konsultasikan dengan tenaga teknis atau BPBD setempat.',
          ],
          urgentWarning: null,
          isSimulation: true,
          classifierName: name,
          analyzedAt: DateTime.now(),
          detectedRegions: [
            DamageBoundingBox(
              left: 0.24,
              top: 0.28,
              width: 0.50,
              height: 0.36,
              label: 'Indikasi Retak Permukaan (Simulasi)',
              confidence: confidenceScore,
            ),
          ],
        );

      case DamageCategory.sedang:
        return DamageClassificationResult(
          category: DamageCategory.sedang,
          confidenceScore: confidenceScore,
          summary:
              'Simulasi pengujian mengindikasikan kerusakan sedang pada elemen dinding atau bagian non-struktural/struktural seperti retak diagonal cukup lebar atau plester terkelupas signifikan.',
          recommendations: const [
            'Jauhi ruangan atau sisi bangunan yang memperlihatkan retakan besar, terutama jika gempa susulan masih mungkin terjadi.',
            'Matikan aliran listrik utama dan tutup katup gas apabila ditemukan instalasi yang terganggu.',
            'Jangan memperbaiki atau membongkar bagian struktur utama sebelum diperiksa petugas teknis.',
            'Laporkan kondisi bangunan kepada RT/RW, BPBD Kota Padang, atau layanan darurat 112 untuk pemeriksaan lanjutan.',
          ],
          urgentWarning:
              'Peringatan Keselamatan: Indikasi kerusakan sedang dapat membahayakan jika terjadi gempa susulan. Jauhi area bangunan yang berpotensi berbahaya dan segera hubungi petugas berwenang (BPBD Kota Padang / 112).',
          isSimulation: true,
          classifierName: name,
          analyzedAt: DateTime.now(),
          detectedRegions: [
            DamageBoundingBox(
              left: 0.18,
              top: 0.22,
              width: 0.62,
              height: 0.48,
              label: 'Indikasi Retak Dinding/Struktur (Simulasi)',
              confidence: confidenceScore,
            ),
          ],
        );

      case DamageCategory.berat:
        return DamageClassificationResult(
          category: DamageCategory.berat,
          confidenceScore: confidenceScore,
          summary:
              'Simulasi pengujian mengindikasikan kerusakan berat seperti potensi keruntuhan sebagian, retakan struktural parah pada kolom/balok, atau ketidakstabilan bangunan.',
          recommendations: const [
            'SEGERA keluar dan jauhi bangunan menuju area terbuka atau titik kumpul evakuasi terdekat yang aman.',
            'Dilarang keras memasuki kembali bangunan untuk mengambil barang sebelum dinyatakan aman oleh tim teknis berwenang.',
            'Pastikan seluruh anggota keluarga dan warga sekitar menjauh dari radius jatuhan material bangunan.',
            'Segera hubungi Layanan Darurat 112, PUSDALOPS BPBD Kota Padang ((0751) 778775), atau Basarnas jika ada korban/bahaya langsung.',
          ],
          urgentWarning:
              'BAHAYA POTENSIAL: Indikasi kerusakan berat! Segera jauhi area bangunan yang berpotensi runtuh dan hubungi petugas berwenang (BPBD Kota Padang / Darurat 112) untuk evakuasi serta asesmen resmi.',
          isSimulation: true,
          classifierName: name,
          analyzedAt: DateTime.now(),
          detectedRegions: [
            DamageBoundingBox(
              left: 0.14,
              top: 0.18,
              width: 0.72,
              height: 0.58,
              label: 'Indikasi Kerusakan Struktural Berat (Simulasi)',
              confidence: confidenceScore,
            ),
          ],
        );
    }
  }
}
