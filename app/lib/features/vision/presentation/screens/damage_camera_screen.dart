import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap/core/navigation/sigap_transitions.dart';
import 'package:sigap/core/theme/app_colors.dart';
import '../../data/damage_report_repository.dart';
import '../../data/mock_damage_classifier.dart';
import '../../data/vision_device_service.dart';
import '../../domain/damage_classifier.dart';
import '../../domain/models/damage_models.dart';
import 'damage_preview_screen.dart';

/// Halaman Kamera Pemindaian SIGAP-Vision (`DamageCameraScreen`).
///
/// Menyediakan:
/// - Pratinjau kamera langsung dengan bingkai panduan pemotretan kerusakan bangunan.
/// - Kontrol flash (jika didukung perangkat), ganti kamera, dan tombol kembali.
/// - Pemilihan foto dari galeri atau kamera sistem sebagai alternatif.
/// - Penanganan lengkap status izin kamera & galeri, kamera tidak tersedia,
///   pembatalan pengguna, serta kegagalan pembacaan berkas.
class DamageCameraScreen extends StatefulWidget {
  final DamageClassifier? classifier;
  final DamageReportRepository? repository;
  final VisionDeviceService? deviceService;

  /// Hook opsional untuk menonaktifkan inisialisasi plugin kamera native saat widget test.
  final bool disableNativeCameraForTest;

  const DamageCameraScreen({
    super.key,
    this.classifier,
    this.repository,
    this.deviceService,
    this.disableNativeCameraForTest = false,
  });

  @override
  State<DamageCameraScreen> createState() => _DamageCameraScreenState();
}

