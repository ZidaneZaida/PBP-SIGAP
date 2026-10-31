# Backend System Requirements — SIGAP

**Versi:** 1.0  
**Status:** Draft untuk Diskusi Tim  
**Tanggal:** Oktober 2026  
**Platform Target:** Django 5.x + Supabase (PostgreSQL) + Render.com  

---

## 1. Gambaran Umum

Backend SIGAP bertindak sebagai **single source of truth** untuk semua data yang dikonsumsi oleh dua frontend:
- **Flutter Android** (Mobile App)
- **Flutter Web** (Desktop/PC)

Seluruh interaksi frontend ke backend dilakukan melalui **REST API JSON** yang diautentikasi dengan token JWT. Backend juga bertanggung jawab atas sinkronisasi data resmi dari BMKG dan pengiriman push notification darurat via Firebase Cloud Messaging (FCM).

---

## 2. Tech Stack yang Dipilih

| Layer | Teknologi | Alasan Pemilihan |
|---|---|---|
| Framework | Django 5.x + DRF (Django REST Framework) 3.x | Kurikulum PBP, Django Admin untuk petugas, ORM kuat |
| Database | PostgreSQL 15+ via **Supabase Free Tier** | Mendukung PostGIS (GIS), gratis 500 MB, dashboard visual |
| Hosting | **Render.com Free Tier** | Deployment mudah dari GitHub, HTTPS otomatis |
| Auth | `djangorestframework-simplejwt` | Token JWT, refresh token, blacklist |
| GIS / Spasial | **GeoDjango + PostGIS** | Query radius titik evakuasi & zona bahaya Padang |
| Push Notification | **Firebase Cloud Messaging (FCM)** | Peringatan darurat < 1 menit ke device Android |
| Cache | **Upstash Redis (Free Tier)** | Cache data BMKG agar tidak membebani server resmi |
| Background Task | `django-crontab` atau Celery + Redis | Sinkronisasi otomatis data BMKG setiap 2 menit |
| Static Files | `whitenoise` | Serve CSS/JS Django Admin di Render |
| CORS | `django-cors-headers` | Izinkan akses dari Flutter Web dan Android |
| Environment Config | `python-decouple` atau `django-environ` | Secret key, DATABASE_URL, FCM credentials dari env vars |

---

## 3. Kebutuhan Fungsional Backend

### 3.1 Manajemen Akun Pengguna (Prioritas P0)

| ID | Kebutuhan | Detail |
|---|---|---|
| BE-AUTH-01 | Registrasi akun | Validasi email unik, nama, password (min 8 karakter, harus ada huruf & angka). Password di-hash dengan **Argon2** (lebih aman dari bcrypt bawaan Django). |
| BE-AUTH-02 | Login & penerbitan token | Return `access_token` (expire 1 jam) + `refresh_token` (expire 7 hari) dalam format JWT. |
| BE-AUTH-03 | Refresh token | Endpoint khusus memperpanjang sesi tanpa login ulang. |
| BE-AUTH-04 | Logout (blacklist token) | Memasukkan refresh token ke blacklist (`TokenBlacklist`) sehingga tidak bisa dipakai lagi. |
| BE-AUTH-05 | Pemulihan kata sandi | Kirim email dengan link/OTP reset password. (**Keputusan Tim:** Pakai layanan email apa? Rekomendasi: Resend.com atau Brevo Free Tier) |
| BE-AUTH-06 | Profil pengguna | CRUD data profil: nama, nomor telepon, foto profil (simpan ke Supabase Storage), wilayah utama. |
| BE-AUTH-07 | Sistem RBAC | 4 peran: `citizen` (default), `officer` (Petugas BPBD), `editor` (Editor Berita), `superadmin`. Peran diset manual oleh superadmin atau melalui Django Admin. |

---

### 3.2 Peringatan Bencana / Alerts (Prioritas P0)

