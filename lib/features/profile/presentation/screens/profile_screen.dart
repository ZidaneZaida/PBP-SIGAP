import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap/core/theme/app_colors.dart';
import 'package:sigap/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:sigap/features/family/presentation/screens/family_assistance_screen.dart';
import 'package:sigap/features/map/presentation/screens/risk_map_screen.dart';
import 'package:sigap/features/settings/presentation/screens/settings_screen.dart';

/// Screen Profil SIGAP Kota Padang
/// Mengimplementasikan secara presisi desain:
/// "SIGAP mobile — Profil — iPhone 17 Pro.svg"
class ProfileScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToAlerts;
  final VoidCallback? onNavigateToMap;
  final VoidCallback? onNavigateToFamily;
  final VoidCallback? onNavigateToSettings;

  const ProfileScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToAlerts,
    this.onNavigateToMap,
    this.onNavigateToFamily,
    this.onNavigateToSettings,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Form Controllers sesuai Mockup
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  final String _sigapId = '02941';

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

    _nameController = TextEditingController(text: 'Aulia Rahman');
    _phoneController = TextEditingController(text: '+62 812 •••• 2841');
    _emailController = TextEditingController(text: 'aulia.r@email.id');
    _addressController = TextEditingController(
      text: 'Jl. Veteran No. 18, Padang Barat, Kota Padang',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Hitung inisial nama
  String get _initials {
    final words = _nameController.text.trim().split(' ');
    if (words.isEmpty || words.first.isEmpty) return 'AR';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  // ==========================================
  // ACTION HANDLERS
  // ==========================================

  void _showPhotoOptionsModal() {
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
              'Ganti Foto Profil',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryDark),
              title: Text('Ambil Foto Kamera', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Membuka kamera...')),
                );
              },
            ),
            const Divider(color: AppColors.borderLight),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryDark),
              title: Text('Pilih dari Galeri', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Membuka galeri...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'Profil berhasil disimpan!',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              // 1. Header (SIGAP Brand + PDG Time + Settings Gear + Active Profile Icon)
              _buildHeader(),
              const SizedBox(height: 24),

              // 2. Title & Subtitle
              Text(
                'Profil',
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

              // 3. Card 1: Avatar & Basic Identity
              _buildIdentityCard(),
              const SizedBox(height: 16),

              // 4. Card 2: Form Data Pribadi
              _buildPersonalDataCard(),
              const SizedBox(height: 24),

              // 5. Tombol Utama: SIMPAN PERUBAHAN
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
            const SizedBox(width: 14),
            GestureDetector(
              onTap: () {
                if (widget.onNavigateToSettings != null) {
                  widget.onNavigateToSettings!();
                } else {
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
                }
              },
              child: const Icon(
                Icons.settings_outlined,
                size: 20,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 10),
            // Profile Icon with Active Mint Container
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.mintAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIdentityCard() {
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
            children: [
              // Initials Avatar Circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.mintAccent,
                  border: Border.all(color: AppColors.primaryDark, width: 1.2),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Akun terverifikasi · ID SIGAP $_sigapId',
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

          // GANTI FOTO Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderLight, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _showPhotoOptionsModal,
              child: Text(
                'GANTI FOTO',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDataCard() {
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
          // 1. Nama lengkap
          _buildFormField(
            label: 'Nama lengkap',
            controller: _nameController,
            onChanged: (val) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // 2. Nomor telepon
          _buildFormField(
            label: 'Nomor telepon',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          // 3. Email
          _buildFormField(
            label: 'Email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // 4. Alamat
          _buildFormField(
            label: 'Alamat',
            controller: _addressController,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
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
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
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
        onPressed: _saveProfile,
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
