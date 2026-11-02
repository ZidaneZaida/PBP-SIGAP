# Implementasi Backend — Status & Panduan

**Versi:** 1.0 · **Tanggal:** 11 Februari 2026
**Database:** Supabase (dev + produksi), tanpa DB lokal

---

## 1. Status

| Milestone | Status | Isi |
|---|---|---|
| M0b · Fondasi | ✅ Terverifikasi lokal | settings, common, accounts (User/UserProfile/DeviceToken), health |
| M1 · Auth & profil | ✅ Terverifikasi lokal | 11 endpoint auth + me |
| M2 · Konten publik | ✅ Terverifikasi lokal | alerts + lazy BMKG, news, map, guides, dashboard, seed |
| M3 · Keluarga & FCM | ✅ Terverifikasi lokal | 13 endpoint family, FCM client |
| M4 · Audit & otorisasi | ✅ Terverifikasi lokal | `audit_logs`, mixin, admin, permission role |
| M5 · Deploy | ⬜ Belum | render.yaml, CI |
| M6 · Integrasi Flutter | ⬜ Belum | `app/lib/core/network/` |

**Terverifikasi (branch `feat/lokal`, Postgres 16 lokal):**

| Cek | Hasil |
|---|---|
| `manage.py check` | 0 issue |
| `manage.py migrate` | semua migrasi OK (termasuk `common.0001`) |
| `manage.py seed_demo` | 2 sumber, 6 kontak, 12 titik, 9 panduan |
| `manage.py test --noinput` | **33 test lulus** |
| `ruff check .` | bersih |
| `curl /api/health/` | `{"db":"ok"}` |
| `curl /api/guides/`, `/assistance-points/`, `/emergency-contacts/` | data seed tampil |
| `curl /api/me/` tanpa token | `401 UNAUTHORIZED` |
| `curl /api/alerts/latest/` | `200`, `alert: null` (tidak ada gempa ≤300 km saat itu) |

**Belum diverifikasi:** koneksi ke Supabase (placeholder `[ref]` belum diisi), FCM asli, upload foto.

---

## 2. Peta kode

```
backend/
├── config/settings.py          1 file, env-driven, guard test remote
├── apps/common/                envelope, pagination, exceptions, geo, audit, dashboard, seed
│   └── management/commands/seed_demo.py
├── apps/accounts/              User, UserProfile, DeviceToken, auth views, Supabase upload
├── apps/alerts/                Source, Alert, services.py (BMKG lazy + cache)
├── apps/news/                  NewsArticle, slug unik, CRUD editor
├── apps/map/                   AssistancePoint, RiskZone (GeoJSON), nearby haversine
├── apps/guides/                EmergencyContact, Guide
├── apps/family/                FamilyGroup, FamilyMembership(approval), SafetyStatus
└── apps/notifications/fcm.py   kirim FCM; aman bila kredensial kosong
```

---

## 3. Langkah manual yang diperlukan

### 3.1 Prasyarat

Tidak butuh `sudo`, tidak butuh Docker. Yang dipakai: Miniconda (interpreter + server Postgres).

```bash
# interpreter Python 3.13 untuk venv
conda create -n py313 python=3.13 -y

# server Postgres 16
conda create -n pg16 -c conda-forge --override-channels postgresql=16 -y
```

### 3.2 venv proyek

```bash
cd backend
~/miniconda3/envs/py313/bin/python -m venv server-django
source server-django/bin/activate
pip install -U pip && pip install -r requirements-dev.txt
```

Nama venv boleh apa saja; Makefile memakai `VENV ?= server-django`. Override bila berbeda:
`make PY=.venv/bin/python test`.

### 3.3 Postgres lokal

```bash
make db-init     # initdb sekali saja (-U postgres, auth trust)
make db-start    # jalankan di port 5432
make db-create   # buat database `sigap`
make db-stop     # hentikan
```

Data tersimpan di `~/sigap-pgdata`, log di `~/sigap-pgdata/server.log`.

### 3.4 `.env`

```bash
cp .env.example .env
```

Default `.env.example` sudah menunjuk Postgres lokal:

```env
DATABASE_URL=postgres://postgres@127.0.0.1:5432/sigap
DEBUG=True
ALLOW_REMOTE_TESTS=
```

### 3.5 Migrasi, data awal, superuser

```bash
make check                 # 0 issue
make makemigrations        # bila model berubah
make migrate
make seed
make superuser             # interaktif: email + password
make run                   # http://127.0.0.1:8000
```

Verifikasi: `curl http://127.0.0.1:8000/api/health/`
→ `{"status":"success","data":{"db":"ok","version":"0.1.0"}}`

### 3.6 FCM (opsional, untuk M3)

