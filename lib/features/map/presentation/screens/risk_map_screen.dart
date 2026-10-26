import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap/core/theme/app_colors.dart';
import 'package:sigap/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:sigap/features/family/presentation/screens/family_assistance_screen.dart';
import 'package:sigap/features/settings/presentation/screens/settings_screen.dart';
import 'package:sigap/features/profile/presentation/screens/profile_screen.dart';

/// Model untuk titik risiko di peta
class RiskZonePoint {
  final String id;
  final String title;
  final String category; // 'BANJIR', 'GEMPA', 'LONGSOR'
  final String level; // 'Rendah', 'Sedang', 'Tinggi'
  final String locationName;
  final String description;
  final String recommendation;
  final Offset relativePos; // (x, y) relative 0.0 - 1.0

  const RiskZonePoint({
    required this.id,
    required this.title,
    required this.category,
    required this.level,
    required this.locationName,
    required this.description,
    required this.recommendation,
    required this.relativePos,
  });
}

/// Screen Peta Risiko Wilayah SIGAP Kota Padang
/// Mengimplementasikan secara presisi desain:
/// "SIGAP mobile — Peta risiko — iPhone 17 Pro.svg"
class RiskMapScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToAlerts;
  final VoidCallback? onNavigateToFamily;
  final Function(int)? onTabSelected;

  const RiskMapScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToAlerts,
    this.onNavigateToFamily,
    this.onTabSelected,
  });

  @override
  State<RiskMapScreen> createState() => _RiskMapScreenState();
}

class _RiskMapScreenState extends State<RiskMapScreen> with SingleTickerProviderStateMixin {
  final int _activeTab = 2; // 2: Peta risiko (Active)

  // Filter & Search State
  String _selectedRiskType = 'Semua'; // 'Semua' | 'Banjir' | 'Gempa' | 'Longsor'
  String _selectedLevel = 'Semua'; // 'Semua' | 'Rendah' | 'Sedang' | 'Tinggi'
  final TextEditingController _searchController = TextEditingController();

  // Animasi radar pulse
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Daftar Titik Risiko Kota Padang
  final List<RiskZonePoint> _allRiskPoints = const [
    RiskZonePoint(
      id: '1',
      title: 'BANJIR',
      category: 'Banjir',
      level: 'Sedang',
      locationName: 'DAS Batang Arau & Kuranji',
      description: 'Ketinggian muka air sungai mencapai 120 cm akibat hujan intensitas sedang di hulu.',
      recommendation: 'Warga bantaran sungai diminta waspada terhadap potensi luapan air.',
      relativePos: Offset(0.32, 0.40),
    ),
    RiskZonePoint(
      id: '2',
      title: 'GEMPA',
      category: 'Gempa',
      level: 'Tinggi',
      locationName: 'Pesisir Pantai Padang & Zona Megathrust',
      description: 'Pusat gempa dangkal M5.8 berjarak 24 km Barat Daya Padang, guncangan dirasakan III-IV MMI.',
      recommendation: 'Waspadai retakan pada struktur bangunan dan pantau jalur evakuasi vertikal (TES).',
      relativePos: Offset(0.68, 0.52),
    ),
    RiskZonePoint(
      id: '3',
      title: 'LONGSOR',
      category: 'Longsor',
      level: 'Sedang',
      locationName: 'Kawasan Bukit Barisan / Jalur Sitinjau Lauik',
      description: 'Kondisi tanah jenuh air di lereng perbukitan berpotensi memicu guguran batu dan material lumpur.',
      recommendation: 'Pengendara diimbau berhati-hati dan mengurangi kecepatan saat melintas.',
      relativePos: Offset(0.68, 0.74),
    ),
  ];

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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Filtered Points
  List<RiskZonePoint> get _filteredPoints {
    return _allRiskPoints.where((p) {
      if (_selectedRiskType != 'Semua' && p.category.toLowerCase() != _selectedRiskType.toLowerCase()) {
        return false;
      }
      if (_selectedLevel != 'Semua' && p.level.toLowerCase() != _selectedLevel.toLowerCase()) {
        return false;
      }
      if (_searchController.text.trim().isNotEmpty) {
        final query = _searchController.text.trim().toLowerCase();
        final matchLoc = p.locationName.toLowerCase().contains(query);
        final matchCat = p.category.toLowerCase().contains(query);
        if (!matchLoc && !matchCat) return false;
      }
      return true;
    }).toList();
  }