| ID | Kebutuhan | Detail |
|---|---|---|
| BE-ALERT-01 | Sinkronisasi BMKG otomatis | Background job (cron / Celery) polling API BMKG (`https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json`) setiap **2 menit**. Data disimpan ke tabel `alerts` jika belum ada (berdasarkan hash konten / tanggal-jam unik). |
| BE-ALERT-02 | Cache hasil fetch BMKG | Hasil fetch BMKG disimpan di Redis selama 90 detik. Flutter client yang request `/api/alerts/latest/` membaca dari cache, bukan memanggil BMKG langsung. |
| BE-ALERT-03 | Penerbitan peringatan manual | Petugas BPBD / superadmin dapat membuat peringatan khusus Kota Padang melalui Django Admin atau endpoint khusus (protected role `officer`). |
| BE-ALERT-04 | Trigger push notification | Setiap ada peringatan baru aktif, background job mengirim FCM broadcast ke semua token device yang mengaktifkan notifikasi darurat. |
| BE-ALERT-05 | Filter wilayah | Peringatan gempa/tsunami hanya dikirimkan notifikasi ke pengguna yang wilayahnya adalah Kota Padang (atau area yang dimasukkan manual). |
| BE-ALERT-06 | Riwayat peringatan | Arsip peringatan (status `active` / `expired` / `cancelled`) dapat diakses dengan filter jenis bencana dan rentang tanggal. |

> **⚠️ Keputusan yang Diperlukan (diskusi tim):**  
> Apakah peringatan dari petugas BPBD langsung `active` atau perlu disetujui `superadmin` terlebih dahulu?

---

### 3.3 Berita Kebencanaan (Prioritas P0)

| ID | Kebutuhan | Detail |
|---|---|---|
| BE-NEWS-01 | CRUD berita oleh editor | Hanya akun dengan role `editor` atau `superadmin` yang dapat membuat, mengubah, dan menghapus artikel berita. |
| BE-NEWS-02 | Metadata wajib | Setiap berita **wajib** memiliki: sumber, penulis/editor, tanggal publikasi, dan kategori (gempa, banjir, longsor, tsunami, umum). |
| BE-NEWS-03 | Berita publik (tanpa login) | Endpoint daftar berita dan detail berita dapat diakses tanpa autentikasi (public read). |
| BE-NEWS-04 | Pagination | Daftar berita menggunakan cursor-based atau page-based pagination (default 10 artikel per halaman). |

---

### 3.4 Peta Risiko & Lokasi Bantuan (Prioritas P0)

| ID | Kebutuhan | Detail |
|---|---|---|
| BE-MAP-01 | Data titik bantuan dengan koordinat | Tabel `assistance_points` menyimpan koordinat sebagai tipe data **Point (PostGIS)**. |
| BE-MAP-02 | Endpoint query radius | `GET /api/map/nearby/?lat=X&lon=Y&radius=5000&category=evacuation` mengembalikan titik bantuan terdekat dalam radius X meter. Menggunakan query PostGIS `ST_DWithin`. |
| BE-MAP-03 | Layer zona risiko | Data zona risiko bencana (gempa, tsunami, banjir) disimpan sebagai tipe **Polygon (PostGIS)** di tabel `risk_zones`. Diekspos sebagai GeoJSON. |
| BE-MAP-04 | Data CRUD oleh admin | Titik bantuan dan zona risiko hanya dapat ditambah/ubah/hapus oleh `officer` atau `superadmin` melalui Django Admin. |

> **⚠️ Keputusan yang Diperlukan:**  
> Data awal zona risiko dan titik evakuasi Kota Padang darimana? Opsi: 1) Input manual oleh admin SIGAP, 2) Import dari data shapefile BPBD Padang (jika tersedia).

---

### 3.5 Keluarga & Status Keselamatan (Prioritas P0)

