import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap/core/navigation/sigap_transitions.dart';
import 'package:sigap/core/theme/app_colors.dart';
import 'package:sigap/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:sigap/features/dashboard/presentation/screens/home_screen.dart';
import 'package:sigap/features/evacuation/data/evacuation_location_service.dart';
import 'package:sigap/features/evacuation/data/padang_evacuation_data.dart';
import 'package:sigap/features/evacuation/domain/evacuation_decision_engine.dart';
import 'package:sigap/features/family/presentation/screens/keluarga_screen.dart';
import 'package:sigap/features/profile/presentation/screens/profile_screen.dart';
import 'package:sigap/features/settings/presentation/screens/pengaturan_screen.dart';
import 'package:sigap/features/vision/data/damage_report_repository.dart';
import '../../data/damage_heatmap_service.dart';
import '../../domain/damage_heatmap_point.dart';

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

/// Screen Peta Interaktif SIGAP Kota Padang (FE-08).
/// Menggunakan [FlutterMap] dengan koordinat riil Kota Padang, lokasi GPS dinamis,
/// 3 zona elevasi tsunami (Merah/Kuning/Hijau), konsistensi data shelter TES
/// dengan [PadangEvacuationData], serta layer Heatmap Sebaran Kerusakan SIGAP-Vision.
class PetaScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToAlerts;
  final VoidCallback? onNavigateToFamily;
  final Function(int)? onTabSelected;
  final bool embedded;
  final EvacuationLocationService? locationService;
  final DamageReportRepository? damageReportRepository;
  final DamageHeatmapService? heatmapService;

  const PetaScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToAlerts,
    this.onNavigateToFamily,
    this.onTabSelected,
    this.embedded = false,
    this.locationService,
    this.damageReportRepository,
    this.heatmapService,
  });

  @override
  State<PetaScreen> createState() => _PetaScreenState();
}

