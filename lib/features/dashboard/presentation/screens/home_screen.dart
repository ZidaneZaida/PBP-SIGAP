import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap/core/navigation/sigap_transitions.dart';
import 'package:sigap/core/theme/app_colors.dart';
import 'package:sigap/features/alerts/presentation/screens/peringatan_screen.dart';
import 'package:sigap/features/family/presentation/screens/keluarga_screen.dart';
import 'package:sigap/features/map/presentation/screens/peta_screen.dart';
import 'package:sigap/features/settings/presentation/screens/pengaturan_screen.dart';
import 'package:sigap/features/profile/presentation/screens/profile_screen.dart';

/// Screen Utama HomeScreen (Beranda/Dashboard) SIGAP Kota Padang.
///
/// Memiliki logika kondisi (State Management) yang merender UI berbeda
/// antara "Kondisi Aman" (Normal) dan "Kondisi Darurat" (Bencana Aktif).
class HomeScreen extends StatefulWidget {
  final String userName;
  final bool initialEmergencyState;
  final bool initialTsunamiWarning;

  const HomeScreen({
    super.key,
    this.userName = 'Warga Padang',
    this.initialEmergencyState = false,
    this.initialTsunamiWarning = true,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _activeBottomNavIndex = 0; // 0: Beranda, 1: Peringatan, 2: Peta Siaga, 3: Keluarga

  // Dynamic State Management: Kondisi Aman vs Kondisi Darurat
  late bool _isEmergency;
  late bool _hasTsunamiWarning;

  // Interaktivitas & Status Pengguna
  bool _isSpeakingTts = false;
  bool _isSirenActive = false;
  bool _isUserMarkedSafe = false;
  Timer? _ttsSimulationTimer;

  // Animasi pulsing untuk badge darurat
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _isEmergency = widget.initialEmergencyState;
    _hasTsunamiWarning = widget.initialTsunamiWarning;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ttsSimulationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleEmergencyState() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isEmergency = !_isEmergency;
      if (!_isEmergency) {
        _isSpeakingTts = false;
        _isSirenActive = false;
        _ttsSimulationTimer?.cancel();
      }
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEmergency
              ? '🚨 Beralih ke KONDISI DARURAT (Simulasi Bencana Gempa Padang)'
              : '🟢 Beralih ke KONDISI AMAN (Status Normal Kota Padang)',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _isEmergency ? const Color(0xFFDC2626) : const Color(0xFF15803D),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleTsunamiWarning() {
    HapticFeedback.lightImpact();
    setState(() {
      _hasTsunamiWarning = !_hasTsunamiWarning;
    });
  }

  void _toggleSpeakAlert() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSpeakingTts = !_isSpeakingTts;
    });

