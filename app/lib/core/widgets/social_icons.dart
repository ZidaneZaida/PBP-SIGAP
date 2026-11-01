import 'package:flutter/material.dart';

/// Reusable Google Logo Vector
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 20.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final paintBlue = Paint()..color = const Color(0xFF4285F4);
    final paintGreen = Paint()..color = const Color(0xFF34A853);
    final paintYellow = Paint()..color = const Color(0xFFFBBC05);
    final paintRed = Paint()..color = const Color(0xFFEA4335);

    final pathRed = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -1.75,
        -1.35,
        false,
      )
      ..close();
    canvas.drawPath(pathRed, paintRed);

    final pathYellow = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -3.1,
        -1.2,
        false,
      )
      ..close();
    canvas.drawPath(pathYellow, paintYellow);

    final pathGreen = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        1.95,
        -1.3,
        false,
      )
      ..close();
    canvas.drawPath(pathGreen, paintGreen);

    final pathBlue = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        0.65,
        -1.3,
        false,
      )
      ..lineTo(center.dx + radius * 0.95, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(pathBlue, paintBlue);

    // Inner white circle
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, innerPaint);

    // Horizontal blue bar
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTRB(center.dx - radius * 0.05, center.dy - radius * 0.22, center.dx + radius * 0.95, center.dy + radius * 0.22),
      const Radius.circular(2),
    );
    canvas.drawRRect(rrect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Reusable Facebook Logo Vector
class FacebookLogo extends StatelessWidget {
  final double size;

  const FacebookLogo({super.key, this.size = 20.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.72,
            fontWeight: FontWeight.w800,
            fontFamily: 'sans-serif',
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
