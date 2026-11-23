import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap/core/navigation/sigap_transitions.dart';
import 'package:sigap/core/theme/app_colors.dart';
import '../../data/damage_report_repository.dart';
import '../../data/image_quality_validator.dart';
import '../../data/mock_damage_classifier.dart';
import '../../data/vision_device_service.dart';
import '../../domain/damage_classifier.dart';
import '../../domain/models/damage_models.dart';
import '../widgets/damage_widgets.dart';
import 'damage_analysis_screen.dart';

/// Halaman Pratinjau Foto sebelum proses analisis kerusakan dijalankan.
///
/// Melakukan validasi teknis kualitas foto secara lokal (format, ukuran, resolusi,
/// kecerahan, dan ketajaman) serta menyediakan pilihan opsional penyertaan lokasi GPS.
class DamagePreviewScreen extends StatefulWidget {
  final CapturedPhotoData photoData;
  final DamageClassifier? classifier;
  final DamageReportRepository? repository;
  final VisionDeviceService? deviceService;
  final ImageQualityValidator? validator;

  const DamagePreviewScreen({
    super.key,
    required this.photoData,
    this.classifier,
    this.repository,
    this.deviceService,
    this.validator,
  });

  @override
  State<DamagePreviewScreen> createState() => _DamagePreviewScreenState();
}

class _DamagePreviewScreenState extends State<DamagePreviewScreen> {
  late final DamageClassifier _classifier;
  late final DamageReportRepository _repository;
  late final VisionDeviceService _deviceService;
  late final ImageQualityValidator _validator;

