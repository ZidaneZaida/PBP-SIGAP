# Backend System Requirements — SIGAP

**Versi:** 2.0 (hasil audit 11 Februari 2026)
**Status:** Siap implementasi
**Platform Target:** Django 5.x + Supabase (PostgreSQL) + Render.com Free Tier
**Dokumen terkait:** [`backend-audit.md`](./backend-audit.md), [`database-schema.md`](./database-schema.md), [`api-documentation.md`](./api-documentation.md)

---

## 1. Gambaran Umum

Backend SIGAP adalah **single source of truth** untuk dua frontend:
- **Flutter Android** (mobile)
- **Flutter Web** (desktop)

Seluruh interaksi melalui **REST API JSON** dengan JWT. Backend juga menyimpan data gempa BMKG, menerbitkan peringatan petugas, dan mengirim push notification via FCM.

**Batasan yang menentukan desain:** seluruh sistem harus berjalan di free tier. Karena itu tidak ada cron job, tidak ada background worker, tidak ada message queue, dan tidak ada PostGIS.

---

## 2. Tech Stack Final

| Layer | Teknologi | Keterangan |
|---|---|---|
| Framework | Django 5.x + DRF 3.x | — |
| **ORM** | **Django ORM** | Built-in. Migrasi, relasi, admin terintegrasi. Tidak memakai ORM eksternal |
| Database | PostgreSQL 15 via Supabase Free Tier | 500 MB, koneksi lewat **Supavisor session pooler** |
| Hosting | Render.com Free Tier | 750 jam/bln, spin down 15 menit idle |
| Auth | `djangorestframework-simplejwt` | Access 1 jam, refresh 7 hari, blacklist |
| Password hash | Argon2 (`argon2-cffi`) | Default Django PBKDF2; Argon2 opsional |
| Push Notification | Firebase Cloud Messaging (`firebase-admin`) | Gratis |
| Cache | **`LocMemCache` bawaan Django** | TTL 60 detik untuk data BMKG |
| Data spasial | **`FloatField` + haversine Python** | Tanpa PostGIS/GeoDjango |
| Zona risiko | **`JSONField` berisi GeoJSON** | Disajikan apa adanya ke `flutter_map` |
| Email | **Brevo SMTP (port 2525)** | Port 25/465/587 diblokir Render |
| Static files | `whitenoise` | Django Admin |
| CORS | `django-cors-headers` | — |
| Config | `django-environ` | — |

### 2.1 Yang Tidak Digunakan (dan alasannya)

| Ditolak | Alasan |
|---|---|
| Celery, Redis, `django-crontab` | Render Free tanpa cron/worker. `django-crontab` tidak dirawat sejak 2017 |
| GeoDjango, PostGIS, GDAL | GDAL butuh native lib (Docker ±1 GB). Query spasial hanya 1 (radius) |
| Prisma, Drizzle, SQLAlchemy | ORM Node/TS atau di luar Django. Django ORM sudah memadai |
| Supabase Python client | Dependency berat untuk satu operasi upload |
| Django Channels / WebSocket | Polling 20 detik memenuhi kebutuhan |

---

## 3. Kebutuhan Fungsional

### 3.1 Akun & Autentikasi (P0)

| ID | Kebutuhan | Detail |
|---|---|---|
| BE-AUTH-01 | Registrasi | Email unik, `full_name`, password min 8 karakter (huruf + angka). Hash Argon2 |
| BE-AUTH-02 | Login | Return `access` (1 jam) + `refresh` (7 hari) + objek user |
| BE-AUTH-03 | Refresh token | `POST /api/auth/token/refresh/` |
| BE-AUTH-04 | Logout | Refresh token masuk blacklist |
| BE-AUTH-05 | Lupa password | Kirim email tautan reset via Brevo. Response selalu 200 (tidak membocorkan status email) |
| BE-AUTH-06 | Konfirmasi reset password | Verifikasi `uid` + `token` Django, lalu set password baru |
| BE-AUTH-07 | Ganti password | Wajib `old_password` |
| BE-AUTH-08 | Profil | GET/PATCH nama, telepon, foto, wilayah, catatan alamat |
| BE-AUTH-09 | Hapus akun | Anonimisasi data pribadi, lepas keanggotaan grup, audit log dipertahankan |
| BE-AUTH-10 | RBAC | `citizen` (default), `officer`, `editor`, `superadmin`. Diset via Django Admin |

### 3.2 Peringatan Bencana (P0)