1. Firebase Console → buat project → aktifkan Cloud Messaging.
2. Project settings → Service accounts → *Generate new private key*.
3. Tempel isi JSON (satu baris) ke `FIREBASE_CREDENTIALS_JSON` di `.env`.

Bila dikosongkan, `fcm.send_*` mengembalikan 0 dan mencatat log — endpoint tetap sukses.

---

## 4. Troubleshooting

### 4.1 `permission denied to create database` saat `manage.py test`

Django membuat database `test_postgres`. Role `postgres` Supabase **bukan superuser**.

| Urutan | Aksi |
|---|---|
| 1 | Cek: `python manage.py test` — bila lulus, selesai |
| 2 | Bila ditolak: buat **project Supabase kedua** khusus test (kuota free = 2 project). Set `TEST_DB_NAME=postgres` di `.env` **hanya bila** `DATABASE_URL` menunjuk project test |
| 3 | Bila masih gagal: jalankan test dengan `DATABASE_URL=<pooler project test> python manage.py test --keepdb` |

Peringatan: opsi 2–3 memakai database project test apa adanya. **Jangan arahkan ke project produksi** — Django akan membuat/menghapus data di sana.

### 4.1b `manage.py test` menggantung tanpa output

Django menanyakan konfirmasi interaktif bila database test sudah ada:

```
Type 'yes' if you would like to try deleting the test database 'test_sigap', or 'no' to cancel:
```

Solusi: `make test` (sudah memakai `--noinput`). Bila terlanjur ada:

```bash
~/miniconda3/envs/pg16/bin/dropdb -h 127.0.0.1 -U postgres --if-exists test_sigap
```

### 4.2 `runserver` me-redirect ke HTTPS

`DEBUG=False` memasang `SECURE_SSL_REDIRECT=True`. Pastikan `.env` ada dan `DEBUG=True`.

### 4.3 `Tenant or user not found`

Username pooler harus `postgres.<project_ref>`, bukan `postgres`.

### 4.4 Semua request lambat setelah idle

Supabase free pause setelah 7 hari low-activity. Buka dashboard untuk membangunkan.

---

### 4.5 `/api/alerts/latest/` mengembalikan `alert: null`

Bukan error. Sumber `gempadirasakan.json` hanya memuat gempa yang **dirasakan**
(±15 kejadian nasional terakhir); sering tidak ada yang berjarak ≤ 300 km dari Padang.
Untuk demo, buat peringatan manual via Django Admin atau `POST /api/officer/alerts/`
(jalur ini juga yang dipakai untuk banjir/longsor, yang tidak punya API BMKG).

### 4.6 `assistance_point_count` di dashboard bernilai 0

Dashboard hanya menghitung titik berstatus `verified`. Data seed sengaja
`unverified` (belum dikonfirmasi BPBD). Verifikasi lewat Django Admin →
Assistance Points → ubah `verification_status`, atau tambahkan query param
`?verification_status=all` di `/api/assistance-points/`.

---

## 5. Checklist verifikasi lokal

| # | Perintah | Harapan |
|---|---|---|
| 1 | `python manage.py check` | 0 issue |
| 2 | `python manage.py migrate` | tabel `accounts_user`, `alerts`, `family_*`, `audit_logs` dibuat |
| 3 | `make test` (`--noinput`) | 33 test lulus |
| 4 | `curl /api/health/` | `data.db == "ok"` |
| 5 | `curl /api/tidak-ada/` | `{"status":"error","code":"NOT_FOUND"}` |
| 6 | `curl /api/alerts/latest/` | `data.alert` berisi atau `null`, tanpa error 500 |
| 7 | `curl /api/assistance-points/` | data seed (>0 setelah `seed_demo`) |
| 8 | `curl /api/guides/` | 9 panduan |
| 9 | `/admin/` | login + CRUD Alert berhasil |
| 10 | `ruff check .` | bersih |

---

## 6. Catatan implementasi

| Keputusan | Konsekuensi |
|---|---|
| Tanpa PostGIS | radius pakai haversine Python; `risk_zones.geojson` JSONB |
| Throttle | `apps.common.throttling.parse_window` mendukung `5/10min` (DRF bawaan hanya `<n>/<s\|m\|h\|d>`) |
| Tanpa cron | `/api/alerts/latest/` dan `/api/dashboard/` memicu sync BMKG (cache 60 s) |
| FCM sinkron | alert tetap tersimpan walau FCM gagal; respons menyertakan `fcm_error` |
| Approval wajib | gabung grup = `pending` sampai admin menyetujui (`FR-25` BRD) |
| Admin terakhir dilindungi | tidak bisa keluar/dikeluarkan/ditolak (`LAST_ADMIN_*`) |
| Seed ditandai `unverified` | kontak & posko tidak diklaim resmi sebelum diverifikasi BPBD |
| `audit_logs` P0 | dicatat di endpoint officer/editor lewat `log_action()` |
