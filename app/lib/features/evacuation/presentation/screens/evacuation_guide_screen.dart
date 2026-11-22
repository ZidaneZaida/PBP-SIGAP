import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:sigap/core/navigation/sigap_transitions.dart';
import 'package:sigap/core/theme/app_colors.dart';
import 'package:sigap/features/dashboard/presentation/screens/home_screen.dart';
import 'package:sigap/features/map/presentation/screens/peta_screen.dart';
import '../../data/evacuation_location_service.dart';
import '../../data/padang_evacuation_data.dart';
import '../../domain/evacuation_decision_engine.dart';
import '../../domain/evacuation_models.dart';
import '../widgets/evacuation_compass_card.dart';

/// Layar FE-07: Smart Tsunami Evacuation & Golden Time Matrix Kota Padang.
///
/// Menampilkan:
/// A. Header & Dynamic Golden Time Countdown + Disclaimer wajib BMKG (Bagian 7.2)
/// B. Status Lokasi GPS (dengan fallback aman & tombol Perbarui GPS / Pengaturan)
/// C. Kartu Keputusan Evakuasi (Vertikal TES vs Horizontal Zona Aman Timur)
/// D. Kompas Penunjuk Arah (bearing GPS acuan Utara) & Rute Bebas Hambatan
/// E. Daftar Alternatif Lokasi Evakuasi terdekat & tombol "Lihat di Peta Siaga"
class EvacuationGuideScreen extends StatefulWidget {
  final int initialRemainingSeconds;
  final EvacuationLocationService? locationService;
  final LatLng? initialPositionOverride;
  final bool autoStartTimer;

  const EvacuationGuideScreen({
    super.key,
    this.initialRemainingSeconds = HomeScreen.defaultGoldenTimeSeconds,
    this.locationService,
    this.initialPositionOverride,
    this.autoStartTimer = true,
  });

  @override
  State<EvacuationGuideScreen> createState() => _EvacuationGuideScreenState();
}

class _EvacuationGuideScreenState extends State<EvacuationGuideScreen> {
  late final EvacuationLocationService _locationService;
  late int _remainingSeconds;
  Timer? _countdownTimer;

  late EvacuationLocationResult _locationResult;
  bool _isLoadingLocation = false;
  String? _selectedAlternativeId;

  late EvacuationDecision _decision;
  late List<EvacuationCandidate> _rankedAll;