class _PetaScreenState extends State<PetaScreen>
    with SingleTickerProviderStateMixin {
  final int _activeBottomNavIndex = 2; // 2: Peta Siaga (Aktif)

  // Controller Peta & Services
  late final MapController _mapController;
  late final EvacuationLocationService _locationService;
  late final DamageReportRepository _damageRepository;
  late final DamageHeatmapService _heatmapService;

  // Koordinat Utama Kota Padang (Latitude: -0.9471, Longitude: 100.3658)
  static const LatLng _padangCenter = LatLng(-0.9471, 100.3658);

  // Lokasi Pengguna Dinamis (default fallback Padang Barat konsisten dengan PadangEvacuationData)
  LatLng _userLocation = PadangEvacuationData.defaultFallbackLocation;
  bool _hasLiveGpsFix = false;
  bool _isRefreshingGps = false;

  // Camera Boundary: Batas Geser Peta Terkunci Khusus Wilayah Padang & Sekitarnya
  final LatLngBounds _padangBounds = LatLngBounds(
    const LatLng(
      -1.1500,
      100.2200,
    ), // Barat Daya (Pesisir Teluk Bayur / Samudra)
    const LatLng(-0.7600, 100.5200), // Timur Laut (Koto Tangah / Batang Anai)
  );

  // Filter Kategori Aktif: 'shelter', 'hospital', 'posko', 'tsunami', 'heatmap'
  String _selectedCategory = 'shelter';
  final TextEditingController _searchController = TextEditingController();

  // Daftar lokasi fasilitas (4 shelter TES disinkronkan dari PadangEvacuationData)
  late final List<PadangMapLocation> _locations;

  // Shelter / Lokasi Terpilih untuk Kartu Navigasi Bawah
  late PadangMapLocation _selectedLocation;
  bool _isNavigating = false;

  // State Layer Heatmap Kerusakan SIGAP-Vision (FE-08)
  List<DamageHeatmapPoint> _heatmapPoints = const <DamageHeatmapPoint>[];
  DamageHeatmapLoadResult? _heatmapLoadResult;
  DamageHeatmapPoint? _selectedHeatmapPoint;
  bool _isLoadingHeatmap = false;
  bool _hasAttemptedHeatmapLoad = false;

  // Animasi pulsing untuk titik biru "My Location"
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const Map<String, ({String typeLabel, String distance, String walkTime, String phone})>
      _tesMetadata = {
    'shelter_unp': (
      typeLabel: 'Tempat Evakuasi Sementara',
      distance: '400 meter',
      walkTime: '5 mnt jalan kaki',
      phone: '(0751) 7051260',
    ),
    'shelter_ulak_karang': (
      typeLabel: 'TES Utama Mandiri',
      distance: '850 meter',
      walkTime: '10 mnt jalan kaki',
      phone: '(0751) 778775',
    ),
    'shelter_masjid_raya': (
      typeLabel: 'Shelter Titik Kumpul Akbar',
      distance: '1.8 km',
      walkTime: '22 mnt jalan kaki',
      phone: '(0751) 8950001',
    ),
    'shelter_smp1': (
      typeLabel: 'Shelter Vertikal Bertingkat',
      distance: '1.2 km',
      walkTime: '15 mnt jalan kaki',
      phone: '(0751) 21545',
    ),
  };

  List<PadangMapLocation> _buildPadangLocations() {
    // 1. 4 Shelter TES langsung dari PadangEvacuationData (single source of truth dengan FE-07)
    final shelters = PadangEvacuationData.tesShelters.map((tes) {
      final meta = _tesMetadata[tes.id];
      return PadangMapLocation(
        id: tes.id,
        name: tes.name,
        category: 'shelter',
        typeLabel: meta?.typeLabel ?? 'Tempat Evakuasi Sementara',
        distance: meta?.distance ?? '1.0 km',
        walkTime: meta?.walkTime ?? '12 mnt jalan kaki',
        elevation: tes.elevationLabel,
        capacity: tes.capacityLabel,
        routeNote: tes.routeNote,
        position: tes.latLng,
        phone: meta?.phone ?? '112',
      );
    });

    return <PadangMapLocation>[
      ...shelters,

      // 🏥 Rumah Sakit & PMI
      const PadangMapLocation(
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
      const PadangMapLocation(
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
      const PadangMapLocation(
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
      const PadangMapLocation(
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
      const PadangMapLocation(
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
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _locationService =
        widget.locationService ?? DefaultEvacuationLocationService.instance;
    _damageRepository =
        widget.damageReportRepository ?? DamageReportRepository.instance;
    _heatmapService =
        widget.heatmapService ??
        DefaultDamageHeatmapService(repository: _damageRepository);

    _locations = _buildPadangLocations();
    _selectedLocation = _locations.first; // Default: Gedung TES UNP

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _damageRepository.reportsNotifier.addListener(_onLocalDamageReportsChanged);
    _seedLocalHeatmapPointsFromNotifier();
    _refreshUserLocation(moveCamera: false, showFeedback: false);
  }

  @override
  void dispose() {
    _damageRepository.reportsNotifier.removeListener(
      _onLocalDamageReportsChanged,
    );
    _searchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _seedLocalHeatmapPointsFromNotifier() {
    final localPoints = _damageRepository.reportsNotifier.value
        .map(DamageHeatmapPoint.fromLocalReport)
        .whereType<DamageHeatmapPoint>()
        .toList();
    if (localPoints.isNotEmpty) {
      _heatmapPoints = localPoints;
    }
  }

  void _onLocalDamageReportsChanged() {
    if (!mounted) return;
    if (_selectedCategory == 'heatmap' || _hasAttemptedHeatmapLoad) {
      _loadHeatmapData();
    } else {
      setState(_seedLocalHeatmapPointsFromNotifier);
    }
  }

  Future<void> _loadHeatmapData({bool showFeedback = false}) async {
    if (_isLoadingHeatmap) return;
    setState(() {
      _isLoadingHeatmap = true;
      _hasAttemptedHeatmapLoad = true;
    });

    final result = await _heatmapService.loadHeatmapPoints();
    if (!mounted) return;

    DamageHeatmapPoint? nextSelected = _selectedHeatmapPoint;
    if (nextSelected != null) {
      final stillExists = result.points.any((p) => p.id == nextSelected!.id);
      if (!stillExists) {
        nextSelected = null;
      }
    }

    setState(() {
      _heatmapLoadResult = result;
      _heatmapPoints = result.points;
      _selectedHeatmapPoint = nextSelected;
      _isLoadingHeatmap = false;
    });

    if (showFeedback) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: result.serverAvailable
              ? const Color(0xFF15803D)
              : const Color(0xFF1E293B),
          duration: const Duration(seconds: 3),
          content: Text(
            result.statusMessage,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  double _distanceMetersTo(PadangMapLocation loc) {
    return calculateHaversineDistanceMeters(
      _userLocation.latitude,
      _userLocation.longitude,
      loc.position.latitude,
      loc.position.longitude,
    );
  }

  /// Menampilkan jarak dinamis dari GPS nyata bila tersedia, atau nilai bawaan
  /// bila masih dalam mode fallback awal.
  String _displayDistanceFor(PadangMapLocation loc) {
    if (!_hasLiveGpsFix) return loc.distance;
    return formatEvacuationDistance(_distanceMetersTo(loc));
  }

  /// Menampilkan estimasi jalan kaki dinamis dari GPS nyata bila tersedia, atau
  /// nilai bawaan bila masih dalam mode fallback awal.
  String _displayWalkTimeFor(PadangMapLocation loc) {
    if (!_hasLiveGpsFix) return loc.walkTime;
    final eta = estimateEmergencyWalkingMinutes(_distanceMetersTo(loc));
    if (eta <= 0.5) return '< 1 mnt jalan kaki';
    return '${eta.ceil()} mnt jalan kaki';
  }

  Future<void> _refreshUserLocation({
    required bool moveCamera,
    required bool showFeedback,
  }) async {
    if (_isRefreshingGps) return;
    _isRefreshingGps = true;

    final result = await _locationService.fetchCurrentLocation();
    _isRefreshingGps = false;
    if (!mounted) return;

    final bool wasLive = _hasLiveGpsFix;
    setState(() {
      _userLocation = result.position;
      _hasLiveGpsFix = !result.isFallback;

      // Saat pertama kali memperoleh fix GPS nyata, otomatis sorot shelter
      // terdekat dari posisi nyata pengguna.
      if (_hasLiveGpsFix && !wasLive && _selectedCategory == 'shelter') {
        final shelters = _locations
            .where((l) => l.category == 'shelter')
            .toList()
          ..sort((a, b) => _distanceMetersTo(a).compareTo(_distanceMetersTo(b)));
        if (shelters.isNotEmpty) {
          _selectedLocation = shelters.first;
        }
      }
    });

    if (moveCamera) {
      _mapController.move(_userLocation, 15.0);
    }

    if (showFeedback) {
      final latStr = _userLocation.latitude.toStringAsFixed(4);
      final lngStr = _userLocation.longitude.toStringAsFixed(4);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _hasLiveGpsFix
                ? '📍 Memusatkan ke Lokasi GPS Anda ($latStr, $lngStr)'
                : '📍 GPS tidak aktif/ditolak — menampilkan lokasi perkiraan Padang Barat ($latStr, $lngStr)',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          backgroundColor: _hasLiveGpsFix
              ? const Color(0xFF2563EB)
              : const Color(0xFFB45309),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _moveToPadangCenter() {
    HapticFeedback.lightImpact();
    _mapController.move(_padangCenter, 13.0);
  }

  void _moveToMyLocation() {
    HapticFeedback.mediumImpact();
    _refreshUserLocation(moveCamera: true, showFeedback: true);
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
      _selectedHeatmapPoint = null;
    });
    _mapController.move(loc.position, 14.5);
  }

  void _selectHeatmapPoint(DamageHeatmapPoint point) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedHeatmapPoint = point;
    });
    _mapController.move(point.position, 15.0);
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

    final distLabel = _displayDistanceFor(_selectedLocation);
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
                'Rute Evakuasi Aktif: Ikuti jalur hijau menuju ${_selectedLocation.name} ($distLabel)',
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
    if (_selectedCategory == 'heatmap') {
      return const <PadangMapLocation>[];
    }

    final query = _searchController.text.trim().toLowerCase();
    final filtered = _locations.where((loc) {
      final matchesCategory =
          _selectedCategory == 'tsunami' || loc.category == _selectedCategory;
      if (query.isEmpty) return matchesCategory;
      return matchesCategory &&
          (loc.name.toLowerCase().contains(query) ||
              loc.typeLabel.toLowerCase().contains(query) ||
              loc.routeNote.toLowerCase().contains(query));
    }).toList();

    if (_hasLiveGpsFix) {
      filtered.sort(
        (a, b) => _distanceMetersTo(a).compareTo(_distanceMetersTo(b)),
      );
    }
    return filtered;
  }

  List<DamageHeatmapPoint> get _filteredHeatmapPoints {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _heatmapPoints;
    return _heatmapPoints.where((pt) {
      return pt.description.toLowerCase().contains(query) ||
          pt.category.label.toLowerCase().contains(query) ||
          pt.sourceLabel.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mapStack = Stack(
      children: [
        // 1. WIDGET PETA INTERAKTIF SUNGGUHAN (FlutterMap)
        _buildInteractiveMap(),

        // Banner Rute Navigasi Berjalan Kaki Aktif (Jika diaktifkan)
        if (_isNavigating && _selectedCategory != 'heatmap')
          _buildActiveNavigationBanner(),

        // Legenda 3 Zona Elevasi Tsunami (Jika filter Zona Tsunami aktif)
        if (_selectedCategory == 'tsunami') _buildTsunamiZoneLegend(),

        // Banner Status Jujur Heatmap Kerusakan (Jika filter Peta Kerusakan aktif)
        if (_selectedCategory == 'heatmap') _buildHeatmapStatusBanner(),

        // 2. SEARCH BAR & FILTER LOKASI (Di Atas Peta)
        _buildFloatingSearchAndFilters(),

        // Floating Map Action Buttons (Lokasi Saya, Zoom, Pusatkan)
        _buildFloatingMapControls(),

        // 3. KARTU DETAIL BAWAH (Shelter atau Detail Heatmap Kerusakan)
        if (_selectedCategory == 'heatmap')
          _buildHeatmapBottomCard()
        else
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
            // ATURAN GLOBAL 1: HEADER STICKY / FIXED (dengan tombol kembali bila canPop)
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
    final canPop = Navigator.of(context).canPop();
    final subtitleText = _hasLiveGpsFix
        ? 'GPS Aktif (${_userLocation.latitude.toStringAsFixed(4)}, ${_userLocation.longitude.toStringAsFixed(4)})'
        : 'Padang, Sumbar · GPS Siaga Aktif';

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
          if (canPop)
            IconButton(
              key: const ValueKey('peta_back_button'),
              tooltip: 'Kembali',
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).maybePop();
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.primaryDark,
                size: 24,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            )
          else
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
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
                      decoration: BoxDecoration(
                        color: _hasLiveGpsFix
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        subtitleText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSlate,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                    'Layer Peta: Shelter TES, 3 Zona Elevasi Tsunami, & Heatmap Kerusakan SIGAP-Vision.',
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
    final visibleHeatmapPoints = _selectedCategory == 'heatmap'
        ? _filteredHeatmapPoints
        : const <DamageHeatmapPoint>[];

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

        // Layer 3 Zona Elevasi Tsunami (Merah <5m, Kuning 5-10m, Hijau >15m)
        if (_selectedCategory == 'tsunami') ...[
          PolygonLayer(
            polygons: [
              // 1. Zona Merah Tsunami (<5 mdpl: Pesisir Pantai Padang / Muara Batang Arau s/d Jl. Veteran)
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

              // 2. Zona Kuning Waspada (5-10 mdpl: Zona Transisi antara pesisir dan Bypass Timur)
              Polygon(
                points: const [
                  LatLng(-0.8750, 100.3450),
                  LatLng(-0.9000, 100.3580),
                  LatLng(-0.9400, 100.3650),
                  LatLng(-0.9750, 100.3700),
                  LatLng(-0.9600, 100.3950),
                  LatLng(-0.9200, 100.3800),
                  LatLng(-0.8800, 100.3700),
                ],
                color: const Color(0xFFF59E0B).withValues(alpha: 0.22),
                borderColor: const Color(0xFFD97706),
                borderStrokeWidth: 2.0,
              ),

              // 3. Zona Hijau Aman Evakuasi (>15 mdpl: Wilayah Timur / By Pass)
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

        // Layer Circle Heatmap Sebaran Kerusakan SIGAP-Vision (FE-08)
        if (_selectedCategory == 'heatmap' && visibleHeatmapPoints.isNotEmpty)
          CircleLayer(
            circles: visibleHeatmapPoints.map((pt) {
              return CircleMarker(
                point: pt.position,
                radius: pt.circleRadiusMeters,
                useRadiusInMeter: true,
                color: pt.overlayColor.withValues(alpha: 0.26),
                borderColor: pt.overlayColor,
                borderStrokeWidth: 2.0,
              );
            }).toList(),
          ),

        // Polyline Rute Evakuasi Jalan Kaki (Ketika user menekan tombol Mulai Rute)
        if (_isNavigating && _selectedCategory != 'heatmap') ...[
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

        // Marker Layer: Titik Lokasi Pengguna ("My Location"), Fasilitas, & Titik Heatmap
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

            // Marker Titik Kerusakan SIGAP-Vision (Saat filter 'heatmap' aktif)
            ...visibleHeatmapPoints.map((pt) {
              final isSelected = _selectedHeatmapPoint?.id == pt.id;
              return Marker(
                point: pt.position,
                width: isSelected ? 46 : 36,
                height: isSelected ? 46 : 36,
                child: GestureDetector(
                  key: ValueKey('heatmap_marker_${pt.id}'),
                  onTap: () => _selectHeatmapPoint(pt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? pt.overlayColor : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : pt.overlayColor,
                        width: isSelected ? 3 : 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: pt.overlayColor.withValues(alpha: 0.35),
                          blurRadius: isSelected ? 8 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        pt.category.icon,
                        color: isSelected ? Colors.white : pt.overlayColor,
                        size: isSelected ? 22 : 17,
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
                const SizedBox(width: 8),

                // 5. [🔥 Peta Kerusakan] (FE-08 Heatmap SIGAP-Vision)
                _buildFilterChip(
                  label: '🔥 Peta Kerusakan',
                  categoryKey: 'heatmap',
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
          if (categoryKey != 'heatmap') {
            _selectedHeatmapPoint = null;
          }
        });

        if (categoryKey == 'tsunami') {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFDC2626),
              content: Text(
                '🌊 Menampilkan 3 Zona Elevasi Tsunami: Merah (<5m), Kuning (5-10m), & Hijau (>15m)',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (categoryKey == 'heatmap') {
          _loadHeatmapData();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isPrimaryGreen
                    ? AppColors.primaryDark
                    : categoryKey == 'heatmap'
                    ? const Color(0xFF991B1B)
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
  // LEGENDA 3 ZONA ELEVASI TSUNAMI (FE-08)
  // ==========================================
  Widget _buildTsunamiZoneLegend() {
    return Positioned(
      top: _isNavigating ? 176 : 114,
      left: 14,
      right: 74,
      child: Container(
        key: const ValueKey('tsunami_zone_legend'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            _buildLegendDot(const Color(0xFFEF4444), 'Merah <5 mdpl'),
            _buildLegendDot(const Color(0xFFF59E0B), 'Kuning 5-10 mdpl'),
            _buildLegendDot(const Color(0xFF10B981), 'Hijau >15 mdpl'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDarkest,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BANNER STATUS HEATMAP KERUSAKAN (FE-08)
  // ==========================================
  Widget _buildHeatmapStatusBanner() {
    final result = _heatmapLoadResult;
    final message = _isLoadingHeatmap
        ? 'Memuat titik kerusakan lokal & server...'
        : (result?.statusMessage ??
              'Menampilkan ${_heatmapPoints.length} titik kerusakan lokal.');

    return Positioned(
      top: 114,
      left: 14,
      right: 74,
      child: Container(
        key: const ValueKey('heatmap_status_banner'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (result?.serverAvailable ?? false)
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              (result?.serverAvailable ?? false)
                  ? Icons.cloud_done_rounded
                  : Icons.storage_rounded,
              size: 18,
              color: (result?.serverAvailable ?? false)
                  ? const Color(0xFF047857)
                  : const Color(0xFFB45309),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDarkest,
                  height: 1.3,
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('heatmap_refresh_button'),
              tooltip: 'Muat ulang heatmap',
              onPressed: _isLoadingHeatmap
                  ? null
                  : () => _loadHeatmapData(showFeedback: true),
              icon: _isLoadingHeatmap
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: AppColors.primaryDark,
                    ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
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
          // Tombol Titik Kumpul Keluarga
          FloatingActionButton.small(
            heroTag: 'family_meeting_point_btn',
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menampilkan rute ke Titik Kumpul Keluarga...'),
                ),
              );
            },
            elevation: 4,
            child: const Icon(Icons.family_restroom, size: 20),
          ),
          const SizedBox(height: 8),

          // Tombol Pusatkan ke Lokasi Pengguna ("My Location")
          FloatingActionButton.small(
            key: const ValueKey('my_location_fab'),
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

          // Zoom In & Zoom Out
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
                    'Menuju ${_selectedLocation.name} (${_displayWalkTimeFor(_selectedLocation)})',
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
  // KARTU DETAIL HEATMAP KERUSAKAN / EMPTY STATE (FE-08)
  // ==========================================
  Widget _buildHeatmapBottomCard() {
    final selected = _selectedHeatmapPoint;
    final visiblePoints = _filteredHeatmapPoints;

    return Positioned(
      left: 12,
      right: 12,
      bottom: 10,
      child: Container(
        key: ValueKey(
          selected != null ? 'heatmap_detail_${selected.id}' : 'heatmap_summary_card',
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected != null
                ? selected.overlayColor
                : AppColors.borderLight,
            width: selected != null ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: selected != null
            ? _buildHeatmapPointDetailsContent(selected)
            : _buildHeatmapOverviewOrEmptyContent(visiblePoints),
      ),
    );
  }

  Widget _buildHeatmapPointDetailsContent(DamageHeatmapPoint point) {
    final coordStr =
        '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
    final timeStr =
        '${point.reportedAt.day.toString().padLeft(2, '0')}/${point.reportedAt.month.toString().padLeft(2, '0')}/${point.reportedAt.year} '
        '${point.reportedAt.hour.toString().padLeft(2, '0')}:${point.reportedAt.minute.toString().padLeft(2, '0')}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: point.category.backgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: point.category.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    point.category.icon,
                    size: 14,
                    color: point.category.accentColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    point.category.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: point.category.textColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.mintSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Text(
                point.sourceLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => setState(() => _selectedHeatmapPoint = null),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          point.description,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDarkest,
            height: 1.35,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            Text(
              'Confidence: ${point.confidenceLabel}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            Text(
              'GPS: $coordStr',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSlate,
              ),
            ),
            Text(
              'Waktu: $timeStr',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSlate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Status: ${point.syncStatusLabel}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapOverviewOrEmptyContent(
    List<DamageHeatmapPoint> visiblePoints,
  ) {
    if (visiblePoints.isEmpty) {
      return Column(
        key: const ValueKey('heatmap_empty_card'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primaryDark,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Belum Ada Titik Kerusakan Tercatat',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDarkest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Titik sebaran kerusakan akan muncul otomatis di peta setelah Anda memindai bangunan dengan koordinat GPS melalui fitur SIGAP-Vision atau saat server heatmap tersedia.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSlate,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoadingHeatmap
                  ? null
                  : () => _loadHeatmapData(showFeedback: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Muat Ulang Data Kerusakan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Peta Sebaran Kerusakan (${visiblePoints.length} Titik)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryDarkest,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ketuk penanda di peta atau pilih laporan terbaru di bawah untuk melihat detail risiko.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSlate,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 54,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: visiblePoints.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final pt = visiblePoints[index];
              return GestureDetector(
                key: ValueKey('heatmap_chip_${pt.id}'),
                onTap: () => _selectHeatmapPoint(pt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: pt.category.backgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: pt.category.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        pt.category.icon,
                        size: 18,
                        color: pt.category.accentColor,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            pt.category.shortLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: pt.category.textColor,
                            ),
                          ),
                          Text(
                            pt.sourceLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSlate,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 3. KARTU NAVIGASI DARURAT (Di Bawah Peta)
  // Draggable Bottom Sheet / Card
  // ==========================================
  Widget _buildEmergencyBottomSheet() {
    final displayDistance = _displayDistanceFor(_selectedLocation);
    final displayWalkTime = _displayWalkTimeFor(_selectedLocation);

    return Positioned(
      left: 12,
      right: 12,
      bottom: 10,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slideAnim = Tween<Offset>(
            begin: const Offset(0.0, 0.2),
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

              // Metrik Singkat: Jarak & Estimasi Jalan Kaki
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
                          Expanded(
                            child: Column(
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
                                  displayDistance,
                                  key: const ValueKey('shelter_distance_text'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDarkest,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
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
                          Expanded(
                            child: Column(
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
                                  displayWalkTime,
                                  key: const ValueKey('shelter_walk_time_text'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDarkest,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
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
                  Expanded(
                    child: Text(
                      _selectedLocation.elevation,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSlate,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                    backgroundColor: const Color(0xFF15803D),
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