| ID | Kebutuhan | Detail |
|---|---|---|
| BE-FAM-01 | Buat dan kelola grup keluarga | Pengguna dapat membuat grup dan mendapatkan kode undangan unik (6 karakter alfanumerik, expire 24 jam). |
| BE-FAM-02 | Bergabung ke grup | Pengguna memasukkan kode undangan untuk bergabung ke grup keluarga. Perlu persetujuan dari pembuatan grup (opsional, perlu diskusi). |
| BE-FAM-03 | Kirim status keselamatan | `POST /api/family/status/` menerima `status` (`safe` / `need_help` / `unknown`) dan `message` (opsional). Status langsung tersimpan dan FCM silent push dikirim ke semua anggota grup. |
| BE-FAM-04 | Lihat status anggota | `GET /api/family/members/` mengembalikan daftar anggota beserta status keselamatan terakhir dan waktu update. Anggota yang belum update ditampilkan sebagai `belum_konfirmasi`. |
| BE-FAM-05 | Privasi lokasi | Koordinat hanya dikirim ke server jika pengguna secara eksplisit men-toggle opsi "Bagikan lokasi saya". Backend menyimpan lokasi terakhir hanya di record `safety_status`, bukan di profil. |

> **⚠️ Keputusan yang Diperlukan:**  
> Apakah bergabung ke grup keluarga memerlukan persetujuan dari admin grup, atau langsung masuk dengan kode?

---

### 3.6 Kontak Darurat & Panduan Kesiapsiagaan (Prioritas P0)

| ID | Kebutuhan | Detail |
|---|---|---|
| BE-CONTACT-01 | Data kontak darurat | Tabel `emergency_contacts` berisi nama layanan, nomor telepon, kategori (polisi, BPBD, SAR, rumah sakit), dan status verifikasi. |
| BE-CONTACT-02 | CRUD oleh admin | Hanya `officer` / `superadmin` yang dapat menambah/ubah/hapus kontak darurat. |
| BE-CONTACT-03 | Panduan kesiapsiagaan | Tabel `guides` berisi artikel panduan (Sebelum/Saat/Sesudah bencana). Konten bisa disimpan dalam format Markdown atau HTML sederhana. |

---

### 3.7 Laporan Warga & Moderasi (Prioritas P1 - Setelah MVP)

| ID | Kebutuhan | Detail |
|---|---|---|
| BE-REPORT-01 | Submit laporan kejadian | Pengguna (harus login) dapat mengirim laporan: kategori, deskripsi, koordinat (opsional), foto (opsional, upload ke Supabase Storage). |
| BE-REPORT-02 | Moderasi admin | Laporan baru otomatis berstatus `pending`. Petugas dapat mengubah ke `verified`, `rejected`, atau `closed` di Django Admin. |
| BE-REPORT-03 | Audit trail | Setiap perubahan status laporan dicatat di tabel `audit_logs` (siapa, kapan, dari status apa ke status apa). |

---

## 4. Kebutuhan Non-Fungsional

| ID | Kategori | Target |
|---|---|---|
| NFR-01 | Response Time API | < 500ms untuk endpoint publik (berita, alerts) yang di-cache |
| NFR-02 | Kecepatan Notifikasi | FCM dikirim < 60 detik setelah peringatan baru disimpan |
| NFR-03 | Keamanan Password | Hash Argon2 (bukan MD5 / SHA1 polos) |
| NFR-04 | Enkripsi Transport | HTTPS wajib (sudah otomatis di Render.com) |
| NFR-05 | Offline Fallback | Flutter client harus cache respons terakhir secara lokal (tanggung jawab frontend, bukan backend) |
| NFR-06 | Privasi Lokasi | Koordinat pengguna tidak pernah disimpan tanpa consent eksplisit |
| NFR-07 | CORS | Whitelist hanya domain yang dikenal (Flutter Web production URL + localhost dev) |
| NFR-08 | Rate Limiting | Endpoint login dibatasi: maks 5 kali gagal per IP per 10 menit (cegah brute force) |

---

## 5. Konfigurasi Environment Variables

Berikut variabel lingkungan yang harus dikonfigurasi di **Render.com Dashboard** maupun di file `.env` lokal (jangan pernah di-commit ke Git):

