# Audit Perencanaan Backend SIGAP

**Tanggal audit:** 11 Februari 2026
**Dokumen yang diaudit:** `backend-requirements.md`, `database-schema.md`, `api-documentation.md`
**Rujukan produk:** `PRD_SIGAP_Kota_Padang.md`, `BRD Aplikasi SIGAP (Siaga Bencana Kota Padang).md`
**Rujukan kode:** `lib/` — Flutter belum terhubung ke backend; hanya `lib/core/services/bmkg_service.dart` yang memanggil BMKG langsung dari device.

---

## 1. Kesimpulan

Rencana **layak secara fungsional**, tetapi **tidak layak dijalankan apa adanya** dengan kombinasi Django + Supabase + Render Free Tier:

- 5 blocker teknis membuat sebagian rencana mustahil dieksekusi.
- `requirements.txt` yang tertulis **gagal `pip install`**.
- ±15 inkonsistensi internal antar dokumen.
- 8 kebutuhan PRD/BRD belum punya endpoint.
- Arsitektur over-build untuk skala tugas (±5.000 LOC; cukup ±1.800 LOC).

Setelah koreksi pada dokumen ini diterapkan, seluruh stack **tetap 100% gratis** dan tidak ada framework yang perlu diganti.

---

## 2. Blocker Teknis

| # | Klaim dokumen | Fakta platform | Dampak | Keputusan |
|---|---|---|---|---|
| B1 | `django-crontab` / Celery polling BMKG tiap 2 menit | Render Free tidak menyediakan cron job (min $1/bln) maupun background worker. `django-crontab` rilis 2017 dan butuh daemon cron yang tidak ada di Render | Sinkronisasi otomatis mustahil | **Lazy-fetch** saat request + cache 60 detik |
| B2 | Reset password via `smtp.gmail.com:587` | Render memblokir outbound port 25/465/587 di semua service | Email reset password gagal terkirim | **Brevo SMTP port 2525** (free 300 email/hari) |
| B3 | `GDAL==3.9.2` + `django-geospatial` di `requirements.txt` | GDAL adalah library sistem, bukan wheel pip. `django-geospatial` **bukan package yang ada di PyPI**. Render native runtime tidak bisa `apt-get` → harus Docker image ±1 GB | `pip install -r` gagal | **Buang GeoDjango/PostGIS** |
| B4 | `DATABASE_URL=postgresql://postgres:[password]@db.[ref].supabase.co:5432/postgres` | Direct connection Supabase hanya IPv6. IPv4 adalah add-on berbayar ($4/bln) | Koneksi DB gagal dari Render | **Supavisor session pooler** (`aws-0-[region].pooler.supabase.com:5432`) |
| B5 | NFR-01 "response < 500 ms" | Free web service spin down setelah 15 menit idle; cold start ±50 detik | Target hanya valid saat service warm | Dicatat sebagai batas operasional, bukan kegagalan |

---

## 3. Inkonsistensi Antar Dokumen

| # | Temuan | Lokasi | Koreksi |
|---|---|---|---|
| I1 | Kode undangan "6 karakter" vs `CHAR(8)` vs contoh `"SIGAP8K"` (7 karakter) | BE-FAM-01, schema, API | Seragamkan: **8 karakter** |
| I2 | Nama tabel `auth_user` | Schema | Model custom `AbstractBaseUser` menghasilkan tabel **`accounts_user`** |
| I3 | `role` di `auth_user` (RBAC) bertabrakan dengan `role` di `family_memberships` (`admin`/`member`) | Schema | Ganti menjadi `is_group_admin` (boolean) |
| I4 | Enum status: `safe\|need_help\|unknown` vs `belum_konfirmasi` | Schema, BE-FAM-04 | Hapus `unknown`. Tidak ada laporan = `latest_status: null` |
| I5 | Enum bencana tidak seragam (`extreme_weather` hanya di `alerts`, `general` hanya di `guides`) | Schema, filter API | Satu sumber konstanta per model; filter API menyebut daftar lengkap |
| I6 | `severity` (`waspada/siaga/awas`) tidak ada di data BMKG | BE-ALERT-01 | `severity` hanya untuk peringatan manual; alert BMKG memakai label "Info Gempa BMKG" |
| I7 | Amplop response tidak konsisten (`/api/me/preferences/`, `/api/map/risk-zones/`, `/api/auth/token/refresh/`) | API | Semua endpoint memakai `{status, data, message}` kecuali GeoJSON (dibungkus `data`) |
| I8 | `count/next/previous` diletakkan di dalam `data` | API | DRF menaruhnya di luar; dokumen mengikuti DRF |
| I9 | "Argon2 lebih aman dari bcrypt bawaan Django" | BE-AUTH-01 | Default Django adalah **PBKDF2** |
| I10 | `UNIQUE(user_id, fcm_token)` pada `device_tokens` | Schema | Satu device bisa berganti akun → salah sasaran. Ubah ke **`UNIQUE(fcm_token)`** |
| I11 | Deduplikasi BMKG via `content_hash` SHA256 | BE-ALERT-01 | Rapuh terhadap perubahan whitespace. Pakai **`UNIQUE(source_id, bmkg_datetime)`** |
| I12 | `audit_logs` prioritas P1 | Schema | NFR-03 & BRD §13 menuntut audit aksi admin sejak MVP → **P0** |
| I13 | `/api/alerts/latest/` mengembalikan `is_cached`, `cached_at` | API | Membocorkan detail internal dan melanggar NFR-02 PRD → ganti `source_updated_at` |
| I14 | Rate limit login "per IP" tanpa penanganan proxy | NFR-08 | Render berada di belakang proxy; tanpa `NUM_PROXIES` semua user dianggap 1 IP |
| I15 | "Ketersediaan 99,5%" | NFR BRD | Mustahil di free tier (tanpa SLA, restart sewaktu-waktu) → dicabut |

