import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap/core/navigation/sigap_transitions.dart';
import 'package:sigap/core/theme/app_colors.dart';
import 'package:sigap/features/dashboard/presentation/screens/home_screen.dart';
import 'package:sigap/features/family/presentation/screens/keluarga_screen.dart';
import 'package:sigap/features/map/presentation/screens/peta_screen.dart';
import 'package:sigap/features/settings/presentation/screens/pengaturan_screen.dart';
import 'package:sigap/features/profile/presentation/screens/profile_screen.dart';

/// Screen Utama Tab Peringatan (PeringatanScreen) SIGAP Kota Padang.
///
/// Fitur:
/// - Sticky Header (Profil & Status) & Sticky Bottom Navigation Bar (Tab Peringatan Aktif).
/// - TabBar Melintang: "🚨 Info Bencana" (Default) & "📖 Buku Saku".
/// - Tab 1 (Info Bencana): Responsif 2 state dinamis (Kondisi Aman vs Kondisi Darurat).
/// - Tab 2 (Buku Saku): Panduan edukasi offline (Gempa, Tsunami, Banjir, Tas Siaga).
class PeringatanScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToFamily;
  final VoidCallback? onNavigateToMap;
  final Function(int)? onTabSelected;
  final bool initialEmergencyState;
  final bool embedded;

  const PeringatanScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToFamily,
    this.onNavigateToMap,
    this.onTabSelected,
    this.initialEmergencyState = false,
    this.embedded = false,
  });

  @override
  State<PeringatanScreen> createState() => _PeringatanScreenState();
}

class _PeringatanScreenState extends State<PeringatanScreen> with SingleTickerProviderStateMixin {
  final int _activeBottomNavIndex = 1; // 1: Peringatan (Aktif)

  // Tab Melintang: 0 = "🚨 Info Bencana", 1 = "📖 Buku Saku"
  int _selectedTabIndex = 0;

  // Dynamic State: Kondisi Aman vs Kondisi Darurat
  late bool _isEmergency;

  // Status TTS
  bool _isSpeakingTts = false;
  Timer? _ttsTimer;

