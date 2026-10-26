import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap/core/theme/app_colors.dart';
import 'package:sigap/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:sigap/features/family/presentation/screens/family_assistance_screen.dart';
import 'package:sigap/features/map/presentation/screens/risk_map_screen.dart';
import 'package:sigap/features/settings/presentation/screens/settings_screen.dart';
import 'package:sigap/features/profile/presentation/screens/profile_screen.dart';

/// Screen Dashboard SIGAP Kota Padang
/// Mengimplementasikan secara presisi desain:
/// "SIGAP mobile — Dashboard — iPhone 17 Pro.svg"
///
/// Komponen & Fitur:
/// - Header: Logo SIGAP, Waktu Padang (PDG 09:41), Pengaturan & Akun
/// - Judul: "Dashboard" + "Ringkasan kondisi terkini · Padang, Sumatera Barat"
/// - Kartu Peringatan Aktif: "Gempa bumi M5.8" + Tombol "LIHAT PERINGATAN"
/// - 4 Kartu Tindakan Cepat (Grid 2x2): "SAYA AMAN", "BUTUH BANTUAN", "PETA RISIKO", "HUBUNGI DARURAT"
/// - Kartu Risiko Lokasi Anda: "Potensi banjir" (Status: SEDANG)
/// - Kartu Keluarga & Bantuan: Daftar anggota (Ibu AMAN, Ayah BELUM TERHUBUNG, Adik PERLU KONFIRMASI)
/// - Kartu Pembaruan Terakhir (Timeline log kejadian terkini)
/// - Bottom Navigation Bar (4 tab kustom sesuai mockup: Dashboard, Peringatan, Peta risiko, Keluarga & Bantuan)
class DashboardScreen extends StatefulWidget {
  final String userName;