    if (_isSpeakingTts) {
      _ttsSimulationTimer?.cancel();
      _ttsSimulationTimer = Timer(const Duration(seconds: 6), () {
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
                  '🔊 "Peringatan Dini: Gempa M 6.0, Jarak 14 km dari lokasi Anda. ${_hasTsunamiWarning ? "Berpotensi Tsunami. Segera jauhi pantai!" : "Tidak Berpotensi Tsunami."}"',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    } else {
      _ttsSimulationTimer?.cancel();
      ScaffoldMessenger.of(context).clearSnackBars();
    }
  }

  void _showSosDialog() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'KIRIM SINYAL SOS',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: const Color(0xFF991B1B),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lokasi GPS Anda akan dikirimkan langsung ke Pusat Pengendali Operasi (PUSDALOPS) BPBD Kota Padang & Tim SAR gabungan.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: AppColors.textSlate,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.mintAccent.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Koordinat: -0.9492, 100.3542 (Padang Barat)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDarkest,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSlate,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFFDC2626),
                  content: Text(
                    '🚨 SINYAL SOS TERKIRIM! Petugas BPBD & SAR sedang mengarahkan evakuasi ke titik Anda.',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'KIRIM SEKARANG',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _markSelfSafe() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isUserMarkedSafe = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF15803D),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Status Anda: "AMAN" telah tersimpan & dibagikan ke lingkaran keluarga!',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _triggerSiren() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isSirenActive = !_isSirenActive;
    });

    if (_isSirenActive) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.campaign_rounded, color: Color(0xFFDC2626), size: 30),
              const SizedBox(width: 10),
              Text(
                'SIRINE SOS AKTIF',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          content: Text(
            'Sirine audio dengan frekuensi tinggi aktif untuk memandu Tim Penyelamat dan warga sekitar menemukan posisi Anda.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.textSlate),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                setState(() => _isSirenActive = false);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'MATIKAN SIRINE',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _callEmergency112() {
    HapticFeedback.mediumImpact();
    showSigapModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kontak Darurat Kota Padang',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDarkest,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Layanan bebas pulsa 24 jam untuk keadaan darurat bencana & medis.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSlate),
            ),
            const SizedBox(height: 18),
            _buildContactTile(
              title: 'Panggilan Darurat Padang Siaga 112',
              number: '112 (Bebas Pulsa)',
              icon: Icons.phone_in_talk_rounded,
              isPrimary: true,
            ),
            const SizedBox(height: 10),
            _buildContactTile(
              title: 'PUSDALOPS BPBD Kota Padang',
              number: '(0751) 778775',
              icon: Icons.support_agent_rounded,
              isPrimary: false,
            ),
            const SizedBox(height: 10),
            _buildContactTile(
              title: 'Basarnas Kantor SAR Padang',
              number: '(0751) 484501',
              icon: Icons.health_and_safety_rounded,
              isPrimary: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required String title,
    required String number,
    required IconData icon,
    required bool isPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFFFEE2E2) : AppColors.mintAccent.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPrimary ? const Color(0xFFFCA5A5) : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isPrimary ? const Color(0xFFDC2626) : AppColors.primaryDark,
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
                    color: isPrimary ? const Color(0xFFDC2626) : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isPrimary ? const Color(0xFFDC2626) : AppColors.primaryDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'PANGGIL',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _requestFamilyUpdate() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryDark,
        content: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Permintaan kabar telah terkirim via notifikasi & SMS darurat ke Ayah & Adik!',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    if (index == _activeBottomNavIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _activeBottomNavIndex = index);
  }

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'WP';
    final parts = clean.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Column(
          children: [
            // Header Pengguna (Profil sederhana, TANPA jam statis) - DIAM/STATIS
            _buildHeader(),

            // Area tengah (Body) berganti layar dengan animasi Fade-Through & State Preservation
            Expanded(
              child: FadeThroughIndexedStack(
                index: _activeBottomNavIndex,
                duration: const Duration(milliseconds: 240),
                children: [
                  // Tab 0: Beranda
                  _buildHomeBodyContent(),
                  // Tab 1: Peringatan (Embedded)
                  const PeringatanScreen(embedded: true),
                  // Tab 2: Peta Siaga (Embedded)
                  const PetaScreen(embedded: true),
                  // Tab 3: Keluarga (Embedded)
                  const KeluargaScreen(embedded: true),
                ],
              ),
            ),
          ],
        ),
      ),

      // 4. BOTTOM NAVIGATION BAR - DIAM/STATIS
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Konten Scrollable Beranda (Tab 0)
  Widget _buildHomeBodyContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. KARTU STATUS UTAMA (Dynamic State UI)
          _buildMainStatusCard(),

          // 1b. BANNER INFORMASI BERMANFAAT & EDUKASI SIAGA (Mode Aman)
          if (!_isEmergency) ...[
            const SizedBox(height: 12),
            _buildSafeEducationBanner(),
          ],

          const SizedBox(height: 18),

          // 2. GRID 2x2 TINDAKAN CEPAT (Quick Actions)
          _buildQuickActionsGrid(),

          const SizedBox(height: 22),

          // 3. RINGKASAN KELUARGA (Family Circle)
          _buildFamilyCircleSection(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _getHeaderTitle() {
    switch (_activeBottomNavIndex) {
      case 1:
        return 'Peringatan Bencana';
      case 2:
        return 'Peta Siaga & Evakuasi';
      case 3:
        return 'Pantauan Keluarga';
      case 0:
      default:
        return 'Halo, ${widget.userName}';
    }
  }

  String _getHeaderSubtitle() {
    switch (_activeBottomNavIndex) {
      case 1:
        return 'Pusat Info & Peringatan Dini BMKG';
      case 2:
        return 'Kota Padang, Sumbar';
      case 3:
        return 'Lingkaran Siaga Padang';
      case 0:
      default:
        return 'Kota Padang, Sumbar';
    }
  }

  // ==========================================
  // HEADER PENGGUNA (Tanpa Jam Statis)
  // ==========================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCream,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderLight.withValues(alpha: 0.6),
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
              radius: 21,
              backgroundColor: AppColors.primaryDark,
              child: Text(
                _getInitials(widget.userName),
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Teks Profil Sederhana: "Halo, [Nama User]" atau "Halo, Warga Padang"
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getHeaderTitle(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDarkest,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _getHeaderSubtitle(),
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

          // Pill Toggle State Management (Kondisi Aman vs Kondisi Darurat)
          GestureDetector(
            onTap: _toggleEmergencyState,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isEmergency ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
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

          const SizedBox(width: 8),

          // Pengaturan Icon
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
  // 1. KARTU STATUS UTAMA (Dynamic State UI)
  // ==========================================
  Widget _buildMainStatusCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: _isEmergency
          ? _buildEmergencyStatusCard()
          : _buildSafeStatusCard(),
    );
  }

  // STATE AMAN (Kondisi Normal)
  Widget _buildSafeStatusCard() {
    return Container(
      key: const ValueKey('safe_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mintAccent, // Hijau Tenang khas SIGAP
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC2DFCD), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                    const SizedBox(width: 5),
                    Text(
                      'STATUS NORMAL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'BMKG Padang',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Teks Status Utama
          Text(
            'Kondisi Kota Padang: AMAN • Tidak ada peringatan bencana aktif',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDarkest,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFCCE4D5)),
          const SizedBox(height: 12),

          // Ringkasan Cuaca Padang Hari Ini
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC7E2D2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.wb_cloudy_rounded,
                      color: Color(0xFFF59E0B),
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cuaca Padang Hari Ini',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSlate,
                            ),
                          ),
                          Text(
                            '29°C · Cerah Berawan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDarkest,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.mintAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '0.8m (Tenang)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Wrap agar otomatis turun ke baris baru jika kepanjangan (No Overflow)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildWeatherItem(Icons.water_drop_outlined, 'Kelembapan', '78%'),
                    _buildWeatherItem(Icons.air_rounded, 'Angin', '12 km/j BD'),
                    _buildWeatherItem(Icons.waves_rounded, 'Pesisir', 'Tenang'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Komponen Cuaca Padat 2 Baris Atas-Bawah (Bebas Overflow)
  Widget _buildWeatherItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mintAccent.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC7E2D2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSlate,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDarkest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 1b. Banner Informasi Edukasi & Titik Kumpul (Mode Aman)
  // Background hijau sangat pudar (transparan), padat, ringkas, dan tidak mengalihkan perhatian dari tombol SOS
  Widget _buildSafeEducationBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.mintAccent.withValues(alpha: 0.35), // hijau sangat pudar (transparan)
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFC2DFCD).withValues(alpha: 0.8), // border tipis
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris 1 (Lokasi Evakuasi): 📍 Titik Kumpul Terdekat: Gedung TES UNP (400m)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('📍', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Titik Kumpul Terdekat: Gedung TES UNP (400m)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDarkest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // Baris 2 (Tips Edukasi): 💡 Tips Siaga: Pastikan powerbank Anda terisi penuh saat musim hujan.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('💡', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tips Siaga: Pastikan powerbank Anda terisi penuh saat musim hujan.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSlate,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // STATE DARURAT (Ada Bencana)
  Widget _buildEmergencyStatusCard() {
    return Container(
      key: const ValueKey('emergency_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), // Merah / Oranye Muda
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEF4444), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Peringatan Dini + Speaker Tombol (🔊 Bacakan) di sudut kartu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'PERINGATAN DARURAT AKTIF',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Ikon tombol Speaker (🔊 Bacakan) di sudut kartu
              InkWell(
                onTap: _toggleSpeakAlert,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isSpeakingTts ? const Color(0xFFDC2626) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDC2626), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isSpeakingTts ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                        color: _isSpeakingTts ? Colors.white : const Color(0xFFDC2626),
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '🔊 Bacakan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: _isSpeakingTts ? Colors.white : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Teks Judul Tegas (misal: "Gempa Bumi M 6.0")
          Text(
            'Gempa Bumi M 6.0',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF991B1B),
              height: 1.2,
            ),
          ),

          const SizedBox(height: 6),

          // Info Wajib: "Jarak dari lokasi Anda: 14 km"
          Row(
            children: [
              const Icon(
                Icons.near_me_rounded,
                size: 16,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(width: 5),
              Text(
                'Jarak dari lokasi Anda: 14 km',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // WAJIB ADA DI KARTU DARURAT: Badge besar penanda tsunami
          // ("🚨 BERPOTENSI TSUNAMI" atau "✅ TIDAK BERPOTENSI TSUNAMI")
          GestureDetector(
            onTap: _toggleTsunamiWarning,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: _hasTsunamiWarning ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (_hasTsunamiWarning
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF15803D))
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      _hasTsunamiWarning
                          ? '🚨 BERPOTENSI TSUNAMI'
                          : '✅ TIDAK BERPOTENSI TSUNAMI',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.touch_app_outlined,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Format Bullet/Poin Ringkas (Jangan pakai paragraf panjang)
          _buildBulletPoint('Episentrum: 14 km Barat Daya Padang (Kedalaman 10 km)'),
          const SizedBox(height: 4),
          _buildBulletPoint('Arahan: Segera jauhi pesisir pantai & muara Batang Arau'),
          const SizedBox(height: 4),
          _buildBulletPoint('Evakuasi: Menuju Zona Hijau (>15 mdpl) atau TES Shelter terdekat'),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6, right: 8),
          child: Icon(Icons.circle, size: 6, color: Color(0xFF991B1B)),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7F1D1D),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 2. GRID 2x2 TINDAKAN CEPAT (Quick Actions)
  // ==========================================
  Widget _buildQuickActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tindakan Cepat Darurat',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDarkest,
          ),
        ),
        const SizedBox(height: 10),

        // Baris 1: Tombol 1 (Merah Tegas) & Tombol 2 (Hijau Tegas)
        Row(
          children: [
            // Tombol 1: "🚨 BUTUH BANTUAN (SOS)" (Merah Tegas, teks tidak terpotong)
            Expanded(
              child: _buildActionButton(
                label: '🚨 BUTUH BANTUAN\n(SOS)',
                backgroundColor: const Color(0xFFDC2626), // Merah Tegas
                textColor: Colors.white,
                borderColor: Colors.transparent,
                onTap: _showSosDialog,
              ),
            ),
            const SizedBox(width: 12),

            // Tombol 2: "✅ SAYA AMAN" (Hijau Tegas)
            Expanded(
              child: _buildActionButton(
                label: _isUserMarkedSafe ? '✅ STATUS: AMAN' : '✅ SAYA AMAN',
                backgroundColor: const Color(0xFF15803D), // Hijau Tegas
                textColor: Colors.white,
                borderColor: Colors.transparent,
                onTap: _markSelfSafe,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Baris 2: Tombol 3 (Sirine SOS) & Tombol 4 (Darurat 112)
        Row(
          children: [
            // Tombol 3: "🔊 SIRINE SOS" (Ikon speaker/peluit, outline)
            Expanded(
              child: _buildActionButton(
                label: '🔊 SIRINE SOS',
                icon: Icons.campaign_rounded,
                backgroundColor: Colors.white,
                textColor: AppColors.primaryDark,
                borderColor: AppColors.borderLight,
                onTap: _triggerSiren,
              ),
            ),
            const SizedBox(width: 12),

            // Tombol 4: "📞 DARURAT 112" (Ikon telepon, outline)
            Expanded(
              child: _buildActionButton(
                label: '📞 DARURAT 112',
                icon: Icons.phone_in_talk_rounded,
                backgroundColor: Colors.white,
                textColor: AppColors.primaryDark,
                borderColor: AppColors.borderLight,
                onTap: _callEmergency112,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    IconData? icon,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: (backgroundColor == Colors.white
                        ? Colors.black
                        : backgroundColor)
                    .withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: textColor, size: 22),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1.25,
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

  // ==========================================
  // 3. RINGKASAN KELUARGA (Family Circle)
  // ==========================================
  Widget _buildFamilyCircleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Seksi + Tombol "[🔔 Minta Kabar]"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pantauan Keluarga',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDarkest,
                      ),
                    ),
                    Text(
                      'Status keselamatan lingkaran terdekat',
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
              const SizedBox(width: 8),

              // Tombol Kecil "[🔔 Minta Kabar]"
              OutlinedButton(
                onPressed: _requestFamilyUpdate,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  backgroundColor: AppColors.mintAccent.withValues(alpha: 0.6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🔔 Minta Kabar',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Deretan Avatar Bulat Menyamping (Horizontal Scroll) dengan Cincin Warna
          // Cincin Hijau: Ibu (Aman)
          // Cincin Kuning: Adik (Menunggu)
          // Cincin Merah: Ayah (Belum Konfirmasi)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // 1. Ibu (Cincin Hijau: Aman)
                _buildFamilyAvatar(
                  name: 'Ibu',
                  status: 'Aman',
                  ringColor: const Color(0xFF16A34A), // Hijau
                  initials: 'IB',
                  statusIcon: Icons.check_circle_rounded,
                  locationNote: 'Rumah Lolong',
                ),

                // 2. Adik (Cincin Kuning: Menunggu)
                _buildFamilyAvatar(
                  name: 'Adik',
                  status: 'Menunggu',
                  ringColor: const Color(0xFFF59E0B), // Kuning
                  initials: 'AD',
                  statusIcon: Icons.access_time_filled_rounded,
                  locationNote: 'Kampus UNP',
                ),

                // 3. Ayah (Cincin Merah: Belum Konfirmasi)
                _buildFamilyAvatar(
                  name: 'Ayah',
                  status: 'Belum Konfirmasi',
                  ringColor: const Color(0xFFDC2626), // Merah
                  initials: 'AY',
                  statusIcon: Icons.help_rounded,
                  locationNote: 'Khatib Sulaiman',
                ),

                // 4. Tombol Tambah Anggota
                _buildAddFamilyAvatar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyAvatar({
    required String name,
    required String status,
    required Color ringColor,
    required String initials,
    required IconData statusIcon,
    required String locationNote,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$name: Status $status • Lokasi terakhir: $locationNote',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        width: 86,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Cincin Warna Status
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ringColor, width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: ringColor.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ringColor.withValues(alpha: 0.12),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: ringColor == const Color(0xFFF59E0B)
                                ? const Color(0xFFB45309)
                                : ringColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Mini Badge Status Icon
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: ringColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(statusIcon, size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDarkest,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ringColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: ringColor == const Color(0xFFF59E0B)
                      ? const Color(0xFFB45309)
                      : ringColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddFamilyAvatar() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const KeluargaScreen()),
        );
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.borderLight,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                color: AppColors.mintAccent.withValues(alpha: 0.4),
              ),
              child: const Center(
                child: Icon(Icons.add_rounded, color: AppColors.primary, size: 26),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Kelola',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Semua',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppColors.textSlate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 4. BOTTOM NAVIGATION BAR
  // 4 Menu Utama: 1. Beranda, 2. Peringatan, 3. Peta Siaga, 4. Keluarga
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
            icon: Icon(Icons.warning_amber_rounded),
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