  @override
  void initState() {
    super.initState();
    _locationService =
        widget.locationService ?? DefaultEvacuationLocationService.instance;
    _remainingSeconds =
        widget.initialRemainingSeconds < 0 ? 0 : widget.initialRemainingSeconds;

    if (widget.initialPositionOverride != null) {
      final pos = widget.initialPositionOverride!;
      _locationResult = EvacuationLocationResult(
        position: pos,
        isFallback: false,
        sourceLabel:
            'GPS Aktif (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})',
        statusMessage:
            'Koordinat lokasi aktif digunakan untuk menghitung rute evakuasi terdekat.',
        fetchedAt: DateTime.now(),
      );
    } else {
      _locationResult = EvacuationLocationResult.fallback(
        statusMessage:
            'Sedang mengambil sinyal GPS perangkat. Sementara menggunakan koordinat perkiraan Padang Barat.',
      );
    }

    _recomputeEvacuationPlan();
    _startCountdownIfNeeded();

    if (widget.initialPositionOverride == null) {
      _refreshLocation(showFeedback: false);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    super.dispose();
  }

  void _startCountdownIfNeeded() {
    _countdownTimer?.cancel();
    _countdownTimer = null;

    if (!widget.autoStartTimer || _remainingSeconds <= 0) {
      return;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        if (_countdownTimer == timer) {
          _countdownTimer = null;
        }
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        _countdownTimer = null;
        setState(() {
          _remainingSeconds = 0;
          _recomputeEvacuationPlan();
        });
      } else {
        setState(() {
          _remainingSeconds -= 1;
          // Evaluasi ulang secara real-time setiap detik agar transisi
          // Horizontal -> Vertikal langsung tercermin ketika Golden Time menipis.
          _recomputeEvacuationPlan();
        });
      }
    });
  }

  void _recomputeEvacuationPlan() {
    final pos = _locationResult.position;
    final remainingMinutes = _remainingSeconds / 60.0;

    _decision = EvacuationDecisionEngine.evaluate(
      userLat: pos.latitude,
      userLng: pos.longitude,
      remainingGoldenTimeMinutes: remainingMinutes,
      tesShelters: PadangEvacuationData.tesShelters,
      horizontalSafeZones: PadangEvacuationData.horizontalSafeZones,
    );

    _rankedAll = EvacuationDecisionEngine.rankCandidates(
      userLat: pos.latitude,
      userLng: pos.longitude,
      points: PadangEvacuationData.allPoints,
    );
  }

  Future<void> _refreshLocation({bool showFeedback = true}) async {
    if (_isLoadingLocation) return;
    if (showFeedback) {
      HapticFeedback.lightImpact();
    }

    setState(() {
      _isLoadingLocation = true;
    });

    final result = await _locationService.fetchCurrentLocation();
    if (!mounted) return;

    setState(() {
      _locationResult = result;
      _isLoadingLocation = false;
      _recomputeEvacuationPlan();
    });

    if (showFeedback) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: result.isFallback
              ? const Color(0xFFB45309)
              : const Color(0xFF15803D),
          duration: const Duration(seconds: 3),
          content: Text(
            result.isFallback
                ? 'GPS belum tersedia — menggunakan koordinat perkiraan Padang Barat.'
                : '📍 Lokasi GPS diperbarui. Rute evakuasi telah disesuaikan.',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openAppSettings() async {
    HapticFeedback.selectionClick();
    await _locationService.openDeviceAppSettings();
  }

  void _openPetaSiaga() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      SigapRoutes.slideRight(const PetaScreen()),
    );
  }

  void _selectAlternative(EvacuationCandidate candidate) {
    HapticFeedback.selectionClick();
    setState(() {
      if (candidate.point.id == _decision.primaryTarget.id) {
        _selectedAlternativeId = null;
      } else {
        _selectedAlternativeId = candidate.point.id;
      }
    });
  }

  EvacuationCandidate get _activeCompassCandidate {
    final targetId = _selectedAlternativeId ?? _decision.primaryTarget.id;
    return _rankedAll.firstWhere(
      (c) => c.point.id == targetId,
      orElse: () => _rankedAll.first,
    );
  }

  bool get _isUsingCustomSelection =>
      _selectedAlternativeId != null &&
      _selectedAlternativeId != _decision.primaryTarget.id;

  String _formatCountdown(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = (safe ~/ 60).toString().padLeft(2, '0');
    final seconds = (safe % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final activeCandidate = _activeCompassCandidate;

    return Scaffold(
      backgroundColor: const Color(0xFF450A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7F1D1D),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panduan Evakuasi Tsunami',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Text(
              'Smart Golden Time Matrix · Kota Padang',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFECACA),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const ValueKey('appbar_refresh_gps_button'),
            tooltip: 'Perbarui GPS',
            onPressed: _isLoadingLocation ? null : () => _refreshLocation(),
            icon: _isLoadingLocation
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.my_location_rounded, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A. GOLDEN TIME COUNTDOWN + DISCLAIMER WAJIB
              _buildGoldenTimeCard(),
              const SizedBox(height: 12),

              // B. STATUS LOKASI GPS
              _buildLocationStatusCard(),
              const SizedBox(height: 14),

              // C. KARTU KEPUTUSAN EVAKUASI (VERTIKAL VS HORIZONTAL)
              _buildDecisionCard(),
              const SizedBox(height: 14),

              // D1. KOMPAS PENUNJUK ARAH (BEARING GPS ACUAN UTARA)
              EvacuationCompassCard(
                targetName: activeCandidate.point.name,
                distanceText: formatEvacuationDistance(
                  activeCandidate.distanceMeters,
                ),
                bearingDegrees: activeCandidate.bearingDegrees,
                cardinalDirection: activeCandidate.cardinalDirection,
                isVerticalTarget:
                    activeCandidate.point.type ==
                    EvacuationPointType.verticalTes,
                isCustomSelection: _isUsingCustomSelection,
                onResetToRecommended: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedAlternativeId = null);
                },
              ),
              const SizedBox(height: 14),

              // D2. PANDUAN LANGKAH RUTE BEBAS HAMBATAN & CHECKLIST KESELAMATAN
              _buildRouteAndSafetyCard(activeCandidate),
              const SizedBox(height: 16),

              // E1. DAFTAR ALTERNATIF LOKASI EVAKUASI TERDEKAT
              _buildAlternativesSection(activeCandidate.point.id),
              const SizedBox(height: 18),

              // E2. TOMBOL AKSI BESAR: LIHAT DI PETA SIAGA
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  key: const ValueKey('open_peta_siaga_button'),
                  onPressed: _openPetaSiaga,
                  icon: const Icon(Icons.map_rounded, size: 22),
                  label: Text(
                    'Lihat di Peta Siaga',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // A. DYNAMIC GOLDEN TIME COUNTDOWN CARD
  // =========================================================================
  Widget _buildGoldenTimeCard() {
    final isUrgent = _remainingSeconds <= 5 * 60;

    return Container(
      key: const ValueKey('evacuation_golden_time_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isUrgent
              ? const [Color(0xFF991B1B), Color(0xFFDC2626)]
              : const [Color(0xFF991B1B), Color(0xFFC2410C)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFCA5A5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 12,
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
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SISA GOLDEN TIME EVAKUASI',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFFEE2E2),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _remainingSeconds == 0
                          ? 'Waktu kritis tercapai — segera naik ke tempat tinggi!'
                          : 'Bergerak sekarang menjauhi pesisir pantai',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  _formatCountdown(_remainingSeconds),
                  key: const ValueKey('evacuation_countdown_text'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              HomeScreen.goldenTimeDisclaimerText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFEF3C7),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // B. STATUS LOKASI GPS CARD
  // =========================================================================
  Widget _buildLocationStatusCard() {
    final pos = _locationResult.position;
    final coordText =
        '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
    final isFallback = _locationResult.isFallback;

    return Container(
      key: const ValueKey('evacuation_location_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isFallback ? const Color(0xFFFFFBEB) : AppColors.mintSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFallback ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFallback
                    ? Icons.location_searching_rounded
                    : Icons.gps_fixed_rounded,
                size: 20,
                color: isFallback
                    ? const Color(0xFFB45309)
                    : const Color(0xFF047857),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFallback
                      ? 'Lokasi Perkiraan (Fallback Padang)'
                      : 'Lokasi GPS Nyata Aktif',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isFallback
                        ? const Color(0xFF92400E)
                        : AppColors.primaryDarkest,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isFallback
                      ? const Color(0xFFFEF3C7)
                      : AppColors.mintAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  coordText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isFallback
                        ? const Color(0xFF92400E)
                        : AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _locationResult.statusMessage,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isFallback
                  ? const Color(0xFF78350F)
                  : AppColors.textSlate,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                key: const ValueKey('refresh_gps_button'),
                onPressed: _isLoadingLocation ? null : () => _refreshLocation(),
                icon: Icon(
                  _isLoadingLocation
                      ? Icons.hourglass_top_rounded
                      : Icons.refresh_rounded,
                  size: 16,
                ),
                label: Text(
                  _isLoadingLocation ? 'Memperbarui...' : 'Perbarui GPS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFallback
                      ? const Color(0xFFD97706)
                      : AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_locationResult.permanentlyDenied)
                OutlinedButton.icon(
                  key: const ValueKey('open_app_settings_button'),
                  onPressed: _openAppSettings,
                  icon: const Icon(Icons.settings_outlined, size: 16),
                  label: Text(
                    'Buka Pengaturan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF92400E),
                    side: const BorderSide(
                      color: Color(0xFFD97706),
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // C. KARTU KEPUTUSAN EVAKUASI (VERTIKAL VS HORIZONTAL)
  // =========================================================================
  Widget _buildDecisionCard() {
    final isVertical = _decision.isVerticalRecommended;
    final badgeColor = isVertical
        ? const Color(0xFFDC2626)
        : const Color(0xFF15803D);
    final cardBg = isVertical
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFECFDF5);
    final borderColor = isVertical
        ? const Color(0xFFEF4444)
        : const Color(0xFF10B981);
    final headlineColor = isVertical
        ? const Color(0xFF7F1D1D)
        : const Color(0xFF064E3B);

    final primary = _decision.primaryTarget;
    final primaryDistance = formatEvacuationDistance(
      _decision.distanceToPrimaryMeters,
    );
    final primaryEta = formatEtaMinutes(_decision.etaToPrimaryMinutes);

    return Container(
      key: const ValueKey('evacuation_decision_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge Tegas Keputusan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isVertical
                      ? Icons.stairs_rounded
                      : Icons.directions_run_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _decision.recommendedType.badgeLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Headline Keputusan Tegas sesuai Revisi Zidan Bagian 2.3.C
          Text(
            _decision.headline,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: headlineColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Detail Target Utama
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primary.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDarkest,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMetricChip(
                      icon: Icons.straighten_rounded,
                      label: 'Jarak',
                      value: primaryDistance,
                      tint: badgeColor,
                    ),
                    _buildMetricChip(
                      icon: Icons.directions_walk_rounded,
                      label: 'Jalan Kaki',
                      value: primaryEta,
                      tint: badgeColor,
                    ),
                    _buildMetricChip(
                      icon: Icons.terrain_rounded,
                      label: 'Elevasi',
                      value: primary.elevationLabel,
                      tint: AppColors.primaryDark,
                    ),
                    _buildMetricChip(
                      icon: Icons.groups_rounded,
                      label: 'Kapasitas',
                      value: primary.capacityLabel,
                      tint: AppColors.primaryDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Alasan Evaluasi Golden Time
          Text(
            _decision.rationale,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: headlineColor.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Perbandingan Ringkas: TES Terdekat vs Zona Aman Timur
          Row(
            children: [
              Expanded(
                child: _buildComparisonBox(
                  title: 'TES Vertikal Terdekat',
                  name: _decision.nearestTes.name,
                  distance: formatEvacuationDistance(
                    _decision.distanceToTesMeters,
                  ),
                  eta: formatEtaMinutes(_decision.etaToTesMinutes),
                  isRecommended: isVertical,
                  accentColor: const Color(0xFFEA580C),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildComparisonBox(
                  title: 'Zona Aman Timur',
                  name: _decision.nearestHorizontalZone.name,
                  distance: formatEvacuationDistance(
                    _decision.distanceToHorizontalMeters,
                  ),
                  eta: formatEtaMinutes(_decision.etaToHorizontalMinutes),
                  isRecommended: !isVertical,
                  accentColor: const Color(0xFF15803D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required String value,
    required Color tint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tint.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tint),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDarkest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonBox({
    required String title,
    required String name,
    required String distance,
    required String eta,
    required bool isRecommended,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRecommended ? accentColor : AppColors.borderLight,
          width: isRecommended ? 1.8 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isRecommended ? accentColor : AppColors.textSlate,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isRecommended)
                Icon(Icons.check_circle_rounded, size: 14, color: accentColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDarkest,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '$distance · $eta',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // D2. PANDUAN RUTE BEBAS HAMBATAN & CHECKLIST KESELAMATAN
  // =========================================================================
  Widget _buildRouteAndSafetyCard(EvacuationCandidate activeCandidate) {
    final bool isCustom = _isUsingCustomSelection;
    final List<String> routeSteps = isCustom
        ? <String>[
            'Menuju ${activeCandidate.point.name} (${formatEvacuationDistance(activeCandidate.distanceMeters)}, ${formatEtaMinutes(activeCandidate.etaMinutes)}) ke arah ${activeCandidate.cardinalDirection}.',
            'Catatan rute: ${activeCandidate.point.routeNote}',
            activeCandidate.point.type == EvacuationPointType.verticalTes
                ? 'Setibanya di gedung TES, segera naik ke lantai aman minimal Lantai 3 (${activeCandidate.point.elevationLabel}).'
                : 'Terus bergerak menuju dataran tinggi (${activeCandidate.point.elevationLabel}) menjauhi garis pantai.',
          ]
        : _decision.steps;

    const safetyChecklist = <String>[
      'Segera jauhi garis pantai, jembatan pesisir, dan muara Batang Arau.',
      'Jangan gunakan mobil atau motor jika jalan macet; berjalan cepat lebih aman.',
      'Untuk evakuasi vertikal (TES), naik minimal ke Lantai 3 (>10 mdpl) lewat tangga, bukan lift.',
      'Tetap berada di lokasi aman hingga pengumuman resmi berakhirnya ancaman dari BMKG/BPBD.',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.alt_route_rounded,
                color: AppColors.primaryDark,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Panduan Jalur Bebas Hambatan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDarkest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...routeSteps.asMap().entries.map((entry) {
            final stepNumber = entry.key + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryDark,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$stepNumber',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDarkest,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 8),
          Text(
            'Checklist Keselamatan Darurat',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF991B1B),
            ),
          ),
          const SizedBox(height: 8),
          ...safetyChecklist.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // E1. DAFTAR ALTERNATIF LOKASI EVAKUASI TERDEKAT
  // =========================================================================
  Widget _buildAlternativesSection(String activeTargetId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daftar Lokasi Evakuasi Terdekat',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ketuk lokasi mana saja untuk melihat arah kompas dan catatan rutenya.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFFECACA),
          ),
        ),
        const SizedBox(height: 10),
        ..._rankedAll.map((candidate) {
          final isPrimaryRecommended =
              candidate.point.id == _decision.primaryTarget.id;
          final isSelected = candidate.point.id == activeTargetId;
          final isTes =
              candidate.point.type == EvacuationPointType.verticalTes;
          final typeColor = isTes
              ? const Color(0xFFEA580C)
              : const Color(0xFF15803D);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('evacuation_option_${candidate.point.id}'),
                onTap: () => _selectAlternative(candidate),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? typeColor : AppColors.borderLight,
                      width: isSelected ? 2.2 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isTes
                              ? Icons.apartment_rounded
                              : Icons.landscape_rounded,
                          color: typeColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    candidate.point.type.shortTag,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: typeColor,
                                    ),
                                  ),
                                ),
                                if (isPrimaryRecommended)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryDark,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'UTAMA',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              candidate.point.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDarkest,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${candidate.point.elevationLabel} · ${candidate.cardinalDirection}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSlate,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatEvacuationDistance(candidate.distanceMeters),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: typeColor,
                            ),
                          ),
                          Text(
                            formatEtaMinutes(candidate.etaMinutes),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSlate,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
