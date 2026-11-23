import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap/core/navigation/sigap_transitions.dart';
import 'package:sigap/core/theme/app_colors.dart';
import 'package:sigap/features/map/presentation/screens/peta_screen.dart';
import '../../data/damage_report_repository.dart';
import '../../data/mock_damage_classifier.dart';
import '../../data/vision_device_service.dart';
import '../../domain/damage_classifier.dart';
import '../../domain/models/damage_models.dart';
import '../widgets/damage_widgets.dart';
import 'damage_camera_screen.dart';
import 'damage_history_screen.dart';

/// Halaman Hasil Analisis SIGAP-Vision (`DamageResultScreen`).
///
/// Menampilkan:
/// - Gerbang disclaimer AI wajib minimal 3 detik (non-dismissible) untuk hasil
///   analisis baru sebelum kartu hasil asesmen ditampilkan (Revisi Zidan G-06).
/// A. Informasi Foto (foto bangunan + opsional overlay area, waktu pemeriksaan, lokasi).
/// B. Hasil Deteksi (kategori AMAN / WASPADA / BAHAYA KRITIS, confidence score bila ada,
///    indikator visual tingkat kerusakan, penjelasan singkat).
/// C. Rekomendasi Tindakan + peringatan khusus untuk kerusakan Sedang/Berat.
/// D. Disclaimer wajib dan Tombol Aksi (Simpan Laporan, Cari Titik Kumpul / Shelter
///    Terdekat, Pindai Ulang, Kembali ke Beranda).
class DamageResultScreen extends StatefulWidget {
  static const int mandatoryDisclaimerSeconds = 3;
  static const String mandatoryAiDisclaimerText =
      'Hasil analisis ini dihasilkan oleh model kecerdasan buatan (AI) dan bukan merupakan pengganti penilaian struktural oleh ahli teknik sipil atau insinyur bangunan bersertifikat. Gunakan hasil ini hanya sebagai panduan tindakan darurat awal. SIGAP tidak bertanggung jawab atas keputusan yang diambil berdasarkan hasil analisis ini.';

  final CapturedPhotoData? photoData;
  final DamageClassificationResult? result;
  final DamageScanReport? existingReport;
  final bool isFromHistory;
  final DamageClassifier? classifier;
  final DamageReportRepository? repository;
  final VisionDeviceService? deviceService;

  const DamageResultScreen({
    super.key,
    this.photoData,
    this.result,
    this.existingReport,
    this.isFromHistory = false,
    this.classifier,
    this.repository,
    this.deviceService,
  }) : assert(
          existingReport != null || (photoData != null && result != null),
          'Harus menyediakan existingReport atau pasangan photoData & result.',
        );

  @override
  State<DamageResultScreen> createState() => _DamageResultScreenState();
}

class _DamageResultScreenState extends State<DamageResultScreen> {
  late final DamageClassifier _classifier;
  late final DamageReportRepository _repository;
  late final VisionDeviceService _deviceService;

  bool _showRegionOverlay = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  DamageScanReport? _savedReport;

  // Gerbang Disclaimer AI wajib minimal 3 detik (khusus hasil baru)
  late bool _isDisclaimerGateActive;
  late int _disclaimerSecondsRemaining;
  Timer? _disclaimerTimer;

  String get _imagePath =>
      _savedReport?.imagePath ??
      widget.existingReport?.imagePath ??
      widget.photoData!.imagePath;

  DateTime get _inspectedAt =>
      _savedReport?.createdAt ??
      widget.existingReport?.createdAt ??
      widget.result!.analyzedAt;

  VisionLocationData? get _location =>
      _savedReport?.location ??
      widget.existingReport?.location ??
      widget.photoData?.location;

  DamageClassificationResult get _result =>
      _savedReport?.result ?? widget.existingReport?.result ?? widget.result!;

  @override
  void initState() {
    super.initState();
    _classifier = widget.classifier ?? const MockDamageClassifier();
    _repository = widget.repository ?? DamageReportRepository.instance;
    _deviceService = widget.deviceService ?? DefaultVisionDeviceService.instance;
    _savedReport = widget.existingReport;

    _isDisclaimerGateActive = !widget.isFromHistory;
    _disclaimerSecondsRemaining =
        _isDisclaimerGateActive ? DamageResultScreen.mandatoryDisclaimerSeconds : 0;

    if (_isDisclaimerGateActive) {
      _startDisclaimerCountdown();
    }
  }

