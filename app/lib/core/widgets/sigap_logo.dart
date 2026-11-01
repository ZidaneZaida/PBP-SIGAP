import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Widget Logo Resmi SIGAP (Alam, Kota, dan Kesiapsiagaan)
/// Dapat digunakan di berbagai layar (Splash, Header, AppBar, Dialog)
class SigapLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final String? subtitle;
  final Color? textColor;
  final Color? subtitleColor;
  final bool hasGlow;
  final bool isCircular;
  final double borderRadius;
  final VoidCallback? onTap;

  const SigapLogo({
    super.key,
    this.size = 36.0,
    this.showText = false,
    this.subtitle,
    this.textColor,
    this.subtitleColor,
    this.hasGlow = false,
    this.isCircular = true,
    this.borderRadius = 10.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircular ? null : BorderRadius.circular(borderRadius),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: AppColors.mintAccent.withValues(alpha: 0.35),
                  blurRadius: size * 0.45,
                  spreadRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isCircular ? size : borderRadius),
        child: Image.asset(
          'assets/logo_sigap.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            // Fallback elegan bila asset belum selesai termuat
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.mintAccent,
                shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isCircular ? null : BorderRadius.circular(borderRadius),
              ),
              child: Icon(
                Icons.shield_rounded,
                size: size * 0.55,
                color: AppColors.primaryDark,
              ),
            );
          },
        ),
      ),
    );

    if (!showText) {
      return onTap != null ? GestureDetector(onTap: onTap, child: imageWidget) : imageWidget;
    }

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        imageWidget,
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SIGAP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: size * 0.55,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                  color: textColor ?? AppColors.textDark,
                  height: 1.1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: size * 0.28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: subtitleColor ?? AppColors.textSlate,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );

    return onTap != null ? GestureDetector(onTap: onTap, child: content) : content;
  }
}
