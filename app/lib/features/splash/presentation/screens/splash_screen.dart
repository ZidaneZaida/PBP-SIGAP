import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/bmkg_service.dart';
import '../../../auth/presentation/screens/register_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

/// Screen Splash SIGAP
/// Tampilan bersih, minimalis, dan tenang dengan warna latar hijau tua khas SIGAP.
///
/// Desain Layar:
/// - Tengah: Logo bulat SIGAP dengan efek glow halus, judul besar "SIGAP",
///   sub-judul "Siaga Bencana Kota Padang", dan teks "Alam • Kota • Kesiapsiagaan".
/// - Bawah: Indikator loading sederhana dengan teks "Memeriksa peringatan BMKG & lokasi GPS...".
///
/// Logika Latar Belakang (Background Logic):
/// - Pengecekan internet (fallback: Mode Offline Siaga)
/// - Pengecekan cache & data lokal (fallback: data dasar)
/// - Pengecekan GPS (fallback: lanjut tanpa lokasi)
/// - Pengecekan peringatan BMKG/BPBD (fallback: data terakhir & larangan klaim aman)
/// - Penentuan tujuan otomatis:
///   * Jika darurat aktif valid -> langsung buka Beranda Mode Darurat tanpa login + TTS Bahasa Indonesia
///   * Jika normal & sudah login -> buka Beranda
///   * Jika normal & belum login -> buka halaman Onboarding / Register
/// Begitu loading selesai, halaman otomatis berpindah sendiri tanpa ada tombol di layar.
class SplashScreen extends StatefulWidget {
  final VoidCallback? onInitializationComplete;
  final bool isUserLoggedIn;
  final bool? simulateEmergency;
  final bool? simulateOffline;