---

## 4. Kebutuhan PRD/BRD yang Belum Punya Endpoint

| # | Kebutuhan | Status | Tindakan |
|---|---|---|---|
| G1 | Konfirmasi reset password (`FR-01` P0) | Hanya ada request, tidak ada konfirmasi | Tambah `POST /api/auth/password/reset/confirm/` |
| G2 | Ganti password (`FR-10` P0) | Tidak ada | Tambah `POST /api/auth/password/change/` |
| G3 | Dashboard agregat (`FR-02` P0) | Harus 4–5 round-trip | Tambah `GET /api/dashboard/` |
| G4 | Hapus akun + retensi data (`NFR-04` PRD, §14 BRD, UU PDP) | Tidak ada | Tambah `DELETE /api/me/` + manajemen retensi |
| G5 | Persetujuan gabung grup (`FR-25` BRD) | Masih berstatus open issue | `family_memberships.status = pending/active/rejected` |
| G6 | Keluarkan anggota / transfer admin / hapus grup | Tidak ada | Tambah 3 endpoint |
| G7 | Validasi pelapor status adalah anggota grup | Tidak ada | Validasi di serializer + constraint |
| G8 | Strategi data awal zona risiko & titik evakuasi | Belum ada | Seed manual 20–30 titik, `verification_status=unverified` |

---

## 5. Keputusan yang Diambil

| # | Isu | Keputusan | Alasan |
|---|---|---|---|
| K1 | Sumber BMKG otomatis | Hanya **gempa** dari `gempadirasakan.json` | `autogempa.json` hanya 1 gempa nasional terakhir. Banjir/longsor/cuaca ekstrem tidak punya endpoint API publik |
| K2 | Severity alert BMKG | `severity = null` untuk BMKG | BMKG tidak mengirim skala waspada/siaga/awas. Membuat sendiri = melanggar BR-01 |
| K3 | Persetujuan gabung grup | **Wajib approve** admin grup | BRD FR-25 sudah mewajibkan |
| K4 | Layanan email | **Brevo SMTP port 2525** (free 300/hari) | Port 587 diblokir Render. Alternatif Resend butuh verifikasi domain |
| K5 | Data spasial | **Tanpa PostGIS.** `latitude`/`longitude` FloatField + haversine Python | Menghindari Docker + GDAL. Jumlah titik ratusan |
| K6 | Zona risiko | Simpan **GeoJSON** di `JSONField`, serve apa adanya | Flutter hanya merender layer, tidak melakukan query spasial |
| K7 | Cache | `LocMemCache` bawaan Django (TTL 60 detik) | Satu instance, tanpa dependency |
| K8 | Background task | Tidak ada. Lazy-fetch saat request | Free tier tidak punya cron/worker |
| K9 | Real-time keluarga | Polling 20 detik + FCM | Tanpa Django Channels |
| K10 | Panel admin | Django Admin | 8 area CRUD gratis |
| K11 | ORM | **Django ORM** | Built-in, migrasi otomatis, admin terintegrasi |
| K12 | Foto | Profil: Supabase Storage. Foto laporan: P1 | Foto opsional di PRD |
| K13 | OAuth Google | Ditunda | PRD menyatakan opsional |

---

## 6. Yang Dibuang (YAGNI)

| Item | Alasan | Pengganti |
|---|---|---|
| GeoDjango + PostGIS + GIST index | Butuh GDAL (Docker) untuk 1 query radius | FloatField + haversine |
| Celery + Redis + `django-crontab` | Tidak jalan di free tier | Lazy-fetch |
| `supabase` Python client | ±10 MB dependency untuk 1 PUT | `requests` ke Storage REST |
| `notification_preferences` (tabel + 2 endpoint) | 3 boolean | Kolom di `user_profiles` |
| `incident_reports` | P1 | Ditunda ke Fase 4 |
| `config/settings/{base,dev,prod}.py` | 3 file untuk 1 proyek kecil | 1 `settings.py` + env |
| `whitenoise` + Redis throttling | — | Dipertahankan: `whitenoise`; throttling pakai cache bawaan |

---

## 7. Batas Free Tier yang Diterima

| Layanan | Batas | Konsekuensi |
|---|---|---|
| Render web service | 750 instance jam/bln, spin down 15 menit idle, cold start ±50 detik | Request pertama setelah idle lambat |
| Render filesystem | Ephemeral | Media wajib ke Supabase Storage; `collectstatic` tiap deploy |
| Supabase DB | 500 MB, 5 GB egress, pause setelah 7 hari low-activity | Jangan tinggalkan proyek menganggur seminggu |
| Supabase backup | Tidak ada PITR | `pg_dump` manual sebelum demo/sidang |
| Supabase koneksi | Direct = IPv6 saja | Wajib Supavisor session pooler |
| Brevo | 300 email/hari, butuh verifikasi sender | Cukup untuk reset password |
| FCM | Gratis | — |

---

## 8. Estimasi Ulang

| Fase | Isi | Estimasi |
|---|---|---|
| Fase 0 | Revisi dokumen | ½ hari |
| Fase 1 | Settings, auth, profil, alerts, news, contacts, guides, map + seed | 1,5 minggu |
| Fase 2 | Keluarga, status, FCM, preferensi | 1 minggu |
| Fase 3 | CRUD officer/editor, Django Admin, audit log | ½ minggu |
| Fase 4 (P1) | Laporan warga, moderasi, retensi | 1 minggu |

Total P0: ±3 minggu untuk 1 orang part-time. Perkiraan LOC backend P0: ±1.800.
