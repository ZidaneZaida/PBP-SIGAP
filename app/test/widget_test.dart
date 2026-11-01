import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap/main.dart';
import 'package:sigap/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:sigap/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:sigap/features/family/presentation/screens/family_assistance_screen.dart';
import 'package:sigap/features/family/presentation/screens/keluarga_screen.dart';
import 'package:sigap/features/map/presentation/screens/risk_map_screen.dart';
import 'package:sigap/features/settings/presentation/screens/settings_screen.dart';
import 'package:sigap/features/profile/presentation/screens/profile_screen.dart';

import 'package:sigap/features/splash/presentation/screens/splash_screen.dart';
import 'package:sigap/features/auth/presentation/screens/login_screen.dart';
import 'package:sigap/features/auth/presentation/screens/register_screen.dart';

void main() {
  testWidgets(
    'Splash screen loads properly with clean minimalist design and text',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SigapApp());

      // Verifikasi branding tengah: Logo, Judul, Tagline, dan Teks kecil
      expect(find.text('SIGAP'), findsOneWidget);
      expect(find.text('Siaga Bencana Kota Padang'), findsOneWidget);
      expect(find.text('Alam • Kota • Kesiapsiagaan'), findsOneWidget);

      // Verifikasi satu baris teks tipis di bawah
      expect(
        find.text('Memeriksa peringatan BMKG & lokasi GPS...'),
        findsOneWidget,
      );

      // Pastikan kotak diagnostik, kartu nomor 1-5, dan tombol-tombol TIDAK ADA di layar
      expect(find.text('DIAGNOSTIK SISTEM SIGAP'), findsNothing);
      expect(find.text('(1) Koneksi Internet'), findsNothing);
      expect(find.text('(2) Cache & Data Lokal'), findsNothing);
      expect(find.text('(3) Lokasi GPS Wilayah'), findsNothing);
      expect(find.text('(4) Peringatan BMKG/BPBD'), findsNothing);
      expect(find.text('(5) Penentuan Rute Aplikasi'), findsNothing);
      expect(find.text('Akses Cepat Tanpa Login'), findsNothing);
      expect(find.text('Lewati'), findsNothing);
      expect(find.text('BUKA BERANDA DARURAT SEKARANG'), findsNothing);
    },
  );

  testWidgets('Splash screen auto-navigates on completion callback', (
    WidgetTester tester,
  ) async {
    bool initialized = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          onInitializationComplete: () {
            initialized = true;
          },
        ),
      ),
    );

    // Pompa durasi hingga animasi loading selesai (1800ms)
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 1900));

    expect(initialized, isTrue);
  });

  testWidgets(
    'LoginScreen loads properly with clean UI, form, and emergency bypass button',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      // Header
      expect(find.text('Selamat Datang di SIGAP'), findsOneWidget);
      expect(
        find.text('Masuk untuk memantau kondisi Padang dan keluarga.'),
        findsOneWidget,
      );

      // Form
      expect(find.text('Email atau Nomor HP'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Lupa kata sandi?'), findsOneWidget);

      // Tombol Aksi
      expect(find.text('MASUK'), findsOneWidget);
      expect(find.text('Masuk dengan Google'), findsOneWidget);

      // Navigasi Bawah
      expect(find.text('Belum punya akun SIGAP? '), findsOneWidget);
      expect(find.text('Daftar di sini'), findsOneWidget);

      // Tombol Footer Bypass Darurat
      expect(find.text('🚨 MASUK TANPA AKUN (MODE DARURAT)'), findsOneWidget);
    },
  );

  testWidgets(
    'RegisterScreen loads properly with clean UI, HP darurat, checkbox, and emergency bypass button',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

      // Header
      expect(find.text('Buat Akun SIGAP'), findsOneWidget);
      expect(
        find.text('Satu akun untuk melindungi Anda dan keluarga.'),
        findsOneWidget,
      );

      // Form
      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('Nomor HP / WhatsApp'), findsOneWidget);
      expect(find.text('Wajib untuk darurat'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);

      // Checkbox Persetujuan
      expect(
        find.text(
          'Saya setuju dengan Syarat & Ketentuan serta Kebijakan Privasi data lokasi.',
        ),
        findsOneWidget,
      );

      // Tombol Aksi
      expect(find.text('BUAT AKUN'), findsOneWidget);
      expect(find.text('Daftar dengan Google'), findsOneWidget);

      // Navigasi Bawah
      expect(find.text('Sudah punya akun? '), findsOneWidget);
      expect(find.text('Masuk di sini'), findsOneWidget);

      // Tombol Footer Bypass Darurat
      expect(find.text('🚨 MASUK TANPA AKUN (MODE DARURAT)'), findsOneWidget);
    },
  );

  testWidgets(
    'PeringatanScreen / AlertsScreen loads with Sticky Header, TabBar, Dynamic State, and Buku Saku',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AlertsScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      // 1. ATURAN GLOBAL: Sticky Header & Bottom Navigation Bar (Tab Peringatan Aktif)
      expect(find.text('Peringatan Bencana'), findsOneWidget);
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Peringatan'), findsOneWidget);
      expect(find.text('Peta Siaga'), findsOneWidget);
      expect(find.text('Keluarga'), findsOneWidget);

      // 2. TABBAR MELINTANG DENGAN 2 MENU
      expect(find.text('🚨 Info Bencana'), findsOneWidget);
      expect(find.text('📖 Buku Saku'), findsOneWidget);

      // 3. TAB 1: KONDISI AMAN (Default Empty State)
      expect(find.text('Kondisi Aman Terkendali'), findsOneWidget);
      expect(
        find.text(
          'Saat ini tidak ada peringatan bencana aktif dari BMKG di Kota Padang.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);

      // 4. TAB 1: UJI KONDISI DARURAT (Switch via Pill Toggle)
      await tester.tap(find.text('Mode: Aman'));
      await tester.pump(const Duration(milliseconds: 200));

      // Verifikasi Kartu Darurat
      expect(find.text('AWAS'), findsOneWidget);
      expect(find.text('Baru saja'), findsOneWidget);
      expect(find.text('Gempa Bumi M 6.0'), findsOneWidget);
      expect(
        find.text('Kedalaman 10 km • Jarak dari lokasi Anda: 14 km'),
        findsOneWidget,
      );
      expect(find.text('🚨 BERPOTENSI TSUNAMI'), findsOneWidget);
      expect(find.text('Sumber: BMKG'), findsOneWidget);
      expect(find.text('Bacakan Arahan'), findsWidgets);

      // Uji Tombol 🔊 "Bacakan Arahan"
      await tester.tap(find.text('Bacakan Arahan').first);
      await tester.pump(const Duration(milliseconds: 100));

      // 5. TAB 2: UJI BUKU SAKU (Offline Guide)
      await tester.tap(find.text('📖 Buku Saku'));
      await tester.pump(const Duration(milliseconds: 200));

      // Verifikasi 4 Panduan Edukasi Sederhana
      expect(find.text('Panduan Saat Gempa'), findsOneWidget);
      expect(find.text('Panduan Evakuasi Tsunami'), findsOneWidget);
      expect(find.text('Saat Terjadi Banjir'), findsOneWidget);
      expect(find.text('Checklist Tas Siaga'), findsOneWidget);

      // Buka Salah Satu Panduan
      await tester.tap(find.text('Panduan Saat Gempa'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('SAYA MENGERTI'), findsOneWidget);

      // Tutup Modal
      await tester.tap(find.byIcon(Icons.close_rounded), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));
    },
  );

  testWidgets('Family & Assistance screen loads properly with all sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: FamilyAssistanceScreen()));

    // Verify Title & Subtitle
    expect(find.text('Keluarga & Bantuan'), findsWidgets);
    expect(find.text('PERBARUI STATUS SAYA'), findsOneWidget);
    expect(find.text('SAYA AMAN'), findsOneWidget);
    expect(find.text('BUTUH BANTUAN'), findsOneWidget);

    // Verify members
    expect(find.text('Ibu'), findsOneWidget);
    expect(find.text('Ayah'), findsOneWidget);
    expect(find.text('Adik'), findsOneWidget);

    // Verify Emergency Contact & Assistance
    expect(find.text('Kontak darurat'), findsOneWidget);
    expect(find.text('Nurhayati'), findsOneWidget);
    expect(find.text('Bantuan di sekitar Anda'), findsOneWidget);
    expect(find.text('RSUD terdekat'), findsOneWidget);
    expect(find.text('Darurat segera? Hubungi 112'), findsOneWidget);
  });

  testWidgets(
    'PetaScreen / RiskMapScreen loads with interactive map, search, filter chips, and navigation card',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RiskMapScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      // 1. ATURAN GLOBAL: Fixed Header & Fixed Bottom Navigation Bar
      expect(find.text('Peta Siaga & Evakuasi'), findsOneWidget);
      expect(find.text('Padang, Sumbar · GPS Siaga Aktif'), findsOneWidget);
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Peringatan'), findsOneWidget);
      expect(find.text('Peta Siaga'), findsOneWidget);
      expect(find.text('Keluarga'), findsOneWidget);

      // 2. SEARCH BAR & FILTER LOKASI (Di Atas Peta)
      expect(find.text('Cari shelter, RS, atau lokasi...'), findsOneWidget);
      expect(find.text('🏃 Shelter Terdekat'), findsOneWidget);
      expect(find.text('🏥 Rumah Sakit & PMI'), findsOneWidget);
      expect(find.text('⛺ Posko Darurat'), findsOneWidget);
      expect(find.text('🌊 Zona Tsunami'), findsOneWidget);

      // 3. KARTU NAVIGASI DARURAT (Di Bawah Peta)
      expect(find.text('Gedung TES UNP'), findsWidgets);
      expect(find.text('400 meter'), findsOneWidget);
      expect(find.text('5 mnt jalan kaki'), findsOneWidget);
      expect(find.text('Mulai Rute Evakuasi (Jalan Kaki)'), findsOneWidget);

      // 4. Uji Tap Filter Chip [🌊 Zona Tsunami]
      await tester.ensureVisible(find.text('🌊 Zona Tsunami'));
      await tester.tap(find.text('🌊 Zona Tsunami'));
      await tester.pump(const Duration(milliseconds: 100));

      // 5. Uji Tap Tombol "Mulai Rute Evakuasi (Jalan Kaki)"
      await tester.ensureVisible(find.text('Mulai Rute Evakuasi (Jalan Kaki)'));
      await tester.tap(find.text('Mulai Rute Evakuasi (Jalan Kaki)'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('PANDUAN RUTE JALAN KAKI AKTIF'), findsOneWidget);
    },
  );

  testWidgets(
    'PengaturanScreen / SettingsScreen loads with elderly-friendly UX, 4 cards, auto-save, and logout',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      // 1. NAVIGASI: Top App Bar khusus dengan tombol Kembali
      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      // Pastikan Bottom Navigation Bar disembunyikan
      expect(find.byType(BottomNavigationBar), findsNothing);

      // 2. SEKSI 1: AKUN & ID MEDIS (Warna Aksen Hijau)
      expect(find.text('AKUN & ID MEDIS'), findsOneWidget);
      expect(find.text('Profil & Kontak Darurat'), findsOneWidget);
      expect(find.text('ID Medis (Darurat SAR)'), findsOneWidget);
      expect(
        find.text('Golongan darah, alergi, & riwayat penyakit'),
        findsOneWidget,
      );

      // 3. SEKSI 2: AKSESIBILITAS & EVAKUASI (Sangat Penting)
      expect(find.text('AKSESIBILITAS & EVAKUASI'), findsOneWidget);
      expect(find.text('Ukuran Teks Aplikasi'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Besar'), findsOneWidget);
      expect(find.text('Sangat Besar'), findsOneWidget);
      expect(find.text('Prioritas Pendamping Evakuasi'), findsOneWidget);
      expect(find.text('Asisten Suara Otomatis'), findsOneWidget);

      // Uji Auto-Save pada Segmented Button "Besar"
      await tester.tap(find.text('Besar'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Ukuran teks diubah'), findsOneWidget);

      // Scroll ke bawah untuk melihat Seksi 3
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 100));

      // 4. SEKSI 3: DATA OFFLINE & PRIVASI
      expect(find.text('DATA OFFLINE & PRIVASI'), findsOneWidget);
      expect(find.text('Peta & Buku Saku Offline'), findsOneWidget);
      expect(find.text('50 MB Tersimpan'), findsOneWidget);
      expect(find.text('Berbagi Lokasi GPS'), findsOneWidget);
      expect(find.text('Hanya Saat Darurat'), findsOneWidget);
      expect(find.text('Selalu Bagikan'), findsOneWidget);
      expect(find.text('Cadangan SMS Darurat'), findsOneWidget);

      // Uji Toggle Switch Auto-Save
      final switches = find.byType(Switch);
      expect(switches, findsWidgets);
      await tester.tap(switches.last);
      await tester.pump(const Duration(milliseconds: 100));

      // 5. SEKSI 4: KELUAR AKUN & VERSI APLIKASI
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Keluar Akun (Log Out)'), findsOneWidget);
      expect(find.text('SIGAP v1.0.0 - BPBD Kota Padang'), findsOneWidget);

      // 6. AUTO-SAVE: Pastikan TIDAK ADA tombol "Simpan Perubahan" di paling bawah
      expect(find.text('Simpan Perubahan'), findsNothing);
      expect(find.text('SIMPAN PERUBAHAN'), findsNothing);

      // 7. Uji Dialog Logout
      await tester.tap(find.text('Keluar Akun (Log Out)'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Keluar Akun?'), findsOneWidget);
      expect(find.text('Ya, Keluar Akun'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pump(const Duration(milliseconds: 200));
    },
  );

  testWidgets('Profile screen loads properly with identity and form fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));

    // Verify Title & Subtitle
    expect(find.text('Profil'), findsOneWidget);
    expect(
      find.text('Kelola data pribadi dan preferensi kesiapsiagaan Anda.'),
      findsOneWidget,
    );

    // Verify Identity
    expect(find.text('AR'), findsOneWidget);
    expect(find.text('Aulia Rahman'), findsWidgets);
    expect(find.text('Akun terverifikasi · ID SIGAP 02941'), findsOneWidget);
    expect(find.text('GANTI FOTO'), findsOneWidget);

    // Verify Form Labels
    expect(find.text('Nama lengkap'), findsOneWidget);
    expect(find.text('Nomor telepon'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Alamat'), findsOneWidget);
    expect(find.text('SIMPAN PERUBAHAN'), findsOneWidget);
  });

  testWidgets(
    'HomeScreen / DashboardScreen loads properly with dynamic state UI, quick actions, and family circle',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Header (Profil Pengguna sederhana, TANPA jam statis)
      expect(find.text('Halo, Warga Padang'), findsOneWidget);
      expect(find.text('Kota Padang, Sumbar'), findsOneWidget);
      expect(find.textContaining('09:41'), findsNothing); // Tanpa jam statis!

      // 2. KARTU STATUS UTAMA - STATE AMAN (Default)
      expect(find.text('STATUS NORMAL'), findsOneWidget);
      expect(
        find.text(
          'Kondisi Kota Padang: AMAN • Tidak ada peringatan bencana aktif',
        ),
        findsOneWidget,
      );
      expect(find.text('Cuaca Padang Hari Ini'), findsOneWidget);
      expect(find.text('29°C · Cerah Berawan'), findsOneWidget);
      expect(find.text('Kelembapan'), findsOneWidget);
      expect(find.text('Angin'), findsOneWidget);

      // 2b. Banner Edukasi & Titik Kumpul (Mode Aman)
      expect(
        find.text('Titik Kumpul Terdekat: Gedung TES UNP (400m)'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Tips Siaga: Pastikan powerbank Anda terisi penuh saat musim hujan.',
        ),
        findsOneWidget,
      );

      // 3. GRID 2x2 TINDAKAN CEPAT (Quick Actions)
      expect(find.textContaining('BUTUH BANTUAN'), findsOneWidget);
      expect(find.text('✅ SAYA AMAN'), findsOneWidget);
      expect(find.text('🔊 SIRINE SOS'), findsOneWidget);
      expect(find.text('📞 DARURAT 112'), findsOneWidget);

      // 4. RINGKASAN KELUARGA (Family Circle)
      expect(find.text('Pantauan Keluarga'), findsOneWidget);
      expect(find.text('🔔 Minta Kabar'), findsOneWidget);
      expect(find.text('Ibu'), findsOneWidget);
      expect(find.text('Aman'), findsOneWidget);
      expect(find.text('Adik'), findsOneWidget);
      expect(find.text('Menunggu'), findsOneWidget);
      expect(find.text('Ayah'), findsOneWidget);
      expect(find.text('Belum Konfirmasi'), findsOneWidget);

      // 5. BOTTOM NAVIGATION BAR (4 menu utama)
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Peringatan'), findsOneWidget);
      expect(find.text('Peta Siaga'), findsOneWidget);
      expect(find.text('Keluarga'), findsWidgets);

      // 6. UJI STATE DARURAT (Dynamic State UI Switch)
      // Tap pill switcher untuk beralih ke Mode Darurat
      await tester.tap(find.text('Mode: Aman'));
      await tester.pump(const Duration(milliseconds: 400));

      // Verifikasi Kartu Status State Darurat
      expect(find.text('PERINGATAN DARURAT AKTIF'), findsOneWidget);
      expect(find.text('Gempa Bumi M 6.0'), findsOneWidget);
      expect(find.text('Jarak dari lokasi Anda: 14 km'), findsOneWidget);
      expect(find.text('🚨 BERPOTENSI TSUNAMI'), findsOneWidget);
      expect(find.text('🔊 Bacakan'), findsOneWidget);
      expect(
        find.text('Episentrum: 14 km Barat Daya Padang (Kedalaman 10 km)'),
        findsOneWidget,
      );
      expect(
        find.text('Arahan: Segera jauhi pesisir pantai & muara Batang Arau'),
        findsOneWidget,
      );

      // Toggle penanda tsunami ("🚨 BERPOTENSI TSUNAMI" -> "✅ TIDAK BERPOTENSI TSUNAMI")
      await tester.tap(find.text('🚨 BERPOTENSI TSUNAMI'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('✅ TIDAK BERPOTENSI TSUNAMI'), findsOneWidget);

      // Uji Tombol Aksi "🔊 Bacakan"
      await tester.tap(find.text('🔊 Bacakan'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.volume_up_rounded), findsWidgets);
    },
  );

  testWidgets(
    'KeluargaScreen loads with fixed header, status bar, family cards, ping, quick chat modal, and add family',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: KeluargaScreen()));

      // 1. ATURAN GLOBAL: FIXED HEADER & TITLE
      expect(find.text('Pantauan Keluarga'), findsOneWidget);
      expect(find.text('Jaringan Darurat Padang Siaga'), findsOneWidget);
      expect(find.text('Siaga Jaringan'), findsOneWidget);

      // 2. BAR "STATUS SAYA" (Di Bagian Paling Atas)
      expect(find.text('Status Anda:'), findsOneWidget);
      expect(find.text('🟢 AMAN (Update 2 mnt lalu)'), findsOneWidget);
      expect(find.text('Ubah Status'), findsOneWidget);

      // Uji Buka Modal Ubah Status Saya
      await tester.tap(find.text('Ubah Status'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Perbarui Status Anda'), findsOneWidget);
      expect(find.text('🟢 SAYA AMAN'), findsOneWidget);
      expect(find.text('🟡 SEDANG EVAKUASI / DI PERJALANAN'), findsOneWidget);
      expect(find.text('🔴 BUTUH BANTUAN DARURAT (SOS)'), findsOneWidget);

      // Pilih Opsi Bantuan Darurat
      await tester.ensureVisible(find.text('🔴 BUTUH BANTUAN DARURAT (SOS)'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('🔴 BUTUH BANTUAN DARURAT (SOS)'));
      await tester.pump(const Duration(milliseconds: 200));

      // Simpan Status
      await tester.ensureVisible(find.text('Simpan & Beri Tahu Keluarga'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Simpan & Beri Tahu Keluarga'));
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi Status Baru Tercermin di Bar
      expect(find.text('🔴 BUTUH BANTUAN (Baru saja)'), findsOneWidget);

      // 3. DAFTAR ANGGOTA KELUARGA (Vertical List)
      expect(find.text('Anggota Keluarga Terhubung (3)'), findsOneWidget);

      // Item 1: Ibu (Hijau - Aman)
      expect(find.text('Ibu'), findsOneWidget);
      expect(find.text('Aman di Masjid Raya'), findsOneWidget);
      expect(find.text('🔋 78%'), findsOneWidget);
      expect(find.text('2 mnt lalu'), findsOneWidget);

      // Item 2: Adik Aulia (Oranye - Menunggu Konfirmasi)
      expect(find.text('Adik Aulia'), findsOneWidget);
      expect(find.text('Menuju Shelter UNP'), findsOneWidget);
      expect(find.text('🔋 42%'), findsOneWidget);
      expect(find.text('5 mnt lalu'), findsOneWidget);

      // Item 3: Ayah Hendra (Merah - Belum Terhubung)
      expect(find.text('Ayah Hendra'), findsOneWidget);
      expect(find.text('Belum merespons'), findsOneWidget);
      expect(find.text('🔋 15%'), findsOneWidget);
      expect(find.text('18 mnt lalu'), findsOneWidget);

      // 4. UJI FUNGSI PING / MINTA KABAR (LONCENG)
      final pingIcons = find.byIcon(Icons.notifications_outlined);
      expect(pingIcons, findsWidgets);
      await tester.tap(pingIcons.first);
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.textContaining('Sinyal Ping Terkirim ke Ibu'),
        findsOneWidget,
      );

      // 5. UJI MODAL PESAN CEPAT (CANNED RESPONSES)
      final chatButtons = find.byIcon(Icons.chat_bubble_outline_rounded);
      expect(chatButtons, findsWidgets);
      await tester.tap(chatButtons.first);
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi 3 Tombol Balasan Instan Berukuran Besar
      expect(find.text('Pesan Cepat ke Ibu'), findsOneWidget);
      expect(find.text('Saya sudah aman di titik kumpul'), findsOneWidget);
      expect(find.text('Baterai HP saya kritis!'), findsOneWidget);
      expect(find.text('Tolong jemput di lokasi saya'), findsOneWidget);

      // Tap balasan instan pertama
      await tester.ensureVisible(find.text('Saya sudah aman di titik kumpul'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(
        find.text('Saya sudah aman di titik kumpul'),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.textContaining('Saya sudah aman di titik kumpul'),
        findsOneWidget,
      );

      // 6. UJI TOMBOL TAMBAH KELUARGA (FAB & LIST FOOTER)
      expect(find.text('+ Tambah Keluarga'), findsOneWidget);
      expect(find.text('+ Tambah Keluarga via WhatsApp'), findsOneWidget);

      // 7. BOTTOM NAVIGATION BAR (Tab Keluarga Aktif)
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Peringatan'), findsOneWidget);
      expect(find.text('Peta Siaga'), findsOneWidget);
      expect(find.text('Keluarga'), findsWidgets);
    },
  );

  testWidgets(
    'Navigation routing, state preservation across tabs, and settings slide transition',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verifikasi tab awal adalah Beranda
      expect(find.text('Halo, Warga Padang'), findsOneWidget);
      expect(
        find.text(
          'Kondisi Kota Padang: AMAN • Tidak ada peringatan bencana aktif',
        ),
        findsOneWidget,
      );

      // 2. Berpindah ke Tab Peringatan via Bottom Nav
      await tester.tap(find.text('Peringatan'));
      await tester.pump(const Duration(milliseconds: 300));

      // Header dan Bottom Bar tetap statis
      expect(find.text('Peringatan Bencana'), findsOneWidget);
      expect(find.text('Pusat Info & Peringatan Dini BMKG'), findsOneWidget);
      expect(find.text('🚨 Info Bencana'), findsOneWidget);
      expect(find.text('📖 Buku Saku'), findsOneWidget);

      // Switch ke sub-tab "📖 Buku Saku" di Peringatan
      await tester.tap(find.text('📖 Buku Saku'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Panduan Saat Gempa'), findsOneWidget);

      // 3. Berpindah ke Tab Keluarga via Bottom Nav
      await tester.tap(find.text('Keluarga').last);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pantauan Keluarga'), findsOneWidget);
      expect(find.text('Status Anda:'), findsOneWidget);

      // 4. Kembali ke Tab Peringatan: Verifikasi STATE PRESERVATION
      // "📖 Buku Saku" harus tetap aktif tanpa ter-reset ke "🚨 Info Bencana"
      await tester.tap(find.text('Peringatan'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Panduan Saat Gempa'), findsOneWidget);

      // 5. Uji Navigasi Pengaturan (Settings Screen) via Slide-in
      final settingsIcon = find.byIcon(Icons.settings_outlined);
      expect(settingsIcon, findsOneWidget);
      await tester.tap(settingsIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Verifikasi PengaturanScreen terbuka
      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('AKUN & ID MEDIS'), findsOneWidget);

      // Tekan tombol Kembali (Back) di Pengaturan
      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Verifikasi kembali ke layar sebelumnya
      expect(find.text('Pengaturan'), findsNothing);
      expect(find.text('Peringatan Bencana'), findsOneWidget);
    },
  );
}
