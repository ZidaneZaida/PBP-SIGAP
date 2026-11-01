import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap/core/navigation/sigap_transitions.dart';
import 'package:sigap/core/theme/app_colors.dart';
import 'package:sigap/features/alerts/presentation/screens/peringatan_screen.dart';
import 'package:sigap/features/dashboard/presentation/screens/home_screen.dart';
import 'package:sigap/features/map/presentation/screens/peta_screen.dart';
import 'package:sigap/features/profile/presentation/screens/profile_screen.dart';
import 'package:sigap/features/settings/presentation/screens/pengaturan_screen.dart';

/// Status Keberadaan / Keamanan Anggota Keluarga
enum FamilySafetyStatus {
  aman, // Hijau: Kondisi Aman
  menungguKonfirmasi, // Oranye: Menunggu Konfirmasi / Dalam Perjalanan
  belumTerhubung, // Merah: Belum Terhubung / Sinyal Hilang
}

/// Model Data Anggota Keluarga SIGAP
class FamilyMember {
  final String id;
  final String name;
  final String relation;
  String statusNote;
  FamilySafetyStatus safetyStatus;
  int batteryLevel;
  String updateTime;
  String locationNote;
  final String phone;
  bool isPingSent;

  FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    required this.statusNote,
    required this.safetyStatus,
    required this.batteryLevel,
    required this.updateTime,
    required this.locationNote,
    required this.phone,
    this.isPingSent = false,
  });
}

/// Screen Komponen Tab Keempat: "KeluargaScreen"
///
/// Halaman ini dirancang untuk komunikasi cepat saat jaringan sibuk
/// dan pengguna sedang panik:
/// - Header (Profil & Pengaturan) dan Bottom Navigation Bar FIXED/STICKY.
/// - Tab "Keluarga" di menu bawah berada dalam state Aktif (Hijau Tua).
/// - 1. Bar "Status Saya" di bagian paling atas (Compact Card).
/// - 2. Daftar Anggota Keluarga (Vertical List) dengan cincin status, baterai, waktu update, dan tombol aksi cepat.
/// - 3. Modal Pesan Cepat (Canned Responses) via Draggable Bottom Sheet.
/// - 4. Tombol "+ Tambah Keluarga" via WhatsApp.
class KeluargaScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToAlerts;
  final VoidCallback? onNavigateToMap;
  final Function(int)? onTabSelected;
  final bool embedded;

  const KeluargaScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToAlerts,
    this.onNavigateToMap,
    this.onTabSelected,
    this.embedded = false,
  });

  @override
  State<KeluargaScreen> createState() => _KeluargaScreenState();
}

class _KeluargaScreenState extends State<KeluargaScreen> {
  final int _activeBottomNavIndex = 3; // 3: Keluarga (Aktif)

  // Status Pengguna Sendiri
  FamilySafetyStatus _mySafetyStatus = FamilySafetyStatus.aman;
  String _myStatusNote = '🟢 AMAN (Update 2 mnt lalu)';
  String _myStatusLocation = 'Dekat Kantor Camat Padang Barat';

  // Daftar Anggota Keluarga (Contoh Data Padang)
  final List<FamilyMember> _familyMembers = [
    FamilyMember(
      id: 'fam_1',
      name: 'Ibu',
      relation: 'Ibu Kandung',
      statusNote: 'Aman di Masjid Raya',
      safetyStatus: FamilySafetyStatus.aman, // Hijau
      batteryLevel: 78,
      updateTime: '2 mnt lalu',
      locationNote: 'Kec. Padang Barat (Zona Hijau)',
      phone: '+62 812-7564-9011',
    ),
    FamilyMember(
      id: 'fam_2',
      name: 'Adik Aulia',
      relation: 'Adik',
      statusNote: 'Menuju Shelter UNP',
      safetyStatus: FamilySafetyStatus.menungguKonfirmasi, // Oranye
      batteryLevel: 42,
      updateTime: '5 mnt lalu',
      locationNote: 'Air Tawar Barat, Padang Utara',
      phone: '+62 821-6543-2289',
    ),
    FamilyMember(
      id: 'fam_3',
      name: 'Ayah Hendra',
      relation: 'Ayah Kandung',
      statusNote: 'Belum merespons',
      safetyStatus: FamilySafetyStatus.belumTerhubung, // Merah
      batteryLevel: 15,
      updateTime: '18 mnt lalu',
      locationNote: 'Sinyal terakhir: Teluk Bayur',
      phone: '+62 813-8821-4450',
    ),
  ];

