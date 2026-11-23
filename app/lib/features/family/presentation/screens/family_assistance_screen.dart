import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap/core/theme/app_colors.dart';
import 'package:sigap/core/widgets/sigap_logo.dart';
import 'package:sigap/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:sigap/features/map/presentation/screens/risk_map_screen.dart';
import 'package:sigap/features/settings/presentation/screens/settings_screen.dart';
import 'package:sigap/features/profile/presentation/screens/profile_screen.dart';

/// Model untuk anggota keluarga / orang terdekat
class FamilyMember {
  final String id;
  String name;
  String relation;
  String status; // 'AMAN', 'BELUM TERHUBUNG', 'PERLU KONFIRMASI'
  String locationNote;
  String updateTime;
  String phone;
  bool isPrimary;

  FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    required this.status,
    required this.locationNote,
    required this.updateTime,
    required this.phone,
    this.isPrimary = false,
  });
}

/// Model untuk posko bantuan terdekat
class NearbyAssistance {
  final String name;
  final String distance;
  final String address;
  final String phone;
  final String operationalHours;

  const NearbyAssistance({
    required this.name,
    required this.distance,
    required this.address,
    required this.phone,
    required this.operationalHours,
  });
}

/// Screen Keluarga & Bantuan SIGAP Kota Padang
/// Mengimplementasikan secara presisi desain:
/// "SIGAP mobile — Keluarga & Bantuan — iPhone 17 Pro.svg"
class FamilyAssistanceScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToAlerts;
  final VoidCallback? onNavigateToMap;
  final Function(int)? onTabSelected;

  const FamilyAssistanceScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToAlerts,
    this.onNavigateToMap,
    this.onTabSelected,
  });

  @override
  State<FamilyAssistanceScreen> createState() => _FamilyAssistanceScreenState();
}

class _FamilyAssistanceScreenState extends State<FamilyAssistanceScreen> {
  final int _activeTab = 3; // 3: Keluarga & Bantuan (Active)

  // Status Pengguna Sendiri
  String _myStatus = 'AMAN'; // 'AMAN' | 'BANTUAN'
  final TextEditingController _conditionController = TextEditingController(
    text: 'Saya aman di rumah, sedang menunggu keluarga.',
  );
  bool _shareLocation = false;

  // Daftar Orang Terdekat sesuai Mockup
  final List<FamilyMember> _members = [
    FamilyMember(
      id: '1',
      name: 'Ibu',
      relation: 'Ibu Kandung',
      status: 'AMAN',
      locationNote: 'rumah',
      updateTime: 'update 2 menit lalu',
      phone: '+62 813-8812-8102',
      isPrimary: true,
    ),
    FamilyMember(
      id: '2',
      name: 'Ayah',
      relation: 'Ayah Kandung',
      status: 'BELUM TERHUBUNG',
      locationNote: 'lokasi tidak diketahui',
      updateTime: 'belum ada pembaruan',
      phone: '+62 812-3456-7890',
      isPrimary: false,
    ),
    FamilyMember(
      id: '3',
      name: 'Adik',
      relation: 'Adik',
      status: 'PERLU KONFIRMASI',
      locationNote: 'sekolah',
      updateTime: 'update 40 menit lalu',
      phone: '+62 821-9876-5432',
      isPrimary: false,
    ),
  ];

  // Kontak Darurat Utama
  String _primaryContactName = 'Nurhayati';
  String _primaryContactRelation = 'Ibu';
  String _primaryContactPhone = '+62 813 •••• 8102';

