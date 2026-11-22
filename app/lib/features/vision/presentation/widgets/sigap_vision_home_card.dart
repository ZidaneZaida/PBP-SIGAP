import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap/core/navigation/sigap_transitions.dart';
import 'package:sigap/core/theme/app_colors.dart';
import '../../data/damage_report_repository.dart';
import '../../domain/models/damage_models.dart';
import '../screens/damage_history_screen.dart';
import '../screens/sigap_vision_screen.dart';

/// Kartu akses fitur SIGAP-Vision pada halaman Beranda SIGAP.
///
/// Dirancang selaras dengan identitas visual SIGAP (emerald, mint, cream)
/// sehingga mudah ditemukan tanpa mendominasi keseluruhan halaman Beranda.
class SigapVisionHomeCard extends StatefulWidget {
  final VoidCallback? onStartScan;
  final VoidCallback? onOpenHistory;

  const SigapVisionHomeCard({
    super.key,
    this.onStartScan,
    this.onOpenHistory,
  });

  @override
  State<SigapVisionHomeCard> createState() => _SigapVisionHomeCardState();
}

class _SigapVisionHomeCardState extends State<SigapVisionHomeCard> {
  @override
  void initState() {
    super.initState();
    // Muat ringkasan jumlah riwayat lokal tanpa mengganggu build Beranda
    DamageReportRepository.instance
        .loadReports()
        .catchError((_) => const <DamageScanReport>[]);
  }

  void _openVision(BuildContext context) {
    HapticFeedback.mediumImpact();
    if (widget.onStartScan != null) {
      widget.onStartScan!();
      return;
    }
    Navigator.of(context).push(
      SigapRoutes.slideRight(const SigapVisionScreen()),
    );
  }

  void _openHistory(BuildContext context) {
    HapticFeedback.selectionClick();
    if (widget.onOpenHistory != null) {
      widget.onOpenHistory!();
      return;
    }
    Navigator.of(context).push(
      SigapRoutes.slideRight(const DamageHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primaryMedium,
            AppColors.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    color: Colors.white,
                    size: 26,
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
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.mintAccent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'FITUR BARU • OFFLINE SIAGA',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMint,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'SIGAP-Vision — Pindai Kerusakan Bangunan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Periksa indikasi kerusakan bangunan setelah gempa melalui foto.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMint,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _openVision(context),
                      icon: const Icon(
                        Icons.camera_alt_rounded,
                        size: 20,
                      ),
                      label: Text(
                        'Mulai Pemindaian',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.backgroundCream,
                        foregroundColor: AppColors.primaryDarkest,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ValueListenableBuilder(
                  valueListenable:
                      DamageReportRepository.instance.reportsNotifier,
                  builder: (context, reports, _) {
                    return SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _openHistory(context),
                        icon: const Icon(
                          Icons.history_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          reports.isEmpty
                              ? 'Riwayat'
                              : 'Riwayat (${reports.length})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