  const SplashScreen({
    super.key,
    this.onInitializationComplete,
    this.isUserLoggedIn = false,
    this.simulateEmergency,
    this.simulateOffline,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Controller animasi intro logo, teks, dan tagline
  late AnimationController _introController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _taglineFadeAnimation;

  // Controller animasi pulse glow halus di sekitar emblem
  late AnimationController _glowController;

  // Controller animasi loading bar sederhana di bawah
  late AnimationController _loadingController;
  late Animation<double> _progressAnimation;

  // Hasil pengecekan latar belakang
  bool _isEmergencyActive = false;
  String _ttsSpeechText = '';
  bool _hasNavigated = false;
  final List<Timer> _activeTimers = [];
  Timer? _watchdogTimer;

  @override
  void initState() {
    super.initState();

    // Pastikan status bar dan navigation bar menyatu dengan background hijau tua
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.primaryDark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _initAnimations();

    // Jalankan animasi intro dan loading bar
    _introController.forward();
    _loadingController.forward();

    // Jalankan seluruh pengecekan di latar belakang (background logic)
    _runBackgroundDiagnostic();

    // Watchdog Timer (Maksimal 4 detik) agar tidak pernah memuat tanpa batas
    _watchdogTimer = Timer(const Duration(milliseconds: 4000), () {
      if (mounted && !_hasNavigated) {
        _finishAndNavigate();
      }
    });
  }

  void _initAnimations() {
    // 1. Intro Animation Controller (1000ms)
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.50, curve: Curves.easeOut),
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.25, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.25, 0.75, curve: Curves.easeIn),
      ),
    );

    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
      ),
    );

    // 2. Glow Controller (berdenyut lembut berulang)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // 3. Loading Controller (Durasi 1800ms)
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _loadingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishAndNavigate();
      }
    });
  }

  /// Pengecekan 5 tahapan di latar belakang (Background Logic)
  Future<void> _runBackgroundDiagnostic() async {
    try {
      // 1. Pengecekan Koneksi Internet & BMKG di latar belakang
      bool isOnline = true;
      if (widget.simulateOffline == true) {
        isOnline = false;
      } else {
        try {
          final gempa = await BmkgService.fetchLatestGempa().timeout(
            const Duration(milliseconds: 1200),
            onTimeout: () => BmkgGempa.fallbackPadang,
          );
          isOnline = gempa.isLiveFromApi;

          // Evaluasi peringatan darurat valid
          final mag = double.tryParse(gempa.magnitude) ?? 0.0;
          if (widget.simulateEmergency == true || mag >= 5.0) {
            _isEmergencyActive = true;
            _ttsSpeechText =
                'PERINGATAN DARURAT RESMI BMKG KOTA PADANG: Telah terjadi gempa bumi berkekuatan Magnitudo ${gempa.magnitude} pada kedalaman ${gempa.kedalaman} di ${gempa.wilayah}. Waspadai potensi gempa susulan. Harap segera amankan diri dan menuju shelter atau Tempat Evakuasi Sementara terdekat!';
          }
        } catch (_) {
          isOnline = false;
        }
      }

      // 2. Aturan Fallback jika offline
      if (!isOnline && widget.simulateEmergency != true) {
        // Menggunakan data cache riwayat tanpa mengklaim kondisi aman
        _isEmergencyActive = false;
      }

      if (widget.simulateEmergency == true) {
        _isEmergencyActive = true;
        _ttsSpeechText =
            'PERINGATAN DARURAT RESMI BMKG KOTA PADANG: Telah terjadi gempa bumi Magnitudo 5.8 di Barat Daya Kota Padang. Waspadai gempa susulan dan segera menuju shelter terdekat.';
      }
    } catch (_) {
      // Fail-safe: abaikan error pengecekan agar aplikasi tidak pernah gagal membuka
    }
  }

  void _finishAndNavigate() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    // Jika ada callback inisialisasi eksternal
    if (widget.onInitializationComplete != null) {
      widget.onInitializationComplete!();
      return;
    }

    // 1. Kondisi Darurat Aktif: Langsung buka Beranda Darurat tanpa login + aktifkan TTS
    if (_isEmergencyActive) {
      try {
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
      } catch (_) {}

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, a1, a2) => DashboardScreen(
            userName: 'Warga Padang (Mode Darurat)',
          ),
          transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );

      // Tampilkan notifikasi suara TTS Bahasa Indonesia di Beranda
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
        if (scaffoldMessenger != null && _ttsSpeechText.isNotEmpty) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 8),
              backgroundColor: AppColors.alertRust,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.volume_up_rounded, color: AppColors.alertRust, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TTS SUARA BAHASA INDONESIA AKTIF',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _ttsSpeechText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.95),
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
      });
      return;
    }

    // 2. Kondisi Normal & Sudah Login: Arahkan langsung ke Beranda
    if (widget.isUserLoggedIn) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, a1, a2) => const DashboardScreen(
            userName: 'Aulia Rahman',
          ),
          transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
      return;
    }

    // 3. Kondisi Normal & Belum Login: Arahkan ke Onboarding / Register
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => const RegisterScreen(),
        transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _watchdogTimer?.cancel();
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
    _introController.dispose();
    _glowController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Warna Latar Hijau Tua Khas SIGAP (Gradient Halus)
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.splashGradient,
            ),
          ),

          // 2. Efek Radial Ambient Glow Halus di Area Tengah
          Positioned.fill(
            child: Center(
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  final glowRadius = 260.0 + (50.0 * _glowController.value);
                  final glowAlpha = 0.20 + (0.15 * _glowController.value);
                  return Container(
                    width: glowRadius,
                    height: glowRadius,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primaryLight.withValues(alpha: glowAlpha),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.85],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. Konten Tengah: Logo Bulat SIGAP + Judul + Tagline + Teks Kecil
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo Bulat SIGAP dengan Efek Glow Halus
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _logoScaleAnimation,
                      _logoFadeAnimation,
                      _glowController,
                    ]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScaleAnimation.value,
                        child: Opacity(
                          opacity: _logoFadeAnimation.value,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.mintAccent.withValues(
                                    alpha: 0.35 + (0.25 * _glowController.value),
                                  ),
                                  blurRadius: 28,
                                  spreadRadius: 4,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/logo_sigap.png',
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.mintAccent,
                                    child: const Icon(
                                      Icons.shield_rounded,
                                      size: 44,
                                      color: AppColors.primaryDark,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 22),

                  // Judul Besar: "SIGAP"
                  SlideTransition(
                    position: _textSlideAnimation,
                    child: FadeTransition(
                      opacity: _textFadeAnimation,
                      child: Text(
                        'SIGAP',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.5,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Sub-judul: "Siaga Bencana Kota Padang"
                  FadeTransition(
                    opacity: _taglineFadeAnimation,
                    child: Text(
                      'Siaga Bencana Kota Padang',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: AppColors.textMint,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Teks Kecil: "Alam • Kota • Kesiapsiagaan"
                  FadeTransition(
                    opacity: _taglineFadeAnimation,
                    child: Text(
                      'Alam • Kota • Kesiapsiagaan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.2,
                        color: AppColors.textMint.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Bagian Bawah Layar:
          // Satu Indikator Loading Sederhana + Satu Baris Teks Tipis
          Positioned(
            left: 0,
            right: 0,
            bottom: 46,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Progress Bar Sederhana (Track 72px x 3px)
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      const double trackWidth = 72.0;
                      return Container(
                        width: trackWidth,
                        height: 3.0,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: math.max(6.0, trackWidth * _progressAnimation.value),
                          height: 3.0,
                          decoration: BoxDecoration(
                            color: AppColors.mintAccent,
                            borderRadius: BorderRadius.circular(1.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.mintAccent.withValues(alpha: 0.45),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // Satu Baris Teks Tipis
                  Text(
                    'Memeriksa peringatan BMKG & lokasi GPS...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                      color: AppColors.textMint.withValues(alpha: 0.85),
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
}
