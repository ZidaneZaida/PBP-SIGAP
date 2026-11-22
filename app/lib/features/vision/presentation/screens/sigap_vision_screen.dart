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
import '../widgets/damage_widgets.dart';
import 'damage_camera_screen.dart';
import 'damage_history_screen.dart';
import 'damage_preview_screen.dart';

/// Halaman utama (hub) fitur SIGAP-Vision.
///
/// Menjadi penghubung alur:
/// Beranda -> SIGAP-Vision -> Kamera/Galeri -> Pratinjau -> Analisis -> Hasil -> Riwayat/Beranda.
class SigapVisionScreen extends StatefulWidget {
  final DamageClassifier? classifier;
  final DamageReportRepository? repository;
  final VisionDeviceService? deviceService;

  const SigapVisionScreen({
    super.key,
    this.classifier,
    this.repository,
    this.deviceService,
  });

  @override
  State<SigapVisionScreen> createState() => _SigapVisionScreenState();
}

class _SigapVisionScreenState extends State<SigapVisionScreen> {
  late final DamageClassifier _classifier;
  late final DamageReportRepository _repository;
  late final VisionDeviceService _deviceService;
  bool _isPickingGallery = false;

  @override
  void initState() {
    super.initState();
    _classifier = widget.classifier ?? const MockDamageClassifier();
    _repository = widget.repository ?? DamageReportRepository.instance;
    _deviceService = widget.deviceService ?? DefaultVisionDeviceService.instance;
    _repository.loadReports().catchError((_) => const <DamageScanReport>[]);
  }

  void _openCamera() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      SigapRoutes.slideRight(
        DamageCameraScreen(
          classifier: _classifier,
          repository: _repository,
          deviceService: _deviceService,
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    if (_isPickingGallery) return;
    HapticFeedback.selectionClick();
    setState(() => _isPickingGallery = true);

    try {
      final result = await _deviceService.pickFromGallery();
      if (!mounted) return;

      if (result.cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primaryDark,
            content: Text(
              'Pemilihan foto dari galeri dibatalkan.',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );
        return;
      }

      if (!result.hasPhoto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.alertAwas,
            content: Text(
              result.errorMessage ??
                  'Foto gagal dipilih dari galeri. Silakan coba lagi.',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        );
        return;
      }

      final photoData = CapturedPhotoData(
        imagePath: result.imagePath!,
        sourceLabel: 'Galeri Perangkat',
        capturedAt: DateTime.now(),
      );

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
    } finally {
      if (mounted) {
        setState(() => _isPickingGallery = false);
      }
    }
  }

  void _openHistory() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      SigapRoutes.slideRight(
        DamageHistoryScreen(
          classifier: _classifier,
          repository: _repository,
          deviceService: _deviceService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: VisionTopBar(
        title: 'SIGAP-Vision',
        subtitle: 'Pindai Indikasi Kerusakan Bangunan',
        actions: [
          IconButton(
            tooltip: 'Riwayat Pemindaian',
            onPressed: _openHistory,
            icon: const Icon(
              Icons.history_rounded,
              color: AppColors.primaryDark,
            ),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Card SIGAP-Vision
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.mintSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFC2DFCD),
                    width: 1.4,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.document_scanner_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pemeriksaan Awal Pasca Gempa',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDarkest,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _buildMiniPill(
                                    icon: Icons.wifi_off_rounded,
                                    label: _classifier.requiresInternet
                                        ? 'Butuh Internet'
                                        : 'Dapat Digunakan Offline',
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ambil foto bagian bangunan yang mengalami retakan atau kerusakan untuk mendapatkan indikasi awal tingkat kerusakan (Ringan, Sedang, atau Berat) beserta saran tindakan keselamatan.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: AppColors.textDark,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tombol Utama: Buka Kamera Pemindaian
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _openCamera,
                        icon: const Icon(Icons.camera_alt_rounded, size: 22),
                        label: Text(
                          'Buka Kamera Pemindaian',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tombol Sekunder: Pilih dari Galeri
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isPickingGallery ? null : _pickFromGallery,
                        icon: _isPickingGallery
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColors.primaryDark,
                                ),
                              )
                            : const Icon(
                                Icons.photo_library_outlined,
                                size: 20,
                              ),
                        label: Text(
                          _isPickingGallery
                              ? 'Membuka Galeri...'
                              : 'Pilih Foto dari Galeri',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryDark,
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_classifier.isSimulation) ...[
                const SizedBox(height: 14),
                const SimulationModeBanner(),
              ],

              const SizedBox(height: 16),

              // Kartu Ringkasan Riwayat Pemindaian
              ValueListenableBuilder<List<DamageScanReport>>(
                valueListenable: _repository.reportsNotifier,
                builder: (context, reports, _) {
                  final pendingCount = reports
                      .where((r) => r.syncStatus == DamageSyncStatus.pendingSync)
                      .length;
                  return InkWell(
                    onTap: _openHistory,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.mintAccent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.folder_copy_outlined,
                              color: AppColors.primaryDark,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Riwayat Pemindaian (${reports.length})',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDarkest,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  reports.isEmpty
                                      ? 'Belum ada laporan tersimpan di perangkat ini.'
                                      : pendingCount > 0
                                          ? '$pendingCount laporan tersimpan di antrean lokal.'
                                          : 'Lihat detail atau kelola laporan tersimpan.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    color: AppColors.textSlate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Panduan Pengambilan Foto Terbaik
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
                  children: [
                    Text(
                      'Panduan Pengambilan Foto yang Baik',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDarkest,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildGuideRow(
                      icon: Icons.health_and_safety_outlined,
                      title: 'Utamakan Keselamatan',
                      desc:
                          'Jangan mendekati bangunan yang miring, runtuh sebagian, atau berisiko ambruk.',
                    ),
                    const SizedBox(height: 10),
                    _buildGuideRow(
                      icon: Icons.wb_sunny_outlined,
                      title: 'Pencahayaan Cukup & Stabil',
                      desc:
                          'Pastikan area retakan terlihat jelas, tidak gelap, dan ponsel dipegang stabil.',
                    ),
                    const SizedBox(height: 10),
                    _buildGuideRow(
                      icon: Icons.crop_free_rounded,
                      title: 'Fokus ke Bagian Bangunan',
                      desc:
                          'Arahkan kamera ke dinding, kolom, balok, atau plafon yang mengalami kerusakan.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Privasi & Keamanan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.mintAccent.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.primaryDark,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Privasi Terjaga: Foto dan lokasi opsional hanya disimpan secara lokal di perangkat Anda dan tidak dikirim ke server tanpa persetujuan Anda.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.mintAccent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryDark),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDarkest,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: AppColors.textSlate,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
