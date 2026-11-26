import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap/core/theme/app_colors.dart';
import 'package:sigap/features/evacuation/data/evacuation_location_service.dart';
import '../../data/beacon_hardware_service.dart';
import '../../domain/beacon_models.dart';
import '../../domain/morse_sos_engine.dart';

/// Layar FE-09: Suar SOS Offline (Strobo Morse Senter & Layar, Panggilan Suara
/// Darurat Offline via TTS, Koordinat GPS Terakhir, dan Kesiapan BLE Beacon).
class EmergencyBeaconScreen extends StatefulWidget {
  static const String distressSpeechText =
      'Tolong! Darurat! Ada penyintas membutuhkan bantuan evakuasi di lokasi ini.';
  static const String defaultBeaconId = 'SIGAP-PDG-SOS01';

  final EmergencyBeaconHardwareService? hardwareService;
  final EvacuationLocationService? locationService;
  final Duration morseUnitDuration;
  final bool autoActivate;

  const EmergencyBeaconScreen({
    super.key,
    this.hardwareService,
    this.locationService,
    this.morseUnitDuration = kDefaultMorseUnitDuration,
    this.autoActivate = false,
  });

  @override
  State<EmergencyBeaconScreen> createState() => _EmergencyBeaconScreenState();
}

class _EmergencyBeaconScreenState extends State<EmergencyBeaconScreen> {
  late final EmergencyBeaconHardwareService _hardwareService;
  late final EvacuationLocationService _locationService;
  late final List<MorseStep> _morseSequence;

  // State utama Suar SOS
  bool _isActive = false;
  bool _isPowerSaveMode = false;
  int _activeDurationSeconds = 0;
  int _currentStepIndex = 0;
  bool _isLightPhaseOn = false;
  int _activationGeneration = 0;

  // Kontrol independen sinyal
  bool _torchEnabled = true;
  bool _ttsEnabled = true;
  bool _screenStrobeEnabled = true;

  // Status hardware senter & izin
  bool _torchReady = false;
  bool _torchUnavailable = false;
  String? _torchNotice;
  BeaconPermissionSnapshot _permissions = const BeaconPermissionSnapshot();

  // Status lokasi GPS & payload
  late EvacuationLocationResult _locationResult;
  bool _isRefreshingLocation = false;
  DateTime _payloadTimestamp = DateTime.now();

  // Timers (seluruhnya wajib dibatalkan saat berhenti maupun dispose)
  Timer? _morseStepTimer;
  Timer? _elapsedTimer;
  Timer? _ttsRepeatTimer;

