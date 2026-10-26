import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap/main.dart';
import 'package:sigap/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:sigap/features/family/presentation/screens/family_assistance_screen.dart';
import 'package:sigap/features/map/presentation/screens/risk_map_screen.dart';
import 'package:sigap/features/settings/presentation/screens/settings_screen.dart';
import 'package:sigap/features/profile/presentation/screens/profile_screen.dart';

void main() {
  testWidgets('Splash screen loads properly and displays branding', (WidgetTester tester) async {
    await tester.pumpWidget(const SigapApp());

    // Verify that SIGAP branding and tagline are displayed
    expect(find.text('SIGAP'), findsOneWidget);
    expect(find.text('Sistem informasi bencana'), findsOneWidget);
  });

  testWidgets('Alerts screen loads properly with active and riwayat cards', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AlertsScreen()));

    // Verify title and active alerts
    expect(find.text('Peringatan bencana'), findsOneWidget);
    expect(find.text('SIAGA'), findsOneWidget);
    expect(find.text('WASPADA'), findsOneWidget);
    expect(find.text('Gempa bumi M5.8'), findsOneWidget);
    expect(find.text('Banjir sungai Batang'), findsOneWidget);
  });

  testWidgets('Family & Assistance screen loads properly with all sections', (WidgetTester tester) async {
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

  testWidgets('Risk Map screen loads properly with map, pins, and legend', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RiskMapScreen()));

    // Verify Title & Search
    expect(find.text('Peta risiko wilayah'), findsOneWidget);
    expect(find.text('cari wilayah...'), findsOneWidget);
    expect(find.text('filter: jenis risiko'), findsOneWidget);

    // Verify Map pins and overlay
    expect(find.text('BANJIR'), findsOneWidget);
    expect(find.text('GEMPA'), findsOneWidget);
    expect(find.text('LONGSOR'), findsOneWidget);
    expect(find.text('PLACEHOLDER PETA · PADANG'), findsOneWidget);

    // Verify User location and legend
    expect(find.text('LOKASI ANDA'), findsOneWidget);
    expect(find.text('Risiko sedang'), findsOneWidget);
    expect(find.text('potensi banjir'), findsOneWidget);
    expect(find.text('LEGENDA'), findsOneWidget);
    expect(find.text('Rendah'), findsOneWidget);
    expect(find.text('Sedang'), findsOneWidget);
    expect(find.text('Tinggi'), findsOneWidget);
  });

  testWidgets('Settings screen loads properly with preferences, profile, and security', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    // Verify Title & Subtitle
    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('Preferensi notifikasi'), findsOneWidget);
    expect(find.text('Peringatan darurat'), findsOneWidget);
    expect(find.text('Kabar orang terdekat'), findsOneWidget);
    expect(find.text('Pembaruan posko'), findsOneWidget);

    // Verify Contacts & Linked Members
    expect(find.text('Orang terdekat tertaut'), findsOneWidget);
    expect(find.text('Fadli Rahman'), findsOneWidget);
    expect(find.text('TERTAUT'), findsNWidgets(2));

    // Verify Location & Accessibility
    expect(find.text('LOKASI UTAMA'), findsOneWidget);
    expect(find.text('Rumah · Padang Barat'), findsOneWidget);
    expect(find.text('Kebutuhan aksesibilitas'), findsOneWidget);
    expect(find.text('TEKS BESAR'), findsOneWidget);
    expect(find.text('PENDAMPING EVAKUASI'), findsOneWidget);

    // Verify Security & Save Button
    expect(find.text('Keamanan akun'), findsOneWidget);
    expect(find.text('Kata sandi'), findsOneWidget);
    expect(find.text('Verifikasi 2 langkah'), findsOneWidget);
    expect(find.text('SIMPAN PERUBAHAN'), findsOneWidget);
  });

  testWidgets('Profile screen loads properly with identity and form fields', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));

    // Verify Title & Subtitle
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Kelola data pribadi dan preferensi kesiapsiagaan Anda.'), findsOneWidget);

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
}