  @override
  void dispose() {
    super.dispose();
  }

  // ==========================================
  // LOGIKA NAVIGASI BOTTOM BAR
  // ==========================================
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
          MaterialPageRoute(builder: (context) => const PeringatanScreen()),
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
    }
  }

  // ==========================================
  // 1. MODAL UBAH STATUS SAYA
  // ==========================================
  void _showChangeStatusModal() {
    HapticFeedback.mediumImpact();
    showSigapModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Perbarui Status Anda',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDarkest,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Disinkronkan ke keluarga · $_myStatusLocation',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textSlate,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSlate),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  const SizedBox(height: 18),

                  // Opsi 1: AMAN (Hijau)
                  _buildStatusOption(
                    title: '🟢 SAYA AMAN',
                    subtitle: 'Kondisi baik, sudah berada di lokasi aman / shelter.',
                    isSelected: _mySafetyStatus == FamilySafetyStatus.aman,
                    selectedBorderColor: const Color(0xFF10B981),
                    selectedBgColor: const Color(0xFFECFDF5),
                    onTap: () {
                      setModalState(() {
                        _mySafetyStatus = FamilySafetyStatus.aman;
                        _myStatusNote = '🟢 AMAN (Baru saja)';
                        _myStatusLocation = 'Titik Kumpul / Lokasi Aman Padang';
                      });
                      setState(() {});
                      HapticFeedback.selectionClick();
                    },
                  ),
                  const SizedBox(height: 10),

                  // Opsi 2: MENUNGGU KONFIRMASI (Oranye)
                  _buildStatusOption(
                    title: '🟡 SEDANG EVAKUASI / DI PERJALANAN',
                    subtitle: 'Dalam pergerakan menuju titik kumpul, sinyal terbatas.',
                    isSelected: _mySafetyStatus == FamilySafetyStatus.menungguKonfirmasi,
                    selectedBorderColor: const Color(0xFFF59E0B),
                    selectedBgColor: const Color(0xFFFFFBEB),
                    onTap: () {
                      setModalState(() {
                        _mySafetyStatus = FamilySafetyStatus.menungguKonfirmasi;
                        _myStatusNote = '🟡 SEDANG EVAKUASI (Baru saja)';
                        _myStatusLocation = 'Dalam perjalanan evakuasi';
                      });
                      setState(() {});
                      HapticFeedback.selectionClick();
                    },
                  ),
                  const SizedBox(height: 10),

                  // Opsi 3: BUTUH BANTUAN (Merah)
                  _buildStatusOption(
                    title: '🔴 BUTUH BANTUAN DARURAT (SOS)',
                    subtitle: 'Terjebak, terluka, atau memerlukan pertolongan segera!',
                    isSelected: _mySafetyStatus == FamilySafetyStatus.belumTerhubung,
                    selectedBorderColor: const Color(0xFFEF4444),
                    selectedBgColor: const Color(0xFFFEF2F2),
                    onTap: () {
                      setModalState(() {
                        _mySafetyStatus = FamilySafetyStatus.belumTerhubung;
                        _myStatusNote = '🔴 BUTUH BANTUAN (Baru saja)';
                        _myStatusLocation = 'Butuh pertolongan darurat segera!';
                      });
                      setState(() {});
                      HapticFeedback.selectionClick();
                    },
                  ),
                  const SizedBox(height: 20),

                  // Tombol Konfirmasi Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: _getStatusColor(_mySafetyStatus),
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Status Anda diperbarui: $_myStatusNote',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Simpan & Beri Tahu Keluarga',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          },
        );
      },
    );
  }

  Widget _buildStatusOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color selectedBorderColor,
    required Color selectedBgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? selectedBorderColor : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
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
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? selectedBorderColor : AppColors.borderLight,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2. LOGIKA PING / MINTA KABAR (LONCENG)
  // ==========================================
  void _sendPingToMember(FamilyMember member) {
    HapticFeedback.heavyImpact();
    setState(() {
      member.isPingSent = true;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        content: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: Color(0xFFF59E0B), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white),
                  children: [
                    const TextSpan(text: '🔔 Sinyal Ping Terkirim ke '),
                    TextSpan(
                      text: member.name,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFCD34D)),
                    ),
                    const TextSpan(text: '! Notifikasi getar prioritas dikirimkan ke ponselnya.'),
                  ],
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: const Color(0xFF38BDF8),
          onPressed: () {},
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ==========================================
  // 3. MODAL PESAN CEPAT (CANNED RESPONSES)
  // Draggable Bottom Sheet saat ikon Pesan diklik
  // ==========================================
  void _showQuickChatModal(FamilyMember member) {
    HapticFeedback.mediumImpact();
    final TextEditingController textController = TextEditingController();

    // 3 Pilihan Balasan Instan Sesuai Spesifikasi:
    final List<String> cannedResponses = [
      'Saya sudah aman di titik kumpul',
      'Baterai HP saya kritis!',
      'Tolong jemput di lokasi saya',
    ];

    showSigapModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                children: [
                  // Handle Bar
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

                  // Header Modal Chat
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.mintAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.primaryDark,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pesan Cepat ke ${member.name}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDarkest,
                              ),
                            ),
                            Text(
                              'SMS Darurat & Paket Kompresi Rendah Kuota',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: AppColors.textSlate,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSlate),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Keterangan Mode Panik
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCream,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flash_on_rounded, color: Color(0xFFD97706), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Saat panik atau sinyal darurat macet, tekan 1 tombol di bawah untuk kirim instan:',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDarkest,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3 TOMBOL BALASAN INSTAN (QUICK REPLIES) BERUKURAN BESAR
                  ...cannedResponses.map((msg) {
                    IconData iconData;
                    Color iconColor;
                    if (msg.contains('titik kumpul')) {
                      iconData = Icons.pin_drop_rounded;
                      iconColor = const Color(0xFF10B981);
                    } else if (msg.contains('Baterai')) {
                      iconData = Icons.battery_alert_rounded;
                      iconColor = const Color(0xFFEF4444);
                    } else {
                      iconData = Icons.directions_car_filled_rounded;
                      iconColor = const Color(0xFF2563EB);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () {
                            _sendQuickMessage(member: member, message: msg);
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.borderLight, width: 1.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryDarkest,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(iconData, color: iconColor, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  msg,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDarkest,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.send_rounded,
                                color: AppColors.primaryDark,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: 14),

                  // KOLOM INPUT TEKS BIASA + TOMBOL KIRIM
                  Text(
                    'Atau Ketik Pesan Manual:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDarkest,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: textController,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: 'Tulis pesan singkat...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: AppColors.textSlate,
                              fontSize: 13,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            filled: true,
                            fillColor: AppColors.backgroundCream,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.borderLight),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.borderLight),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            final text = textController.text.trim();
                            if (text.isNotEmpty) {
                              _sendQuickMessage(member: member, message: text);
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            elevation: 0,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Kirim',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _sendQuickMessage({required FamilyMember member, required String message}) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: Colors.white),
                  children: [
                    const TextSpan(text: 'Pesan terkirim ke '),
                    TextSpan(
                      text: member.name,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6EE7B7)),
                    ),
                    TextSpan(text: ': "$message"'),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ==========================================
  // 4. TOMBOL TAMBAH KELUARGA (VIA WHATSAPP)
  // ==========================================
  void _showAddFamilyModal() {
    HapticFeedback.mediumImpact();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String relation = 'Keluarga';

    showSigapModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '+ Tambah Anggota Keluarga',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDarkest,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Undang keluarga via tautan pemantauan WhatsApp.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.textSlate,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSlate),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Input Nama
                  Text(
                    'Nama Panggilan / Lengkap',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDarkest,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Misal: Kakak Rian, Kakek Hasan',
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primaryDark),
                      filled: true,
                      fillColor: AppColors.backgroundCream,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Input Nomor WhatsApp
                  Text(
                    'Nomor WhatsApp / HP',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDarkest,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Misal: 0812-3456-7890',
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primaryDark),
                      filled: true,
                      fillColor: AppColors.backgroundCream,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Kirim Undangan via WhatsApp
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final phone = phoneController.text.trim();
                        if (name.isNotEmpty) {
                          setState(() {
                            _familyMembers.add(
                              FamilyMember(
                                id: 'fam_${DateTime.now().millisecondsSinceEpoch}',
                                name: name,
                                relation: relation,
                                statusNote: 'Undangan dikirim via WhatsApp',
                                safetyStatus: FamilySafetyStatus.menungguKonfirmasi,
                                batteryLevel: 100,
                                updateTime: 'Baru saja',
                                locationNote: 'Menunggu konfirmasi penerimaan',
                                phone: phone.isNotEmpty ? phone : '+62 812-0000-0000',
                              ),
                            );
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.primaryDark,
                              content: Text(
                                '✅ Undangan WhatsApp terkirim ke $name!',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                      label: Text(
                        'Undang via WhatsApp',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15803D), // Hijau WhatsApp / SIGAP Utama
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // HELPER WARNA & ICON STATUS
  // ==========================================
  Color _getStatusColor(FamilySafetyStatus status) {
    switch (status) {
      case FamilySafetyStatus.aman:
        return const Color(0xFF10B981); // Hijau Aman
      case FamilySafetyStatus.menungguKonfirmasi:
        return const Color(0xFFF59E0B); // Oranye Menunggu Konfirmasi
      case FamilySafetyStatus.belumTerhubung:
        return const Color(0xFFEF4444); // Merah Belum Terhubung
    }
  }

  Color _getBatteryColor(int level) {
    if (level <= 20) return const Color(0xFFEF4444); // Merah
    if (level <= 50) return const Color(0xFFF59E0B); // Oranye
    return const Color(0xFF10B981); // Hijau
  }

  // ==========================================
  // MAIN BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final listContent = Column(
      children: [
        // FIXED HEADER (Profil & Pengaturan)
        if (!widget.embedded) _buildFixedHeader(),

        // 1. BAR "STATUS SAYA" (Di Bagian Paling Atas)
        _buildMyStatusBar(),

        // KONTEN BODY: DAFTAR ANGGOTA KELUARGA (Vertical List)
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primaryDark,
            onRefresh: () async {
              HapticFeedback.lightImpact();
              await Future.delayed(const Duration(milliseconds: 500));
              if (mounted) setState(() {});
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
              children: [
                // Sub-header ringkas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.people_alt_rounded,
                          size: 18,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Anggota Keluarga Terhubung (${_familyMembers.length})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDarkest,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.mintAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Sinyal Darurat 🟢',
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

                // 2. DAFTAR ANGGOTA KELUARGA (Vertical List)
                ..._familyMembers.map((member) => _buildFamilyCard(member)),

                const SizedBox(height: 14),

                // KARTU TAMBAH KELUARGA (Di akhir list)
                _buildAddFamilyCard(),

                const SizedBox(height: 18),

                // Edukasi Singkat Jaringan Darurat
                _buildOfflineNoticeBanner(),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return Stack(
        children: [
          listContent,
          Positioned(
            right: 18,
            bottom: 18,
            child: FloatingActionButton.extended(
              heroTag: 'fab_add_family_embedded',
              onPressed: _showAddFamilyModal,
              backgroundColor: AppColors.primaryDark,
              elevation: 4,
              icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
              label: Text(
                '+ Tambah Keluarga',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,

      // ATURAN GLOBAL 1: FIXED / STICKY HEADER (Profil & Pengaturan)
      body: SafeArea(
        child: listContent,
      ),

      // 4. TOMBOL TAMBAH KELUARGA (Floating Action Button Melayang di Kanan Bawah)
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_family',
        onPressed: _showAddFamilyModal,
        backgroundColor: AppColors.primaryDark,
        elevation: 4,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
        label: Text(
          '+ Tambah Keluarga',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),

      // ATURAN GLOBAL 2: FIXED / STICKY BOTTOM NAVIGATION BAR (Tab Keluarga Aktif)
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ==========================================
  // ATURAN GLOBAL: FIXED HEADER (Profil & Pengaturan)
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
          // Avatar Profil Pengguna
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
              child: const Icon(
                Icons.family_restroom_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Judul Header
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pantauan Keluarga',
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
                      'Jaringan Darurat Padang Siaga',
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

          // Indikator Mode Komunikasi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.mintAccent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFB7DAC4), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_tethering_rounded, color: Color(0xFF15803D), size: 14),
                const SizedBox(width: 4),
                Text(
                  'Siaga Jaringan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF065F46),
                  ),
                ),
              ],
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
  // 1. BAR "STATUS SAYA" (Di Bagian Paling Atas)
  // Satu kartu tipis memanjang (compact card)
  // - Teks Kiri: "Status Anda:"
  // - Tengah: Badge hijau "🟢 AMAN (Update 2 mnt lalu)"
  // - Kanan: Tombol kecil (TextButton) "Ubah Status"
  // ==========================================
  Widget _buildMyStatusBar() {
    final statusColor = _getStatusColor(_mySafetyStatus);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Teks Kiri: "Status Anda:"
          Text(
            'Status Anda:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDarkest,
            ),
          ),
          const SizedBox(width: 8),

          // Tengah: Badge hijau "🟢 AMAN (Update 2 mnt lalu)"
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _myStatusNote,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Kanan: Tombol kecil (TextButton) "Ubah Status"
          TextButton(
            onPressed: _showChangeStatusModal,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(50, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.primaryDark,
            ),
            child: Text(
              'Ubah Status',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. DAFTAR ANGGOTA KELUARGA (Vertical List)
  // - Bagian Kiri: Avatar bulat dengan cincin warna sesuai status:
  //   (Hijau = Aman, Oranye = Menunggu Konfirmasi, Merah = Belum Terhubung)
  // - Bagian Tengah: Nama, Teks Status Singkat, Baterai HP (🔋 42%), Waktu Update ("5 mnt lalu")
  // - Bagian Kanan: Ikon Lonceng 🔔 (Ping) & Ikon Pesan 💬 (Quick Chat)
  // ==========================================
  Widget _buildFamilyCard(FamilyMember member) {
    final statusColor = _getStatusColor(member.safetyStatus);
    final batteryColor = _getBatteryColor(member.batteryLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: member.safetyStatus == FamilySafetyStatus.belumTerhubung
              ? const Color(0xFFFCA5A5)
              : AppColors.borderLight.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // BAGIAN KIRI: Avatar bulat dengan cincin warna status
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor, // Cincin Warna Status
                    width: 3.0,
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  backgroundColor: AppColors.mintAccent,
                  child: Text(
                    member.name.substring(0, member.name.length >= 2 ? 2 : 1).toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),

              // Dot status di pojok kanan bawah avatar
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // BAGIAN TENGAH: Informasi Utama
          // - Nama
          // - Teks Status Singkat
          // - Baterai HP & Waktu Update
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris Nama & Hubungan
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDarkest,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${member.relation}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSlate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Teks Status Singkat
                Text(
                  member.statusNote,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: member.safetyStatus == FamilySafetyStatus.belumTerhubung
                        ? const Color(0xFFDC2626)
                        : AppColors.primaryDarkest,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // INFO KRUSIAL: Baterai HP & Waktu Update
                Row(
                  children: [
                    // Indikator Baterai HP
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: batteryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            member.batteryLevel <= 20
                                ? Icons.battery_alert_rounded
                                : Icons.battery_5_bar_rounded,
                            size: 13,
                            color: batteryColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '🔋 ${member.batteryLevel}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: batteryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Waktu Update
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textSlate),
                        const SizedBox(width: 3),
                        Text(
                          member.updateTime,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSlate,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // BAGIAN KANAN: Tombol Aksi Cepat (Hemat Tempat)
          // 1. Ikon Lonceng 🔔 (Fungsi Ping / Minta Kabar)
          // 2. Ikon Pesan 💬 (Fungsi Quick Chat)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Ikon Lonceng 🔔 (Ping)
              Tooltip(
                message: 'Minta Kabar (Ping)',
                child: Material(
                  color: member.isPingSent
                      ? const Color(0xFFFEF3C7) // Kuning lembut jika terkirim
                      : AppColors.mintAccent.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _sendPingToMember(member),
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      child: Icon(
                        member.isPingSent
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_outlined,
                        color: member.isPingSent
                            ? const Color(0xFFD97706)
                            : AppColors.primaryDark,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // 2. Ikon Pesan 💬 (Quick Chat)
              Tooltip(
                message: 'Pesan Cepat',
                child: Material(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showQuickChatModal(member),
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.white,
                        size: 19,
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
  }

  // ==========================================
  // KARTU TAMBAH ANGGOTA KELUARGA (LIST ITEM)
  // ==========================================
  Widget _buildAddFamilyCard() {
    return GestureDetector(
      onTap: _showAddFamilyModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF15803D).withValues(alpha: 0.35),
            width: 1.2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF15803D).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                color: Color(0xFF15803D),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '+ Tambah Keluarga via WhatsApp',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDarkest,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Kirimkan tautan siaga agar bisa saling pantau lokasi & baterai.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AppColors.textSlate,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textSlate,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // BANNER EDUKASI MODE OFFLINE SIAGA
  // ==========================================
  Widget _buildOfflineNoticeBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.mintAccent.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primaryDark, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fitur SMS Fallback Aktif',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDarkest,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Jika jaringan seluler Padang sibuk atau padam, pesan dan status Anda akan otomatis dialihkan ke protokol SMS prioritas darurat.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textSlate,
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

  // ==========================================
  // ATURAN GLOBAL: FIXED BOTTOM NAVIGATION BAR
  // 4 Menu: 1. Beranda, 2. Peringatan, 3. Peta Siaga, 4. Keluarga (Aktif)
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
            icon: Icon(Icons.family_restroom_rounded),
            activeIcon: Icon(Icons.family_restroom_rounded),
            label: 'Keluarga',
          ),
        ],
      ),
    );
  }
}
