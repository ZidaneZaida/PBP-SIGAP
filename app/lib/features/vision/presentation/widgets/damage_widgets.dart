import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap/core/navigation/sigap_transitions.dart';
import 'package:sigap/core/theme/app_colors.dart';
import '../../domain/models/damage_models.dart';

/// AppBar standar untuk halaman fitur SIGAP-Vision agar konsisten dengan SIGAP.
class VisionTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const VisionTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCream,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderLight.withValues(alpha: 0.75),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 62,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Kembali ke halaman sebelumnya',
                  child: IconButton(
                    tooltip: 'Kembali',
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.primaryDark,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDarkest,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSlate,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ...?actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner transparan yang menandakan hasil masih menggunakan simulasi pengujian.
class SimulationModeBanner extends StatelessWidget {
  final String? customMessage;
  final bool compact;

  const SimulationModeBanner({
    super.key,
    this.customMessage,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 8 : 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.science_outlined,
              size: 18,
              color: Color(0xFFB45309),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode Simulasi Pengujian',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  customMessage ??
                      'Analisis saat ini menggunakan MockDamageClassifier (simulasi deterministik untuk pengujian frontend), belum menggunakan model AI/Machine Learning sungguhan.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: compact ? 11.5 : 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF78350F),
                    height: 1.35,
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

/// Badge kategori kerusakan dengan pembeda warna, ikon, dan label teks yang jelas.
class DamageCategoryBadge extends StatelessWidget {
  final DamageCategory category;
  final bool large;

  const DamageCategoryBadge({
    super.key,
    required this.category,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 7 : 4,
      ),
      decoration: BoxDecoration(
        color: category.backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: category.borderColor, width: 1.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            category.icon,
            size: large ? 18 : 14,
            color: category.accentColor,
          ),
          const SizedBox(width: 6),
          Text(
            category.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: large ? 13.5 : 11.5,
              fontWeight: FontWeight.w800,
              color: category.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Indikator visual tingkat kerusakan 3 tahap (Ringan / Sedang / Berat).
class DamageSeverityMeter extends StatelessWidget {
  final DamageCategory category;

  const DamageSeverityMeter({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final activeLevel = category.severityLevel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSegment(
              label: DamageCategory.ringan.shortLabel,
              isActive: activeLevel >= 1,
              color: AppColors.safeGreen,
            ),
            const SizedBox(width: 8),
            _buildSegment(
              label: DamageCategory.sedang.shortLabel,
              isActive: activeLevel >= 2,
              color: AppColors.alertSiaga,
            ),
            const SizedBox(width: 8),
            _buildSegment(
              label: DamageCategory.berat.shortLabel,
              isActive: activeLevel >= 3,
              color: AppColors.alertAwas,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSegment({
    required String label,
    required bool isActive,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 9,
            decoration: BoxDecoration(
              color: isActive ? color : AppColors.borderLight.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive ? AppColors.primaryDarkest : AppColors.textSlate,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget penampil foto bangunan dengan proporsi terjaga serta opsional overlay
/// area indikasi kerusakan apabila classifier menyediakan bounding box.
class DamagePhotoFrame extends StatelessWidget {
  final String imagePath;
  final List<DamageBoundingBox> regions;
  final bool showRegions;
  final Color regionColor;
  final double aspectRatio;
  final VoidCallback? onTap;

  const DamagePhotoFrame({
    super.key,
    required this.imagePath,
    this.regions = const [],
    this.showRegions = false,
    this.regionColor = AppColors.alertSiaga,
    this.aspectRatio = 4 / 3,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    final fileExists = imagePath.isNotEmpty && file.existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Material(
          color: const Color(0xFF101C16),
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (fileExists)
                  Image.file(
                    file,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildMissingPhotoPlaceholder(
                      'Foto tidak dapat ditampilkan',
                    ),
                  )
                else
                  _buildMissingPhotoPlaceholder(
                    'Berkas foto tidak tersedia di perangkat',
                  ),
                if (fileExists && showRegions && regions.isNotEmpty)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: regions.map((box) {
                          final left =
                              (box.left.clamp(0.0, 0.9)) * constraints.maxWidth;
                          final top =
                              (box.top.clamp(0.0, 0.9)) * constraints.maxHeight;
                          final width = (box.width.clamp(0.08, 1.0 - box.left)) *
                              constraints.maxWidth;
                          final height =
                              (box.height.clamp(0.08, 1.0 - box.top)) *
                                  constraints.maxHeight;
                          return Positioned(
                            left: left,
                            top: top,
                            width: width,
                            height: height,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: regionColor,
                                  width: 2.2,
                                ),
                                color: regionColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.topLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: regionColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(6),
                                    bottomRight: Radius.circular(6),
                                  ),
                                ),
                                child: Text(
                                  box.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                if (fileExists && onTap != null)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.zoom_in_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Perbesar',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissingPhotoPlaceholder(String message) {
    return Container(
      color: const Color(0xFF1A2821),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.broken_image_outlined,
            color: AppColors.textMuted,
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMint,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog pratinjau penuh (zoom) foto bangunan.
void showFullScreenPhotoDialog(BuildContext context, String imagePath) {
  final file = File(imagePath);
  if (!file.existsSync()) return;

  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.9),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(file, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.7),
              child: IconButton(
                tooltip: 'Tutup pratinjau',
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Bottom sheet kontak darurat BPBD & 112 Kota Padang yang konsisten dengan SIGAP.
void showVisionEmergencyContactsSheet(BuildContext context) {
  HapticFeedback.mediumImpact();
  showSigapModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Kontak Petugas Berwenang Kota Padang',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDarkest,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Segera hubungi petugas resmi apabila bangunan menunjukkan indikasi kerusakan sedang/berat atau membahayakan keselamatan.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSlate,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _EmergencyContactCard(
            title: 'Layanan Darurat Padang Siaga 112',
            number: '112 (Bebas Pulsa 24 Jam)',
            icon: Icons.phone_in_talk_rounded,
            isUrgent: true,
            onCopy: () {
              Clipboard.setData(const ClipboardData(text: '112'));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.primaryDark,
                  content: Text(
                    'Nomor darurat 112 disalin. Hubungi segera melalui aplikasi telepon Anda.',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _EmergencyContactCard(
            title: 'PUSDALOPS BPBD Kota Padang',
            number: '(0751) 778775',
            icon: Icons.support_agent_rounded,
            isUrgent: false,
            onCopy: () {
              Clipboard.setData(const ClipboardData(text: '0751778775'));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.primaryDark,
                  content: Text(
                    'Nomor BPBD Kota Padang (0751) 778775 disalin ke papan klip.',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _EmergencyContactCard(
            title: 'Basarnas Kantor SAR Padang',
            number: '(0751) 484501',
            icon: Icons.health_and_safety_rounded,
            isUrgent: false,
            onCopy: () {
              Clipboard.setData(const ClipboardData(text: '0751484501'));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.primaryDark,
                  content: Text(
                    'Nomor Basarnas Padang (0751) 484501 disalin ke papan klip.',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _EmergencyContactCard extends StatelessWidget {
  final String title;
  final String number;
  final IconData icon;
  final bool isUrgent;
  final VoidCallback onCopy;

  const _EmergencyContactCard({
    required this.title,
    required this.number,
    required this.icon,
    required this.isUrgent,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isUrgent
            ? const Color(0xFFFEE2E2)
            : AppColors.mintAccent.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent ? const Color(0xFFFCA5A5) : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isUrgent ? const Color(0xFFDC2626) : AppColors.primaryDark,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDarkest,
                  ),
                ),
                Text(
                  number,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isUrgent
                        ? const Color(0xFFDC2626)
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onCopy,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isUrgent ? const Color(0xFFDC2626) : AppColors.primaryDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Salin',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