  // Animasi pulsing untuk kartu darurat
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _isEmergency = widget.initialEmergencyState;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ttsTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleEmergencyMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isEmergency = !_isEmergency;
      if (!_isEmergency) {
        _isSpeakingTts = false;
        _ttsTimer?.cancel();
      }
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEmergency
              ? '🚨 Beralih ke KONDISI DARURAT: Menampilkan Kartu Peringatan Aktif Padang'
              : '🟢 Beralih ke KONDISI AMAN: Kota Padang Aman Terkendali',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _isEmergency ? const Color(0xFFDC2626) : const Color(0xFF15803D),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _speakAlert({required String title, required String instruction}) {
    HapticFeedback.heavyImpact();
    setState(() {
      _isSpeakingTts = true;
    });

    _ttsTimer?.cancel();
    _ttsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isSpeakingTts = false;
        });
      }
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF991B1B),
        content: Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '🔊 "Membacakan Arahan BMKG: $title. $instruction Segera evakuasi ke tempat tinggi!"',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    if (index == _activeBottomNavIndex) return;

    if (index == 0) {
      if (widget.onNavigateToDashboard != null) {
        widget.onNavigateToDashboard!();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else if (index == 2) {
      if (widget.onNavigateToMap != null) {
        widget.onNavigateToMap!();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PetaScreen()),
        );
      }
    } else if (index == 3) {
      if (widget.onNavigateToFamily != null) {
        widget.onNavigateToFamily!();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const KeluargaScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = Column(
      children: [
        if (!widget.embedded) _buildFixedHeader(),

        // NAVIGASI TABBAR MELINTANG: "🚨 Info Bencana" & "📖 Buku Saku"
        _buildStickyTabBar(),

        // KONTEN HALAMAN (BODY)
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _selectedTabIndex == 0
                ? _buildInfoBencanaBody()
                : _buildBukuSakuBody(),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: bodyContent,
      ),

      // ATURAN GLOBAL 2: FIXED / STICKY BOTTOM NAVIGATION BAR (Tab Peringatan Aktif)
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ==========================================
  // ATURAN GLOBAL: FIXED / STICKY HEADER
  // ==========================================
  Widget _buildFixedHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundCream,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderLight.withValues(alpha: 0.7),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar Pengguna
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryDark,
              child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),

          // Judul Header Sederhana
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Peringatan Bencana',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDarkest,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _isEmergency ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isEmergency ? 'Peringatan Darurat Aktif' : 'BMKG & BPBD Padang · Siaga',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSlate,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Switcher Kondisi Dinamis (Mode Aman <-> Simulasi Darurat)
          GestureDetector(
            onTap: _toggleEmergencyMode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _isEmergency ? const Color(0xFFFEE2E2) : AppColors.mintAccent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isEmergency ? const Color(0xFFEF4444) : const Color(0xFFB7DAC4),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _isEmergency ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isEmergency ? 'Mode: Darurat' : 'Mode: Aman',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _isEmergency ? const Color(0xFF991B1B) : const Color(0xFF065F46),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Tombol Pengaturan
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.primaryDark, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                SigapRoutes.slideRight(const PengaturanScreen()),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TABBAR MELINTANG DENGAN 2 MENU:
  // 1. "🚨 Info Bencana" (Default Aktif)
  // 2. "📖 Buku Saku"
  // ==========================================
  Widget _buildStickyTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Menu 1: "🚨 Info Bencana"
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTabIndex = 0);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? AppColors.primaryDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '🚨 Info Bencana',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _selectedTabIndex == 0 ? Colors.white : AppColors.textSlate,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Menu 2: "📖 Buku Saku"
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTabIndex = 1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? AppColors.primaryDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '📖 Buku Saku',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _selectedTabIndex == 1 ? Colors.white : AppColors.textSlate,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ISI TAB 1: INFO BENCANA (State Dinamis)
  // Responsif 2 Kondisi: Kondisi Aman vs Kondisi Darurat
  // ==========================================
  Widget _buildInfoBencanaBody() {
    return _isEmergency
        ? _buildKondisiDaruratList()
        : _buildKondisiAmanEmptyState();
  }

  // 1A. KONDISI AMAN (Empty State):
  // Ilustrasi centang hijau menenangkan, teks tebal "Kondisi Aman Terkendali",
  // dan sub-teks "Saat ini tidak ada peringatan bencana aktif dari BMKG di Kota Padang."
  Widget _buildKondisiAmanEmptyState() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Ikon Centang Hijau Menenangkan
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5), // Hijau Lembut
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFA7F3D0), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF059669),
                size: 58,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Teks Tebal: "Kondisi Aman Terkendali"
          Text(
            'Kondisi Aman Terkendali',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDarkest,
            ),
          ),

          const SizedBox(height: 10),

          // Sub-teks Wajib: "Saat ini tidak ada peringatan bencana aktif dari BMKG di Kota Padang."
          Text(
            'Saat ini tidak ada peringatan bencana aktif dari BMKG di Kota Padang.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textSlate,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 32),

          // Info Kartu Sensor & Pemantauan BMKG Padang
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.sensors_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sensor Seismik Padang: Aktif & Normal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDarkest,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.update_rounded, color: AppColors.textSlate, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Terakhir diperiksa: Baru saja • BMKG Minangkabau',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSlate,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tombol Uji Coba Mode Darurat
          OutlinedButton.icon(
            onPressed: _toggleEmergencyMode,
            icon: const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFDC2626)),
            label: Text(
              'Simulasikan Peringatan Darurat',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFDC2626),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: const Color(0xFFFEF2F2),
            ),
          ),
        ],
      ),
    );
  }

  // 1B. KONDISI DARURAT: Daftar Kartu (Card) Peringatan yang Bisa di-scroll ke Bawah
  Widget _buildKondisiDaruratList() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      children: [
        // ==========================================
        // KARTU DARURAT UTAMA (Gempa Megathrust M 6.0)
        // ==========================================
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2), // Merah Pudar
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEF4444), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris Atas: Badge Tingkat Bahaya (Merah = AWAS) & Waktu Relatif ("Baru saja")
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626), // Merah = AWAS
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            'AWAS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Waktu Relatif: "Baru saja"
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled_rounded, size: 14, color: Color(0xFF991B1B)),
                      const SizedBox(width: 4),
                      Text(
                        'Baru saja',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Bagian Tengah: Judul Tegas "Gempa Bumi M 6.0"
              Text(
                'Gempa Bumi M 6.0',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF991B1B),
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 4),

              // Teks Tipis: "Kedalaman 10 km • Jarak dari lokasi Anda: 14 km"
              Text(
                'Kedalaman 10 km • Jarak dari lokasi Anda: 14 km',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB91C1C),
                ),
              ),

              const SizedBox(height: 12),

              // WAJIB ADA: Badge Penanda Tsunami yang Mencolok "🚨 BERPOTENSI TSUNAMI"
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626), // Merah Mencolok
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '🚨 BERPOTENSI TSUNAMI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Arahan Singkat Evakuasi
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5, right: 6),
                    child: Icon(Icons.circle, size: 5, color: Color(0xFF991B1B)),
                  ),
                  Expanded(
                    child: Text(
                      'Segera evakuasi mandiri ke Gedung TES terdekat atau Zona Hijau (>15 mdpl).',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7F1D1D),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFFCA5A5)),
              const SizedBox(height: 12),

              // Baris Bawah (Footer): Teks "Sumber: BMKG" & Tombol Ikon 🔊 "Bacakan Arahan"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Kiri: Teks "Sumber: BMKG"
                  Text(
                    'Sumber: BMKG',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7F1D1D),
                    ),
                  ),

                  // Kanan: Tombol Ikon 🔊 "Bacakan Arahan" (Warna Kontras agar Mudah Dipencet)
                  ElevatedButton.icon(
                    onPressed: () => _speakAlert(
                      title: 'Gempa Bumi Magnitudo 6.0',
                      instruction: 'Berpotensi Tsunami. Jauhi wilayah pesisir pantai Padang.',
                    ),
                    icon: Icon(
                      _isSpeakingTts ? Icons.volume_up_rounded : Icons.campaign_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      'Bacakan Arahan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF991B1B), // Merah Gelap Kontras
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ==========================================
        // KARTU PERINGATAN KEDUA (Banjir Sungai Batang Arau)
        // ==========================================
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFBBF24), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B), // Kuning = WASPADA
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'WASPADA',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '25 menit lalu',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSlate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Banjir Luapan Batang Arau',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDarkest,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tinggi Muka Air (TMA) meningkat 180 cm akibat hujan hulu Bukit Barisan.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: AppColors.textSlate,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sumber: BPBD Padang',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _speakAlert(
                      title: 'Waspada Banjir Sungai Batang Arau',
                      instruction: 'Tinggi muka air meningkat. Amankan barang berharga ke tempat tinggi.',
                    ),
                    icon: const Icon(Icons.volume_up_outlined, size: 16, color: AppColors.primaryDark),
                    label: Text(
                      'Bacakan Arahan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  // ==========================================
  // ISI TAB 2: BUKU SAKU (Offline Guide)
  // 4 Panduan Edukasi Sederhana:
  // - Item 1: 🫨 Panduan Saat Gempa
  // - Item 2: 🌊 Panduan Evakuasi Tsunami
  // - Item 3: 🌧️ Saat Terjadi Banjir
  // - Item 4: 🎒 Checklist Tas Siaga
  // ==========================================
  Widget _buildBukuSakuBody() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      children: [
        // Subtitle Buku Saku
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 4),
          child: Text(
            'Panduan Siaga Darurat (Bisa Dibaca Offline)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSlate,
            ),
          ),
        ),

        // Item 1: 🫨 Panduan Saat Gempa
        _buildBukuSakuItem(
          emoji: '🫨',
          title: 'Panduan Saat Gempa',
          subtitle: 'Drop, Cover, Hold On & Lindungi Kepala',
          onTap: () => _showGuideDetail(
            title: 'Panduan Saat Gempa',
            emoji: '🫨',
            points: [
              '1. Berlutut, Lindungi Kepala, dan Berlindung di bawah meja kokoh (Drop, Cover, Hold On).',
              '2. Jauhi jendela kaca, cermin, dan benda gantung yang rawan roboh.',
              '3. Jika berada di luar ruangan, jauhi tiang listrik, baliho, dan lereng perbukitan.',
              '4. Setelah guncangan mereda, periksa bahaya kebakaran dan segera keluar menuju tanah lapang.',
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Item 2: 🌊 Panduan Evakuasi Tsunami
        _buildBukuSakuItem(
          emoji: '🌊',
          title: 'Panduan Evakuasi Tsunami',
          subtitle: 'Aturan 20-20-20 & Menuju Zona Hijau >15 mdpl',
          onTap: () => _showGuideDetail(
            title: 'Panduan Evakuasi Tsunami',
            emoji: '🌊',
            points: [
              '1. Kenali Rumus 20-20-20: Jika gempa terasa 20 detik, Anda punya 20 menit untuk lari ke elevasi 20 meter.',
              '2. Jika air laut surut tiba-tiba atau tercium bau garam pekat, segera lari tanpa menunggu peringatan sirine.',
              '3. Jangan gunakan mobil atau motor karena memicu kemacetan total; berjalan kaki atau berlari jauh lebih efektif.',
              '4. Manfaatkan Tempat Evakuasi Sementara (TES) bertingkat kokoh jika tidak sempat mencapai perbukitan.',
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Item 3: 🌧️ Saat Terjadi Banjir
        _buildBukuSakuItem(
          emoji: '🌧️',
          title: 'Saat Terjadi Banjir',
          subtitle: 'Matikan Sekring Listrik & Waspadai Arus Deras',
          onTap: () => _showGuideDetail(
            title: 'Saat Terjadi Banjir',
            emoji: '🌧️',
            points: [
              '1. Segera matikan sekring utama listrik dan putuskan regulator tabung gas.',
              '2. Amankan surat berharga (ijazah, sertifikat, KK) ke dalam kantong plastik kedap air.',
              '3. Hindari berjalan atau menyeberangi arus banjir melebihi batas lutut karena rentan terseret.',
              '4. Waspadai hewan berbisa (ular/kalajengking) yang ikut terbawa genangan banjir.',
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Item 4: 🎒 Checklist Tas Siaga
        _buildBukuSakuItem(
          emoji: '🎒',
          title: 'Checklist Tas Siaga',
          subtitle: 'Perlengkapan 72 Jam Bertahan Hidup Mandiri',
          onTap: () => _showGuideDetail(
            title: 'Checklist Tas Siaga',
            emoji: '🎒',
            points: [
              '1. Air minum botol (min. 3 liter per anggota keluarga) & biskuit/makanan kaleng siap santap.',
              '2. Kotak P3K, obat rutin pribadi, plester luka, dan antiseptik.',
              '3. Senter LED baterai cadangan, peluit darurat frekuensi tinggi, dan korek api kedap air.',
              '4. Powerbank baterai penuh, fotokopi KTP/KK, uang tunai secukupnya, dan baju ganti hangat.',
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBukuSakuItem({
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Ikon Besar di Kiri
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.mintAccent.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Judul Teks Tebal di Tengah & Sub-teks
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDarkest,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: AppColors.textSlate,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Ikon Panah di Kanan
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSlate,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGuideDetail({
    required String title,
    required String emoji,
    required List<String> points,
  }) {
    HapticFeedback.lightImpact();
    showSigapModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDarkest,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...points.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.primaryDarkest,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'SAYA MENGERTI',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ATURAN GLOBAL: FIXED BOTTOM NAVIGATION BAR
  // 4 Menu: 1. Beranda, 2. Peringatan (Aktif), 3. Peta Siaga, 4. Keluarga
  // ==========================================
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.borderLight.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _activeBottomNavIndex,
        onTap: _onBottomNavTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.textSlate,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_rounded),
            activeIcon: Icon(Icons.warning_rounded),
            label: 'Peringatan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map_rounded),
            label: 'Peta Siaga',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.family_restroom_outlined),
            activeIcon: Icon(Icons.family_restroom_rounded),
            label: 'Keluarga',
          ),
        ],
      ),
    );
  }
}
