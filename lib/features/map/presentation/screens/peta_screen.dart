import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap/core/navigation/sigap_transitions.dart';
import 'package:sigap/core/theme/app_colors.dart';
import 'package:sigap/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:sigap/features/family/presentation/screens/keluarga_screen.dart';
import 'package:sigap/features/dashboard/presentation/screens/home_screen.dart';
import 'package:sigap/features/settings/presentation/screens/pengaturan_screen.dart';
import 'package:sigap/features/profile/presentation/screens/profile_screen.dart';

/// Model Titik Lokasi Penting di Peta Padang
class PadangMapLocation {
  final String id;
  final String name;
  final String category; // 'shelter', 'hospital', 'posko', 'tsunami'
  final String typeLabel;
  final String distance;
  final String walkTime;
  final String elevation;
  final String capacity;
  final String routeNote;
  final LatLng position;
  final String phone;

  const PadangMapLocation({
    required this.id,
    required this.name,
    required this.category,
    required this.typeLabel,
    required this.distance,
    required this.walkTime,
    required this.elevation,
    required this.capacity,
    required this.routeNote,
    required this.position,
    this.phone = '112',
  });
}

/// Screen Peta Interaktif SIGAP Kota Padang
/// Menggunakan [FlutterMap] dengan koordinat riil Kota Padang,
/// batas kamera (Camera Boundary), Floating Search Bar,
/// Smart Filter Chips, layer lokasi saya, dan Kartu Navigasi Darurat.
class PetaScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToAlerts;
  final VoidCallback? onNavigateToFamily;
  final Function(int)? onTabSelected;
  final bool embedded;

  const PetaScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToAlerts,
    this.onNavigateToFamily,
    this.onTabSelected,
    this.embedded = false,
  });

  @override
  State<PetaScreen> createState() => _PetaScreenState();
}