class _DamageCameraScreenState extends State<DamageCameraScreen>
    with WidgetsBindingObserver {
  late final DamageClassifier _classifier;
  late final DamageReportRepository _repository;
  late final VisionDeviceService _deviceService;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = const [];
  int _selectedCameraIndex = 0;

  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isPickingGallery = false;
  bool _flashSupported = false;
  FlashMode _flashMode = FlashMode.off;

  VisionPermissionState _cameraPermission = VisionPermissionState.denied;
  VisionPermissionState _galleryPermission = VisionPermissionState.denied;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _classifier = widget.classifier ?? const MockDamageClassifier();
    _repository = widget.repository ?? DamageReportRepository.instance;
    _deviceService = widget.deviceService ?? DefaultVisionDeviceService.instance;
    _bootstrapCameraAndPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCameraController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (state == AppLifecycleState.inactive) {
      if (controller != null && controller.value.isInitialized) {
        _disposeCameraController();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_cameraController == null && !_isInitializing) {
        _bootstrapCameraAndPermissions();
      }
    }
  }

  Future<void> _disposeCameraController() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      try {
        await controller.dispose();
      } catch (_) {
        // Abaikan error dispose kamera
      }
    }
  }

  Future<void> _bootstrapCameraAndPermissions() async {
    if (!mounted) return;
    setState(() {
      _isInitializing = true;
      _cameraError = null;
    });

    final galleryPerm = await _deviceService.checkGalleryPermission();
    var cameraPerm = await _deviceService.checkCameraPermission();

    if (cameraPerm == VisionPermissionState.denied) {
      cameraPerm = await _deviceService.requestCameraPermission();
    }

    if (!mounted) return;
    setState(() {
      _cameraPermission = cameraPerm;
      _galleryPermission = galleryPerm;
    });

    if (cameraPerm == VisionPermissionState.denied ||
        cameraPerm == VisionPermissionState.permanentlyDenied ||
        cameraPerm == VisionPermissionState.restricted) {
      setState(() {
        _isInitializing = false;
      });
      return;
    }

    if (widget.disableNativeCameraForTest ||
        kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      setState(() {
        _isInitializing = false;
        _cameraError =
            'Pratinjau kamera langsung belum tersedia pada platform ini. Gunakan tombol Kamera Sistem atau Pilih dari Galeri.';
      });
      return;
    }

    await _initializeLiveCamera();
  }

  Future<void> _initializeLiveCamera({int? cameraIndex}) async {
    try {
      await _disposeCameraController();
      final cameras = await availableCameras();
      if (!mounted) return;

      if (cameras.isEmpty) {
        setState(() {
          _cameras = const [];
          _isInitializing = false;
          _cameraError =
              'Kamera tidak terdeteksi pada perangkat ini. Anda tetap dapat memilih foto bangunan dari galeri.';
        });
        return;
      }

      int targetIndex = cameraIndex ??
          cameras.indexWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
          );
      if (targetIndex < 0 || targetIndex >= cameras.length) {
        targetIndex = 0;
      }

      final controller = CameraController(
        cameras[targetIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      bool flashSupported = true;
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {
        flashSupported = false;
      }

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameras = cameras;
        _selectedCameraIndex = targetIndex;
        _cameraController = controller;
        _flashSupported = flashSupported;
        _flashMode = FlashMode.off;
        _isInitializing = false;
        _cameraError = null;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      final isPermDenied = e.code.toLowerCase().contains('access') ||
          e.code.toLowerCase().contains('permission');
      setState(() {
        _isInitializing = false;
        if (isPermDenied) {
          _cameraPermission = VisionPermissionState.denied;
        }
        _cameraError = isPermDenied
            ? 'Izin kamera belum diberikan. Aktifkan izin kamera untuk memindai bangunan.'
            : 'Kamera sedang tidak tersedia (${e.description ?? e.code}). Gunakan galeri atau coba lagi.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _cameraError =
            'Kamera perangkat gagal dibuka. Coba muat ulang atau pilih foto dari galeri.';
      });
    }
  }

  Future<void> _requestCameraPermissionAgain() async {
    HapticFeedback.selectionClick();
    final status = await _deviceService.requestCameraPermission();
    if (!mounted) return;
    setState(() => _cameraPermission = status);
    if (status.isGranted || status == VisionPermissionState.unsupported) {
      await _bootstrapCameraAndPermissions();
    }
  }

  Future<void> _requestGalleryPermission() async {
    HapticFeedback.selectionClick();
    final status = await _deviceService.requestGalleryPermission();
    if (!mounted) return;
    setState(() => _galleryPermission = status);
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || !_flashSupported) {
      _showInfoSnackBar('Flash tidak didukung pada kamera yang sedang aktif.');
      return;
    }

    HapticFeedback.selectionClick();
    final nextMode = switch (_flashMode) {
      FlashMode.off => FlashMode.torch,
      FlashMode.torch => FlashMode.auto,
      _ => FlashMode.off,
    };

    try {
      await controller.setFlashMode(nextMode);
      if (!mounted) return;
      setState(() => _flashMode = nextMode);
    } catch (_) {
      if (!mounted) return;
      setState(() => _flashSupported = false);
      _showInfoSnackBar('Perangkat ini tidak mendukung pengaturan flash.');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isInitializing) return;
    HapticFeedback.selectionClick();
    setState(() => _isInitializing = true);
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initializeLiveCamera(cameraIndex: nextIndex);
  }

  Future<void> _capturePhoto() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isCapturing = true);

    try {
      final captured = await controller.takePicture();
      final file = File(captured.path);
      if (!await file.exists()) {
        _showErrorSnackBar(
          'Foto berhasil dijepret tetapi berkas gagal dibaca. Silakan ulangi pemotretan.',
        );
        return;
      }

      if (!mounted) return;
      await _navigateToPreview(
        CapturedPhotoData(
          imagePath: captured.path,
          sourceLabel: 'Kamera SIGAP-Vision',
          capturedAt: DateTime.now(),
        ),
      );
    } catch (_) {
      _showErrorSnackBar(
        'Gagal mengambil gambar dari kamera. Silakan coba lagi atau gunakan galeri.',
      );
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _captureWithSystemCamera() async {
    if (_isCapturing) return;
    HapticFeedback.selectionClick();
    setState(() => _isCapturing = true);

    try {
      final result = await _deviceService.captureWithSystemCamera();
      if (!mounted) return;

      if (result.cancelled) {
        _showInfoSnackBar('Pengambilan foto dibatalkan.');
        return;
      }

      if (!result.hasPhoto) {
        _showErrorSnackBar(
          result.errorMessage ?? 'Gagal mengambil foto melalui kamera sistem.',
        );
        return;
      }

      final file = File(result.imagePath!);
      if (!await file.exists()) {
        _showErrorSnackBar(
          'Berkas foto dari kamera gagal dibaca. Silakan coba lagi.',
        );
        return;
      }

      await _navigateToPreview(
        CapturedPhotoData(
          imagePath: result.imagePath!,
          sourceLabel: 'Kamera Perangkat',
          capturedAt: DateTime.now(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isPickingGallery) return;
    HapticFeedback.selectionClick();
    setState(() => _isPickingGallery = true);

    try {
      final result = await _deviceService.pickFromGallery();
      if (!mounted) return;

      if (result.cancelled) {
        _showInfoSnackBar('Pemilihan gambar dari galeri dibatalkan.');
        return;
      }

      if (!result.hasPhoto) {
        _showErrorSnackBar(
          result.errorMessage ?? 'Foto gagal dipilih dari galeri.',
        );
        return;
      }

      final file = File(result.imagePath!);
      if (!await file.exists()) {
        _showErrorSnackBar(
          'Berkas foto yang dipilih tidak dapat dibaca. Pilih gambar lain.',
        );
        return;
      }

      await _navigateToPreview(
        CapturedPhotoData(
          imagePath: result.imagePath!,
          sourceLabel: 'Galeri Perangkat',
          capturedAt: DateTime.now(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingGallery = false);
      }
    }
  }

  Future<void> _navigateToPreview(CapturedPhotoData photoData) async {
    await Navigator.of(context).push(
      SigapRoutes.slideRight(
        DamagePreviewScreen(
          photoData: photoData,
          classifier: _classifier,
          repository: _repository,
          deviceService: _deviceService,
        ),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.alertAwas,
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.torch:
        return Icons.flash_on_rounded;
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      case FlashMode.off:
      case FlashMode.always:
        return Icons.flash_off_rounded;
    }
  }

  String get _flashLabel {
    switch (_flashMode) {
      case FlashMode.torch:
        return 'Flash Aktif';
      case FlashMode.auto:
        return 'Flash Otomatis';
      case FlashMode.off:
      case FlashMode.always:
        return 'Flash Mati';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLiveCameraReady = _cameraController != null &&
        _cameraController!.value.isInitialized &&
        _cameraError == null;

    final isCameraBlockedByPermission =
        _cameraPermission == VisionPermissionState.denied ||
            _cameraPermission == VisionPermissionState.permanentlyDenied ||
            _cameraPermission == VisionPermissionState.restricted;

    return Scaffold(
      backgroundColor: const Color(0xFF0C1712),
      body: SafeArea(
        child: Column(
          children: [
            // Bar Atas: Tombol Kembali, Judul, dan Flash
            _buildTopOverlayBar(isLiveCameraReady: isLiveCameraReady),

            // Area Utama: Live Preview / Status Izin / Fallback Kamera
            Expanded(
              child: _isInitializing
                  ? _buildLoadingView()
                  : isCameraBlockedByPermission
                      ? _buildPermissionRequiredView()
                      : isLiveCameraReady
                          ? _buildLiveCameraView()
                          : _buildCameraUnavailableView(),
            ),

            // Bar Kontrol Bawah: Galeri, Tombol Jepret, dan Ganti Kamera
            _buildBottomControlBar(isLiveCameraReady: isLiveCameraReady),
          ],
        ),
      ),
    );
  }

  Widget _buildTopOverlayBar({required bool isLiveCameraReady}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: const Color(0xFF0C1712),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Kembali',
            child: IconButton(
              tooltip: 'Kembali',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kamera Pemindaian',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'SIGAP-Vision • Offline Siaga',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMint,
                  ),
                ),
              ],
            ),
          ),
          if (isLiveCameraReady && _flashSupported)
            Semantics(
              button: true,
              label: _flashLabel,
              child: TextButton.icon(
                onPressed: _toggleFlash,
                icon: Icon(_flashIcon, color: Colors.white, size: 20),
                label: Text(
                  _flashMode == FlashMode.torch
                      ? 'Aktif'
                      : _flashMode == FlashMode.auto
                          ? 'Auto'
                          : 'Flash',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.safeGreen),
          const SizedBox(height: 14),
          Text(
            'Menyiapkan kamera perangkat...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCameraView() {
    final controller = _cameraController!;
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: CameraPreview(controller),
        ),
        // Panduan Area Pemotretan Bangunan
        IgnorePointer(
          child: CustomPaint(
            painter: _ScanGuideOverlayPainter(),
          ),
        ),
        // Petunjuk Pemotretan di Bagian Atas
        Positioned(
          top: 14,
          left: 18,
          right: 18,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.center_focus_strong_rounded,
                  color: AppColors.safeGreen,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Arahkan bingkai ke bagian bangunan yang mengalami kerusakan (dinding, kolom, atau balok) dengan jelas.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Petunjuk Jarak Aman di Bagian Bawah Viewfinder
        Positioned(
          bottom: 14,
          left: 24,
          right: 24,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Pastikan pencahayaan cukup & tetap berada di jarak aman',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMint,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionRequiredView() {
    final isPermanent =
        _cameraPermission == VisionPermissionState.permanentlyDenied;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.alertWaspada.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.no_photography_outlined,
              color: AppColors.alertWaspada,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Izin Kamera Diperlukan',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPermanent
                ? 'Izin kamera ditolak permanen pada perangkat Anda. Buka Pengaturan aplikasi untuk mengaktifkan akses kamera, atau pilih foto bangunan dari galeri.'
                : 'SIGAP-Vision membutuhkan izin kamera agar Anda dapat memotret kondisi bangunan secara langsung. Foto hanya diproses secara lokal.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: AppColors.textMint,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),

          // Status Izin Kamera & Galeri
          _buildPermissionStatusCard(),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: isPermanent
                  ? () => _deviceService.openDeviceAppSettings()
                  : _requestCameraPermissionAgain,
              icon: Icon(
                isPermanent
                    ? Icons.settings_outlined
                    : Icons.camera_alt_rounded,
              ),
              label: Text(
                isPermanent ? 'Buka Pengaturan Aplikasi' : 'Izinkan Akses Kamera',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.safeGreen,
                foregroundColor: Colors.white,
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
              onPressed: _isPickingGallery ? null : _pickFromGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                'Pilih Foto dari Galeri',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
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

  Widget _buildCameraUnavailableView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Area Bingkai Panduan Simbolik agar pengguna tetap memahami panduan pemotretan
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF15251D),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.camera_enhance_outlined,
                  color: AppColors.textMint,
                  size: 46,
                ),
                const SizedBox(height: 12),
                Text(
                  'Pratinjau Kamera Tidak Tersedia',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _cameraError ??
                      'Kamera langsung tidak dapat digunakan di perangkat ini. Anda tetap bisa mengambil foto melalui kamera sistem atau memilih foto dari galeri.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textMint,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildPermissionStatusCard(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isCapturing ? null : _captureWithSystemCamera,
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(
                _isCapturing
                    ? 'Membuka Kamera...'
                    : 'Ambil Foto (Kamera Sistem)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.safeGreen,
                foregroundColor: Colors.white,
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
              onPressed: _isPickingGallery ? null : _pickFromGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                'Pilih Foto dari Galeri',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _bootstrapCameraAndPermissions,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textMint),
            label: Text(
              'Coba Muat Ulang Kamera',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textMint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Izin Perangkat',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          _buildPermissionRow(
            icon: Icons.camera_alt_outlined,
            label: 'Izin Kamera',
            state: _cameraPermission,
            onAction: _cameraPermission.isGranted
                ? null
                : _requestCameraPermissionAgain,
          ),
          const SizedBox(height: 6),
          _buildPermissionRow(
            icon: Icons.photo_library_outlined,
            label: 'Izin Galeri',
            state: _galleryPermission,
            onAction: _galleryPermission.isGranted ||
                    _galleryPermission == VisionPermissionState.unsupported
                ? null
                : _requestGalleryPermission,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow({
    required IconData icon,
    required String label,
    required VisionPermissionState state,
    VoidCallback? onAction,
  }) {
    final color = state.isGranted || state == VisionPermissionState.unsupported
        ? AppColors.safeGreen
        : AppColors.alertWaspada;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: ${state.label}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMint,
            ),
          ),
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Izinkan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.safeGreen,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomControlBar({required bool isLiveCameraReady}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      color: const Color(0xFF0C1712),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol Galeri
          Semantics(
            button: true,
            label: 'Pilih foto dari galeri',
            child: InkWell(
              onTap: _isPickingGallery ? null : _pickFromGallery,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 78,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Galeri',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tombol Shutter Besar (Ambil Foto)
          Semantics(
            button: true,
            label: 'Ambil foto kerusakan bangunan',
            child: GestureDetector(
              onTap: _isCapturing
                  ? null
                  : (isLiveCameraReady
                      ? _capturePhoto
                      : _captureWithSystemCamera),
              child: Container(
                width: 74,
                height: 74,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3.5,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isCapturing
                        ? AppColors.textMuted
                        : AppColors.safeGreen,
                  ),
                  child: _isCapturing
                      ? const Padding(
                          padding: EdgeInsets.all(18),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                ),
              ),
            ),
          ),

          // Tombol Ganti Kamera / Petunjuk
          Semantics(
            button: true,
            label: _cameras.length > 1
                ? 'Ganti kamera depan atau belakang'
                : 'Info panduan pemotretan',
            child: InkWell(
              onTap: _cameras.length > 1 && isLiveCameraReady
                  ? _switchCamera
                  : () {
                      _showInfoSnackBar(
                        'Potret retakan atau bagian bangunan yang rusak dari jarak aman dengan cahaya cukup.',
                      );
                    },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 78,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _cameras.length > 1 && isLiveCameraReady
                          ? Icons.cameraswitch_outlined
                          : Icons.help_outline_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _cameras.length > 1 && isLiveCameraReady
                          ? 'Putar'
                          : 'Panduan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter bingkai panduan pengambilan foto kerusakan bangunan.
class _ScanGuideOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final frameWidth = size.width * 0.80;
    final frameHeight = size.height * 0.52;
    final left = (size.width - frameWidth) / 2;
    final top = (size.height - frameHeight) / 2;
    final rect = Rect.fromLTWH(left, top, frameWidth, frameHeight);

    // Mask gelap semi-transparan di luar area panduan
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.42);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(18)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlayPaint);

    // Garis panduan tipis
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      borderPaint,
    );

    // Sudut penanda warna hijau SIGAP
    final cornerPaint = Paint()
      ..color = AppColors.safeGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLen = 28.0;

    // Kiri atas
    canvas.drawLine(
      Offset(rect.left, rect.top + cornerLen),
      Offset(rect.left, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLen, rect.top),
      cornerPaint,
    );

    // Kanan atas
    canvas.drawLine(
      Offset(rect.right - cornerLen, rect.top),
      Offset(rect.right, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLen),
      cornerPaint,
    );

    // Kiri bawah
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerLen),
      Offset(rect.left, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLen, rect.bottom),
      cornerPaint,
    );

    // Kanan bawah
    canvas.drawLine(
      Offset(rect.right - cornerLen, rect.bottom),
      Offset(rect.right, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - cornerLen),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