  const DashboardScreen({
    super.key,
    this.userName = 'Warga Padang',
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _activeTab = 0; // 0: Dashboard, 1: Peringatan, 2: Peta risiko, 3: Keluarga

  // Status Keamanan Pengguna
  bool _isSafe = true;
  String _userSafetyTime = 'baru saja';
  String _userLocationNote = 'rumah';
  bool _shareLocation = true;

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

  // ==========================================
  // MODAL / DIALOG HANDLERS
  // ==========================================

  void _showSayaAmanDialog() {
    final noteController = TextEditingController(text: _userLocationNote);
    bool shareLoc = _shareLocation;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.mintAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shield_rounded, color: AppColors.primaryDark, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konfirmasi Status: SAYA AMAN',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'Keluarga terdekat akan segera melihat status ini',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: AppColors.textSlate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Keterangan Kondisi / Lokasi (Opsional)',
                  labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSlate),
                  hintText: 'Misal: di rumah bersama keluarga, kondisi aman',
                  filled: true,
                  fillColor: AppColors.backgroundCream,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // BRD FR-24: Berbagi lokasi hanya bila dicentang secara sadar
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: shareLoc,
                activeColor: AppColors.primaryDark,
                title: Text(
                  'Sertakan titik lokasi perkiraan (Padang Barat)',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textDark),
                ),
                onChanged: (val) {
                  setModalState(() {
                    shareLoc = val ?? true;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isSafe = true;
                    _userSafetyTime = 'baru saja';
                    _userLocationNote = noteController.text.trim().isEmpty ? 'rumah' : noteController.text.trim();
                    _shareLocation = shareLoc;
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Status "Saya Aman" berhasil diperbarui dan dibagikan!',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: AppColors.safeGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'Kirim Status Aman',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showButuhBantuanDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.alertPeach,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_rounded, color: AppColors.alertRust, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pemberitahuan: BUTUH BANTUAN',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Pilih kondisi darurat Anda saat ini di Kota Padang',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textSlate),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildEmergencyOption(
              icon: Icons.personal_injury_rounded,
              title: 'Butuh Bantuan Medis / Evakuasi',
              subtitle: 'Kondisi luka atau terjebak reruntuhan/banjir',
            ),
            const SizedBox(height: 10),
            _buildEmergencyOption(
              icon: Icons.family_restroom_rounded,
              title: 'Anggota Keluarga Hilang / Terpisah',
              subtitle: 'Terputus kontak saat evakuasi bencana',
            ),
            const SizedBox(height: 10),
            _buildEmergencyOption(
              icon: Icons.fastfood_rounded,
              title: 'Butuh Logistik / Air Bersih',
              subtitle: 'Posko atau rumah isolasi kekurangan logistik',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isSafe = false;
                  _userSafetyTime = 'baru saja';
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Status darurat "BUTUH BANTUAN" telah dikirimkan ke keluarga dan relawan!'),
                    backgroundColor: AppColors.alertRust,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.alertRust,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Kirim Sinyal Bantuan',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyOption({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.alertRust, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSlate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHubungiDaruratSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Layanan Darurat Kota Padang',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            Text(
              'Panggilan langsung tanpa perantara ke pihak berwenang',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSlate),
            ),
            const SizedBox(height: 18),
            _buildContactRow(name: 'Call Center Darurat Padang', number: '112', tag: 'Bebas Pulsa / 24 Jam', isPrimary: true),
            const SizedBox(height: 10),
            _buildContactRow(name: 'BPBD Kota Padang', number: '(0751) 778775', tag: 'Pusdalops Bencana'),
            const SizedBox(height: 10),
            _buildContactRow(name: 'Basarnas Pos SAR Padang', number: '(0751) 484344', tag: 'Pencarian & Penyelamatan'),
            const SizedBox(height: 10),
            _buildContactRow(name: 'PMI Kota Padang', number: '(0751) 23812', tag: 'Ambulans & Medis'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow({
    required String name,
    required String number,
    required String tag,
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.mintAccent : AppColors.backgroundCream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isPrimary ? AppColors.primary : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(Icons.phone_in_talk_rounded, color: isPrimary ? AppColors.primaryDark : AppColors.textDark, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textDark)),
                Text('$number · $tag', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSlate)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call_rounded, color: AppColors.safeGreen),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Menghubungkan panggilan ke $number ($name)...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDetailPeringatanDialog() {
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.alertPeach,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.alertBorderPeach),
              ),
              child: Text(
                'PERINGATAN RESMI BMKG',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.alertRust,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Gempa bumi M5.8',
              style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              'Waktu Kejadian: Hari ini, 08:42 WIB\nPusat Gempa: 24 km Barat Daya Kota Padang\nKedalaman: 10 km (Gempa Dangkal)',
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.textSlate, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: 12),
            Text(
              'Instruksi Keselamatan Bagi Warga Padang:',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              '1. Jauhi gedung bertingkat dan bangunan dengan keretakan struktur.\n2. Bersiap di area terbuka atau titik kumpul terdekat (GOR H. Agus Salim, Lapangan Imam Bonjol).\n3. Waspadai gempa susulan (*aftershocks*).\n4. Tidak berpotensi tsunami di pesisir Kota Padang.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textDark, height: 1.5),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _navigateToAlerts();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.borderLight),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Buka Peringatan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Tutup', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAlerts() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => AlertsScreen(
          onNavigateToDashboard: () {
            Navigator.of(context).pop();
          },
          onNavigateToFamily: () {
            Navigator.of(context).pop();
            _navigateToFamilyAssistance();
          },
          onNavigateToMap: () {
            Navigator.of(context).pop();
            _navigateToRiskMap();
          },
        ),
        transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _navigateToFamilyAssistance() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => FamilyAssistanceScreen(
          onNavigateToDashboard: () {
            Navigator.of(context).pop();
          },
          onNavigateToAlerts: () {
            Navigator.of(context).pop();
            _navigateToAlerts();
          },
          onNavigateToMap: () {
            Navigator.of(context).pop();
            _navigateToRiskMap();
          },
        ),
        transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _navigateToRiskMap() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => RiskMapScreen(
          onNavigateToDashboard: () {
            Navigator.of(context).pop();
          },
          onNavigateToAlerts: () {
            Navigator.of(context).pop();
            _navigateToAlerts();
          },
          onNavigateToFamily: () {
            Navigator.of(context).pop();
            _navigateToFamilyAssistance();
          },
        ),
        transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => SettingsScreen(
          onNavigateToDashboard: () {
            Navigator.of(context).pop();
          },
          onNavigateToAlerts: () {
            Navigator.of(context).pop();
            _navigateToAlerts();
          },
          onNavigateToMap: () {
            Navigator.of(context).pop();
            _navigateToRiskMap();
          },
          onNavigateToFamily: () {
            Navigator.of(context).pop();
            _navigateToFamilyAssistance();
          },
        ),
        transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => ProfileScreen(
          onNavigateToDashboard: () {
            Navigator.of(context).pop();
          },
          onNavigateToAlerts: () {
            Navigator.of(context).pop();
            _navigateToAlerts();
          },
          onNavigateToMap: () {
            Navigator.of(context).pop();
            _navigateToRiskMap();
          },
          onNavigateToFamily: () {
            Navigator.of(context).pop();
            _navigateToFamilyAssistance();
          },
          onNavigateToSettings: () {
            Navigator.of(context).pop();
            _navigateToSettings();
          },
        ),
        transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
        transitionDuration: const Duration(milliseconds: 250),
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
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    // Brand Text "SIGAP"
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
                    // Local Time Badge: "PDG · 09:41"
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
                    // Gear / Settings Icon
                    GestureDetector(
                      onTap: _navigateToSettings,
                      child: const Icon(
                        Icons.settings_outlined,
                        size: 21,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Profile Icon
                    GestureDetector(
                      onTap: _navigateToProfile,
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
              // 2. DASHBOARD TITLE & SUBTITLE
              // Sesuai Figma y=120..270
              // ==========================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Dashboard',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ringkasan kondisi terkini · Padang, Sumatera Barat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSlate,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'diperbarui 09:40',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSlate,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),

              // ==========================================
              // 3. KARTU PERINGATAN AKTIF · PALING MENDESAK
              // Sesuai Figma y=294.5 w=349 h=310
              // ==========================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.alertPeach,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.alertBorderPeach, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PERINGATAN AKTIF · PALING MENDESAK',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSlate,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                        '08:42 · 24 km barat daya Padang · kedalaman 10 km',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSlate,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Jauhi bangunan retak dan pantau arahan resmi.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Button "LIHAT PERINGATAN"
                      SizedBox(
                        width: double.infinity,
                        height: 47,
                        child: OutlinedButton(
                          onPressed: _showDetailPeringatanDialog,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.alertTerracotta, width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'LIHAT PERINGATAN',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.alertRust,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ==========================================
              // 4. TINDAKAN CEPAT (2x2 GRID CARDS)
              // Sesuai Figma y=580..1020
              // ==========================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TINDAKAN CEPAT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSlate,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Baris 1: SAYA AMAN & BUTUH BANTUAN
                    Row(
                      children: [
                        // Card 1: SAYA AMAN (Active Dark Green)
                        Expanded(
                          child: InkWell(
                            onTap: _showSayaAmanDialog,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 145,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.borderLight, width: 1.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.shield_rounded,
                                    color: AppColors.mintAccent,
                                    size: 22,
                                  ),
                                  const Spacer(),
                                  Text(
                                    'SAYA AMAN',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Bagikan ke orang terdekat',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.textMint.withValues(alpha: 0.9),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Card 2: BUTUH BANTUAN (White Card)
                        Expanded(
                          child: InkWell(
                            onTap: _showButuhBantuanDialog,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 145,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.borderLight, width: 1.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.waving_hand_rounded,
                                    color: AppColors.textDark,
                                    size: 20,
                                  ),
                                  const Spacer(),
                                  Text(
                                    'BUTUH\nBANTUAN',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pilih kondisi dan berbagi lokasi',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      color: AppColors.textSlate,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Baris 2: PETA RISIKO & HUBUNGI DARURAT
                    Row(
                      children: [
                        // Card 3: PETA RISIKO
                        Expanded(
                          child: InkWell(
                            onTap: _navigateToRiskMap,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 150,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.borderLight, width: 1.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.flag_rounded,
                                    color: AppColors.textDark,
                                    size: 21,
                                  ),
                                  const Spacer(),
                                  Text(
                                    'PETA RISIKO',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Lihat bahaya di sekitar',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.textSlate,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Card 4: HUBUNGI DARURAT
                        Expanded(
                          child: InkWell(
                            onTap: _showHubungiDaruratSheet,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 150,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.borderLight, width: 1.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.phone_rounded,
                                    color: AppColors.textDark,
                                    size: 20,
                                  ),
                                  const Spacer(),
                                  Text(
                                    'HUBUNGI\nDARURAT',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Layanan mengikuti wilayah',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      color: AppColors.textSlate,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ==========================================
              // 5. RISIKO LOKASI ANDA (POTENSI BANJIR - SEDANG)
              // Sesuai Figma y=1035.5 w=349 h=184
              // ==========================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RISIKO LOKASI ANDA',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSlate,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.mintAccent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'SEDANG',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Potensi banjir',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kec. Padang Barat · hujan sedang',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSlate,
                        ),
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: _navigateToRiskMap,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'lihat peta risiko',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ==========================================
              // 6. KELUARGA & BANTUAN CARD
              // Sesuai Figma y=1240.5 w=349 h=474
              // ==========================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keluarga & Bantuan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '1 aman · 1 belum terhubung · 1 perlu konfirmasi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          color: AppColors.textSlate,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Member 0: User sendiri
                      _buildFamilyItem(
                        name: 'Anda (${widget.userName})',
                        detail: '$_userLocationNote · $_userSafetyTime',
                        badgeText: _isSafe ? 'AMAN' : 'BUTUH BANTUAN',
                        badgeBg: _isSafe ? AppColors.mintAccent : AppColors.alertPeach,
                        badgeColor: _isSafe ? AppColors.textDark : AppColors.alertRust,
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: AppColors.borderLight),
                      ),

                      // Member 1: Ibu
                      _buildFamilyItem(
                        name: 'Ibu',
                        detail: 'rumah · 2 menit lalu',
                        badgeText: 'AMAN',
                        badgeBg: AppColors.mintAccent,
                        badgeColor: AppColors.textDark,
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: AppColors.borderLight),
                      ),

                      // Member 2: Ayah
                      _buildFamilyItem(
                        name: 'Ayah',
                        detail: 'lokasi tidak diketahui',
                        badgeText: 'BELUM TERHUBUNG',
                        badgeBg: AppColors.alertPeach,
                        badgeColor: AppColors.alertRust,
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: AppColors.borderLight),
                      ),

                      // Member 3: Adik
                      _buildFamilyItem(
                        name: 'Adik',
                        detail: 'sekolah · 40 menit lalu',
                        badgeText: 'PERLU KONFIRMASI',
                        badgeBg: AppColors.alertPeach,
                        badgeColor: AppColors.alertRust,
                      ),

                      const SizedBox(height: 22),

                      GestureDetector(
                        onTap: _navigateToFamilyAssistance,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'lihat semua',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ==========================================
              // 7. PEMBARUAN TERAKHIR (TIMELINE LOG)
              // Sesuai Figma y=1735.5 w=349 h=261
              // ==========================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PEMBARUAN TERAKHIR',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSlate,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Log Item 1
                      _buildLogItem(
                        time: '09:38',
                        text: 'Ibu menandai status Aman.',
                      ),
                      const SizedBox(height: 14),

                      // Log Item 2
                      _buildLogItem(
                        time: '09:24',
                        text: 'Posko GOR Agus Salim masih tersedia.',
                      ),
                      const SizedBox(height: 14),

                      // Log Item 3
                      _buildLogItem(
                        time: '08:42',
                        text: 'Peringatan gempa M5.8 diterbitkan.',
                      ),

                      const SizedBox(height: 18),

                      GestureDetector(
                        onTap: () {},
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'semua',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),

      // ==========================================
      // 8. BOTTOM NAVIGATION BAR
      // Sesuai Figma rects: 4 Tab Pills di y=2031
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
              ),
              _buildNavPill(
                index: 1,
                icon: Icons.notifications_active_rounded,
                label: 'Peringatan',
              ),
              _buildNavPill(
                index: 2,
                icon: Icons.map_rounded,
                label: 'Peta risiko',
              ),
              _buildNavPill(
                index: 3,
                icon: Icons.group_rounded,
                label: 'Keluarga & Bantuan',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyItem({
    required String name,
    required String detail,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          detail,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.textSlate,
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem({
    required String time,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            time,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavPill({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isActive = _activeTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 1) {
            _navigateToAlerts();
          } else if (index == 2) {
            _navigateToRiskMap();
          } else if (index == 3) {
            _navigateToFamilyAssistance();
          } else {
            setState(() {
              _activeTab = index;
            });
          }
        },
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