| ID | Kebutuhan | Detail |
|---|---|---|
| BE-ALERT-01 | Ambil data gempa BMKG | **Lazy-fetch** dari `gempadirasakan.json` saat `/api/alerts/latest/` atau `/api/dashboard/` dipanggil. Hasil di-cache 60 detik. **Bukan cron** |
| BE-ALERT-02 | Filter relevansi Padang | Simpan hanya gempa dengan jarak episentrum ≤ 300 km dari Kota Padang (-0.9492, 100.3543), dihitung haversine |
| BE-ALERT-03 | Deduplikasi | `UNIQUE(source_id, bmkg_datetime)` |
| BE-ALERT-04 | Peringatan manual | `officer`/`superadmin` membuat peringatan (gempa, tsunami, banjir, longsor, cuaca ekstrem) via API atau Django Admin. Langsung `active` |
| BE-ALERT-05 | Severity | Hanya untuk peringatan manual: `waspada`/`siaga`/`awas`. Alert BMKG memakai `severity = null` dan label "Info Gempa BMKG" |
| BE-ALERT-06 | Push notification | Dikirim **sinkron** di dalam request pembuatan alert. Tidak ada worker. Kegagalan FCM tidak menggagalkan pembuatan alert |
| BE-ALERT-07 | Riwayat | Filter `status`, `disaster_type`, rentang tanggal, pagination |
| BE-ALERT-08 | Tanpa prediksi | Backend tidak membuat peringatan sendiri selain meneruskan data BMKG apa adanya (`BR-01` BRD) |

### 3.3 Berita (P0)

| ID | Kebutuhan | Detail |
|---|---|---|
| BE-NEWS-01 | CRUD oleh `editor`/`superadmin` | Slug auto-generate + penanganan tabrakan (`-2`, `-3`) |
| BE-NEWS-02 | Metadata wajib | Sumber, penulis, tanggal publikasi, kategori, area tag |
| BE-NEWS-03 | Akses publik | List + detail tanpa login, hanya `is_published=True` |
| BE-NEWS-04 | Pagination | Page-based, default 10, maks 30 |

### 3.4 Peta & Lokasi Bantuan (P0)

| ID | Kebutuhan | Detail |
|---|---|---|
| BE-MAP-01 | Titik bantuan | `latitude`, `longitude` sebagai `FloatField`. Kategori: `evacuation_point`, `emergency_post`, `hospital`, `health_center`, `relief_point` |
| BE-MAP-02 | Query radius | `GET /api/map/nearby/?lat=&lon=&radius=&category=`. Prefilter bounding box (`latitude__range`, `longitude__range`), lalu haversine Python, urut jarak, maks 50 hasil |
| BE-MAP-03 | Zona risiko | GeoJSON `FeatureCollection` dari `risk_zones.geojson`. Flutter merender langsung |
| BE-MAP-04 | CRUD | Hanya `officer`/`superadmin` (API + Django Admin) |
| BE-MAP-05 | Data awal | Seed manual 20–30 titik dengan `verification_status=unverified`. UI wajib menampilkan label belum terverifikasi |

### 3.5 Keluarga & Status Keselamatan (P0)

| ID | Kebutuhan | Detail |
|---|---|---|
| BE-FAM-01 | Buat grup | Kode undangan **8 karakter**, expire 24 jam, dapat di-regenerate |
| BE-FAM-02 | Gabung grup | Status awal `pending`. **Wajib disetujui admin grup** (`FR-25` BRD) |
| BE-FAM-03 | Kelola anggota | Admin grup dapat approve/reject, mengeluarkan anggota, dan memindahkan status admin |
| BE-FAM-04 | Kirim status | `safe` / `need_help` + pesan opsional. FCM dikirim ke anggota aktif lain di grup |
| BE-FAM-05 | Lihat anggota | Status terbaru per anggota. Anggota tanpa laporan → `latest_status: null` (UI: "Belum ada konfirmasi") |
| BE-FAM-06 | Privasi lokasi | Koordinat hanya disimpan bila `share_location: true`. Disimpan di `safety_statuses`, bukan di profil |
| BE-FAM-07 | Keluar grup | Admin terakhir tidak boleh keluar sebelum memindahkan status admin atau menghapus grup |
| BE-FAM-08 | Otorisasi | Semua endpoint grup memvalidasi `family_memberships(status='active')` |

### 3.6 Kontak Darurat & Panduan (P0)

| ID | Kebutuhan | Detail |
|---|---|---|
| BE-CONTENT-01 | Kontak darurat | Nama, kategori, nomor, status verifikasi, tanggal verifikasi |
| BE-CONTENT-02 | CRUD kontak | `officer`/`superadmin` |
| BE-CONTENT-03 | Panduan | Markdown, dikelompokkan `disaster_type` + `phase` (`before`/`during`/`after`), urut `sort_order` |
| BE-CONTENT-04 | CRUD panduan | `officer`/`superadmin` |

