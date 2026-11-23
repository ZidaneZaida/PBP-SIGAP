import 'dart:async';
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
import 'damage_result_screen.dart';

/// Halaman Proses Analisis SIGAP-Vision.
///
/// Menampilkan 5 tahapan analisis secara informatif:
/// 1. Foto berhasil dipilih
/// 2. Memeriksa gambar
/// 3. Mempersiapkan gambar
/// 4. Menganalisis kerusakan
/// 5. Menyiapkan hasil
///
/// Dilengkapi proteksi timeout, tombol batal, dan tampilan error yang jelas
/// agar pengguna tidak pernah terjebak pada loading tanpa akhir.
class DamageAnalysisScreen extends StatefulWidget {
  final CapturedPhotoData photoData;
  final DamageClassifier? classifier;
  final DamageReportRepository? repository;
  final VisionDeviceService? deviceService;
  final Duration timeout;

  const DamageAnalysisScreen({
    super.key,
    required this.photoData,
    this.classifier,
    this.repository,
    this.deviceService,
    this.timeout = const Duration(seconds: 20),
  });

  @override
  State<DamageAnalysisScreen> createState() => _DamageAnalysisScreenState();
}

class _DamageAnalysisScreenState extends State<DamageAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late final DamageClassifier _classifier;
  late final DamageReportRepository _repository;
  late final VisionDeviceService _deviceService;
  late final AnimationController _pulseController;

  DamageAnalysisStep _currentStep = DamageAnalysisStep.photoSelected;
  bool _isCancelled = false;
  bool _isFailed = false;
  bool _isOfflineError = false;
  String? _errorTitle;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _classifier = widget.classifier ?? const MockDamageClassifier();
    _repository = widget.repository ?? DamageReportRepository.instance;
    _deviceService = widget.deviceService ?? DefaultVisionDeviceService.instance;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAnalysis();
    });
  }

  @override
  void dispose() {
    _isCancelled = true;
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    if (!mounted) return;
    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
    setState(() {
      _isCancelled = false;
      _isFailed = false;
      _isOfflineError = false;
      _errorTitle = null;
      _errorMessage = null;
      _currentStep = DamageAnalysisStep.photoSelected;
    });

    try {
      final imageFile = File(widget.photoData.imagePath);
      final qualityReport = widget.photoData.qualityReport ??
          await ImageQualityValidator().validate(imageFile);

      if (_classifier.requiresInternet) {
        final hasInternet = await _repository.checkInternetAvailability();
        if (!hasInternet) {
          throw const DamageClassifierException(
            code: 'NO_INTERNET',
            message:
                'Analisis menggunakan layanan server membutuhkan koneksi internet. Periksa jaringan Anda lalu coba lagi.',
            isOfflineError: true,
          );
        }
      }

      final result = await _classifier
          .classify(
            imageFile: imageFile,
            qualityReport: qualityReport,
            onStepChanged: (step) {
              if (!mounted || _isCancelled) return;
              setState(() => _currentStep = step);
            },
            isCancelled: () => _isCancelled || !mounted,
          )
          .timeout(
            widget.timeout,
            onTimeout: () {
              throw const DamageClassifierException(
                code: 'ANALYSIS_TIMEOUT',
                message:
                    'Proses analisis membutuhkan waktu terlalu lama. Silakan coba lagi atau periksa ulang foto Anda.',
                isTimeout: true,
              );
            },
          );

      if (!mounted || _isCancelled) return;

      await Navigator.of(context).pushReplacement(
        SigapRoutes.slideRight(
          DamageResultScreen(
            photoData: widget.photoData.copyWith(qualityReport: qualityReport),
            result: result,
            classifier: _classifier,
            repository: _repository,
            deviceService: _deviceService,
          ),
        ),
      );
    } on DamageClassifierException catch (e) {
      if (!mounted || e.isCancelled || _isCancelled) return;
      _pulseController.stop();
      setState(() {
        _isFailed = true;
        _isOfflineError = e.isOfflineError;
        _errorTitle = e.isOfflineError
            ? 'Koneksi Internet Diperlukan'
            : e.isTimeout
                ? 'Waktu Analisis Habis'
                : 'Analisis Gagal Diproses';
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted || _isCancelled) return;
      _pulseController.stop();
      setState(() {
        _isFailed = true;
        _isOfflineError = false;
        _errorTitle = 'Terjadi Kendala Analisis';
        _errorMessage =
            'Foto tidak dapat dianalisis saat ini. Silakan coba lagi atau pilih foto bangunan yang lain.';
      });
    }
  }

  void _cancelAnalysis() {
    HapticFeedback.selectionClick();
    _isCancelled = true;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _isCancelled = true;
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundCream,
        appBar: VisionTopBar(
          title: 'Menganalisis Bangunan',
          subtitle: _classifier.isSimulation
              ? 'SIGAP-Vision • Simulasi Pengujian'
              : 'SIGAP-Vision',
          onBack: _cancelAnalysis,
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: _isFailed ? _buildErrorView() : _buildProgressView(),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressView() {
    final file = File(widget.photoData.imagePath);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_classifier.isSimulation) ...[
          const SimulationModeBanner(compact: true),
          const SizedBox(height: 16),
        ],

        // Thumbnail Foto dengan Animasi Pemindaian Ringkas
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.03).animate(
                  CurvedAnimation(
                    parent: _pulseController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 150,
                        height: 150,
                        child: file.existsSync()
                            ? Image.file(file, fit: BoxFit.cover)
                            : Container(
                                color: AppColors.mintAccent,
                                child: const Icon(
                                  Icons.image_outlined,
                                  size: 46,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                      ),
                    ),
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.safeGreen,
                          width: 2.5,
                        ),
                        color: AppColors.primaryDark.withValues(alpha: 0.16),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _currentStep.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDarkest,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentStep.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSlate,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _currentStep.progress,
                  minHeight: 8,
                  backgroundColor: AppColors.mintAccent,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tahap ${_currentStep.index + 1} dari ${DamageAnalysisStep.values.length}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Daftar Tahapan Analisis
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: DamageAnalysisStep.values.map((step) {
              final isDone = step.index < _currentStep.index;
              final isCurrent = step.index == _currentStep.index;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    if (isDone)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.safeGreen,
                        size: 20,
                      )
                    else if (isCurrent)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: AppColors.primaryDark,
                        ),
                      )
                    else
                      Icon(
                        Icons.radio_button_unchecked_rounded,
                        color: AppColors.borderLight,
                        size: 20,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: isCurrent || isDone
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: isCurrent || isDone
                              ? AppColors.primaryDarkest
                              : AppColors.textSlate,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 18),

        // Tombol Batalkan Analisis
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _cancelAnalysis,
            icon: const Icon(Icons.close_rounded, size: 20),
            label: Text(
              'Batalkan Analisis',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.borderLight, width: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isOfflineError
              ? const Color(0xFFFDE68A)
              : const Color(0xFFFECACA),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _isOfflineError
                  ? const Color(0xFFFFFBEB)
                  : const Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isOfflineError
                  ? Icons.wifi_off_rounded
                  : Icons.error_outline_rounded,
              color: _isOfflineError
                  ? const Color(0xFFD97706)
                  : AppColors.alertAwas,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _errorTitle ?? 'Analisis Gagal',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDarkest,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ??
                'Proses analisis tidak dapat diselesaikan. Silakan coba lagi.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: AppColors.textSlate,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _runAnalysis,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'Coba Analisis Lagi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(
                'Kembali ke Pratinjau Foto',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
