import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap/core/theme/app_colors.dart';

/// Widget kompas penunjuk arah visual berbasis sudut bearing GPS (Acuan Utara).
/// Tidak mengklaim penggunaan sensor magnetometer hardware.
class EvacuationCompassCard extends StatelessWidget {
  final String targetName;
  final String distanceText;
  final double bearingDegrees;
  final String cardinalDirection;
  final bool isVerticalTarget;
  final bool isCustomSelection;
  final VoidCallback? onResetToRecommended;

  const EvacuationCompassCard({
    super.key,
    required this.targetName,
    required this.distanceText,
    required this.bearingDegrees,
    required this.cardinalDirection,
    required this.isVerticalTarget,
    this.isCustomSelection = false,
    this.onResetToRecommended,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedBearing = ((bearingDegrees % 360) + 360) % 360;
    final degreeLabel =
        '${normalizedBearing.round().toString().padLeft(3, '0')}°';
    final accentColor = isVerticalTarget
        ? const Color(0xFFEA580C)
        : const Color(0xFF15803D);

    return Container(
      key: const ValueKey('evacuation_compass_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.explore_rounded, color: accentColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kompas Penunjuk Arah Target',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDarkest,
                  ),
                ),
              ),
              if (isCustomSelection && onResetToRecommended != null)
                TextButton(
                  onPressed: onResetToRecommended,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Target Utama',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Dial Kompas Visual
              SizedBox(
                width: 122,
                height: 122,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(122, 122),
                      painter: _CompassDialPainter(accentColor: accentColor),
                    ),
                    Transform.rotate(
                      angle: normalizedBearing * math.pi / 180.0,
                      child: SizedBox(
                        width: 78,
                        height: 78,
                        child: CustomPaint(
                          painter: _CompassNeedlePainter(
                            arrowColor: accentColor,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDarkest,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Informasi Bearing & Mata Angin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isCustomSelection
                            ? 'PILIHAN ALTERNATIF'
                            : 'ARAH REKOMENDASI',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          degreeLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDarkest,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            cardinalDirection,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      targetName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDarkest,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Jarak garis lurus: $distanceText',
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
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.mintSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Penunjuk arah berdasarkan koordinat GPS (Acuan Utara)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDarkest,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassDialPainter extends CustomPainter {
  final Color accentColor;

  _CompassDialPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final bgPaint = Paint()
      ..color = AppColors.backgroundCream
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final outerRing = Paint()
      ..color = AppColors.borderLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, outerRing);

    final innerRing = Paint()
      ..color = accentColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius - 18, innerRing);

    // Tick marks setiap 45 derajat
    final tickPaint = Paint()
      ..color = AppColors.textSlate.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 8; i++) {
      final angle = (i * 45) * math.pi / 180.0;
      final isMajor = i % 2 == 0;
      final startR = radius - (isMajor ? 6 : 9);
      final endR = radius - 2;
      final p1 = Offset(
        center.dx + startR * math.sin(angle),
        center.dy - startR * math.cos(angle),
      );
      final p2 = Offset(
        center.dx + endR * math.sin(angle),
        center.dy - endR * math.cos(angle),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Label Mata Angin (U, T, S, B)
    _drawLabel(
      canvas,
      'U',
      Offset(center.dx, center.dy - radius + 14),
      const Color(0xFFDC2626),
      FontWeight.w900,
    );
    _drawLabel(
      canvas,
      'T',
      Offset(center.dx + radius - 14, center.dy),
      AppColors.primaryDarkest,
      FontWeight.w800,
    );
    _drawLabel(
      canvas,
      'S',
      Offset(center.dx, center.dy + radius - 14),
      AppColors.primaryDarkest,
      FontWeight.w800,
    );
    _drawLabel(
      canvas,
      'B',
      Offset(center.dx - radius + 14, center.dy),
      AppColors.primaryDarkest,
      FontWeight.w800,
    );
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset position,
    Color color,
    FontWeight weight,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}

class _CompassNeedlePainter extends CustomPainter {
  final Color arrowColor;

  _CompassNeedlePainter({required this.arrowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Jarum penunjuk depan (mengarah ke atas = 0°, lalu diputar sesuai bearing)
    final frontPath = Path()
      ..moveTo(cx, 4)
      ..lineTo(cx - 10, cy + 2)
      ..lineTo(cx, cy - 6)
      ..lineTo(cx + 10, cy + 2)
      ..close();

    final frontPaint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(frontPath, frontPaint);

    // Ekor jarum (arah berlawanan)
    final tailPath = Path()
      ..moveTo(cx, size.height - 10)
      ..lineTo(cx - 6, cy + 2)
      ..lineTo(cx + 6, cy + 2)
      ..close();

    final tailPaint = Paint()
      ..color = AppColors.textSlate.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawPath(tailPath, tailPaint);
  }

  @override
  bool shouldRepaint(covariant _CompassNeedlePainter oldDelegate) {
    return oldDelegate.arrowColor != arrowColor;
  }
}
