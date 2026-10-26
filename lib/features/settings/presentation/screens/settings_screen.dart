import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap/core/theme/app_colors.dart';
import 'package:sigap/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:sigap/features/family/presentation/screens/family_assistance_screen.dart';
import 'package:sigap/features/map/presentation/screens/risk_map_screen.dart';
import 'package:sigap/features/profile/presentation/screens/profile_screen.dart';

/// Screen Pengaturan SIGAP Kota Padang
/// Mengimplementasikan secara presisi desain:
/// "SIGAP mobile — Pengaturan — iPhone 17 Pro.svg"
class SettingsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToAlerts;
  final VoidCallback? onNavigateToMap;
  final VoidCallback? onNavigateToFamily;

  const SettingsScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToAlerts,
    this.onNavigateToMap,
    this.onNavigateToFamily,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 1. Preferensi Notifikasi
  bool _alertEmergencyEnabled = true;
  bool _familyNewsEnabled = true;
  bool _shelterUpdateEnabled = false;

  // 2. Kontak Darurat
  String _emergencyName = 'Nurhayati';
  String _emergencyRelation = 'Ibu';
  String _emergencyPhone = '+62 813 •••• 8102';

  // 3. Lokasi Utama
  String _mainLocationTitle = 'Rumah · Padang Barat';

  // 4. Kebutuhan Aksesibilitas
  final List<String> _accessibilityNeeds = ['TEKS BESAR', 'PENDAMPING EVAKUASI'];

  // 5. Keamanan Akun
  bool _twoFactorEnabled = true;

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
  // MODALS & DIALOGS
  // ==========================================

  void _showChangeEmergencyContactModal() {
    final nameCtrl = TextEditingController(text: _emergencyName);
    final relationCtrl = TextEditingController(text: _emergencyRelation);
    final phoneCtrl = TextEditingController(text: _emergencyPhone);

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
              'Ubah Kontak Darurat',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Kontak'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: relationCtrl,
              decoration: const InputDecoration(labelText: 'Hubungan (contoh: Ibu, Saudara)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Nomor Telepon'),
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
                    _emergencyName = nameCtrl.text.trim();
                    _emergencyRelation = relationCtrl.text.trim();
                    _emergencyPhone = phoneCtrl.text.trim();
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kontak darurat berhasil diperbarui.'),
                      backgroundColor: AppColors.primaryDark,
                    ),
                  );
                },
                child: Text('SIMPAN KONTAK', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeLocationModal() {
    final subdistricts = [
      'Padang Barat',
      'Padang Timur',
      'Padang Selatan',
      'Padang Utara',
      'Koto Tangah',
      'Kuranji',
      'Lubuk Begalung',
      'Lubuk Kilangan',
      'Bungus Teluk Kabung',
      'Nanggalo',
      'Pauh',
    ];

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
              'Pilih Kecamatan Lokasi Utama',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lokasi digunakan untuk akurasi peringatan dini bencana:',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textSlate),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: subdistricts.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderLight),
                itemBuilder: (context, index) {
                  final item = subdistricts[index];
                  final isCurrent = _mainLocationTitle.contains(item);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Kecamatan $item',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                        color: isCurrent ? AppColors.primaryDark : AppColors.textDark,
                      ),
                    ),
                    trailing: isCurrent ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryDark) : null,
                    onTap: () {
                      setState(() {
                        _mainLocationTitle = 'Rumah · $item';
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lokasi utama diubah ke Kecamatan $item.'),
                          backgroundColor: AppColors.primaryDark,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeAccessibilityModal() {
    final available = [
      'TEKS BESAR',
      'PENDAMPING EVAKUASI',
      'KURSI RODA / MOBILITAS TERBATAS',
      'PANDUAN AUDIO / SUARA',
      'BAHASA ISYARAT',
    ];

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
              Text(
                'Kebutuhan Aksesibilitas & Evakuasi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pilih kebutuhan yang relevan untuk mempermudah evakuasi oleh tim BPBD:',
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textSlate),
              ),
              const SizedBox(height: 16),
              ...available.map((need) {
                final isSelected = _accessibilityNeeds.contains(need);
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primaryDark,
                  title: Text(
                    need,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  value: isSelected,
                  onChanged: (val) {
                    setModalState(() {
                      if (val == true) {
                        _accessibilityNeeds.add(need);
                      } else {
                        _accessibilityNeeds.remove(need);
                      }
                    });
                    setState(() {});
                  },
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('SIMPAN', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordModal() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();

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
              'Ubah Kata Sandi',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: oldPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Kata Sandi Saat Ini'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Kata Sandi Baru'),
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
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kata sandi berhasil diperbarui.'),
                      backgroundColor: AppColors.primaryDark,
                    ),
                  );
                },
                child: Text('PERBARUI KATA SANDI', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white)),
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
              // 1. Header (SIGAP Brand + PDG Time + Settings Active Icon)
              _buildHeader(),
              const SizedBox(height: 24),

              // 2. Title & Subtitle
              Text(
                'Pengaturan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Kelola data pribadi dan preferensi kesiapsiagaan Anda.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF5C6B61),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),

              // 3. Card 1: Preferensi Notifikasi
              _buildNotificationPreferencesCard(),
              const SizedBox(height: 16),

              // 4. Card 2: Kontak Darurat
              _buildEmergencyContactCard(),
              const SizedBox(height: 16),

              // 5. Card 3: Orang Terdekat Tertaut
              _buildLinkedMembersCard(),
              const SizedBox(height: 16),

              // 6. Card 4: LOKASI UTAMA
              _buildMainLocationCard(),
              const SizedBox(height: 16),

              // 7. Card 5: Kebutuhan Aksesibilitas
              _buildAccessibilityCard(),
              const SizedBox(height: 16),

              // 8. Card 6: Keamanan Akun
              _buildAccountSecurityCard(),
              const SizedBox(height: 24),

              // 9. Tombol Utama: SIMPAN PERUBAHAN
              _buildSaveButton(),
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
            const SizedBox(width: 12),
            // Settings Icon with Active Mint Container
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.mintAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.settings_outlined,
                size: 20,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, a1, a2) => ProfileScreen(
                      onNavigateToDashboard: () => Navigator.of(context).pop(),
                      onNavigateToAlerts: () => Navigator.of(context).pop(),
                      onNavigateToMap: () => Navigator.of(context).pop(),
                      onNavigateToFamily: () => Navigator.of(context).pop(),
                      onNavigateToSettings: () => Navigator.of(context).pop(),
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

  Widget _buildNotificationPreferencesCard() {
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
            'Preferensi notifikasi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),

          // Row 1: Peringatan darurat
          _buildToggleRow(
            title: 'Peringatan darurat',
            subtitle: 'Notifikasi prioritas tinggi untuk lokasi Anda',
            value: _alertEmergencyEnabled,
            onChanged: (val) {
              setState(() => _alertEmergencyEnabled = val);
            },
          ),
          const Divider(color: AppColors.borderLight, height: 24),

          // Row 2: Kabar orang terdekat
          _buildToggleRow(
            title: 'Kabar orang terdekat',
            subtitle: 'Saat kontak memperbarui kondisi',
            value: _familyNewsEnabled,
            onChanged: (val) {
              setState(() => _familyNewsEnabled = val);
            },
          ),
          const Divider(color: AppColors.borderLight, height: 24),

          // Row 3: Pembaruan posko
          _buildToggleRow(
            title: 'Pembaruan posko',
            subtitle: 'Ketersediaan tempat evakuasi',
            value: _shelterUpdateEnabled,
            onChanged: (val) {
              setState(() => _shelterUpdateEnabled = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: AppColors.textSlate,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: value,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.primaryDark,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: AppColors.borderLight,
          onChanged: onChanged,
        ),
      ],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kontak darurat',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              GestureDetector(
                onTap: _showChangeEmergencyContactModal,
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

          // Contact Item
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderLight, width: 1.5),
                  color: AppColors.mintSurface,
                ),
                child: Center(
                  child: Text(
                    _emergencyName.isNotEmpty ? _emergencyName[0] : 'N',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
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
                          _emergencyName,
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
                      '$_emergencyRelation · $_emergencyPhone',
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

          // Note Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.alertPeach,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Kontak pilihan untuk dihubungi langsung. Tidak ada panggilan otomatis.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.alertTerracotta,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // + tambah kontak darurat
          GestureDetector(
            onTap: _showChangeEmergencyContactModal,
            child: Text(
              '+ tambah kontak darurat',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedMembersCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Orang terdekat tertaut',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (widget.onNavigateToFamily != null) {
                    widget.onNavigateToFamily!();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FamilyAssistanceScreen(),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    Text(
                      'kelola',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primaryDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Member 1: Nurhayati (NR)
          _buildLinkedMemberRow(
            initials: 'NR',
            name: 'Nurhayati',
            relation: 'Ibu',
          ),
          const Divider(color: AppColors.borderLight, height: 22),

          // Member 2: Fadli Rahman (FR)
          _buildLinkedMemberRow(
            initials: 'FR',
            name: 'Fadli Rahman',
            relation: 'Adik',
          ),
          const SizedBox(height: 14),

          // Footnote
          Text(
            '2 anggota dapat melihat status darurat Anda.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: AppColors.textSlate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedMemberRow({
    required String initials,
    required String name,
    required String relation,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryDark, width: 1.2),
          ),
          child: Center(
            child: Text(
              initials,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
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
              Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                relation,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: AppColors.textSlate,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.mintAccent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'TERTAUT',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainLocationCard() {
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
            'LOKASI UTAMA',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textSlate,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _mainLocationTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Digunakan untuk ringkasan risiko dan lokasi evakuasi terdekat.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSlate,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderLight, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _showChangeLocationModal,
              child: Text(
                'UBAH LOKASI',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 6, right: 8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryDark,
                ),
              ),
              Expanded(
                child: Text(
                  'Bagikan lokasi hanya saat status darurat aktif',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: AppColors.textSlate,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kebutuhan aksesibilitas',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              GestureDetector(
                onTap: _showChangeAccessibilityModal,
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
          const SizedBox(height: 8),
          Text(
            'Membantu petugas memahami bantuan yang mungkin Anda perlukan.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSlate,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _accessibilityNeeds.map((need) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.mintAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  need,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                    letterSpacing: 0.4,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSecurityCard() {
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
            'Keamanan akun',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),

          // Kata Sandi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kata sandi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'diubah 3 bulan lalu',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: AppColors.textSlate,
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: _showChangePasswordModal,
                child: Text(
                  'UBAH',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.borderLight, height: 24),

          // Verifikasi 2 langkah
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verifikasi 2 langkah',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'aktif melalui SMS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: AppColors.textSlate,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _twoFactorEnabled = !_twoFactorEnabled);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_twoFactorEnabled
                          ? 'Verifikasi 2 langkah diaktifkan.'
                          : 'Verifikasi 2 langkah dinonaktifkan.'),
                      backgroundColor: AppColors.primaryDark,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _twoFactorEnabled ? AppColors.primaryDark : AppColors.textSlate,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _twoFactorEnabled ? 'AKTIF' : 'NONAKTIF',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.4,
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perubahan pengaturan Anda berhasil disimpan.'),
              backgroundColor: AppColors.primaryDark,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Text(
          'SIMPAN PERUBAHAN',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // BOTTOM NAVIGATION BAR (Navigasi ke 4 Tab Utama)
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: AppColors.textSlate,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSlate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
