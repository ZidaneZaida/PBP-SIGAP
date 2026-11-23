import 'dart:io';
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
import 'damage_result_screen.dart';

/// Halaman Riwayat Pemindaian SIGAP-Vision (`DamageHistoryScreen`).
///
/// Menampilkan daftar laporan kerusakan yang tersimpan secara lokal di perangkat,
/// lengkap dengan status penyimpanan/antrean sinkronisasi, pembukaan detail laporan,
/// penghapusan dengan konfirmasi, serta tombol mulai pemindaian baru.
class DamageHistoryScreen extends StatefulWidget {
  final DamageClassifier? classifier;
  final DamageReportRepository? repository;
  final VisionDeviceService? deviceService;

  const DamageHistoryScreen({
    super.key,
    this.classifier,
    this.repository,
    this.deviceService,
  });

  @override
  State<DamageHistoryScreen> createState() => _DamageHistoryScreenState();
}

class _DamageHistoryScreenState extends State<DamageHistoryScreen> {
  late final DamageClassifier _classifier;
  late final DamageReportRepository _repository;
  late final VisionDeviceService _deviceService;

  bool _isLoading = true;
  bool _isCheckingSync = false;
  String? _loadError;
  List<DamageScanReport> _reports = const [];

  @override
  void initState() {
    super.initState();
    _classifier = widget.classifier ?? const MockDamageClassifier();
    _repository = widget.repository ?? DamageReportRepository.instance;
    _deviceService = widget.deviceService ?? DefaultVisionDeviceService.instance;
    _repository.reportsNotifier.addListener(_onRepositoryReportsChanged);
    _loadReports();
  }

  @override
  void dispose() {
    _repository.reportsNotifier.removeListener(_onRepositoryReportsChanged);
    super.dispose();
  }

  void _onRepositoryReportsChanged() {
    if (!mounted || _isLoading) return;
    setState(() {
      _reports = _repository.reportsNotifier.value;
    });
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final list = await _repository.loadReports();
      if (!mounted) return;
      setState(() {
        _reports = list;
        _isLoading = false;
      });
    } on DamageStorageException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Gagal memuat riwayat pemindaian lokal.';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkSyncQueue() async {
    if (_isCheckingSync) return;
    HapticFeedback.selectionClick();
    setState(() => _isCheckingSync = true);

    try {
      final syncResult = await _repository.checkAndAttemptSync();
      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: syncResult.hasInternet
              ? AppColors.primaryDark
              : const Color(0xFF92400E),
          duration: const Duration(seconds: 4),
          content: Text(
            syncResult.message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.alertAwas,
          content: Text(
            'Gagal memeriksa status antrean sinkronisasi.',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingSync = false);
      }
    }
  }

  Future<void> _confirmDelete(DamageScanReport report) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Laporan Ini?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDarkest,
          ),
        ),
        content: Text(
          'Laporan "${report.result.category.label}" pada ${formatIndonesianDateTime(report.createdAt)} akan dihapus permanen dari penyimpanan lokal perangkat.',
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

    try {
      await _repository.deleteReport(report.id);
      if (!mounted) return;
      await _loadReports();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primaryDark,
          content: Text(
            'Laporan berhasil dihapus.',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
    } on DamageStorageException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.alertAwas,
          content: Text(
            e.message,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openDetail(DamageScanReport report) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      SigapRoutes.slideRight(
        DamageResultScreen(
          existingReport: report,
          isFromHistory: true,
          classifier: _classifier,
          repository: _repository,
          deviceService: _deviceService,
        ),
      ),
    );
    if (mounted) {
      await _loadReports();
    }
  }

  Future<void> _startNewScan() async {
    HapticFeedback.mediumImpact();
    await Navigator.of(context).push(
      SigapRoutes.slideRight(
        DamageCameraScreen(
          classifier: _classifier,
          repository: _repository,
          deviceService: _deviceService,
        ),
      ),
    );
    if (mounted) {
      await _loadReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _reports
        .where((r) => r.syncStatus == DamageSyncStatus.pendingSync)
        .length;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: VisionTopBar(
        title: 'Riwayat Pemindaian',
        subtitle: '${_reports.length} laporan tersimpan lokal',
        actions: [
          if (_reports.isNotEmpty)
            IconButton(
              tooltip: 'Periksa status sinkronisasi lokal',
              onPressed: _isCheckingSync ? null : _checkSyncQueue,
              icon: _isCheckingSync
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.primaryDark,
                      ),
                    )
                  : const Icon(
                      Icons.sync_rounded,
                      color: AppColors.primaryDark,
                    ),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryDark),
              )
            : _loadError != null
                ? _buildErrorState()
                : _reports.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: AppColors.primaryDark,
                        onRefresh: _loadReports,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 96),
                          children: [
                            // Banner Status Antrean Sinkronisasi Lokal
                            if (pendingCount > 0) ...[
                              Container(
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: AppColors.mintSurface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFC2DFCD),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.cloud_queue_rounded,
                                      color: AppColors.primaryDark,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '$pendingCount laporan berada di antrean lokal perangkat (belum dikirim ke server).',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryDarkest,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    TextButton(
                                      onPressed: _isCheckingSync
                                          ? null
                                          : _checkSyncQueue,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Cek',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            ..._reports.map(_buildReportCard),
                          ],
                        ),
                      ),
      ),
      floatingActionButton: _reports.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _startNewScan,
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(
                'Pemindaian Baru',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildReportCard(DamageScanReport report) {
    final file = File(report.imagePath);
    final fileExists = report.imagePath.isNotEmpty && file.existsSync();
    final category = report.result.category;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _openDetail(report),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail Foto Pemeriksaan
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 82,
                    height: 82,
                    child: fileExists
                        ? Image.file(
                            file,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildThumbPlaceholder(),
                          )
                        : _buildThumbPlaceholder(),
                  ),
                ),
                const SizedBox(width: 12),

                // Detail Ringkas Laporan
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          DamageCategoryBadge(category: category),
                          if (report.result.isSimulation)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFFDE68A),
                                ),
                              ),
                              child: Text(
                                'Simulasi',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: AppColors.textSlate,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              formatIndonesianDateTime(report.createdAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDarkest,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.textSlate,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              report.location?.displayLabel ??
                                  'Lokasi tidak disertakan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: AppColors.textSlate,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            report.syncStatus.icon,
                            size: 13,
                            color: report.syncStatus.badgeColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              report.syncStatus.shortLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: report.syncStatus.badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tombol Hapus dengan Konfirmasi
                IconButton(
                  tooltip: 'Hapus laporan',
                  onPressed: () => _confirmDelete(report),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.textSlate,
                    size: 21,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbPlaceholder() {
    return Container(
      color: AppColors.mintAccent,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: AppColors.mintAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.document_scanner_outlined,
                color: AppColors.primaryDark,
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Riwayat Pemindaian',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDarkest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Laporan hasil pemindaian bangunan yang Anda simpan akan muncul di sini dan tetap bisa dibuka meskipun tanpa koneksi internet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: AppColors.textSlate,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _startNewScan,
                icon: const Icon(Icons.camera_alt_rounded),
                label: Text(
                  'Mulai Pemindaian Baru',
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
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.alertAwas,
              size: 46,
            ),
            const SizedBox(height: 12),
            Text(
              'Riwayat Gagal Dimuat',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDarkest,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _loadError ?? 'Terjadi kesalahan saat membaca penyimpanan lokal.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: AppColors.textSlate,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadReports,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'Coba Muat Ulang',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
