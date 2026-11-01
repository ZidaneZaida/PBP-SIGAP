import 'dart:ui';
import 'package:flutter/material.dart';

/// Sistem Transisi Animasi & Routing SIGAP Kota Padang.
///
/// Menyediakan:
/// 1. [FadeThroughIndexedStack]: Transisi Fade-through (cross-fade 240ms) dengan
///    preservasi state penuh (IndexedStack) untuk Bottom Navigation Tabs.
/// 2. [SigapRoutes.slideRight]: Transisi Slide-in dari Kanan (dan Slide-out ke Kanan
///    saat Kembali) untuk halaman berlapis seperti PengaturanScreen.
/// 3. [showSigapModalBottomSheet]: Transisi Slide-up dari bawah dengan efek pegas
///    (Curves.easeOutBack) dan latar belakang gelap sedikit blur (BackdropFilter).
class SigapRoutes {
  /// Animasi "Slide-in dari Kanan" saat membuka halaman
  /// dan "Slide-out ke Kanan" saat menekan tombol Kembali (Back).
  static Route<T> slideRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0), // Dari Kanan
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

        final fadeAnimation = Tween<double>(
          begin: 0.7,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Animasi Fade murni yang lembut (240ms)
  static Route<T> fade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 240),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    );
  }
}

/// Widget Penumpukan Layar dengan Transisi Fade-Through (Cross-fade)
///
/// Mempertahankan State (State Preservation) semua tab di dalamnya
/// agar ketika berpindah dari Beranda -> Peta -> Keluarga, layar sebelumnya
/// tidak ter-reset atau me-reload ulang dari awal.
class FadeThroughIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeThroughIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 240),
  });

  @override
  State<FadeThroughIndexedStack> createState() => _FadeThroughIndexedStackState();
}

class _FadeThroughIndexedStackState extends State<FadeThroughIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late int _currentIndex;
  final Set<int> _activatedIndices = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _activatedIndices.add(_currentIndex);
    _fadeController = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1.0,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(FadeThroughIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _currentIndex = widget.index;
      _activatedIndices.add(_currentIndex);
      _fadeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final builtChildren = List<Widget>.generate(widget.children.length, (i) {
      if (_activatedIndices.contains(i)) {
        return widget.children[i];
      } else {
        return const SizedBox.shrink();
      }
    });

    return FadeTransition(
      opacity: _fadeAnimation,
      child: IndexedStack(
        index: _currentIndex,
        children: builtChildren,
      ),
    );
  }
}

/// Helper pembuka Bottom Sheet dengan efek Slide-up berpegas (Spring)
/// dan Latar Belakang Gelap Sedikit Blur (Backdrop Filter).
Future<T?> showSigapModalBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isScrollControlled = true,
  bool enableDrag = true,
  Color? barrierColor,
  double blurSigma = 4.0,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.5),
    builder: (ctx) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack, // Efek pegas (spring/bounce) halus di akhir
          tween: Tween<double>(begin: 0.08, end: 0.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value * MediaQuery.of(context).size.height),
              child: child,
            );
          },
          child: builder(ctx),
        ),
      );
    },
  );
}
