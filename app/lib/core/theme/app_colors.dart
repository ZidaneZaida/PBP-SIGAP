import 'package:flutter/material.dart';

/// Palet warna resmi aplikasi SIGAP berdasarkan Design System & Mockup Figma
class AppColors {
  // Primary Greens (Background Header, Branding, Active Buttons)
  static const Color primaryDarkest = Color(0xFF11261B);
  static const Color primaryDark = Color(0xFF1A3A2A);
  static const Color primaryMedium = Color(0xFF244838);
  static const Color primary = Color(0xFF2F5B4A);
  static const Color primaryLight = Color(0xFF3B6E59);

  // Mint & Cream (Light theme backgrounds & accents)
  static const Color backgroundCream = Color(0xFFF7F4EE);
  static const Color mintAccent = Color(0xFFE8F3EC);
  static const Color mintSurface = Color(0xFFF3F9F5);
  static const Color borderLight = Color(0xFFD7E0D8);
  static const Color cardCream = Color(0xFFE7E1D8);

  // Alert & Warning Shades (Sesuai Mockup Dashboard)
  static const Color alertPeach = Color(0xFFFFF7F2);
  static const Color alertBorderPeach = Color(0xFFE8C7B8);
  static const Color alertTerracotta = Color(0xFFC46B4F);
  static const Color alertRust = Color(0xFFA64B2A);

  // Typography & Tints
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A3A2A);
  static const Color textSlate = Color(0xFF6B7A8C);
  static const Color textMint = Color(0xFFD8E7E2);
  static const Color textMuted = Color(0xFF9CB8AD);

  // Alert Severity Colors (Berdasarkan BRD: Waspada, Siaga, Awas)
  static const Color alertWaspada = Color(0xFFF59E0B); // Amber / Kuning
  static const Color alertSiaga = Color(0xFFF97316);   // Orange
  static const Color alertAwas = Color(0xFFEF4444);    // Merah Darurat
  static const Color safeGreen = Color(0xFF10B981);    // Status Aman

  // Gradient Background Utama SIGAP (Sesuai SVG Mockup x1:0 y1:0 to x2:390)
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryDark,
      primaryMedium,
      primary,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Modern Luxury Gradients & Glassmorphism Tokens
  static const LinearGradient emeraldLuxuryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0E2218),
      Color(0xFF1A3A2A),
      Color(0xFF224E38),
    ],
  );

  static const LinearGradient sunsetAlertGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF7A59),
      Color(0xFFC44D29),
    ],
  );

  static const LinearGradient oceanWaveGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0277BD),
      Color(0xFF00ACC1),
    ],
  );

  static const LinearGradient safeGreenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF10B981),
      Color(0xFF059669),
    ],
  );

  static const Color glassWhite = Color(0xEBFFFFFF);
  static const Color glassBorder = Color(0x66FFFFFF);
  static const Color neonMint = Color(0xFF22C55E);
  static const Color oceanCyan = Color(0xFF0284C7);
  static const Color vibrantAmber = Color(0xFFF59E0B);
}
