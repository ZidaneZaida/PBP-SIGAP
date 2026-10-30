import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap/core/navigation/sigap_transitions.dart';
import 'package:sigap/core/theme/app_colors.dart';
import 'package:sigap/features/auth/presentation/screens/login_screen.dart';

/// Screen "PengaturanScreen" SIGAP Kota Padang
///
/// Diakses ketika pengguna mengklik ikon Gear/Settings di Header.
///
/// ATURAN UX GLOBAL:
/// - Navigasi: Top App Bar khusus dengan tombol "Kembali (Back)" di kiri atas.
///   Sembunyikan Bottom Navigation Bar saat halaman ini terbuka agar layar lebih luas.
/// - Desain Ramah Lansia: Ukuran teks minimal 16sp untuk judul menu.
///   Tinggi setiap baris (ListTile) minimal 68px agar area sentuh luas.
/// - Auto-Save: JANGAN buat tombol "Simpan Perubahan" di paling bawah.
///   Semua menu toggle (switch) harus menyimpan otomatis saat diklik.
///
/// KONTEN 4 SEKSI:
/// 1. SEKSI 1: AKUN & ID MEDIS (Warna Aksen Hijau)
/// 2. SEKSI 2: AKSESIBILITAS & EVAKUASI (Sangat Penting)
/// 3. SEKSI 3: DATA OFFLINE & PRIVASI
/// 4. SEKSI 4: KELUAR AKUN
class PengaturanScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToAlerts;
  final VoidCallback? onNavigateToMap;
  final VoidCallback? onNavigateToFamily;

  const PengaturanScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToAlerts,
    this.onNavigateToMap,
    this.onNavigateToFamily,
  });

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  // ==========================================
  // STATE MANAGEMENT
  // ==========================================

  // SEKSI 1: Akun & ID Medis
  String _userName = 'Ahmad Zaki';
  String _userPhone = '0812-3456-7890';
  String _emergencyContactName = 'Ibu Nurhayati';
  String _emergencyContactRelation = 'Ibu Kandung';
  String _emergencyContactPhone = '0812-7564-9011';

  String _bloodType = 'O+';
  String _allergies = 'Penisilin, Dingin Ekstrem';
  String _medicalHistory = 'Asma Ringan (Bawa Inhaler)';

  // SEKSI 2: Aksesibilitas & Evakuasi
  String _fontSizeOption = 'Normal'; // 'Normal' | 'Besar' | 'Sangat Besar'
  bool _evacuationPriority = false;
  bool _autoVoiceAssistant = true;

  // SEKSI 3: Data Offline & Privasi
  final String _offlineDataSize = '50 MB';
  bool _isUpdatingOffline = false;
  String _gpsSharingOption = 'Hanya Saat Darurat'; // 'Selalu Bagikan' | 'Hanya Saat Darurat'
  bool _smsBackupEnabled = true;

  // Multiplier ukuran teks ramah lansia
  double get _textScaleMultiplier {
    switch (_fontSizeOption) {
      case 'Besar':
        return 1.15;
      case 'Sangat Besar':
        return 1.30;
      case 'Normal':
      default:
        return 1.0;
    }
  }

  // ==========================================
  // LOGIKA AUTO-SAVE
  // ==========================================
  void _triggerAutoSave(String message) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        duration: const Duration(milliseconds: 1500),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MODAL 1: PROFIL & KONTAK DARURAT
  // ==========================================
  void _showProfileContactModal() {
    HapticFeedback.mediumImpact();
    final nameCtrl = TextEditingController(text: _userName);
    final phoneCtrl = TextEditingController(text: _userPhone);
    final contactNameCtrl = TextEditingController(text: _emergencyContactName);
    final contactRelationCtrl = TextEditingController(text: _emergencyContactRelation);
    final contactPhoneCtrl = TextEditingController(text: _emergencyContactPhone);

    showSigapModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
                            'Profil & Kontak Darurat',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18 * _textScaleMultiplier,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDarkest,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Informasi identitas Anda dan orang terdekat saat bencana.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12 * _textScaleMultiplier,
                              color: AppColors.textSlate,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSlate),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Data Pengguna
                Text(
                  'Nama Lengkap Anda',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13 * _textScaleMultiplier,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDarkest,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14 * _textScaleMultiplier),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primaryDark),
                    filled: true,
                    fillColor: AppColors.backgroundCream,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Nomor HP Pengguna',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13 * _textScaleMultiplier,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDarkest,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14 * _textScaleMultiplier),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primaryDark),
                    filled: true,
                    fillColor: AppColors.backgroundCream,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 16),

                // Kontak Darurat Prioritas
                Text(
                  'Nama Kontak Darurat Utama',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13 * _textScaleMultiplier,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDarkest,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: contactNameCtrl,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14 * _textScaleMultiplier),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.contact_emergency_outlined, color: Color(0xFF15803D)),
                    filled: true,
                    fillColor: AppColors.backgroundCream,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Nomor HP Kontak Darurat',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13 * _textScaleMultiplier,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDarkest,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: contactPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14 * _textScaleMultiplier),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone_callback_rounded, color: Color(0xFF15803D)),
                    filled: true,
                    fillColor: AppColors.backgroundCream,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Tombol Simpan Modal
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _userName = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : _userName;
                        _userPhone = phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : _userPhone;
                        _emergencyContactName = contactNameCtrl.text.trim().isNotEmpty
                            ? contactNameCtrl.text.trim()
                            : _emergencyContactName;
                        _emergencyContactRelation = contactRelationCtrl.text.trim().isNotEmpty
                            ? contactRelationCtrl.text.trim()
                            : _emergencyContactRelation;
                        _emergencyContactPhone = contactPhoneCtrl.text.trim().isNotEmpty
                            ? contactPhoneCtrl.text.trim()
                            : _emergencyContactPhone;
                      });
                      Navigator.pop(ctx);
                      _triggerAutoSave('Profil & Kontak Darurat berhasil disimpan');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Simpan Kontak Darurat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15 * _textScaleMultiplier,
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
  }

  // ==========================================
  // MODAL 2: ID MEDIS (DARURAT SAR)
  // ==========================================
  void _showMedicalIdModal() {
    HapticFeedback.mediumImpact();
    String tempBlood = _bloodType;
    final allergiesCtrl = TextEditingController(text: _allergies);
    final historyCtrl = TextEditingController(text: _medicalHistory);

    showSigapModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
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
                                'ID Medis (Darurat SAR)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18 * _textScaleMultiplier,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDarkest,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Data vital yang dibaca tim SAR saat evakuasi korban bencana.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12 * _textScaleMultiplier,
                                  color: AppColors.textSlate,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSlate),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Golongan Darah
                    Text(
                      'Golongan Darah',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13 * _textScaleMultiplier,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDarkest,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      children: ['A+', 'B+', 'AB+', 'O+', 'Lainnya'].map((type) {
                        final isSelected = tempBlood == type;
                        return ChoiceChip(
                          label: Text(
                            type,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13 * _textScaleMultiplier,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : AppColors.primaryDarkest,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFDC2626),
                          backgroundColor: AppColors.backgroundCream,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                tempBlood = type;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Riwayat Alergi
                    Text(
                      'Riwayat Alergi (Obat / Makanan)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13 * _textScaleMultiplier,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDarkest,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: allergiesCtrl,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14 * _textScaleMultiplier),
                      decoration: InputDecoration(
                        hintText: 'Misal: Penisilin, Dingin, Kacang',
                        prefixIcon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
                        filled: true,
                        fillColor: AppColors.backgroundCream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Riwayat Penyakit Khusus
                    Text(
                      'Riwayat Penyakit & Catatan SAR',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13 * _textScaleMultiplier,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDarkest,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: historyCtrl,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14 * _textScaleMultiplier),
                      decoration: InputDecoration(
                        hintText: 'Misal: Asma, Diabetes, Jantung, Bawa Obat Khusus',
                        prefixIcon: const Icon(Icons.medical_services_outlined, color: Color(0xFFDC2626)),
                        filled: true,
                        fillColor: AppColors.backgroundCream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Tombol Simpan ID Medis
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _bloodType = tempBlood;
                            _allergies = allergiesCtrl.text.trim().isNotEmpty
                                ? allergiesCtrl.text.trim()
                                : _allergies;
                            _medicalHistory = historyCtrl.text.trim().isNotEmpty
                                ? historyCtrl.text.trim()
                                : _medicalHistory;
                          });
                          Navigator.pop(ctx);
                          _triggerAutoSave('ID Medis Darurat SAR berhasil diperbarui');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626), // Merah Medis
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Simpan ID Medis Darurat',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15 * _textScaleMultiplier,
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

  // ==========================================
  // PERBARUI PETA & BUKU SAKU OFFLINE
  // ==========================================
  void _updateOfflineData() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isUpdatingOffline = true;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Mengunduh data peta offline & shelter Kota Padang ($_offlineDataSize)...',
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() {
        _isUpdatingOffline = false;
      });
      _triggerAutoSave('Peta & Buku Saku Offline Padang berhasil diperbarui (50 MB)');
    }
  }

  // ==========================================
  // DIALOG KELUAR AKUN (LOG OUT)
  // ==========================================
  void _showLogoutDialog() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 24),
              const SizedBox(width: 10),
              Text(
                'Keluar Akun?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18 * _textScaleMultiplier,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDarkest,
                ),
              ),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar dari akun SIGAP?\n\nData pemantauan keluarga dan peringatan cepat akan dinonaktifkan sementara di perangkat ini.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5 * _textScaleMultiplier,
              color: AppColors.textSlate,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14 * _textScaleMultiplier,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                'Ya, Keluar Akun',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14 * _textScaleMultiplier,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // MAIN BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,

      // ATURAN UX GLOBAL 1: TOP APP BAR KHUSUS DENGAN TOMBOL KEMBALI
      // Sembunyikan Bottom Navigation Bar agar layar lebih luas
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pengaturan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 19 * _textScaleMultiplier,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDarkest,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.borderLight.withValues(alpha: 0.8),
            height: 1,
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // ==========================================
            // SEKSI 1: AKUN & ID MEDIS (Warna Aksen Hijau)
            // ==========================================
            _buildSectionHeader(
              title: 'AKUN & ID MEDIS',
              badgeColor: const Color(0xFF10B981),
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 8),

            _buildSettingsCard(
              children: [
                // Menu 1: Profil & Kontak Darurat (Ikon user, >= 68px)
                InkWell(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  onTap: _showProfileContactModal,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 68),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.mintAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.primaryDark,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Profil & Kontak Darurat',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16.0 * _textScaleMultiplier,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDarkest,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$_userName • $_emergencyContactName ($_emergencyContactRelation · $_emergencyContactPhone)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5 * _textScaleMultiplier,
                                  color: AppColors.textSlate,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSlate,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, color: AppColors.borderLight),

                // Menu 2: ID Medis (Darurat SAR) (Ikon palang merah, >= 68px)
                InkWell(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                  onTap: _showMedicalIdModal,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 68),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medical_services_outlined,
                            color: Color(0xFFDC2626),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'ID Medis (Darurat SAR)',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16.0 * _textScaleMultiplier,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDarkest,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Gol: $_bloodType',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5 * _textScaleMultiplier,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Golongan darah, alergi, & riwayat penyakit',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5 * _textScaleMultiplier,
                                  color: AppColors.textSlate,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSlate,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ==========================================
            // SEKSI 2: AKSESIBILITAS & EVAKUASI (Sangat Penting)
            // ==========================================
            _buildSectionHeader(
              title: 'AKSESIBILITAS & EVAKUASI',
              badgeColor: const Color(0xFF2563EB),
              icon: Icons.accessibility_new_rounded,
            ),
            const SizedBox(height: 8),

            _buildSettingsCard(
              children: [
                // Menu 1: Ukuran Teks Aplikasi (Segmented Button, >= 68px)
                Container(
                  constraints: const BoxConstraints(minHeight: 68),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.mintAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.format_size_rounded,
                              color: AppColors.primaryDark,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ukuran Teks Aplikasi',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16.0 * _textScaleMultiplier,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDarkest,
                                  ),
                                ),
                                Text(
                                  'Ubah kenyamanan membaca untuk lansia',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.0 * _textScaleMultiplier,
                                    color: AppColors.textSlate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Segmented Button: [ Normal | Besar | Sangat Besar ]
                      Row(
                        children: ['Normal', 'Besar', 'Sangat Besar'].map((opt) {
                          final isSelected = _fontSizeOption == opt;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _fontSizeOption = opt;
                                  });
                                  _triggerAutoSave('Ukuran teks diubah ke: $opt');
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 42,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryDark
                                        : AppColors.backgroundCream,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryDark
                                          : AppColors.borderLight,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Text(
                                    opt,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.0 * _textScaleMultiplier,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.primaryDarkest,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.borderLight),

                // Menu 2: Prioritas Pendamping Evakuasi (Toggle Switch, >= 68px)
                Container(
                  constraints: const BoxConstraints(minHeight: 68),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.elderly_rounded,
                          color: Color(0xFFD97706),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Prioritas Pendamping Evakuasi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16.0 * _textScaleMultiplier,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDarkest,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Aktifkan jika Anda Lansia/Ibu Hamil/Disabilitas agar diprioritaskan tim SAR.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.0 * _textScaleMultiplier,
                                color: AppColors.textSlate,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _evacuationPriority,
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.primaryDark,
                        onChanged: (val) {
                          setState(() {
                            _evacuationPriority = val;
                          });
                          _triggerAutoSave(
                            val
                                ? 'Prioritas pendamping evakuasi diaktifkan'
                                : 'Prioritas pendamping evakuasi dinonaktifkan',
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.borderLight),

                // Menu 3: Asisten Suara Otomatis (Toggle Switch, >= 68px)
                Container(
                  constraints: const BoxConstraints(minHeight: 68),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.mintAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.record_voice_over_rounded,
                          color: AppColors.primaryDark,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Asisten Suara Otomatis',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16.0 * _textScaleMultiplier,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDarkest,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Otomatis bacakan peringatan darurat dengan suara keras.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.0 * _textScaleMultiplier,
                                color: AppColors.textSlate,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _autoVoiceAssistant,
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.primaryDark,
                        onChanged: (val) {
                          setState(() {
                            _autoVoiceAssistant = val;
                          });
                          _triggerAutoSave(
                            val
                                ? 'Asisten suara otomatis aktif'
                                : 'Asisten suara otomatis nonaktif',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ==========================================
            // SEKSI 3: DATA OFFLINE & PRIVASI
            // ==========================================
            _buildSectionHeader(
              title: 'DATA OFFLINE & PRIVASI',
              badgeColor: const Color(0xFFD97706),
              icon: Icons.cloud_download_outlined,
            ),
            const SizedBox(height: 8),

            _buildSettingsCard(
              children: [
                // Menu 1: Peta & Buku Saku Offline (Ikon download, >= 68px)
                InkWell(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  onTap: _isUpdatingOffline ? null : _updateOfflineData,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 68),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.mintAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.download_for_offline_rounded,
                            color: AppColors.primaryDark,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Peta & Buku Saku Offline',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16.0 * _textScaleMultiplier,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDarkest,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Klik untuk perbarui data saat ada WiFi',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.0 * _textScaleMultiplier,
                                  color: AppColors.textSlate,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Teks di kanan: "50 MB Tersimpan"
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isUpdatingOffline ? Icons.sync_rounded : Icons.check_circle_rounded,
                                size: 14,
                                color: const Color(0xFF15803D),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '50 MB Tersimpan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5 * _textScaleMultiplier,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, color: AppColors.borderLight),

                // Menu 2: Berbagi Lokasi GPS (Dropdown/Segmented, >= 68px)
                Container(
                  constraints: const BoxConstraints(minHeight: 68),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E7FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFF3730A3),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Berbagi Lokasi GPS',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16.0 * _textScaleMultiplier,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDarkest,
                                  ),
                                ),
                                Text(
                                  'Izin transmisi koordinat Anda ke tim SAR & keluarga',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.0 * _textScaleMultiplier,
                                    color: AppColors.textSlate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Pilihan: "Selalu Bagikan" atau "Hanya Saat Darurat"
                      Row(
                        children: ['Hanya Saat Darurat', 'Selalu Bagikan'].map((mode) {
                          final isSelected = _gpsSharingOption == mode;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _gpsSharingOption = mode;
                                  });
                                  _triggerAutoSave('Berbagi GPS diatur ke: $mode');
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 42,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryDark
                                        : AppColors.backgroundCream,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryDark
                                          : AppColors.borderLight,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Text(
                                    mode,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5 * _textScaleMultiplier,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.primaryDarkest,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.borderLight),

                // Menu 3: Cadangan SMS Darurat (Toggle Switch, >= 68px)
                Container(
                  constraints: const BoxConstraints(minHeight: 68),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.mintAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sms_outlined,
                          color: AppColors.primaryDark,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Cadangan SMS Darurat',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16.0 * _textScaleMultiplier,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDarkest,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Izinkan kirim SOS via pulsa/SMS jika internet mati.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.0 * _textScaleMultiplier,
                                color: AppColors.textSlate,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _smsBackupEnabled,
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.primaryDark,
                        onChanged: (val) {
                          setState(() {
                            _smsBackupEnabled = val;
                          });
                          _triggerAutoSave(
                            val
                                ? 'Cadangan SMS darurat diaktifkan'
                                : 'Cadangan SMS darurat dinonaktifkan',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ==========================================
            // SEKSI 4: KELUAR AKUN
            // Tombol border/outline merah terang + Versi Aplikasi
            // ==========================================
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: _showLogoutDialog,
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
                label: Text(
                  'Keluar Akun (Log Out)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.0 * _textScaleMultiplier,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFEF4444),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Teks Versi Aplikasi
            Center(
              child: Column(
                children: [
                  Text(
                    'SIGAP v1.0.0 - BPBD Kota Padang',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.0 * _textScaleMultiplier,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDarkest,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sistem Informasi Geospasial & Aksi Penyelamatan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5 * _textScaleMultiplier,
                      color: AppColors.textSlate,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  Widget _buildSectionHeader({
    required String title,
    required Color badgeColor,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13 * _textScaleMultiplier,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDarkest,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

/// Alias kompatibilitas untuk rute yang merujuk ke SettingsScreen
typedef SettingsScreen = PengaturanScreen;