### 3.7 Dashboard (P0)

| ID | Kebutuhan | Detail |
|---|---|---|
| BE-DASH-01 | Endpoint agregat | Satu request: alert aktif terbaru, 3 berita terbaru, ringkasan status keluarga, jumlah titik bantuan terverifikasi, `generated_at` |
| BE-DASH-02 | Data jujur | Field tanpa data dikirim `null` — frontend menampilkan "Data belum tersedia", bukan angka buatan |

### 3.8 Laporan Warga (P1 — Fase 4)

| ID | Kebutuhan | Detail |
|---|---|---|
| BE-REPORT-01 | Submit laporan | Kategori, deskripsi, koordinat opsional (consent), foto opsional |
| BE-REPORT-02 | Moderasi | `pending` → `verified`/`rejected`/`closed` via Django Admin |
| BE-REPORT-03 | Audit | Setiap perubahan status tercatat di `audit_logs` |

---

## 4. Kebutuhan Non-Fungsional

Target disesuaikan dengan kemampuan free tier — angka yang tidak dapat dijamin dihapus.

| ID | Kategori | Target |
|---|---|---|
| NFR-01 | Response time | < 500 ms untuk endpoint publik (saat instance warm). Cold start ±50 detik diterima dan wajib ditangani frontend dengan skeleton loading |
| NFR-02 | Notifikasi | FCM terkirim < 60 detik setelah alert disimpan (sinkron dalam request) |
| NFR-03 | Password | Argon2 / PBKDF2, tidak pernah plaintext |
| NFR-04 | Transport | HTTPS wajib (otomatis di Render) |
| NFR-05 | Offline | Tanggung jawab frontend. Backend tidak menyediakan mode offline |
| NFR-06 | Privasi lokasi | Koordinat hanya disimpan dengan consent eksplisit (`share_location: true`) |
| NFR-07 | CORS | Whitelist domain Flutter Web + localhost. Tidak ada `CORS_ALLOW_ALL_ORIGINS` di produksi |
| NFR-08 | Rate limit | Login: 5 gagal / IP / 10 menit. Register: 10 / IP / jam. Wajib set `NUM_PROXIES` agar IP asli terbaca di belakang proxy Render |
| NFR-09 | Audit | Aksi `officer`/`editor`/`superadmin` yang mengubah data publik dicatat di `audit_logs` |
| NFR-10 | Backup | `pg_dump` manual sebelum demo/sidang (Supabase Free tanpa PITR) |
| NFR-11 | Ketersediaan | Tidak ada SLA. Tidak boleh diklaim sebagai layanan produksi |
| NFR-12 | Retensi | `safety_statuses` lebih dari 90 hari dihapus lewat management command manual |

---

## 5. Konfigurasi Environment Variables

```env
# Django core
SECRET_KEY=ganti-dengan-random-string-panjang
DEBUG=True            # False di produksi
ALLOWED_HOSTS=localhost,127.0.0.1

# Database — Supabase SESSION pooler (port 5432). JANGAN port 6543.
# Dev DAN produksi memakai Supabase (tidak ada DB lokal).
DATABASE_URL=postgresql://postgres.[ref]:[password]@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres
CONN_MAX_AGE=0

# Testing
TEST_DB_NAME=           # isi bila project test berbeda dari DATABASE_URL
ALLOW_REMOTE_TESTS=True # wajib true bila host DB remote (Supabase)

# JWT
ACCESS_TOKEN_LIFETIME_MINUTES=60
REFRESH_TOKEN_LIFETIME_DAYS=7

# Frontend (tautan reset password di email)
FRONTEND_BASE_URL=http://localhost:3000

# FCM — bila kosong, push notification dilewati tanpa error
FIREBASE_CREDENTIALS_JSON={"type":"service_account",...}

# CORS
CORS_ALLOWED_ORIGINS=https://sigap-web.onrender.com,http://localhost:3000
NUM_PROXIES=1

# Email — Brevo, port 2525 (port 25/465/587 diblokir Render).
# Bila EMAIL_HOST_USER kosong, Django memakai console backend.
EMAIL_HOST=smtp-relay.brevo.com
EMAIL_PORT=2525
EMAIL_USE_TLS=True
EMAIL_HOST_USER=xxxxxxx@smtp-brevo.com
EMAIL_HOST_PASSWORD=xxxxxxxxxxxx
DEFAULT_FROM_EMAIL=SIGAP <no-reply@sigap.app>

# Supabase Storage
SUPABASE_URL=https://[ref].supabase.co
SUPABASE_SERVICE_KEY=eyJ...
SUPABASE_BUCKET_AVATARS=avatars

# Endpoint internal (dijadwalkan GitHub Actions, opsional)
INTERNAL_SYNC_TOKEN=random-string-panjang

# Integrasi BMKG
BMKG_GEMPA_URL=https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json
PADANG_LAT=-0.9492
PADANG_LON=100.3543
PADANG_RADIUS_KM=300
BMKG_CACHE_TTL=60
```