```env
# Django Core
SECRET_KEY=django-insecure-ganti-dengan-random-string-panjang
DEBUG=False
ALLOWED_HOSTS=nama-app-anda.onrender.com

# Database Supabase
DATABASE_URL=postgresql://postgres:[password]@db.[ref].supabase.co:5432/postgres

# JWT
ACCESS_TOKEN_LIFETIME_MINUTES=60
REFRESH_TOKEN_LIFETIME_DAYS=7

# Firebase FCM
FIREBASE_CREDENTIALS_JSON={"type":"service_account",...}

# CORS (URL Flutter Web yang diizinkan)
CORS_ALLOWED_ORIGINS=https://nama-web-anda.onrender.com,http://localhost:3000

# Email Service (untuk reset password)
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=email-sigap@gmail.com
EMAIL_HOST_PASSWORD=app-password-gmail

# Supabase Storage (untuk upload foto laporan & profil)
SUPABASE_URL=https://[ref].supabase.co
SUPABASE_SERVICE_KEY=eyJ...
```

---

## 6. Struktur Folder Backend (Rekomendasi)

```
backend/                          ← Root folder backend Django
├── manage.py
├── requirements.txt
├── .env                          ← JANGAN commit ke Git!
├── .env.example                  ← Template env (aman untuk commit)
│
├── config/                       ← Konfigurasi proyek Django
│   ├── __init__.py
│   ├── settings/
│   │   ├── base.py               ← Settings dasar (shared)
│   │   ├── development.py        ← Settings lokal (DEBUG=True)
│   │   └── production.py         ← Settings Render (DEBUG=False)
│   ├── urls.py
│   ├── wsgi.py
│   └── asgi.py
│
├── apps/
│   ├── accounts/                 ← Auth, User, Profile
│   ├── alerts/                   ← Peringatan bencana + BMKG sync
│   ├── news/                     ← Berita kebencanaan
│   ├── map/                      ← Titik bantuan, zona risiko (GIS)
│   ├── family/                   ← Grup keluarga & status keselamatan
│   ├── guides/                   ← Panduan kesiapsiagaan
│   ├── reports/                  ← Laporan warga (P1 - post MVP)
│   └── notifications/            ← FCM push notification
│
└── requirements.txt
```

---

## 7. Dependensi Python (requirements.txt)

```
Django==5.1.3
djangorestframework==3.15.2
djangorestframework-simplejwt==5.3.1
django-cors-headers==4.4.0
django-environ==0.11.2
dj-database-url==2.2.0
psycopg2-binary==2.9.9
whitenoise==6.7.0

# GIS
GDAL==3.9.2               # Cek versi yang tersedia di Render
django-geospatial          # Alternatif jika GDAL sulit

# Push Notification FCM
firebase-admin==6.5.0

# Background Task
django-crontab==0.7.1
# ATAU
celery==5.4.0
redis==5.1.1

# Supabase Storage Client (untuk upload file)
supabase==2.7.4

# Argon2 password hasher
argon2-cffi==23.1.0

# Development only
django-debug-toolbar==4.4.6
```

---

## 8. Hal-hal yang Perlu Didiskusikan Tim

> **Open Issues — Perlu Keputusan Bersama**

### 8.1 🔴 Kritis (Harus Diputuskan Sebelum Mulai Coding)

1. **Persetujuan bergabung grup keluarga** — Langsung masuk dengan kode invite, atau perlu di-approve admin grup?
2. **Penerbitan peringatan BPBD** — Langsung aktif atau butuh persetujuan superadmin?
3. **Sumber data awal peta risiko** — Input manual atau import shapefile? Siapa yang input data awal ini?
4. **Layanan email untuk reset password** — Gmail App Password? Resend.com? Brevo?

### 8.2 🟡 Penting (Diskusikan Sebelum Sprint Kedua)

5. **Real-time status keluarga** — Cukup polling REST API + FCM untuk MVP, atau langsung WebSocket (Django Channels)?
6. **Pembagian tugas implementasi app Django** — Siapa yang mengerjakan `apps/accounts/`, `apps/alerts/`, `apps/family/`, dll.?
7. **Foto profil & foto laporan** — Upload ke Supabase Storage atau cukup URL eksternal?

### 8.3 🟢 Dapat Diputuskan Belakangan

8. Dukungan login Google (OAuth2) — Untuk MVP cukup email/password dulu?
9. Mode offline Flutter — Seberapa dalam cache lokal yang dibutuhkan?
10. Panel admin custom atau cukup Django Admin bawaan untuk seluruh MVP?

