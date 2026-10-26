import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:sigap/features/family/presentation/screens/family_assistance_screen.dart';
import 'package:sigap/features/map/presentation/screens/risk_map_screen.dart';
import 'package:sigap/features/settings/presentation/screens/settings_screen.dart';
import 'package:sigap/features/profile/presentation/screens/profile_screen.dart';

/// Screen Peringatan Bencana SIGAP Kota Padang
/// Mengimplementasikan secara presisi desain:
/// "SIGAP mobile — Peringatan — iPhone 17 Pro.svg"
///
/// Fitur:
/// - Header: Logo SIGAP, Waktu Padang (PDG 09:41), Pengaturan & Akun
/// - Judul: "Peringatan bencana" + "2 aktif · wilayah padang dan sekitar"
/// - Section AKTIF:
///   1. Kartu Siaga: "Gempa bumi M5.8" (Badge: SIAGA di background #FFF7F2)
///   2. Kartu Waspada: "Banjir sungai Batang" (Badge: WASPADA di background white)
/// - Section RIWAYAT:
///   1. "3 hari lalu · gempa m4.2, tidak berdampak" + detail ->
///   2. "1 minggu lalu · longsor jalur alternatif" + detail ->
/// - Modal Detail Peringatan Resmi (BMKG / BPBD Kota Padang)
/// - Bottom Navigation Bar (Tab Peringatan aktif)
class AlertsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToFamily;
  final VoidCallback? onNavigateToMap;
  final Function(int)? onTabSelected;

  const AlertsScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToFamily,
    this.onNavigateToMap,
    this.onTabSelected,
  });

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final int _activeTab = 1; // 1: Peringatan (Active)

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.backgroundCream,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _showDetailAlert({
    required String title,
    required String severity,
    required Color severityBg,
    required Color severityColor,
    required String time,
    required String location,
    required String source,
    required String description,
    required List<String> instructions,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    severity,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: severityColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSlate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Wilayah: $location\nSumber: $source',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: AppColors.textSlate,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              description,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.textDark,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: 12),
            Text(
              'Instruksi Tindakan Resmi:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            ...instructions.map(
              (inst) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        inst,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textDark,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.borderLight),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tautan peringatan disalin ke papan klip!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: Text(
                      'Bagikan',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==========================================
              // 1. TOP HEADER (SIGAP · PDG 09:41 · ICONS)
              // Sesuai Figma y=0..105
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Text(
                      'SIGAP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'PDG · 09:41',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (context, a1, a2) => SettingsScreen(
                              onNavigateToDashboard: () {
                                Navigator.of(context).pop();
                              },
                              onNavigateToAlerts: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.settings_outlined,
                        size: 21,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (context, a1, a2) => ProfileScreen(
                              onNavigateToDashboard: () => Navigator.of(context).pop(),
                              onNavigateToAlerts: () => Navigator.of(context).pop(),
                              onNavigateToMap: () => Navigator.of(context).pop(),
                              onNavigateToFamily: () => Navigator.of(context).pop(),
                            ),
                            transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 22,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // 2. JUDUL HALAMAN: "Peringatan bencana"
              // Sesuai Figma y=110..220
              // ==========================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Peringatan bencana',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '2 aktif · wilayah padang dan sekitar',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSlate,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ==========================================
                    // 3. SECTION AKTIF (2 KARTU AKTIF)
                    // ==========================================
                    Text(
                      'AKTIF',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSlate,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // KARTU 1: Gempa bumi M5.8 (Badge: SIAGA, Background #FFF7F2)
                    InkWell(
                      onTap: () {
                        _showDetailAlert(
                          title: 'Gempa bumi M5.8',
                          severity: 'SIAGA',
                          severityBg: AppColors.alertTerracotta,
                          severityColor: Colors.white,
                          time: '08:42 WIB',
                          location: '24 km Barat Daya Kota Padang, Sumbar',
                          source: 'BMKG Stasiun Geofisika Padang Panjang',
                          description:
                              'Gempa bumi tektonik dangkal berpusat di laut, dirasakan skala MMI III-IV di Kota Padang dan sekitarnya. Tidak berpotensi tsunami.',
                          instructions: [
                            'Periksa kondisi bangunan rumah dari retakan struktur.',
                            'Jauhi lereng rawan longsor di kawasan perbukitan Padang.',
                            'Waspadai potensi gempa susulan dalam 24 jam ke depan.',
                            'Gunakan titik kumpul evakuasi jika berada di area padat bangunan.',
                          ],
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.alertPeach,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.alertBorderPeach, width: 1.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.alertTerracotta,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'SIAGA',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Gempa bumi M5.8',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '08:42 · padang, sumbar · kedalaman 10km',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSlate,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // KARTU 2: Banjir sungai Batang (Badge: WASPADA, Background White)
                    InkWell(
                      onTap: () {
                        _showDetailAlert(
                          title: 'Banjir sungai Batang',
                          severity: 'WASPADA',
                          severityBg: AppColors.mintAccent,
                          severityColor: AppColors.textDark,
                          time: 'Kemarin, 16:30 WIB',
                          location: 'DAS Batang Kuranji & Batang Arau, Padang',
                          source: 'BPBD Kota Padang & BMKG Maritim',
                          description:
                              'Peningkatan debit air sungai akibat curah hujan tinggi di hulu Bukit Barisan. Potensi luapan di pemukiman bantaran sungai.',
                          instructions: [
                            'Amankan dokumen penting dan peralatan elektronik ke tempat lebih tinggi.',
                            'Matikan aliran listrik jika air mulai memasuki rumah.',
                            'Pantau peringatan tinggi muka air sungai secara berkala.',
                          ],
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight, width: 1.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.mintAccent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'WASPADA',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Banjir sungai Batang',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'kemarin · padang, sumbar',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSlate,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ==========================================
                    // 4. SECTION RIWAYAT
                    // Sesuai Figma y=665.5..912
                    // ==========================================
                    Text(
                      'RIWAYAT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSlate,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 14),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight, width: 1.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item 1: Gempa M4.2
                          Text(
                            '3 hari lalu · gempa m4.2, tidak berdampak',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              _showDetailAlert(
                                title: 'Gempa bumi M4.2',
                                severity: 'RIWAYAT',
                                severityBg: AppColors.borderLight,
                                severityColor: AppColors.textSlate,
                                time: '3 hari lalu',
                                location: 'Pesisir Selatan - Padang',
                                source: 'BMKG Padang Panjang',
                                description:
                                    'Gempa tektonik kecil, dirasakan sangat lemah di Padang. Tidak ada kerusakan.',
                                instructions: ['Peringatan telah berakhir dan kondisi normal.'],
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'detail',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textDark),
                              ],
                            ),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Divider(height: 1, color: AppColors.borderLight),
                          ),

                          // Item 2: Longsor jalur alternatif
                          Text(
                            '1 minggu lalu · longsor jalur alternatif',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              _showDetailAlert(
                                title: 'Longsor Jalur Alternatif Sitinjau Lauik',
                                severity: 'RIWAYAT',
                                severityBg: AppColors.borderLight,
                                severityColor: AppColors.textSlate,
                                time: '1 minggu lalu',
                                location: 'Jalan Raya Padang - Solok',
                                source: 'BPBD Kota Padang & Kepolisian',
                                description:
                                    'Longsoran tebing telah dibersihkan oleh alat berat. Jalur kembali dapat dilalui secara normal.',
                                instructions: ['Tetap berhati-hati saat hujan deras di jalur perbukitan.'],
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'detail',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textDark),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ==========================================
      // 5. BOTTOM NAVIGATION BAR
      // Sesuai Figma rects: 4 Tab Pills di y=947
      // Tab 1 (Peringatan) AKTIF (Mint #E8F3EC)
      // ==========================================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.7), width: 1.0),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _buildNavPill(
                index: 0,
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                onTap: () {
                  if (widget.onNavigateToDashboard != null) {
                    widget.onNavigateToDashboard!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
              _buildNavPill(
                index: 1,
                icon: Icons.notifications_active_rounded,
                label: 'Peringatan',
                onTap: () {},
              ),
              _buildNavPill(
                index: 2,
                icon: Icons.map_rounded,
                label: 'Peta risiko',
                onTap: () {
                  if (widget.onNavigateToMap != null) {
                    widget.onNavigateToMap!();
                  } else {
                    Navigator.of(context).pushReplacement(
                      PageRouteBuilder(
                        pageBuilder: (context, a1, a2) => RiskMapScreen(
                          onNavigateToDashboard: () {
                            Navigator.of(context).pop();
                          },
                          onNavigateToAlerts: () {
                            Navigator.of(context).pushReplacement(
                              PageRouteBuilder(
                                pageBuilder: (context, a1, a2) => AlertsScreen(
                                  onNavigateToDashboard: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
                              ),
                            );
                          },
                          onNavigateToFamily: () {
                            Navigator.of(context).pushReplacement(
                              PageRouteBuilder(
                                pageBuilder: (context, a1, a2) => FamilyAssistanceScreen(
                                  onNavigateToDashboard: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
                              ),
                            );
                          },
                        ),
                        transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
                      ),
                    );
                  }
                },
              ),
              _buildNavPill(
                index: 3,
                icon: Icons.group_rounded,
                label: 'Keluarga & Bantuan',
                onTap: () {
                  if (widget.onNavigateToFamily != null) {
                    widget.onNavigateToFamily!();
                  } else {
                    Navigator.of(context).pushReplacement(
                      PageRouteBuilder(
                        pageBuilder: (context, a1, a2) => FamilyAssistanceScreen(
                          onNavigateToDashboard: () {
                            Navigator.of(context).pop();
                          },
                          onNavigateToAlerts: () {
                            Navigator.of(context).pushReplacement(
                              PageRouteBuilder(
                                pageBuilder: (context, a1, a2) => AlertsScreen(
                                  onNavigateToDashboard: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
                              ),
                            );
                          },
                        ),
                        transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavPill({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final bool isActive = _activeTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? AppColors.mintAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? AppColors.primaryDark : AppColors.textSlate,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  color: isActive ? AppColors.primaryDark : AppColors.textSlate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