> **Catatan:**
> - `db.[ref].supabase.co:5432` (direct connection) hanya IPv6 — koneksi akan gagal. Gunakan pooler.
> - `python manage.py test` membuat database `test_postgres` dan butuh privilege `CREATEDB`. Bila ditolak, lihat [`backend-implementation.md`](./backend-implementation.md).
> - `ALLOW_REMOTE_TESTS=True` sengaja dipakai karena DB dev berada di Supabase; guard ini mencegah test tak sengaja menembak DB produksi.

---

## 6. Struktur Folder Backend

```
backend/
├── manage.py
├── requirements.txt
├── .env                  ← jangan commit
├── .env.example
├── config/
│   ├── __init__.py
│   ├── settings.py       ← satu file, dibedakan lewat env
│   ├── urls.py
│   ├── wsgi.py
│   └── asgi.py
├── apps/
│   ├── accounts/         ← User custom, profil, preferensi, device token, auth views
│   ├── alerts/           ← Alert, Source, BMKG lazy-fetch
│   ├── news/             ← Berita
│   ├── map/              ← AssistancePoint, RiskZone, haversine
│   ├── family/           ← Grup, membership, status keselamatan
│   ├── guides/           ← Panduan + kontak darurat
│   ├── notifications/    ← FCM client
│   ├── reports/          ← P1
│   └── common/           ← BaseModel, pagination, envelope response, permissions, audit
└── fixtures/             ← seed data awal (posko, kontak, panduan)
```

### 6.1 Konvensi kode

- Semua model mewarisi `apps.common.models.TimeStampedModel` (`created_at`, `updated_at`).
- UUID sebagai primary key (`uuid.uuid4`).
- Enum memakai `models.TextChoices` di dalam model, satu sumber kebenaran per model.
- Response dibungkus `apps.common.renderers.ApiResponse` → `{status, data, message}`.
- Pagination custom: `count/next/previous/results` di level atas (bukan di dalam `data`).
- Permission object di `apps.common.permissions` (`IsOfficer`, `IsEditor`, `IsSuperAdmin`, `IsGroupAdmin`).

---

## 7. Dependensi Python

```
Django==5.1.3
djangorestframework==3.15.2
djangorestframework-simplejwt==5.3.1
django-cors-headers==4.4.0
django-environ==0.11.2
dj-database-url==2.2.0
psycopg[binary]==3.2.3
whitenoise==6.7.0
argon2-cffi==23.1.0
firebase-admin==6.5.0
requests==2.32.3
```

Dihapus dari versi sebelumnya: `GDAL`, `django-geospatial`, `django-crontab`, `celery`, `redis`, `supabase`.

`requirements-dev.txt`:
```
django-debug-toolbar==4.4.6
ruff==0.7.1
```

---

## 8. Keputusan yang Sudah Ditetapkan

Semua open issue versi 1.0 sudah ditutup. Rinciannya di [`backend-audit.md`](./backend-audit.md) §5.

| Isu lama | Keputusan |
|---|---|
| Persetujuan gabung grup | Wajib approve admin grup |
| Peringatan BPBD langsung aktif? | Ya, langsung `active` |
| Sumber data awal peta | Seed manual, ditandai `unverified` |
| Layanan email | Brevo SMTP port 2525 |
| Real-time keluarga | Polling 20 detik + FCM |
| Upload foto | Profil: Supabase Storage. Laporan: P1 |
| Login Google | Ditunda |
| Panel admin | Django Admin |
| Mode offline | Frontend |

---

## 9. Rencana Implementasi

| Fase | Isi | Keluaran |
|---|---|---|
| 0 | Revisi dokumen | Dokumen konsisten ✅ |
| 1 | `common`, `accounts`, `alerts`, `news`, `guides`, `map` + seed | API publik + auth jalan |
| 2 | `family`, `notifications`, FCM, preferensi | Fitur keluarga jalan |
| 3 | CRUD officer/editor, Django Admin, audit log | Operasional konten |
| 4 | `reports` + moderasi + retensi | P1 selesai |