class _PetaScreenState extends State<PetaScreen>
    with SingleTickerProviderStateMixin {
  final int _activeBottomNavIndex = 2; // 2: Peta Siaga (Aktif)

  // Controller Peta
  late final MapController _mapController;

  // Koordinat Utama Kota Padang (Latitude: -0.9471, Longitude: 100.3658)
  static const LatLng _padangCenter = LatLng(-0.9471, 100.3658);

  // Lokasi Pengguna Saat Ini ("My Location" - Padang Barat dekat Air Tawar / UNP)
  static const LatLng _userLocation = LatLng(-0.9492, 100.3542);

  // Camera Boundary: Batas Geser Peta Terkunci Khusus Wilayah Padang & Sekitarnya
  final LatLngBounds _padangBounds = LatLngBounds(
    const LatLng(
      -1.1500,
      100.2200,
    ), // Barat Daya (Pesisir Teluk Bayur / Samudra)
    const LatLng(-0.7600, 100.5200), // Timur Laut (Koto Tangah / Batang Anai)
  );

  // Filter Kategori Aktif
  String _selectedCategory =
      'shelter'; // 'shelter', 'hospital', 'posko', 'tsunami'
  final TextEditingController _searchController = TextEditingController();

  // Shelter / Lokasi Terpilih untuk Bottom Sheet Navigasi
  late PadangMapLocation _selectedLocation;
  bool _isNavigating = false;

  // Animasi pulsing untuk titik biru "My Location"
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Daftar Lokasi Terdata di Kota Padang
  final List<PadangMapLocation> _locations = const [
    // 🏃 Shelter Terdekat
    PadangMapLocation(
      id: 'shelter_unp',
      name: 'Gedung TES UNP',
      category: 'shelter',
      typeLabel: 'Tempat Evakuasi Sementara',
      distance: '400 meter',
      walkTime: '5 mnt jalan kaki',
      elevation: '18 mdpl (Zona Aman Tsunami)',
      capacity: '4.000 jiwa',
      routeNote:
          'Lewat Jl. Prof. Hamka langsung ke arah Timur menjauhi pantai.',
      position: LatLng(-0.8970, 100.3520),
      phone: '(0751) 7051260',
    ),
    PadangMapLocation(
      id: 'shelter_ulak_karang',
      name: 'TES Escape Building Ulak Karang',
      category: 'shelter',
      typeLabel: 'TES Utama Mandiri',
      distance: '850 meter',
      walkTime: '10 mnt jalan kaki',
      elevation: '16 mdpl (Aman Tsunami)',
      capacity: '3.000 jiwa',
      routeNote: 'Lewat Jl. Bahari lurus ke arah bukit/Utara.',
      position: LatLng(-0.9125, 100.3530),
      phone: '(0751) 778775',
    ),
    PadangMapLocation(
      id: 'shelter_masjid_raya',
      name: 'Masjid Raya Sumatera Barat',
      category: 'shelter',
      typeLabel: 'Shelter Titik Kumpul Akbar',
      distance: '1.8 km',
      walkTime: '22 mnt jalan kaki',
      elevation: '>15 mdpl (Zona Hijau)',
      capacity: '10.000 jiwa',
      routeNote:
          'Akses cepat melalui Jl. Khatib Sulaiman jalur evakuasi utama.',
      position: LatLng(-0.9242, 100.3625),
      phone: '(0751) 8950001',
    ),
    PadangMapLocation(
      id: 'shelter_smp1',
      name: 'SMPN 1 Padang (Vertical Evac)',
      category: 'shelter',
      typeLabel: 'Shelter Vertikal Bertingkat',
      distance: '1.2 km',
      walkTime: '15 mnt jalan kaki',
      elevation: 'Lt. 3 & 4 (15 mdpl)',
      capacity: '1.500 jiwa',
      routeNote: 'Gedung diperkuat konstruksi tahan gempa megathrust.',
      position: LatLng(-0.9520, 100.3610),
      phone: '(0751) 21545',
    ),

    // 🏥 Rumah Sakit & PMI
    PadangMapLocation(
      id: 'rs_djamil',
      name: 'RSUP Dr. M. Djamil Padang',
      category: 'hospital',
      typeLabel: 'Rumah Sakit Rujukan Utama',
      distance: '1.5 km',
      walkTime: '18 mnt jalan kaki',
      elevation: '12 mdpl',
      capacity: 'IGD Siaga Bencana 24 Jam',
      routeNote: 'Jl. Perintis Kemerdekaan, Padang Timur.',
      position: LatLng(-0.9433, 100.3670),
      phone: '(0751) 32372',
    ),
    PadangMapLocation(
      id: 'rs_bhayangkara',
      name: 'RS Bhayangkara Padang',
      category: 'hospital',
      typeLabel: 'Rumah Sakit Darurat Medis',
      distance: '2.1 km',
      walkTime: '25 mnt jalan kaki',
      elevation: '14 mdpl',
      capacity: 'Ambulans & Bedah Darurat',
      routeNote: 'Jl. Jati No. 1, Padang Timur.',
      position: LatLng(-0.9250, 100.3700),
      phone: '(0751) 7051900',
    ),
    PadangMapLocation(
      id: 'pmi_padang',
      name: 'Markas PMI Kota Padang',
      category: 'hospital',
      typeLabel: 'Posko Darah & Medis PMI',
      distance: '1.4 km',
      walkTime: '16 mnt jalan kaki',
      elevation: '11 mdpl',
      capacity: 'Bank Darah & Tim Pertolongan Pertama',
      routeNote: 'Jl. Alang Lawas Koto No. 1.',
      position: LatLng(-0.9515, 100.3650),
      phone: '(0751) 21102',
    ),

    // ⛺ Posko Darurat
    PadangMapLocation(
      id: 'posko_bpbd',
      name: 'PUSDALOPS BPBD Kota Padang',
      category: 'posko',
      typeLabel: 'Pusat Komando Bencana Padang',
      distance: '2.8 km',
      walkTime: '35 mnt jalan kaki',
      elevation: '20 mdpl',
      capacity: 'Pusat Distribusi Logistik & Radio Komunikasi',
      routeNote: 'Jl. Bagindo Aziz Chan, Aie Pacah.',
      position: LatLng(-0.9320, 100.3800),
      phone: '(0751) 778775',
    ),
    PadangMapLocation(
      id: 'posko_agus_salim',
      name: 'Posko Lapangan GOR H. Agus Salim',
      category: 'posko',
      typeLabel: 'Tenda Pengungsian & Dapur Umum',
      distance: '1.1 km',
      walkTime: '13 mnt jalan kaki',
      elevation: '13 mdpl',
      capacity: '5.000 jiwa (Tenda Pengungsi)',
      routeNote: 'Area terbuka luas aman dari reruntuhan gedung tinggi.',
      position: LatLng(-0.9190, 100.3590),
      phone: '112',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = _locations.first; // Default: Gedung TES UNP

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _moveToPadangCenter() {
    HapticFeedback.lightImpact();
    _mapController.move(_padangCenter, 13.0);
  }

  void _moveToMyLocation() {
    HapticFeedback.mediumImpact();
    _mapController.move(_userLocation, 15.0);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '📍 Memusatkan ke Lokasi Anda (Padang Barat · GPS Akurat)',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF2563EB),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _zoomIn() {
    HapticFeedback.selectionClick();
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      (currentZoom + 1).clamp(11.0, 18.0),
    );
  }

  void _zoomOut() {
    HapticFeedback.selectionClick();
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      (currentZoom - 1).clamp(11.0, 18.0),
    );
  }

  void _selectLocation(PadangMapLocation loc) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedLocation = loc;
    });
    _mapController.move(loc.position, 14.5);
  }

  void _startEvacuationRoute() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isNavigating = true;
    });

    // Geser peta agar menampilkan rute antara lokasi pengguna dan shelter
    final bounds = LatLngBounds(_userLocation, _selectedLocation.position);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.only(
          top: 180,
          bottom: 220,
          left: 60,
          right: 60,
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF15803D),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(
              Icons.directions_walk_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Rute Evakuasi Aktif: Ikuti jalur hijau menuju ${_selectedLocation.name} (${_selectedLocation.distance})',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _cancelNavigation() {
    HapticFeedback.lightImpact();
    setState(() {
      _isNavigating = false;
    });
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
    } else if (index == 1) {
      if (widget.onNavigateToAlerts != null) {
        widget.onNavigateToAlerts!();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AlertsScreen()),
        );
      }
    } else if (index == 3) {
      if (widget.onNavigateToFamily != null) {
        widget.onNavigateToFamily!();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const KeluargaScreen(),
          ),
        );
      }
    }
  }

  // Filter lokasi berdasarkan search input dan kategori aktif
  List<PadangMapLocation> get _filteredLocations {
    final query = _searchController.text.trim().toLowerCase();
    return _locations.where((loc) {
      final matchesCategory =
          _selectedCategory == 'tsunami' || loc.category == _selectedCategory;
      if (query.isEmpty) return matchesCategory;
      return matchesCategory &&
          (loc.name.toLowerCase().contains(query) ||
              loc.typeLabel.toLowerCase().contains(query) ||
              loc.routeNote.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mapStack = Stack(
      children: [
        // 1. WIDGET PETA INTERAKTIF SUNGGUHAN (FlutterMap)
        _buildInteractiveMap(),

        // Banner Rute Navigasi Berjalan Kaki Aktif (Jika diaktifkan)
        if (_isNavigating) _buildActiveNavigationBanner(),

        // 2. SEARCH BAR & FILTER LOKASI (Di Atas Peta)
        _buildFloatingSearchAndFilters(),

        // Floating Map Action Buttons (Lokasi Saya, Zoom, Pusatkan)
        _buildFloatingMapControls(),

        // 3. KARTU NAVIGASI DARURAT (Draggable Bottom Sheet di Bawah Peta)
        _buildEmergencyBottomSheet(),
      ],
    );

    if (widget.embedded) {
      return mapStack;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Column(
          children: [
            // ATURAN GLOBAL 1: HEADER STICKY / FIXED (Profil & Status Kota Padang)
            _buildFixedHeader(),

            // AREA UTAMA PETA INTERAKTIF + FLOATING CONTROLS
            Expanded(child: mapStack),
          ],
        ),
      ),

      // ATURAN GLOBAL 2: BOTTOM NAVIGATION BAR STICKY / FIXED (Tidak tertutup peta)
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ==========================================
  // ATURAN GLOBAL: FIXED STICKY HEADER
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
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryDark,
              child: Icon(Icons.map_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Peta Siaga & Evakuasi',
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
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Padang, Sumbar · GPS Siaga Aktif',
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
          IconButton(
            icon: const Icon(
              Icons.tune_rounded,
              color: AppColors.primaryDark,
              size: 22,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Layer Peta: Menampilkan kontur elevasi & shelter evakuasi Padang.',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.primaryDark,
              size: 22,
            ),
            onPressed: () {
              Navigator.push(
                context,
                SigapRoutes.slideRight(const PengaturanScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 1. WIDGET PETA INTERAKTIF SUNGGUHAN (FlutterMap)
  // ==========================================
  Widget _buildInteractiveMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        // Initial Camera Position: Pusat Kota Padang (Lat: -0.9471, Long: 100.3658, Zoom: 13)
        initialCenter: _padangCenter,
        initialZoom: 13.0,
        minZoom: 11.0,
        maxZoom: 18.0,

        // Camera Boundary: Kunci batas gerak kamera khusus di Kota Padang
        cameraConstraint: CameraConstraint.contain(bounds: _padangBounds),

        // Interaktivitas: pinch-to-zoom, pan/geser, double tap
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // Tile Layer Peta Dunia (OpenStreetMap Tile Server)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'id.sigap.padang.siaga',
          maxZoom: 19,
          minZoom: 11,
        ),

        // Layer Zona Bahaya Tsunami (Jika filter Zona Tsunami aktif)
        if (_selectedCategory == 'tsunami') ...[
          PolygonLayer(
            polygons: [
              // Zona Merah Tsunami (Pesisir Pantai Padang / Muara Batang Arau s/d Jl. Veteran)
              Polygon(
                points: const [
                  LatLng(-0.8800, 100.3350),
                  LatLng(-0.9100, 100.3450),
                  LatLng(-0.9450, 100.3500),
                  LatLng(-0.9700, 100.3550),
                  LatLng(-0.9750, 100.3700),
                  LatLng(-0.9400, 100.3650),
                  LatLng(-0.9000, 100.3580),
                  LatLng(-0.8750, 100.3450),
                ],
                color: const Color(0xFFEF4444).withValues(alpha: 0.28),
                borderColor: const Color(0xFFDC2626),
                borderStrokeWidth: 2.5,
              ),

              // Zona Hijau Aman Evakuasi (>15 mdpl: Wilayah Timur / By Pass)
              Polygon(
                points: const [
                  LatLng(-0.8800, 100.3700),
                  LatLng(-0.9200, 100.3800),
                  LatLng(-0.9600, 100.3950),
                  LatLng(-0.9700, 100.4300),
                  LatLng(-0.9000, 100.4200),
                  LatLng(-0.8700, 100.3900),
                ],
                color: const Color(0xFF10B981).withValues(alpha: 0.22),
                borderColor: const Color(0xFF059669),
                borderStrokeWidth: 2.0,
              ),
            ],
          ),
        ],

        // Polyline Rute Evakuasi Jalan Kaki (Ketika user menekan tombol Mulai Rute)
        if (_isNavigating) ...[
          PolylineLayer(
            polylines: [
              Polyline(
                points: [
                  _userLocation,
                  LatLng(
                    (_userLocation.latitude +
                            _selectedLocation.position.latitude) /
                        2,
                    _userLocation.longitude + 0.002,
                  ),
                  _selectedLocation.position,
                ],
                color: const Color(0xFF15803D),
                strokeWidth: 5.5,
                strokeJoin: StrokeJoin.round,
              ),
            ],
          ),
        ],

        // Marker Layer: Titik Lokasi Pengguna ("My Location") & Titik Lokasi Fasilitas
        MarkerLayer(
          markers: [
            // Layer "My Location" (Titik biru berkedip lokasi pengguna saat ini)
            Marker(
              point: _userLocation,
              width: 50,
              height: 50,
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Marker Fasilitas (Shelter, RS, Posko)
            ..._filteredLocations.map((loc) {
              final isSelected = loc.id == _selectedLocation.id;
              final iconColor = loc.category == 'shelter'
                  ? const Color(0xFF15803D) // Hijau untuk Shelter
                  : loc.category == 'hospital'
                  ? const Color(0xFFDC2626) // Merah untuk RS
                  : const Color(0xFFD97706); // Kuning/Oranye untuk Posko

              return Marker(
                point: loc.position,
                width: isSelected ? 48 : 38,
                height: isSelected ? 48 : 38,
                child: GestureDetector(
                  onTap: () => _selectLocation(loc),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: isSelected ? iconColor : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : iconColor,
                        width: isSelected ? 3 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isSelected ? iconColor : Colors.black)
                              .withValues(alpha: 0.3),
                          blurRadius: isSelected ? 8 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        loc.category == 'shelter'
                            ? Icons.directions_run_rounded
                            : loc.category == 'hospital'
                            ? Icons.local_hospital_rounded
                            : Icons.holiday_village_rounded,
                        color: isSelected ? Colors.white : iconColor,
                        size: isSelected ? 24 : 18,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 2. SEARCH BAR & FILTER LOKASI (Di Atas Peta)
  // ==========================================
  Widget _buildFloatingSearchAndFilters() {
    return Positioned(
      top: 14,
      left: 14,
      right: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Floating Search Bar Berdesain Modern (Putih dengan Shadow Lembut)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari shelter, RS, atau lokasi...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: AppColors.textSlate,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : const Icon(
                        Icons.mic_none_rounded,
                        color: AppColors.textSlate,
                        size: 20,
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Deretan Tombol Pintar (Filter Chips) yang Bisa di-scroll Menyamping
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // 1. [🏃 Shelter Terdekat] (Warna Hijau Utama)
                _buildFilterChip(
                  label: '🏃 Shelter Terdekat',
                  categoryKey: 'shelter',
                  isPrimaryGreen: true,
                ),
                const SizedBox(width: 8),

                // 2. [🏥 Rumah Sakit & PMI]
                _buildFilterChip(
                  label: '🏥 Rumah Sakit & PMI',
                  categoryKey: 'hospital',
                ),
                const SizedBox(width: 8),

                // 3. [⛺ Posko Darurat]
                _buildFilterChip(
                  label: '⛺ Posko Darurat',
                  categoryKey: 'posko',
                ),
                const SizedBox(width: 8),

                // 4. [🌊 Zona Tsunami]
                _buildFilterChip(
                  label: '🌊 Zona Tsunami',
                  categoryKey: 'tsunami',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String categoryKey,
    bool isPrimaryGreen = false,
  }) {
    final isSelected = _selectedCategory == categoryKey;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedCategory = categoryKey;
        });

        if (categoryKey == 'tsunami') {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFDC2626),
              content: Text(
                '🌊 Menampilkan Garis Merah Bahaya Tsunami & Zona Hijau (>15 mdpl) Kota Padang',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isPrimaryGreen
                    ? AppColors.primaryDark
                    : const Color(0xFF1E293B))
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.borderLight,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.primaryDarkest,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // FLOATING MAP ACTION BUTTONS
  // (Pusatkan Padang, Lokasi Saya, Zoom In/Out)
  // ==========================================
  Widget _buildFloatingMapControls() {
    return Positioned(
      right: 14,
      bottom: 230,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tombol Pusatkan ke Lokasi Pengguna ("My Location")
          FloatingActionButton.small(
            heroTag: 'my_location_btn',
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2563EB),
            onPressed: _moveToMyLocation,
            elevation: 4,
            child: const Icon(Icons.my_location_rounded, size: 20),
          ),
          const SizedBox(height: 8),

          // Tombol Reset ke Pusat Kota Padang
          FloatingActionButton.small(
            heroTag: 'center_padang_btn',
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primaryDark,
            onPressed: _moveToPadangCenter,
            elevation: 4,
            child: const Icon(Icons.explore_rounded, size: 20),
          ),
          const SizedBox(height: 8),

          // Zoom In
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.add_rounded,
                    color: AppColors.primaryDark,
                    size: 20,
                  ),
                  onPressed: _zoomIn,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
                Container(height: 1, width: 28, color: AppColors.borderLight),
                IconButton(
                  icon: const Icon(
                    Icons.remove_rounded,
                    color: AppColors.primaryDark,
                    size: 20,
                  ),
                  onPressed: _zoomOut,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BANNER RUTE NAVIGASI AKTIF
  // ==========================================
  Widget _buildActiveNavigationBanner() {
    return Positioned(
      top: 110,
      left: 14,
      right: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF15803D),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.directions_walk_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PANDUAN RUTE JALAN KAKI AKTIF',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Menuju ${_selectedLocation.name} (${_selectedLocation.walkTime})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _cancelNavigation,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. KARTU NAVIGASI DARURAT (Di Bawah Peta)
  // Draggable Bottom Sheet / Card
  // ==========================================
  Widget _buildEmergencyBottomSheet() {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 10,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutBack, // Efek pegas (spring/bounce) sangat halus di akhir gerakan
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slideAnim = Tween<Offset>(
            begin: const Offset(0.0, 0.2), // Slide-up dari bawah
            end: Offset.zero,
          ).animate(animation);
          return SlideTransition(
            position: slideAnim,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Container(
          key: ValueKey(_selectedLocation.id),
          padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.borderLight, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar Draggable
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Header: Judul Shelter & Kategori
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedLocation.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDarkest,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedLocation.typeLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_rounded,
                        color: Color(0xFF10B981),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AMAN',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Metrik Singkat: Jarak ("400 meter") & Estimasi ("5 mnt jalan kaki")
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mintAccent.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.near_me_rounded,
                          color: AppColors.primaryDark,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jarak',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: AppColors.textSlate,
                              ),
                            ),
                            Text(
                              _selectedLocation.distance,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDarkest,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mintAccent.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.directions_walk_rounded,
                          color: AppColors.primaryDark,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estimasi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: AppColors.textSlate,
                              ),
                            ),
                            Text(
                              _selectedLocation.walkTime,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDarkest,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Catatan Rute & Elevasi Ringkas
            Row(
              children: [
                const Icon(
                  Icons.terrain_rounded,
                  size: 14,
                  color: AppColors.textSlate,
                ),
                const SizedBox(width: 4),
                Text(
                  _selectedLocation.elevation,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSlate,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // TOMBOL UTAMA SANGAT BESAR & MENCOLOK:
            // "Mulai Rute Evakuasi (Jalan Kaki)"
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _startEvacuationRoute,
                icon: const Icon(
                  Icons.directions_walk_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                label: Text(
                  'Mulai Rute Evakuasi (Jalan Kaki)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF15803D,
                  ), // Hijau Mencolok / Aman
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF15803D).withValues(alpha: 0.4),
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
  // 4 Menu Utama: 1. Beranda, 2. Peringatan, 3. Peta Siaga (Aktif), 4. Keluarga
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
            icon: Icon(Icons.map_rounded),
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