  void _startDisclaimerCountdown() {
    _disclaimerTimer?.cancel();
    _disclaimerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_disclaimerSecondsRemaining <= 1) {
        timer.cancel();
        _disclaimerTimer = null;
        setState(() {
          _disclaimerSecondsRemaining = 0;
          _isDisclaimerGateActive = false;
        });
      } else {
        setState(() {
          _disclaimerSecondsRemaining -= 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _disclaimerTimer?.cancel();
    _disclaimerTimer = null;
    super.dispose();
  }

  Future<void> _saveReport() async {
    if (_isSaving || _savedReport != null) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final report = DamageScanReport(
        id: 'vision_${DateTime.now().millisecondsSinceEpoch}',
        imagePath: _imagePath,
        createdAt: _inspectedAt,
        location: _location,
        result: _result,
        syncStatus: DamageSyncStatus.pendingSync,
      );

      final persisted = await _repository.saveReport(report);
      if (!mounted) return;

      setState(() {
        _savedReport = persisted;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primaryDark,
          content: Text(
            'Laporan berhasil disimpan secara lokal di perangkat Anda.',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          action: SnackBarAction(
            label: 'RIWAYAT',
            textColor: AppColors.textMint,
            onPressed: _openHistory,
          ),
        ),
      );
    } on DamageStorageException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showErrorSnackBar(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showErrorSnackBar(
        'Laporan gagal disimpan ke perangkat. Silakan coba lagi.',
      );
    }
  }

  Future<void> _confirmAndDeleteReport() async {
    final target = _savedReport;
    if (target == null || _isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Laporan?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDarkest,
          ),
        ),
        content: Text(
          'Laporan pemeriksaan beserta salinan fotonya di riwayat lokal akan dihapus secara permanen dari perangkat ini.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: AppColors.textSlate,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppColors.textSlate,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertAwas,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Ya, Hapus',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await _repository.deleteReport(target.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primaryDark,
          content: Text(
            'Laporan berhasil dihapus dari riwayat lokal.',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } on DamageStorageException catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      _showErrorSnackBar(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      _showErrorSnackBar('Gagal menghapus laporan. Silakan coba lagi.');
    }
  }

  void _scanAgain() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushReplacement(
      SigapRoutes.slideRight(
        DamageCameraScreen(
          classifier: _classifier,
          repository: _repository,
          deviceService: _deviceService,
        ),
      ),
    );
  }

  void _backToHome() {
    HapticFeedback.selectionClick();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openNearestShelterMap() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      SigapRoutes.slideRight(const PetaScreen()),
    );
  }

  void _openHistory() {
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

  void _showErrorSnackBar(String message) {
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

  @override
  Widget build(BuildContext context) {
    final category = _result.category;
    final hasRegions = _result.detectedRegions.isNotEmpty;

    return PopScope(
      canPop: !_isDisclaimerGateActive,
      child: Scaffold(
        backgroundColor: AppColors.backgroundCream,
        appBar: VisionTopBar(
          title: _isDisclaimerGateActive
              ? 'Pemberitahuan Penting'
              : (widget.isFromHistory ? 'Detail Laporan' : 'Hasil Analisis'),
          subtitle: 'SIGAP-Vision • Indikasi Awal Kerusakan',
          onBack: _isDisclaimerGateActive ? () {} : null,
          actions: [
            if (!_isDisclaimerGateActive &&
                widget.isFromHistory &&
                _savedReport != null)
              IconButton(
                tooltip: 'Hapus laporan',
                onPressed: _isDeleting ? null : _confirmAndDeleteReport,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.alertAwas,
                ),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: _isDisclaimerGateActive
                ? _buildMandatoryDisclaimerGate()
                : _buildResultScrollView(
                    category: category,
                    hasRegions: hasRegions,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMandatoryDisclaimerGate() {
    final total = DamageResultScreen.mandatoryDisclaimerSeconds;
    final elapsed = (total - _disclaimerSecondsRemaining).clamp(0, total);
    final progress = total > 0 ? elapsed / total : 1.0;

    return Center(
      key: const ValueKey('mandatory_disclaimer_gate'),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFDE68A),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Icon(
                          Icons.gpp_maybe_rounded,
                          color: Color(0xFFD97706),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Disclaimer AI Wajib',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryDarkest,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Harap baca sebelum melihat hasil asesmen',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSlate,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardCream.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Text(
                      DamageResultScreen.mandatoryAiDisclaimerText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDarkest,
                        height: 1.52,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Menampilkan hasil dalam $_disclaimerSecondsRemaining detik...',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mintAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_disclaimerSecondsRemaining}s',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppColors.mintAccent,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_result.isSimulation) ...[
              const SizedBox(height: 14),
              const SimulationModeBanner(compact: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultScrollView({
    required DamageCategory category,
    required bool hasRegions,
  }) {
    return SingleChildScrollView(
      key: const ValueKey('damage_result_content'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              // Label Wajib Jika Hasil Berasal dari Simulasi Pengujian
              if (_result.isSimulation) ...[
                const SimulationModeBanner(),
                const SizedBox(height: 14),
              ],

              // ========================================================
              // A. INFORMASI FOTO
              // ========================================================
              _buildSectionTitle('A. Informasi Foto'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DamagePhotoFrame(
                      imagePath: _imagePath,
                      regions: _result.detectedRegions,
                      showRegions: _showRegionOverlay,
                      regionColor: category.accentColor,
                      aspectRatio: 4 / 3,
                      onTap: () => showFullScreenPhotoDialog(
                        context,
                        _imagePath,
                      ),
                    ),
                    if (hasRegions) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _result.isSimulation
                                  ? 'Visualisasi area indikasi (simulasi pengujian)'
                                  : 'Visualisasi area indikasi kerusakan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSlate,
                              ),
                            ),
                          ),
                          Switch(
                            value: _showRegionOverlay,
                            activeThumbColor: Colors.white,
                            activeTrackColor: AppColors.primaryDark,
                            onChanged: (v) =>
                                setState(() => _showRegionOverlay = v),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 18, color: AppColors.borderLight),
                    _buildInfoRow(
                      icon: Icons.schedule_rounded,
                      label: 'Waktu Pemeriksaan',
                      value: formatIndonesianDateTime(_inspectedAt),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Lokasi',
                      value: _location?.displayLabel ??
                          'Lokasi tidak disertakan (opsional)',
                    ),
                    if (_savedReport != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        icon: _savedReport!.syncStatus.icon,
                        label: 'Status Penyimpanan',
                        value: _savedReport!.syncStatus.label,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ========================================================
              // B. HASIL DETEKSI
              // ========================================================
              _buildSectionTitle('B. Hasil Deteksi'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: category.borderColor,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        DamageCategoryBadge(category: category, large: true),
                        const Spacer(),
                        if (_result.confidencePercentLabel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.mintSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Text(
                              'Skor: ${_result.confidencePercentLabel}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDarkest,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Indikator Tingkat Indikasi Kerusakan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSlate,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DamageSeverityMeter(category: category),
                    if (_result.confidenceScore != null) ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _result.isSimulation
                                ? 'Confidence Score (Simulasi)'
                                : 'Confidence Score Model',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSlate,
                            ),
                          ),
                          Text(
                            _result.confidencePercentLabel!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDarkest,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _result.confidenceScore!.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: AppColors.mintAccent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            category.accentColor,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: AppColors.borderLight),
                    const SizedBox(height: 12),
                    Text(
                      'Ringkasan Indikasi Foto',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDarkest,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _result.summary,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: AppColors.textDark,
                        height: 1.48,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sumber classifier: ${_result.classifierName}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSlate,
                      ),
                    ),
                  ],
                ),
              ),

              // Peringatan Khusus Keselamatan untuk Kerusakan Sedang / Berat
              if (category.isHighRisk) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFEF4444),
                      width: 1.6,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_rounded,
                            color: Color(0xFFDC2626),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Peringatan Keselamatan Segera',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _result.urgentWarning ??
                            'Jauhi area bangunan yang berpotensi berbahaya dan segera hubungi petugas berwenang (BPBD Kota Padang / 112).',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF7F1D1D),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              showVisionEmergencyContactsSheet(context),
                          icon: const Icon(Icons.phone_in_talk_rounded),
                          label: Text(
                            'Hubungi Petugas Berwenang (112 / BPBD)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // ========================================================
              // C. REKOMENDASI TINDAKAN
              // ========================================================
              _buildSectionTitle('C. Rekomendasi Tindakan Awal'),
              const SizedBox(height: 8),
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
                  children: _result.recommendations.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final text = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _result.recommendations.length ? 0 : 10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.mintAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$index',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              text,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                color: AppColors.textDark,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // ========================================================
              // DISCLAIMER WAJIB
              // ========================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardCream.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.gpp_maybe_outlined,
                        color: AppColors.primaryDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Disclaimer Penting',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDarkest,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            DamageResultScreen.mandatoryAiDisclaimerText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: AppColors.textDark,
                              height: 1.42,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ========================================================
              // D. TOMBOL AKSI
              // ========================================================
              if (!widget.isFromHistory) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed:
                        (_isSaving || _savedReport != null) ? null : _saveReport,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.3,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _savedReport != null
                                ? Icons.check_circle_rounded
                                : Icons.save_alt_rounded,
                          ),
                    label: Text(
                      _isSaving
                          ? 'Menyimpan Laporan...'
                          : _savedReport != null
                              ? 'Laporan Tersimpan Lokal'
                              : 'Simpan Laporan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.safeGreen,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Tombol Cari Titik Kumpul / Shelter Terdekat (Revisi Zidan 2.3.B)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _openNearestShelterMap,
                  icon: const Icon(Icons.location_on_rounded, size: 20),
                  label: Text(
                    'Cari Titik Kumpul / Shelter Terdekat',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _scanAgain,
                        icon: const Icon(Icons.camera_alt_outlined, size: 19),
                        label: Text(
                          'Pindai Ulang',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
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
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _backToHome,
                        icon: const Icon(Icons.home_outlined, size: 19),
                        label: Text(
                          'Kembali ke Beranda',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryDarkest,
                          backgroundColor: AppColors.mintSurface,
                          side: const BorderSide(
                            color: AppColors.borderLight,
                            width: 1.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (widget.isFromHistory && _savedReport != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    onPressed: _isDeleting ? null : _confirmAndDeleteReport,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.alertAwas,
                    ),
                    label: Text(
                      _isDeleting ? 'Menghapus...' : 'Hapus Laporan Ini',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.alertAwas,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryDarkest,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 17, color: AppColors.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSlate,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDarkest,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