  // ==========================================
  // MODALS & ACTIONS
  // ==========================================

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Jenis Risiko',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'PILIH KATEGORI BENCANA',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSlate,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Semua', 'Gempa', 'Banjir', 'Longsor'].map((type) {
                  final isSelected = _selectedRiskType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    selectedColor: AppColors.primaryDark,
                    backgroundColor: AppColors.mintSurface,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.primaryDark,
                    ),
                    onSelected: (selected) {
                      setModalState(() {
                        _selectedRiskType = type;
                      });
                      setState(() {
                        _selectedRiskType = type;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'TINGKAT RISIKO',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSlate,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Semua', 'Rendah', 'Sedang', 'Tinggi'].map((lvl) {
                  final isSelected = _selectedLevel == lvl;
                  return ChoiceChip(
                    label: Text(lvl),
                    selected: isSelected,
                    selectedColor: AppColors.primaryDark,
                    backgroundColor: AppColors.mintSurface,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.primaryDark,
                    ),
                    onSelected: (selected) {
                      setModalState(() {
                        _selectedLevel = lvl;
                      });
                      setState(() {
                        _selectedLevel = lvl;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'TERAPKAN FILTER',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
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

  void _showPointDetail(RiskZonePoint point) {
    Color levelBg;
    Color levelColor;
    if (point.level == 'Tinggi') {
      levelBg = AppColors.alertPeach;
      levelColor = AppColors.alertTerracotta;
    } else if (point.level == 'Sedang') {
      levelBg = AppColors.mintAccent;
      levelColor = AppColors.primaryDark;
    } else {
      levelBg = Colors.grey.shade100;
      levelColor = AppColors.textSlate;
    }

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: levelBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'RISIKO ${point.level.toUpperCase()}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: levelColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Text(
                  'KOTA PADANG',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSlate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              point.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              point.locationName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.alertTerracotta,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              point.description,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: AppColors.textDark,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mintSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point.recommendation,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryDark,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Membuka panduan keselamatan wilayah ${point.locationName}...'),
                      backgroundColor: AppColors.primaryDark,
                    ),
                  );
                },
                icon: const Icon(Icons.shield_outlined, size: 18, color: Colors.white),
                label: Text(
                  'LIHAT PANDUAN KESELAMATAN',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserLocationDetails() {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detail Risiko Lokasi Anda',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
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
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Lokasi Terdeteksi: Kec. Padang Barat, Kota Padang',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Area Anda berada di dataran rendah pesisir. Terdapat potensi genangan air / banjir pasang (rob) serta aliran sungai saat curah hujan tinggi terus berlanjut.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSlate, height: 1.35),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: 10),
            Text('• Ketinggian Muka Air: 120 cm (Waspada)', style: GoogleFonts.plusJakartaSans(fontSize: 12.5)),
            const SizedBox(height: 6),
            Text('• Cuaca Saat Ini: Hujan sedang (22 mm/jam)', style: GoogleFonts.plusJakartaSans(fontSize: 12.5)),
            const SizedBox(height: 6),
            Text('• Jalur Evakuasi Terdekat: Shelter Pasar Raya (850 meter)', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text('MENGERTI', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // BUILD METHOD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (SIGAP Brand + PDG Time + Icons)
              _buildHeader(),
              const SizedBox(height: 24),

              // 2. Title & Subtitle
              Text(
                'Peta risiko wilayah',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ringkasan kondisi risiko sekitar · Padang, Sumatera Barat',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF5C6B61),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),

              // 3. Search Bar ("cari wilayah...")
              _buildSearchBar(),
              const SizedBox(height: 10),

              // 4. Filter Button ("filter: jenis risiko ⌄")
              _buildFilterDropdown(),
              const SizedBox(height: 16),

              // 5. Interactive Map Container
              _buildMapContainer(),
              const SizedBox(height: 16),

              // 6. Card: LOKASI ANDA ("Risiko sedang · potensi banjir")
              _buildUserLocationCard(),
              const SizedBox(height: 16),

              // 7. Card: LEGENDA (Rendah, Sedang, Tinggi)
              _buildLegendCard(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ==========================================
  // COMPONENT BUILDERS
  // ==========================================

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'SIGAP',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              'PDG · 09:41',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, a1, a2) => SettingsScreen(
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
                Icons.settings_outlined,
                size: 20,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 12),
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
                size: 21,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {});
        },
        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: 'cari wilayah...',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF5C6B61).withValues(alpha: 0.7),
          ),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primaryDark),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return GestureDetector(
      onTap: _showFilterModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune_rounded, size: 18, color: AppColors.textDark),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedRiskType == 'Semua' && _selectedLevel == 'Semua'
                    ? 'filter: jenis risiko'
                    : 'filter: $_selectedRiskType · $_selectedLevel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMapContainer() {
    return Container(
      width: double.infinity,
      height: 380,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Custom Painted Map (Coastline, Rivers, Hills, Topography)
            Positioned.fill(
              child: CustomPaint(
                painter: _PadangMapPainter(
                  pulseProgress: _pulseAnimation.value,
                ),
              ),
            ),

            // Animated Radar concentric rings
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Positioned.fill(
                  child: CustomPaint(
                    painter: _RadarWavePainter(pulseProgress: _pulseAnimation.value),
                  ),
                );
              },
            ),

            // Map Pins / Badges
            ..._filteredPoints.map((point) {
              return _buildMapBadge(point);
            }),

            // Bottom-Left Overlay Tag: "PLACEHOLDER PETA · PADANG"
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'PLACEHOLDER PETA · PADANG',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSlate,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),

            // Top-Right Recenter & Zoom Controls
            Positioned(
              right: 12,
              top: 12,
              child: Column(
                children: [
                  _buildMapControlBtn(
                    icon: Icons.my_location_rounded,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Memusatkan peta ke lokasi Anda (Padang Barat)'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  _buildMapControlBtn(
                    icon: Icons.layers_outlined,
                    onTap: _showFilterModal,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControlBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, size: 18, color: AppColors.primaryDark),
        ),
      ),
    );
  }

  Widget _buildMapBadge(RiskZonePoint point) {
    // Sesuai desain Figma:
    // BANJIR: Dark Green (#1A3A2A), white text
    // GEMPA: White container, Terracotta text (#C46B4F)
    // LONGSOR: White container, Terracotta text (#C46B4F)
    final bool isDark = point.category == 'Banjir';

    return Positioned(
      left: 360 * point.relativePos.dx - 35,
      top: 380 * point.relativePos.dy - 16,
      child: GestureDetector(
        onTap: () => _showPointDetail(point),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.primaryDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.primaryDark : AppColors.borderLight,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            point.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.alertTerracotta,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserLocationCard() {
    return GestureDetector(
      onTap: _showUserLocationDetails,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.mintAccent.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LOKASI ANDA',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSlate,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Risiko sedang',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'potensi banjir',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5C6B61),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEGENDA',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textSlate,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildLegendItem(
                label: 'Rendah',
                level: 'Rendah',
                indicator: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.textSlate, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              _buildLegendItem(
                label: 'Sedang',
                level: 'Sedang',
                indicator: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              _buildLegendItem(
                label: 'Tinggi',
                level: 'Tinggi',
                indicator: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.alertTerracotta,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required String label,
    required String level,
    required Widget indicator,
  }) {
    final bool isSelected = _selectedLevel == level;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLevel = _selectedLevel == level ? 'Semua' : level;
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BOTTOM NAVIGATION BAR (Tab 2: Peta risiko Aktif)
  // ==========================================

  Widget _buildBottomNavigationBar() {
    return Container(
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
              icon: Icons.notifications_none_rounded,
              label: 'Peringatan',
              onTap: () {
                if (widget.onNavigateToAlerts != null) {
                  widget.onNavigateToAlerts!();
                } else {
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
                }
              },
            ),
            _buildNavPill(
              index: 2,
              icon: Icons.map_rounded,
              label: 'Peta risiko',
              onTap: () {},
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
                          Navigator.of(context).pop();
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

/// Custom Painter yang menggambar kontur peta Kota Padang (laut, daratan, sungai, dan perbukitan)
class _PadangMapPainter extends CustomPainter {
  final double pulseProgress;

  _PadangMapPainter({required this.pulseProgress});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background Daratan (Light Map Gray / Mint Tint)
    final landPaint = Paint()..color = const Color(0xFFE4ECE6);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), landPaint);

    // 2. Perbukitan Timur (Bukit Barisan)
    final hillPaint = Paint()..color = const Color(0xFFCCDCCF);
    final hillPath = Path();
    hillPath.moveTo(size.width * 0.55, 0);
    hillPath.quadraticBezierTo(size.width * 0.7, size.height * 0.3, size.width * 0.85, 0);
    hillPath.lineTo(size.width, 0);
    hillPath.lineTo(size.width, size.height);
    hillPath.quadraticBezierTo(size.width * 0.75, size.height * 0.65, size.width * 0.6, size.height);
    hillPath.close();
    canvas.drawPath(hillPath, hillPaint);

    // 3. Laut / Samudra Hindia (Sisi Kiri / Barat Padang)
    final seaPaint = Paint()..color = const Color(0xFF5B7E96);
    final seaPath = Path();
    seaPath.moveTo(0, size.height * 0.55);
    seaPath.quadraticBezierTo(size.width * 0.12, size.height * 0.65, size.width * 0.16, size.height * 0.78);
    seaPath.quadraticBezierTo(size.width * 0.25, size.height * 0.90, size.width * 0.45, size.height * 0.96);
    seaPath.lineTo(size.width * 0.42, size.height);
    seaPath.lineTo(0, size.height);
    seaPath.close();
    canvas.drawPath(seaPath, seaPaint);

    // 4. Sungai Batang Arau / Batang Kuranji
    final riverPaint = Paint()
      ..color = const Color(0xFF7CA3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final riverPath = Path();
    riverPath.moveTo(size.width * 0.1, 0);
    riverPath.cubicTo(size.width * 0.3, size.height * 0.15, size.width * 0.15, size.height * 0.28, size.width * 0.35, size.height * 0.45);
    riverPath.cubicTo(size.width * 0.42, size.height * 0.55, size.width * 0.35, size.height * 0.7, size.width * 0.45, size.height * 0.95);
    canvas.drawPath(riverPath, riverPaint);

    // 5. Grid Jalan Kota Padang
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double y = 40; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }
    for (double x = 40; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PadangMapPainter oldDelegate) => false;
}

/// Painter untuk lingkaran radar & radius risiko
class _RadarWavePainter extends CustomPainter {
  final double pulseProgress;

  _RadarWavePainter({required this.pulseProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);

    // Crosshair axis
    final axisPaint = Paint()
      ..color = const Color(0xFF6B8A7A).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), axisPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), axisPaint);

    // Concentric Static Rings
    final ringPaint = Paint()
      ..color = const Color(0xFF4A6B58).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, 40, ringPaint);
    canvas.drawCircle(center, 80, ringPaint);
    canvas.drawCircle(center, 120, ringPaint);

    // Dynamic Pulsing Inner Circle (Megathrust / Gempa warning)
    final pulsePaint = Paint()
      ..color = AppColors.alertTerracotta.withValues(alpha: (1.0 - pulseProgress) * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, 40 + pulseProgress * 40, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarWavePainter oldDelegate) =>
      oldDelegate.pulseProgress != pulseProgress;
}