  @override
  void initState() {
    super.initState();
    _hardwareService =
        widget.hardwareService ?? DefaultEmergencyBeaconHardwareService();
    _locationService =
        widget.locationService ?? DefaultEvacuationLocationService.instance;
    _morseSequence = buildSosMorseSequence();

    _locationResult = EvacuationLocationResult.fallback(
      statusMessage:
          'Sedang mengambil koordinat GPS terakhir. Sementara menampilkan perkiraan Padang Barat.',
    );

    _loadInitialDiagnostics();
    if (widget.autoActivate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startBeacon();
        }
      });
    }
  }

  @override
  void dispose() {
    _activationGeneration += 1;
    _cancelAllTimers();
    unawaited(_hardwareService.releaseTorch());
    unawaited(_hardwareService.stopSpeaking());
    unawaited(_hardwareService.dispose());
    super.dispose();
  }

  void _cancelAllTimers() {
    _morseStepTimer?.cancel();
    _morseStepTimer = null;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _ttsRepeatTimer?.cancel();
    _ttsRepeatTimer = null;
  }

  Future<void> _loadInitialDiagnostics() async {
    final snapshot = await _hardwareService.checkPermissions();
    if (!mounted) return;
    setState(() {
      _permissions = snapshot;
    });

    await _refreshLocation(showFeedback: false);
  }

  Future<void> _refreshLocation({bool showFeedback = true}) async {
    if (_isRefreshingLocation) return;
    if (showFeedback) {
      HapticFeedback.lightImpact();
    }

    setState(() {
      _isRefreshingLocation = true;
    });

    final result = await _locationService.fetchCurrentLocation();
    if (!mounted) return;

    setState(() {
      _locationResult = result;
      _payloadTimestamp = result.fetchedAt;
      _isRefreshingLocation = false;
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
                ? 'GPS belum tersedia — payload memakai lokasi perkiraan Padang Barat.'
                : '📍 Koordinat GPS terbaru diperbarui pada payload SOS.',
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

  Future<void> _toggleBeacon() async {
    if (_isActive) {
      await _stopBeacon();
    } else {
      await _startBeacon();
    }
  }

  Future<void> _startBeacon() async {
    if (_isActive) return;

    _cancelAllTimers();
    final generation = ++_activationGeneration;

    setState(() {
      _isActive = true;
      _activeDurationSeconds = 0;
      _currentStepIndex = 0;
      _isLightPhaseOn = false;
      _torchUnavailable = false;
      _torchNotice = null;
    });

    unawaited(_hardwareService.triggerHapticPulse());

    // 1. Timer penghitung durasi aktif MM:SS
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isActive || generation != _activationGeneration) {
        timer.cancel();
        return;
      }
      setState(() {
        _activeDurationSeconds += 1;
      });
    });

    // 2. Mulai siklus panggilan suara TTS bila aktif
    if (_ttsEnabled) {
      _startTtsLoop(generation);
    }

    // 3. Mulai siklus visual & pulsa Morse SOS segera
    _applyCurrentMorseStep(generation);

    // 4. Siapkan flash kamera bila toggle senter aktif
    if (_torchEnabled) {
      await _ensureTorchInitialized(generation);
    }
  }

  Future<void> _ensureTorchInitialized(int generation) async {
    final initialized = await _hardwareService.initializeTorch();
    if (!mounted || !_isActive || generation != _activationGeneration) {
      if (initialized) {
        await _hardwareService.releaseTorch();
      }
      return;
    }

    final refreshedPerms = await _hardwareService.checkPermissions();
    if (!mounted || !_isActive || generation != _activationGeneration) {
      if (initialized) {
        await _hardwareService.releaseTorch();
      }
      return;
    }

    setState(() {
      _permissions = refreshedPerms;
      _torchReady = initialized;
      _torchUnavailable = !initialized;
      _torchNotice = initialized
          ? null
          : (!refreshedPerms.cameraGranted && refreshedPerms.platformSupported
              ? 'Izin kamera belum diberikan untuk senter flash. Strobo layar tetap berjalan.'
              : 'Flash kamera tidak tersedia pada perangkat ini. Strobo visual layar tetap berjalan.');
    });

    if (initialized && _torchEnabled) {
      await _hardwareService.setTorch(_isLightPhaseOn);
    }
  }

  void _startTtsLoop(int generation) {
    _ttsRepeatTimer?.cancel();
    _ttsRepeatTimer = null;

    unawaited(
      _hardwareService.speakDistressCall(
        EmergencyBeaconScreen.distressSpeechText,
      ),
    );

    _ttsRepeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted ||
          !_isActive ||
          !_ttsEnabled ||
          generation != _activationGeneration) {
        timer.cancel();
        return;
      }
      unawaited(
        _hardwareService.speakDistressCall(
          EmergencyBeaconScreen.distressSpeechText,
        ),
      );
    });
  }

  void _applyCurrentMorseStep(int generation) {
    if (!mounted || !_isActive || generation != _activationGeneration) {
      return;
    }

    final step = _morseSequence[_currentStepIndex];
    setState(() {
      _isLightPhaseOn = step.isLightOn;
    });

    if (_torchEnabled && _torchReady) {
      unawaited(_hardwareService.setTorch(step.isLightOn));
    }

    if (step.isLightOn) {
      unawaited(_hardwareService.triggerHapticPulse());
    }

    _morseStepTimer?.cancel();
    _morseStepTimer = Timer(
      step.durationForUnit(widget.morseUnitDuration),
      () {
        if (!mounted || !_isActive || generation != _activationGeneration) {
          return;
        }
        _currentStepIndex = (_currentStepIndex + 1) % _morseSequence.length;
        _applyCurrentMorseStep(generation);
      },
    );
  }

  Future<void> _stopBeacon() async {
    _activationGeneration += 1;
    _cancelAllTimers();

    if (mounted) {
      setState(() {
        _isActive = false;
        _isLightPhaseOn = false;
        _currentStepIndex = 0;
        _torchReady = false;
      });
    }

    await _hardwareService.setTorch(false);
    await _hardwareService.releaseTorch();
    await _hardwareService.stopSpeaking();
  }

  Future<void> _onTorchSwitchChanged(bool value) async {
    HapticFeedback.selectionClick();
    setState(() {
      _torchEnabled = value;
      if (!value) {
        _torchNotice = null;
      }
    });

    if (!value) {
      _torchReady = false;
      await _hardwareService.setTorch(false);
      await _hardwareService.releaseTorch();
      return;
    }

    if (_isActive) {
      await _ensureTorchInitialized(_activationGeneration);
    }
  }

  Future<void> _onTtsSwitchChanged(bool value) async {
    HapticFeedback.selectionClick();
    setState(() {
      _ttsEnabled = value;
    });

    if (!value) {
      _ttsRepeatTimer?.cancel();
      _ttsRepeatTimer = null;
      await _hardwareService.stopSpeaking();
      return;
    }

    if (_isActive) {
      _startTtsLoop(_activationGeneration);
    }
  }

  void _onScreenStrobeSwitchChanged(bool value) {
    HapticFeedback.selectionClick();
    setState(() {
      _screenStrobeEnabled = value;
    });
  }

  Future<void> _requestCameraPermission() async {
    HapticFeedback.selectionClick();
    await _hardwareService.requestCameraPermission();
    final updated = await _hardwareService.checkPermissions();
    if (!mounted) return;
    setState(() {
      _permissions = updated;
    });
    if (updated.cameraGranted && _isActive && _torchEnabled) {
      await _ensureTorchInitialized(_activationGeneration);
    }
  }

  Future<void> _requestBluetoothPermissions() async {
    HapticFeedback.selectionClick();
    final updated = await _hardwareService.requestBluetoothPermissions();
    if (!mounted) return;
    setState(() {
      _permissions = updated;
    });
  }

  Future<void> _openDeviceSettings() async {
    HapticFeedback.selectionClick();
    await _hardwareService.openDeviceSettings();
  }

  Future<void> _copyCoordinatesAndPayload(OfflineSosPayload payload) async {
    HapticFeedback.selectionClick();
    final pos = _locationResult.position;
    final text =
        '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)} | ${payload.toCompactPayloadString()}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        duration: const Duration(seconds: 2),
        content: Text(
          'Koordinat & payload SOS berhasil disalin ke clipboard.',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  OfflineSosPayload _buildCurrentPayload() {
    final pos = _locationResult.position;
    return OfflineSosPayload(
      beaconId: EmergencyBeaconScreen.defaultBeaconId,
      latitude: pos.latitude,
      longitude: pos.longitude,
      isFallbackLocation: _locationResult.isFallback,
      generatedAt: _payloadTimestamp,
      statusText: _isActive ? 'SOS_BUTUH_EVAKUASI' : 'SIAGA_DARURAT',
    );
  }

  String _formatDuration(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = (safe ~/ 60).toString().padLeft(2, '0');
    final seconds = (safe % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _morseSequence[_currentStepIndex];
    final bool screenFlashingNow =
        _isActive && _screenStrobeEnabled && _isLightPhaseOn;
    final payload = _buildCurrentPayload();

    final Color scaffoldBg = _isPowerSaveMode
        ? const Color(0xFF000000)
        : (_isActive ? const Color(0xFF2B0606) : const Color(0xFF1A0A0A));
    final Color appBarBg = _isPowerSaveMode
        ? const Color(0xFF000000)
        : const Color(0xFF7F1D1D);

    return Scaffold(
      key: const ValueKey('emergency_beacon_scaffold'),
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suar SOS Offline',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Text(
              'Mode Darurat Tanpa Sinyal · SIGAP Padang',
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
            tooltip: _isPowerSaveMode
                ? 'Matikan Mode Hemat Layar'
                : 'Mode Hemat Layar (OLED)',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _isPowerSaveMode = !_isPowerSaveMode);
            },
            icon: Icon(
              _isPowerSaveMode
                  ? Icons.dark_mode_rounded
                  : Icons.dark_mode_outlined,
              color: _isPowerSaveMode ? const Color(0xFFFBBF24) : Colors.white,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A. BANNER STATUS UTAMA & DURASI AKTIF MM:SS
              _buildStatusBanner(),
              const SizedBox(height: 14),

              // B. TOMBOL MASTER RAKSASA AKTIFKAN / HENTIKAN SUAR SOS
              _buildMasterToggleButton(),
              const SizedBox(height: 14),

              // C. PANEL VISUAL STROBO MORSE SOS & MODE HEMAT LAYAR
              _buildMorseVisualPanel(
                currentStep: currentStep,
                screenFlashingNow: screenFlashingNow,
              ),
              const SizedBox(height: 14),

              // D. KONTROL INDEPENDEN SINYAL DARURAT
              _buildIndependentControlsCard(),
              const SizedBox(height: 14),

              // E. KARTU KESIAPAN BLE BEACON & PAYLOAD KOORDINAT GPS
              _buildBleAndPayloadCard(payload),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // A. BANNER STATUS UTAMA (SIAGA vs SUAR SOS AKTIF + DURASI MM:SS)
  // =========================================================================
  Widget _buildStatusBanner() {
    final bool activeFlashBorder = _isActive && _isLightPhaseOn;
    final Color cardBg = _isPowerSaveMode
        ? const Color(0xFF0A0A0A)
        : (_isActive ? const Color(0xFF7F1D1D) : const Color(0xFF271717));
    final Color borderColor = _isActive
        ? (activeFlashBorder ? Colors.white : const Color(0xFFEF4444))
        : const Color(0xFF574141);

    return AnimatedContainer(
      key: const ValueKey('beacon_status_banner'),
      duration: const Duration(milliseconds: 120),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: _isActive ? 2.2 : 1.3),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isActive
                  ? const Color(0xFFDC2626)
                  : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isActive
                  ? Icons.sensors_rounded
                  : Icons.shield_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isActive ? 'SUAR SOS AKTIF' : 'SIAGA',
                  key: const ValueKey('beacon_status_label'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _isActive
                        ? const Color(0xFFFEE2E2)
                        : Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isActive
                      ? 'Sinyal Morse SOS & panggilan darurat sedang dipancarkan'
                      : 'Tekan tombol di bawah untuk memancarkan suar pertolongan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFE5E7EB),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'DURASI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFCA5A5),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _formatDuration(_activeDurationSeconds),
                  key: const ValueKey('beacon_duration_text'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // B. TOMBOL MASTER RAKSASA
  // =========================================================================
  Widget _buildMasterToggleButton() {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton.icon(
        key: const ValueKey('master_sos_button'),
        onPressed: _toggleBeacon,
        icon: Icon(
          _isActive ? Icons.stop_circle_rounded : Icons.sensors_rounded,
          size: 28,
        ),
        label: Text(
          _isActive ? 'HENTIKAN SUAR SOS' : 'AKTIFKAN SUAR SOS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isActive
              ? const Color(0xFFB91C1C)
              : const Color(0xFFEA580C),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: Colors.white.withValues(alpha: _isActive ? 0.85 : 0.4),
              width: _isActive ? 2.0 : 1.3,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // C. PANEL VISUAL STROBO MORSE SOS & MODE HEMAT LAYAR (OLED)
  // =========================================================================
  Widget _buildMorseVisualPanel({
    required MorseStep currentStep,
    required bool screenFlashingNow,
  }) {
    final Color surfaceColor = _isPowerSaveMode
        ? const Color(0xFF0A0A0A)
        : const Color(0xFF1F1212);
    final int? activeIdx = _isActive ? currentStep.activeSymbolIndex : null;
    final String activeLetter = _isActive ? currentStep.letter : 'MATI';

    return Container(
      key: const ValueKey('morse_visual_panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: screenFlashingNow
              ? Colors.white
              : Colors.white.withValues(alpha: 0.16),
          width: screenFlashingNow ? 2.2 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flash_on_rounded,
                color: Color(0xFFFBBF24),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Strobo Visual Morse SOS (... --- ...)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: _isActive
                      ? const Color(0xFFDC2626)
                      : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  activeLetter,
                  key: const ValueKey('morse_active_letter'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Panel Cahaya Strobo Layar Besar
          AnimatedContainer(
            key: const ValueKey('screen_strobe_surface'),
            duration: const Duration(milliseconds: 70),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
              color: screenFlashingNow
                  ? const Color(0xFFFFFFFF)
                  : (_isPowerSaveMode
                      ? const Color(0xFF000000)
                      : const Color(0xFF140909)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: screenFlashingNow
                    ? const Color(0xFFFBBF24)
                    : Colors.white.withValues(alpha: 0.18),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  screenFlashingNow
                      ? 'S O S'
                      : (_isActive
                          ? (_screenStrobeEnabled ? '•  —  •' : 'STROBO LAYAR MATI')
                          : '• • •   — — —   • • •'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: screenFlashingNow ? 30 : 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.0,
                    color: screenFlashingNow
                        ? const Color(0xFF991B1B)
                        : Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 12),

                // Indikator 3 kelompok huruf S - O - S
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLetterGroup('S', const [0, 1, 2], false, activeIdx,
                        screenFlashingNow),
                    const SizedBox(width: 14),
                    _buildLetterGroup('O', const [3, 4, 5], true, activeIdx,
                        screenFlashingNow),
                    const SizedBox(width: 14),
                    _buildLetterGroup('S', const [6, 7, 8], false, activeIdx,
                        screenFlashingNow),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tombol Mode Hemat Layar (OLED Black)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('oled_power_save_button'),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _isPowerSaveMode = !_isPowerSaveMode);
              },
              icon: Icon(
                _isPowerSaveMode
                    ? Icons.brightness_6_rounded
                    : Icons.battery_saver_rounded,
                size: 18,
              ),
              label: Text(
                _isPowerSaveMode
                    ? 'Mode Hemat Layar Aktif (Hitam Pekat OLED)'
                    : 'Mode Hemat Layar',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    _isPowerSaveMode ? const Color(0xFFFBBF24) : Colors.white,
                side: BorderSide(
                  color: _isPowerSaveMode
                      ? const Color(0xFFFBBF24)
                      : Colors.white.withValues(alpha: 0.35),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mode Hemat Layar meredupkan tampilan ke hitam pekat (#000000) untuk hemat daya OLED. '
            'Kecerahan fisik layar tetap diatur melalui pengaturan sistem perangkat.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFD1D5DB),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterGroup(
    String letter,
    List<int> indices,
    bool isDash,
    int? activeIndex,
    bool invertedBg,
  ) {
    final bool isGroupActive =
        activeIndex != null && indices.contains(activeIndex);

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: indices.map((idx) {
            final bool lit = activeIndex == idx;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: isDash ? 20 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: lit
                    ? (invertedBg
                        ? const Color(0xFFDC2626)
                        : const Color(0xFFFBBF24))
                    : (invertedBg
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.28)),
                borderRadius: BorderRadius.circular(5),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Text(
          letter,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isGroupActive ? FontWeight.w900 : FontWeight.w700,
            color: invertedBg
                ? (isGroupActive ? const Color(0xFFDC2626) : Colors.black54)
                : (isGroupActive
                    ? const Color(0xFFFBBF24)
                    : Colors.white.withValues(alpha: 0.7)),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // D. KONTROL INDEPENDEN SINYAL DARURAT
  // =========================================================================
  Widget _buildIndependentControlsCard() {
    final Color cardBg = _isPowerSaveMode
        ? const Color(0xFF0A0A0A)
        : Colors.white;
    final Color titleColor =
        _isPowerSaveMode ? Colors.white : AppColors.primaryDarkest;
    final Color subtitleColor =
        _isPowerSaveMode ? const Color(0xFFD1D5DB) : AppColors.textSlate;
    final Color dividerColor = _isPowerSaveMode
        ? Colors.white.withValues(alpha: 0.14)
        : AppColors.borderLight;

    String torchSubtitle;
    if (_torchNotice != null) {
      torchSubtitle = _torchNotice!;
    } else if (!_permissions.platformSupported) {
      torchSubtitle =
          'Flash kamera tidak didukung di platform ini. Gunakan strobo visual layar.';
    } else if (!_permissions.cameraGranted) {
      torchSubtitle =
          'Memerlukan izin kamera untuk mengontrol lampu flash LED secara otomatis.';
    } else if (_isActive && _torchEnabled && _torchReady) {
      torchSubtitle = 'Flash LED berkedip mengikuti pola Morse SOS (... --- ...).';
    } else {
      torchSubtitle = 'Siap menyalakan flash kamera belakang berpola Morse SOS.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isPowerSaveMode
              ? Colors.white.withValues(alpha: 0.18)
              : AppColors.borderLight,
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kontrol Sinyal Darurat',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 10),

          // 1. Toggle Senter Flash Morse
          _buildSignalToggleRow(
            switchKey: const ValueKey('torch_switch'),
            icon: Icons.flashlight_on_rounded,
            iconColor: const Color(0xFFEA580C),
            title: 'Senter Flash Morse',
            subtitle: torchSubtitle,
            value: _torchEnabled,
            onChanged: _onTorchSwitchChanged,
            titleColor: titleColor,
            subtitleColor: subtitleColor,
          ),
          if (_torchUnavailable ||
              (_permissions.platformSupported && !_permissions.cameraGranted))
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (_permissions.platformSupported &&
                      !_permissions.cameraGranted &&
                      !_permissions.cameraPermanentlyDenied)
                    OutlinedButton.icon(
                      key: const ValueKey('request_camera_permission_button'),
                      onPressed: _requestCameraPermission,
                      icon: const Icon(Icons.camera_alt_outlined, size: 16),
                      label: Text(
                        'Izinkan Kamera',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEA580C),
                        side: const BorderSide(color: Color(0xFFEA580C)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  if (_permissions.cameraPermanentlyDenied)
                    OutlinedButton.icon(
                      onPressed: _openDeviceSettings,
                      icon: const Icon(Icons.settings_outlined, size: 16),
                      label: Text(
                        'Buka Pengaturan Kamera',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          Divider(height: 20, color: dividerColor),

          // 2. Toggle Panggilan Suara Darurat Offline (TTS)
          _buildSignalToggleRow(
            switchKey: const ValueKey('tts_switch'),
            icon: Icons.campaign_rounded,
            iconColor: const Color(0xFFDC2626),
            title: 'Panggilan Suara Darurat Offline (TTS)',
            subtitle:
                '"${EmergencyBeaconScreen.distressSpeechText}" (diulang tiap 10 detik saat aktif)',
            value: _ttsEnabled,
            onChanged: _onTtsSwitchChanged,
            titleColor: titleColor,
            subtitleColor: subtitleColor,
          ),

          Divider(height: 20, color: dividerColor),

          // 3. Toggle Strobo Visual Layar
          _buildSignalToggleRow(
            switchKey: const ValueKey('screen_strobe_switch'),
            icon: Icons.wb_incandescent_rounded,
            iconColor: const Color(0xFFD97706),
            title: 'Strobo Visual Layar',
            subtitle:
                'Selalu tersedia 100% offline tanpa memerlukan kamera atau izin tambahan.',
            value: _screenStrobeEnabled,
            onChanged: _onScreenStrobeSwitchChanged,
            titleColor: titleColor,
            subtitleColor: subtitleColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSignalToggleRow({
    required Key switchKey,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          key: switchKey,
          value: value,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFFDC2626),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // =========================================================================
  // E. KARTU KESIAPAN BLE BEACON & PAYLOAD KOORDINAT GPS
  // =========================================================================
  Widget _buildBleAndPayloadCard(OfflineSosPayload payload) {
    final bleStatus = _permissions.bleReadinessStatus;
    final pos = _locationResult.position;
    final coordString =
        '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
    final bool isFallback = _locationResult.isFallback;

    final Color cardBg = _isPowerSaveMode
        ? const Color(0xFF0A0A0A)
        : AppColors.backgroundCream;
    final Color titleColor =
        _isPowerSaveMode ? Colors.white : AppColors.primaryDarkest;
    final Color bodyColor =
        _isPowerSaveMode ? const Color(0xFFD1D5DB) : AppColors.textSlate;

    final Color bleAccent;
    switch (bleStatus) {
      case BleReadinessStatus.pluginPendingPermissionGranted:
        bleAccent = const Color(0xFF0284C7);
      case BleReadinessStatus.permissionRequired:
        bleAccent = const Color(0xFFD97706);
      case BleReadinessStatus.permanentlyDenied:
        bleAccent = const Color(0xFFDC2626);
      case BleReadinessStatus.unavailableOnPlatform:
        bleAccent = const Color(0xFF6B7280);
    }

    return Container(
      key: const ValueKey('ble_and_payload_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isPowerSaveMode
              ? Colors.white.withValues(alpha: 0.18)
              : AppColors.borderLight,
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bluetooth_searching_rounded, color: bleAccent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kesiapan BLE Beacon & Koordinat GPS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Status Jujur Kesiapan BLE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isPowerSaveMode
                  ? const Color(0xFF141414)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: bleAccent.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bleAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    bleStatus.badgeLabel,
                    key: const ValueKey('ble_status_badge'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: bleAccent,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  bleStatus.detailMessage,
                  key: const ValueKey('ble_status_detail'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: bodyColor,
                    height: 1.4,
                  ),
                ),
                if (bleStatus == BleReadinessStatus.permissionRequired) ...[
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    key: const ValueKey('request_ble_permission_button'),
                    onPressed: _requestBluetoothPermissions,
                    icon: const Icon(Icons.bluetooth_rounded, size: 17),
                    label: Text(
                      'Aktifkan Izin Bluetooth',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
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
                ] else if (bleStatus ==
                    BleReadinessStatus.permanentlyDenied) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    key: const ValueKey('open_ble_settings_button'),
                    onPressed: _openDeviceSettings,
                    icon: const Icon(Icons.settings_outlined, size: 17),
                    label: Text(
                      'Buka Pengaturan Bluetooth',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
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
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Koordinat GPS Terakhir / Fallback
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isPowerSaveMode
                  ? const Color(0xFF141414)
                  : (isFallback
                      ? const Color(0xFFFFFBEB)
                      : AppColors.mintSurface),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isFallback
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF10B981),
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
                      size: 18,
                      color: isFallback
                          ? const Color(0xFFB45309)
                          : const Color(0xFF047857),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isFallback
                            ? 'Lokasi Perkiraan (Fallback Padang Barat)'
                            : 'Koordinat GPS Terakhir',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _isPowerSaveMode
                              ? Colors.white
                              : (isFallback
                                  ? const Color(0xFF92400E)
                                  : AppColors.primaryDarkest),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  coordString,
                  key: const ValueKey('beacon_coordinates_text'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _isPowerSaveMode
                        ? const Color(0xFFFBBF24)
                        : AppColors.primaryDarkest,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _locationResult.statusMessage,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: bodyColor,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      key: const ValueKey('beacon_refresh_gps_button'),
                      onPressed:
                          _isRefreshingLocation ? null : () => _refreshLocation(),
                      icon: Icon(
                        _isRefreshingLocation
                            ? Icons.hourglass_top_rounded
                            : Icons.my_location_rounded,
                        size: 16,
                      ),
                      label: Text(
                        _isRefreshingLocation ? 'Memperbarui...' : 'Perbarui GPS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
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
                    OutlinedButton.icon(
                      key: const ValueKey('copy_coordinates_button'),
                      onPressed: () => _copyCoordinatesAndPayload(payload),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(
                        'Salin Koordinat',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isPowerSaveMode
                            ? Colors.white
                            : AppColors.primaryDark,
                        side: BorderSide(
                          color: _isPowerSaveMode
                              ? Colors.white.withValues(alpha: 0.45)
                              : AppColors.primary,
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
          ),

          const SizedBox(height: 12),

          // Preview Payload Ringkas SOS
          Text(
            'Preview Payload Darurat Offline',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            child: SelectableText(
              payload.toCompactPayloadString(),
              key: const ValueKey('sos_payload_preview'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF86EFAC),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