  // Daftar Posko & Bantuan Sekitar
  final List<NearbyAssistance> _facilities = const [
    NearbyAssistance(
      name: 'RSUD terdekat',
      distance: '1.2 km',
      address: 'RSUD Dr. Rasidin Padang, Jl. Air Dingin, Koto Tangah, Padang',
      phone: '(0751) 499158',
      operationalHours: '24 Jam Darurat',
    ),
    NearbyAssistance(
      name: 'Tim SAR posko utama',
      distance: '0.8 km',
      address: 'Pos SAR Gabungan Padang, Kompleks Pelabuhan Teluk Bayur',
      phone: '(0751) 40908',
      operationalHours: '24 Jam Siaga Bencana',
    ),
    NearbyAssistance(
      name: 'Dapur umum lapangan',
      distance: '2.0 km',
      address: 'Gedung Pertemuan Warga RW 04 Kuranji, Padang',
      phone: '0811-6602-334',
      operationalHours: '06:00 - 22:00 WIB',
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
  }

  @override
  void dispose() {
    _conditionController.dispose();
    super.dispose();
  }

  // Ringkasan Jumlah Status
  String get _summaryText {
    int aman = 0;
    int belum = 0;
    int konfirmasi = 0;

    for (var m in _members) {
      if (m.status == 'AMAN') {
        aman++;
      } else if (m.status == 'BELUM TERHUBUNG') {
        belum++;
      } else if (m.status == 'PERLU KONFIRMASI') {
        konfirmasi++;
      }
    }

    return '$aman aman · $belum belum terhubung · $konfirmasi perlu konfirmasi';
  }

  // ==========================================
  // ACTION HANDLERS & MODALS
  // ==========================================

  void _handleStatusSelect(String status) {
    setState(() {
      _myStatus = status;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              status == 'AMAN' ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                status == 'AMAN'
                    ? 'Status Anda diperbarui: SAYA AMAN'
                    : 'Peringatan dikirim: ANDA BUTUH BANTUAN!',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: status == 'AMAN' ? AppColors.primaryDark : AppColors.alertTerracotta,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAddMemberModal() {
    final nameCtrl = TextEditingController();
    final relationCtrl = TextEditingController(text: 'Keluarga');
    final phoneCtrl = TextEditingController(text: '+62 8');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tambah Orang Terdekat',
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
              'Nama Lengkap / Panggilan',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                hintText: 'Contoh: Kakak / Pak RT',
                filled: true,
                fillColor: AppColors.mintSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Hubungan',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: relationCtrl,
              decoration: InputDecoration(
                hintText: 'Contoh: Saudara / Tetangga',
                filled: true,
                fillColor: AppColors.mintSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Nomor Telepon / WhatsApp',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '+62 8...',
                filled: true,
                fillColor: AppColors.mintSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  if (nameCtrl.text.trim().isNotEmpty) {
                    setState(() {
                      _members.add(
                        FamilyMember(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameCtrl.text.trim(),
                          relation: relationCtrl.text.trim(),
                          status: 'BELUM TERHUBUNG',
                          locationNote: 'lokasi baru',
                          updateTime: 'baru ditambahkan',
                          phone: phoneCtrl.text.trim(),
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${nameCtrl.text.trim()} berhasil ditambahkan.'),
                        backgroundColor: AppColors.primaryDark,
                      ),
                    );
                  }
                },
                child: Text(
                  'SIMPAN KONTAK',
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
    );
  }

  void _showMemberDetail(FamilyMember member) {
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      member.relation,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textSlate,
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(member.status),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.location_on_outlined,
              title: 'Catatan Lokasi Terakhir',
              value: member.locationNote == 'rumah'
                  ? 'Rumah (Jl. Sawahan No. 14, Padang Timur)'
                  : member.locationNote == 'sekolah'
                      ? 'Sekolah (SMA Negeri 1 Padang)'
                      : 'Belum memperbarui koordinat GPS',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.access_time_rounded,
              title: 'Waktu Pembaruan Terakhir',
              value: member.updateTime,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.phone_outlined,
              title: 'Nomor Kontak',
              value: member.phone,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.battery_charging_full_rounded,
              title: 'Kondisi Perangkat',
              value: member.status == 'AMAN' ? 'Baterai 82% · Jaringan 4G Kuat' : 'Tidak ada sinyal internet terlacak',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showCallDialog(member);
                    },
                    icon: const Icon(Icons.phone_rounded, size: 18, color: AppColors.primaryDark),
                    label: Text(
                      'Panggil Telepon',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Membuka WhatsApp untuk ${member.name} (${member.phone})...'),
                          backgroundColor: AppColors.primaryDark,
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.white),
                    label: Text(
                      'Chat WhatsApp',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.white,
                      ),
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

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSlate,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCallDialog(FamilyMember member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hubungi ${member.name}',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.primaryDark),
        ),
        content: Text(
          'Panggilan seluler langsung ke ${member.phone}. Pastikan pulsa dan jaringan seluler Anda aktif.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.textSlate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('BATAL', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.textSlate)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Menghubungkan panggilan ke ${member.name} (${member.phone})...'),
                  backgroundColor: AppColors.primaryDark,
                ),
              );
            },
            icon: const Icon(Icons.call_rounded, size: 16, color: Colors.white),
            label: Text('HUBUNGI SEKARANG', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAssistanceLocation(NearbyAssistance item) {
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
                Expanded(
                  child: Text(
                    item.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.mintAccent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'AKTIF',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Jarak: ${item.distance} dari lokasi Anda saat ini',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.alertRust,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.address,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSlate),
            ),
            const SizedBox(height: 6),
            Text(
              'Operasional: ${item.operationalHours}',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.primary),
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
                      content: Text('Membuka rute evakuasi menuju ${item.name}...'),
                      backgroundColor: AppColors.primaryDark,
                    ),
                  );
                },
                icon: const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                label: Text(
                  'PETUNJUK ARAH / NAVIGASI',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEvacuationSheltersModal() {
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
            Text(
              'Lokasi Tempat Evakuasi Sementara (TES)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Daftar shelter vertikal resmi BPBD Kota Padang untuk evakuasi tsunami & gempa bumi:',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textSlate),
            ),
            const SizedBox(height: 16),
            _buildShelterTile('1. TES Pasar Raya Padang', 'Kapasitas 3.000 jiwa · Gedung Blok II, III & IV Pasar Raya'),
            _buildShelterTile('2. Shelter Wisma Indah Ulak Karang', 'Kapasitas 2.500 jiwa · Jl. Beringin, Ulak Karang'),
            _buildShelterTile('3. TES Nurul Haq Kompleks Jondul Rawang', 'Kapasitas 2.000 jiwa · Rawang, Padang Selatan'),
            _buildShelterTile('4. Gedung Escape Building BPBD Sumbar', 'Kapasitas 4.000 jiwa · Jl. Sudirman No. 47'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text('TUTUP', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShelterTile(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.apartment_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSlate)),
              ],
            ),
          ),
        ],
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
                'Keluarga & Bantuan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pantau orang terdekat dan temukan bantuan, meski belum menautkan kontak.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF5C6B61),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),

              // 3. Card 1: PERBARUI STATUS SAYA
              _buildUpdateMyStatusCard(),
              const SizedBox(height: 16),

              // 4. Card 2: RINGKASAN ORANG TERDEKAT
              _buildSummaryCard(),
              const SizedBox(height: 16),

              // 5. Card 3: DAFTAR ORANG TERDEKAT (Ibu, Ayah, Adik)
              _buildMembersListCard(),
              const SizedBox(height: 16),

              // 6. Card 4: Info Note Box (Mint background with lock icon)
              _buildInfoNoteBox(),
              const SizedBox(height: 16),

              // 7. Card 5: Kontak Darurat Utama (Nurhayati)
              _buildEmergencyContactCard(),
              const SizedBox(height: 24),

              // 8. Section: BANTUAN DI SEKITAR ANDA
              Text(
                'Bantuan di sekitar Anda',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Layanan dapat dilihat tanpa menautkan orang terdekat.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF5C6B61),
                ),
              ),
              const SizedBox(height: 14),

              // Nearby Assistance Facilities Card
              _buildAssistanceFacilitiesCard(),
              const SizedBox(height: 14),

              // Disclaimer Box
              _buildDisclaimerBox(),
              const SizedBox(height: 16),

              // Darurat segera? Hubungi 112 Card
              _build112EmergencyCard(),
              const SizedBox(height: 16),

              // CARA MENGGUNAKAN (Tiga langkah sederhana) Card
              _buildHowToUseCard(),
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
        const Flexible(
          child: SigapLogo(
            size: 26,
            showText: true,
            textColor: AppColors.primaryDark,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
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

  Widget _buildUpdateMyStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PERBARUI STATUS SAYA',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textSlate,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bagikan kondisi Anda agar orang terdekat tahu situasi Anda.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: AppColors.textDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Two Action Buttons: SAYA AMAN vs BUTUH BANTUAN
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _myStatus == 'AMAN' ? AppColors.primaryDark : AppColors.mintSurface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: _myStatus == 'AMAN' ? AppColors.primaryDark : AppColors.borderLight,
                        ),
                      ),
                    ),
                    onPressed: () => _handleStatusSelect('AMAN'),
                    child: Text(
                      'SAYA AMAN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _myStatus == 'AMAN' ? Colors.white : AppColors.primaryDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _myStatus == 'BANTUAN' ? AppColors.alertTerracotta : Colors.white,
                      side: const BorderSide(color: AppColors.alertTerracotta, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _handleStatusSelect('BANTUAN'),
                    child: Text(
                      'BUTUH BANTUAN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: _myStatus == 'BANTUAN' ? Colors.white : AppColors.alertTerracotta,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pesan kondisi (opsional)
          Text(
            'Pesan kondisi (opsional)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: TextField(
              controller: _conditionController,
              maxLines: 2,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                hintText: 'Contoh: Saya aman di rumah, sedang menunggu keluarga.',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSlate.withValues(alpha: 0.8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Checkbox: Bagikan lokasi saya kepada orang terdekat
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _shareLocation,
                  activeColor: AppColors.primaryDark,
                  side: const BorderSide(color: AppColors.textSlate, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (val) {
                    setState(() {
                      _shareLocation = val ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _shareLocation = !_shareLocation;
                    });
                  },
                  child: Text(
                    'Bagikan lokasi saya kepada orang terdekat',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Footnote text
          Text(
            'Lokasi hanya dibagikan jika Anda memilihnya. Status dan pesan dikirim saat Anda memilih kondisi.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textSlate,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RINGKASAN ORANG TERDEKAT',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textSlate,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _summaryText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Status terakhir diperbarui 2 menit lalu. Anda bisa menambahkan orang terdekat lain seperti teman atau tetangga.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSlate,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _showAddMemberModal,
              icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              label: Text(
                'TAMBAH ORANG TERDEKAT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersListCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6), width: 1.0),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _members.length,
        separatorBuilder: (context, index) => const Divider(
          color: AppColors.borderLight,
          height: 1,
          thickness: 0.8,
        ),
        itemBuilder: (context, index) {
          final m = _members[index];
          return Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row Header: Nama + Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      m.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    _buildStatusBadge(m.status),
                  ],
                ),
                const SizedBox(height: 4),
                // Subtitle
                Text(
                  '${m.updateTime} · ${m.locationNote}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textSlate,
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons: [detail] and [📞 hubungi]
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.borderLight),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _showMemberDetail(m),
                          child: Text(
                            'detail',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.borderLight),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _showCallDialog(m),
                          icon: const Icon(Icons.phone_outlined, size: 16, color: AppColors.textDark),
                          label: Text(
                            'hubungi',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;

    if (status == 'AMAN') {
      bg = AppColors.mintAccent;
      text = AppColors.primaryDark;
    } else if (status == 'BELUM TERHUBUNG') {
      bg = AppColors.alertPeach;
      text = AppColors.alertTerracotta;
    } else {
      bg = AppColors.alertPeach;
      text = AppColors.alertTerracotta;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: text,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildInfoNoteBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mintAccent.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.primaryDark),
          const SizedBox(height: 8),
          Text(
            'Belum terhubung bukan berarti dalam bahaya. Coba hubungi langsung. Status dan lokasi memerlukan internet; panggilan memerlukan jaringan telepon.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Kontak darurat',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showEditPrimaryContactModal,
                child: Text(
                  'ubah',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Contact Row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderLight, width: 1.5),
                  color: AppColors.mintSurface,
                ),
                child: Center(
                  child: Text(
                    _primaryContactName.isNotEmpty ? _primaryContactName[0] : 'N',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _primaryContactName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'UTAMA',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_primaryContactRelation · $_primaryContactPhone',
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
          const SizedBox(height: 12),

          // Light peach note container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.alertPeach,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Kontak pilihan Anda untuk dihubungi langsung. Tidak ada panggilan otomatis.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.alertTerracotta,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Clickable Link: Hubungi kontak utama · Kelola kontak
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Menghubungi $_primaryContactName ($_primaryContactPhone)...'),
                  backgroundColor: AppColors.primaryDark,
                ),
              );
            },
            child: Text(
              'Hubungi kontak utama · Kelola kontak',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPrimaryContactModal() {
    final nameCtrl = TextEditingController(text: _primaryContactName);
    final relationCtrl = TextEditingController(text: _primaryContactRelation);
    final phoneCtrl = TextEditingController(text: _primaryContactPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ubah Kontak Utama',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Kontak Utama'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: relationCtrl,
              decoration: const InputDecoration(labelText: 'Hubungan (contoh: Ibu, Pasangan)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Nomor Kontak'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  setState(() {
                    _primaryContactName = nameCtrl.text.trim();
                    _primaryContactRelation = relationCtrl.text.trim();
                    _primaryContactPhone = phoneCtrl.text.trim();
                  });
                  Navigator.pop(ctx);
                },
                child: Text('SIMPAN PERUBAHAN', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistanceFacilitiesCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _facilities.length,
        separatorBuilder: (context, index) => const Divider(
          color: AppColors.borderLight,
          height: 1,
          thickness: 0.8,
        ),
        itemBuilder: (context, index) {
          final f = _facilities[index];
          return Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${f.distance} · aktif',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textSlate,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.borderLight),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Memanggil ${f.name} (${f.phone})...'),
                                backgroundColor: AppColors.primaryDark,
                              ),
                            );
                          },
                          icon: const Icon(Icons.phone_outlined, size: 16, color: AppColors.textDark),
                          label: Text(
                            'hubungi',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.borderLight),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _showAssistanceLocation(f),
                          icon: const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textDark),
                          label: Text(
                            'lokasi',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDisclaimerBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.7)),
      ),
      child: Text(
        'Contoh data posko, bukan kondisi real-time. Pastikan informasi dan ketersediaan bantuan melalui petugas.',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: AppColors.textSlate,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _build112EmergencyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Darurat segera? Hubungi 112',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ketersediaan layanan mengikuti wilayah. Gunakan jaringan telepon; respons bergantung kondisi lapangan.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSlate,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _showEvacuationSheltersModal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'Lihat lokasi evakuasi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primaryDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToUseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CARA MENGGUNAKAN',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textSlate,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tiga langkah sederhana',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Untuk keluarga, teman, tetangga, atau pendamping. Bantuan tetap tersedia untuk pengguna tanpa kontak tertaut.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSlate,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          _buildNumberedStep(
            number: '1',
            text: 'Lihat status orang terdekat dan tambahkan kontak baru.',
          ),
          const SizedBox(height: 12),
          _buildNumberedStep(
            number: '2',
            text: 'Bagikan kondisi Anda kepada orang terdekat.',
          ),
          const SizedBox(height: 12),
          _buildNumberedStep(
            number: '3',
            text: 'Cari posko darurat terdekat dan hubungi kontak utama jika diperlukan.',
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedStep({
    required String number,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.mintAccent,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BOTTOM NAVIGATION BAR (Tab 3: Keluarga & Bantuan Aktif)
  // ==========================================

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
              index: 3,
              icon: Icons.group_rounded,
              label: 'Keluarga & Bantuan',
              onTap: () {},
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryDark : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color: isActive ? Colors.white : AppColors.textSlate,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  color: isActive ? Colors.white : AppColors.textSlate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
