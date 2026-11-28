# Progres Implementasi SIGAP

Checklist eksekusi berdasarkan `revisi-sigap-zidan.md` (v2.1-Finalized).
Centang hanya setelah QA lulus dan dokumentasi terkait diperbarui.

**Terakhir diperbarui:** 2026-11-28

---

## Fase A — Backend penutup gap

- [x] **BE-01** App `backend/apps/damage_assessment/` + model `DamageReport`
- [x] **BE-04a** `POST/GET /api/damage-reports/`, `GET /api/damage-reports/my/`
- [x] **BE-04b** `GET /api/damage-reports/heatmap/` (agregasi grid 0.005°)
- [x] **BE-04c** `GET /api/shelters/tsunami/` (reuse `AssistancePoint`)
- [x] **BE-04d** `GET /api/officer/damage-reports/pending/` + `PATCH …/{id}/verify/`
- [x] Throttle `damage_report` 30/jam + validasi bbox Kota Padang
- [x] QA: `manage.py test` → 48 test OK, `ruff check` bersih
- [ ] **BE-03** Fixture polygon zona aman DEMNAS (`safe_zones.json`)
- [ ] **BE-02** Scheduler BMKG periodik (saat ini lazy-fetch + cache 60 detik)

## Fase B — FE integrasi Vision ke backend

- [x] Idempotensi retry: `client_report_id` dikirim FE + constraint unik di BE
- [x] Endpoint `/my/` benar-benar dipakai (bukan lagi jalur "endpoint belum tersedia")
- [x] `damage_history_screen.dart` memuat riwayat server + merge dengan cache lokal
- [x] Banner gagal server (non-blocking) + tombol coba lagi
- [x] Thumbnail & pratinjau `imageUrl` untuk laporan yang hanya ada di server
- [x] Hapus laporan tersinkron dibedakan (hanya salinan lokal)
- [x] `peta_screen.dart` memakai `GET /api/map/risk-zones/` + fallback polygon bawaan
- [x] Layer heatmap kerusakan dari `GET /api/damage-reports/heatmap/`
- [x] QA: `flutter test` 52 test lulus, `flutter analyze` bersih

## Fase C — Evakuasi pakai data server

- [x] `EvacuationPointRepository` menarik `GET /api/shelters/tsunami/`
- [x] Merge dengan katalog bawaan (server menang bila `id` sama)
- [x] Fallback data bundled saat offline / server kosong
- [x] QA: `fe07_evacuation_guide_test.dart` lulus

## Fase D — Emergency Beacon (FE-09)

- [ ] Deps: `flutter_blue_plus`, `audioplayers`, `torch_light`, `flutter_foreground_task`
- [ ] `emergency_beacon_screen.dart` (BLE + sirene + strobo Morse)
- [ ] Izin Android: CAMERA, FLASHLIGHT, lokasi, BLUETOOTH_*
- [ ] Sambungkan `_openOfflineSosBeacon()` di `home_screen.dart`
- [ ] QA-01 simulasi mode pesawat

## Fase E — Model ML (menunggu dataset)

- [ ] Kumpulkan dataset (SDNET2018 / Concrete Crack Detection / foto lokal Padang)
- [ ] Fine-tune EfficientNet-Lite0 → `model_v1.tflite` (< 8 MB)
- [ ] `TfliteDamageClassifier implements DamageClassifier`
- [ ] Ganti injeksi classifier (satu titik)

## Fase F — QA & dokumen

- [x] Dokumen: `api-documentation.md` (§9 + ringkasan endpoint)
- [x] Dokumen: `database-schema.md` (§16 `damage_reports`)
- [ ] QA-02 verifikasi akurasi heatmap setelah sync
- [ ] Regression test FE (widget test alur Vision)

---

## Aturan kerja (disepakati)

1. Implementasi dengan clean code & best practice.
2. Setiap fungsi diberi komentar/docstring yang menjelaskan niatnya.
3. Gunakan tooltip pada kontrol ikon dan validasi pada input/trust boundary.
4. Setiap modul selesai wajib lewat QA (test + lint) sebelum dicentang.
5. Dokumentasi diperbarui setelah fitur tervalidasi; checkbox di dokumen ini
   hanya dicentang setelah QA lulus.
6. Tahapan besar dipecah menjadi langkah kecil yang dapat dieksekusi.
7. **Keamanan data pengguna & sistem** wajib diperhatikan — lihat §Keamanan.

---

## Keamanan (checklist per fase)

| Kategori | Aturan | Status |
|---|---|---|
| Data pengguna | Endpoint laporan hanya mengembalikan milik pemanggil (`user=request.user`) | ✅ |
| Data pengguna | Heatmap publik **hanya** laporan terverifikasi; laporan mentah tidak bocor | ✅ |
| Data pengguna | Pesan galat server tidak membocorkan detail internal ke UI | ✅ |
| Sesi | 401/403 diperlakukan sebagai sesi berakhir, bukan galat umum | ✅ |
| Integritas | `client_report_id` unik per pengguna — retry tidak menggandakan data | ✅ |
| Integritas | Status `pendingSync` lokal tidak pernah ditimpa respons server | ✅ |
| Beban sistem | `POST /damage-reports/` throttle 30/jam per pengguna | ✅ |
| Beban sistem | `GET /damage-reports/heatmap/` throttle 60/menit + cache 30 detik | ✅ |
| Trust boundary | Validasi bbox Padang, skor 0–1, tipe MIME, ukuran foto ≤ 5 MB | ✅ |
| Offline-first | Kegagalan jaringan tidak menghapus/menyembunyikan data lokal | ✅ |
| Belum | Rotasi/penyimpanan token JWT di secure storage (saat ini SharedPreferences) | ⬜ |
| Belum | Rate limit endpoint `officer/*` terpisah dari throttle anon | ⬜ |

---

## Catatan keputusan

| Tanggal | Keputusan | Alasan |
|---|---|---|
| 2026-11-28 | Shelter TES memakai `map.AssistancePoint`, bukan model `SafeZone` baru | Kategori + status verifikasi sudah memenuhi kebutuhan; menghindari duplikasi data |
| 2026-11-28 | `is_verified_by_officer` nullable (3 status) | Satu kolom cukup untuk antrean; jejak audit di `audit_logs` |
| 2026-11-28 | Foto laporan bersifat opsional saat gagal unggah | Data kerusakan lebih penting daripada foto |
| 2026-11-28 | Tidak memasang `django-apscheduler` | Vercel/Render serverless mematikan proses; lazy-fetch lebih murah |
| 2026-11-28 | `client_report_id` berupa `CharField`, bukan UUID | ID laporan Flutter berbentuk `vision_<millis>`, bukan UUID |
| 2026-11-28 | Laporan hanya-di-server memakai pratinjau bottom sheet | Layar hasil penuh butuh berkas gambar lokal di perangkat |
| 2026-11-28 | Shelter server di-merge, bukan menggantikan katalog bawaan | Panduan evakuasi harus tetap berfungsi offline |