  late CapturedPhotoData _photoData;
  bool _isValidating = true;
  bool _isFetchingLocation = false;
  bool _isPickingOtherPhoto = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _classifier = widget.classifier ?? const MockDamageClassifier();
    _repository = widget.repository ?? DamageReportRepository.instance;
    _deviceService = widget.deviceService ?? DefaultVisionDeviceService.instance;
    _validator = widget.validator ?? ImageQualityValidator();
    _photoData = widget.photoData;
    _runQualityValidation();
  }

  Future<void> _runQualityValidation() async {
    setState(() => _isValidating = true);
    final report = await _validator.validate(File(_photoData.imagePath));
    if (!mounted) return;
    setState(() {
      _photoData = _photoData.copyWith(qualityReport: report);
      _isValidating = false;
    });
  }

  Future<void> _toggleLocationAttachment(bool attach) async {
    HapticFeedback.selectionClick();
    if (!attach) {
      setState(() {
        _photoData = _photoData.copyWith(clearLocation: true);
        _locationError = null;
      });
      return;
    }

    setState(() {
      _isFetchingLocation = true;
      _locationError = null;
    });

    final result = await _deviceService.fetchCurrentLocation();
    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _photoData = _photoData.copyWith(location: result.location);
        _isFetchingLocation = false;
        _locationError = null;
      });
    } else {
      setState(() {
        _photoData = _photoData.copyWith(clearLocation: true);
        _isFetchingLocation = false;
        _locationError = result.errorMessage ??
            'Lokasi GPS gagal diambil. Anda tetap dapat melanjutkan tanpa lokasi.';
      });
    }
  }

  Future<void> _pickAnotherPhotoFromGallery() async {
    if (_isPickingOtherPhoto) return;
    HapticFeedback.selectionClick();
    setState(() => _isPickingOtherPhoto = true);

    try {
      final picked = await _deviceService.pickFromGallery();
      if (!mounted) return;

      if (picked.cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primaryDark,
            content: Text(
              'Pemilihan foto pengganti dibatalkan.',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );
        return;
      }

      if (!picked.hasPhoto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.alertAwas,
            content: Text(
              picked.errorMessage ?? 'Foto gagal dipilih dari galeri.',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        );
        return;
      }

      setState(() {
        _photoData = CapturedPhotoData(
          imagePath: picked.imagePath!,
          sourceLabel: 'Galeri Perangkat',
          capturedAt: DateTime.now(),
          location: _photoData.location,
        );
      });
      await _runQualityValidation();
    } finally {
      if (mounted) {
        setState(() => _isPickingOtherPhoto = false);
      }
    }
  }

  void _startAnalysis() {
    final quality = _photoData.qualityReport;
    if (_isValidating || quality == null || !quality.isValid) {
      return;
    }

    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      SigapRoutes.slideRight(
        DamageAnalysisScreen(
          photoData: _photoData,
          classifier: _classifier,
          repository: _repository,
          deviceService: _deviceService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quality = _photoData.qualityReport;
    final canAnalyze = !_isValidating && quality != null && quality.isValid;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: const VisionTopBar(
        title: 'Pratinjau Foto',
        subtitle: 'Periksa kejelasan foto sebelum dianalisis',
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pratinjau Foto Proporsional (Tap untuk Zoom)
                    DamagePhotoFrame(
                      imagePath: _photoData.imagePath,
                      aspectRatio: 4 / 3,
                      onTap: () => showFullScreenPhotoDialog(
                        context,
                        _photoData.imagePath,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Info Sumber & Waktu Foto
                    Row(
                      children: [
                        const Icon(
                          Icons.photo_camera_back_outlined,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${_photoData.sourceLabel} • ${formatIndonesianDateTime(_photoData.capturedAt)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSlate,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Hasil Pemeriksaan Teknis Kualitas Foto (Non-AI)
                    _buildQualityValidationCard(quality),

                    const SizedBox(height: 14),

                    // Pengaturan Lokasi Opsional (Privasi & Transparansi)
                    _buildLocationConsentCard(),
                  ],
                ),
              ),
            ),

            // Bilah Tombol Aksi Bawah
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: AppColors.borderLight.withValues(alpha: 0.9),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: Text(
                          'Ulangi Foto',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryDark,
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: canAnalyze ? _startAnalysis : null,
                        icon: const Icon(
                          Icons.analytics_outlined,
                          size: 20,
                        ),
                        label: Text(
                          'Analisis Kerusakan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.borderLight,
                          disabledForegroundColor: AppColors.textSlate,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityValidationCard(ImageQualityReport? quality) {
    if (_isValidating || quality == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Memeriksa format, ukuran, dan keterbacaan gambar secara lokal...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDarkest,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isBlocking = !quality.isValid;
    final hasWarnings = quality.hasWarnings;

    final Color bgColor = isBlocking
        ? const Color(0xFFFEF2F2)
        : hasWarnings
            ? const Color(0xFFFFFBEB)
            : AppColors.mintSurface;
    final Color borderColor = isBlocking
        ? const Color(0xFFFECACA)
        : hasWarnings
            ? const Color(0xFFFDE68A)
            : const Color(0xFFC2DFCD);
    final Color accentColor = isBlocking
        ? AppColors.alertAwas
        : hasWarnings
            ? const Color(0xFFD97706)
            : AppColors.safeGreen;
    final IconData statusIcon = isBlocking
        ? Icons.error_outline_rounded
        : hasWarnings
            ? Icons.warning_amber_rounded
            : Icons.verified_outlined;
    final String statusTitle = isBlocking
        ? 'Foto Tidak Memenuhi Syarat Teknis'
        : hasWarnings
            ? 'Foto Dapat Dianalisis dengan Catatan'
            : 'Foto Siap untuk Dianalisis';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: accentColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDarkest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pemeriksaan teknis lokal pada perangkat (bukan pemeriksaan kualitas berbasis AI).',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSlate,
            ),
          ),
          const SizedBox(height: 10),

          // Ringkasan Metrik Teknis Gambar
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildMetricChip('Format', quality.format),
              _buildMetricChip('Ukuran', quality.fileSizeLabel),
              if (quality.width != null && quality.height != null)
                _buildMetricChip('Resolusi', quality.resolutionLabel),
              if (quality.meanBrightness != null)
                _buildMetricChip('Cahaya', quality.brightnessLabel),
              if (quality.sharpnessVariance != null)
                _buildMetricChip('Ketajaman', quality.sharpnessLabel),
            ],
          ),

          if (quality.issues.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...quality.issues.map(
              (issue) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Icon(
                        issue.isBlocking
                            ? Icons.cancel_outlined
                            : Icons.info_outline_rounded,
                        size: 16,
                        color: issue.isBlocking
                            ? AppColors.alertAwas
                            : const Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            issue.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDarkest,
                            ),
                          ),
                          Text(
                            issue.message,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textDark,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.camera_alt_outlined, size: 17),
                  label: Text(
                    'Ambil Ulang',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isPickingOtherPhoto
                      ? null
                      : _pickAnotherPhotoFromGallery,
                  icon: const Icon(Icons.photo_library_outlined, size: 17),
                  label: Text(
                    _isPickingOtherPhoto ? 'Membuka...' : 'Pilih Foto Lain',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDarkest,
        ),
      ),
    );
  }

  Widget _buildLocationConsentCard() {
    final hasLocation = _photoData.location != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.primaryDark,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sertakan Lokasi Bangunan (Opsional)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDarkest,
                  ),
                ),
              ),
              if (_isFetchingLocation)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.primaryDark,
                  ),
                )
              else
                Switch(
                  value: hasLocation,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.primaryDark,
                  onChanged: _toggleLocationAttachment,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Koordinat GPS hanya dipakai untuk mencatat lokasi pemeriksaan di laporan lokal Anda dan tidak dikirim ke server tanpa persetujuan Anda.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textSlate,
              height: 1.4,
            ),
          ),
          if (hasLocation) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.mintAccent.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.my_location_rounded,
                    size: 15,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _photoData.location!.displayLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDarkest,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_locationError != null) ...[
            const SizedBox(height: 8),
            Text(
              _locationError!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFB45309),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
