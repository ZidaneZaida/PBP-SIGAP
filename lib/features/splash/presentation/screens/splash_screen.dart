import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/register_screen.dart';

/// Screen Splash SIGAP dengan animasi premium:
/// - Staggered fade & scale pada logo dan teks SIGAP
/// - Efek radar pulse / sinyal kesiapsiagaan bencana di sekitar emblem
/// - Tagline fade-in
/// - Progress bar interaktif & teks "Memuat..." dengan animasi titik berulang
/// - Otomatis berpindah (atau ketuk untuk lewati) ke RegisterScreen
class SplashScreen extends StatefulWidget {
  final VoidCallback? onInitializationComplete;

  const SplashScreen({
    super.key,
    this.onInitializationComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controller animasi utama (intro logo, teks, dan tagline)
  late AnimationController _introController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _taglineFadeAnimation;

  // Controller animasi radar pulse (berulang terus menerus)
  late AnimationController _radarController;

  // Controller animasi loading bar & memuat text
  late AnimationController _loadingController;
  late Animation<double> _progressAnimation;

  int _dotCount = 1;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // Pastikan status bar transparan dengan icon putih agar menyatu dengan background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.primaryDark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // 1. Setup Intro Controller (Durasi 1600ms)
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Animasi Scale & Fade Emblem Logo (0ms - 800ms)
    _logoScaleAnimation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
      ),
    );

    // Animasi Slide & Fade Teks "SIGAP" (250ms - 900ms)
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0.08, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.20, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.20, 0.60, curve: Curves.easeIn),
      ),
    );

    // Animasi Fade-in Tagline "Sistem informasi bencana" (500ms - 1100ms)
    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
      ),
    );

    // 2. Setup Radar Pulse Controller (Durasi 2400ms berulang)
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // 3. Setup Loading Controller (Progress bar terisi bertahap)
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Jalankan animasi intro lalu loading
    _introController.forward();
    _loadingController.forward().then((_) {
      _navigateToNextScreen();
    });

    // Timer siklus titik animasi "Memuat." -> "Memuat.." -> "Memuat..."
    _loadingController.addListener(() {
      final newCount = (1 + (_loadingController.value * 9).floor() % 3);
      if (newCount != _dotCount) {
        setState(() {
          _dotCount = newCount;
        });
      }
    });
  }

  void _navigateToNextScreen() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    if (widget.onInitializationComplete != null) {
      widget.onInitializationComplete!();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const RegisterScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _radarController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigateToNextScreen, // Bisa tap untuk lewati ke register
        child: Stack(
          children: [
            // 1. Background Gradient Khas SIGAP (Sesuai SVG Mockup)
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.splashGradient,
              ),
            ),

            // 2. Subtle Radial Ambient Glow di area tengah
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryLight.withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.85],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Konten Utama di Tengah (Logo + SIGAP + Tagline)
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row Logo Emblem + Teks "SIGAP"
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Emblem Kotak Mint dengan Efek Radar Signal
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _logoScaleAnimation,
                            _logoFadeAnimation,
                            _radarController,
                          ]),
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _logoScaleAnimation.value,
                              child: Opacity(
                                opacity: _logoFadeAnimation.value,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Radar Pulse Wave 1
                                    CustomPaint(
                                      painter: _RadarWavePainter(
                                        progress: _radarController.value,
                                        color: AppColors.mintAccent,
                                      ),
                                      size: const Size(64, 64),
                                    ),
                                    // Radar Pulse Wave 2 (Phase shifted)
                                    CustomPaint(
                                      painter: _RadarWavePainter(
                                        progress: (_radarController.value + 0.5) % 1.0,
                                        color: AppColors.mintAccent,
                                      ),
                                      size: const Size(64, 64),
                                    ),
                                    // Kotak Emblem Logo Utama (Sesuai SVG Mockup x:102.5 y:329.5 w:40 h:40)
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.mintAccent,
                                        borderRadius: BorderRadius.circular(9.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.mintAccent.withValues(alpha: 0.30),
                                            blurRadius: 14,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.sensors_rounded,
                                          size: 26,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(width: 14),

                        // Teks "SIGAP"
                        SlideTransition(
                          position: _textSlideAnimation,
                          child: FadeTransition(
                            opacity: _textFadeAnimation,
                            child: Text(
                              'SIGAP',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3.5,
                                color: AppColors.textWhite,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Tagline: "Sistem informasi bencana"
                    FadeTransition(
                      opacity: _taglineFadeAnimation,
                      child: Text(
                        'Sistem informasi bencana',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                          color: AppColors.textMint.withValues(alpha: 0.92),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Bagian Bawah: Progress Bar & Teks "Memuat..."
            Positioned(
              left: 0,
              right: 0,
              bottom: 46,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Progress Bar (Track 64px x 3px sesuai SVG)
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        const double trackWidth = 64.0;
                        return Container(
                          width: trackWidth,
                          height: 3.0,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
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
                                  color: AppColors.mintAccent.withValues(alpha: 0.40),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 14),

                    // Teks "Memuat..." dinamis
                    SizedBox(
                      height: 20,
                      child: Center(
                        child: Text(
                          'Memuat${'.' * _dotCount}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3,
                            color: AppColors.textMint.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter untuk efek gelombang radar deteksi dini di belakang logo emblem
class _RadarWavePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadarWavePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 + 18.0;
    final currentRadius = 22.0 + (maxRadius - 22.0) * progress;
    final opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.35;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _RadarWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
