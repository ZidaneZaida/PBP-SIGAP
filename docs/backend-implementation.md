# Implementasi Backend — Status & Panduan

**Versi:** 1.0 · **Tanggal:** 11 Februari 2026
**Database:** Supabase (dev + produksi), tanpa DB lokal

---

## 1. Status

| Milestone | Status | Isi |
|---|---|---|
| M0b · Fondasi | ✅ Kode selesai | settings, common, accounts (User/UserProfile/DeviceToken), health |
| M1 · Auth & profil | ✅ Kode selesai | 11 endpoint auth + me |
| M2 · Konten publik | ✅ Kode selesai | alerts + lazy BMKG, news, map, guides, dashboard, seed |
| M3 · Keluarga & FCM | ✅ Kode selesai | 13 endpoint family, FCM client |
| M4 · Audit & otorisasi | ✅ Kode selesai | `audit_logs`, mixin, admin, permission role |
| M5 · Deploy | ⬜ Belum | render.yaml, CI |
| M6 · Integrasi Flutter | ⬜ Belum | `app/lib/core/network/` |

**Yang belum diverifikasi:** `manage.py migrate`, `manage.py test`, dan `curl` endpoint — memerlukan venv + kredensial Supabase (lihat §3).

Endpoint terdaftar: **44 path** (53 handler method). Belum dibuat: `POST/GET /api/reports/*` (P1, Fase 4) dan `POST /api/internal/sync-bmkg/` (opsional).

**Belum ada di repo:** folder `migrations/` untuk tiap app. Digenerate dengan `makemigrations` setelah venv siap.

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

### 3.1 Prasyarat sistem

```bash
sudo apt install python3.13-venv
```

### 3.2 Supabase

1. Buat project di [supabase.com](https://supabase.com), region **Southeast Asia (Singapore)**.
2. Dashboard → **Connect** → pilih **Session pooler (port 5432)**. Salin URI.
3. Simpan password database.
4. (Untuk upload foto) **Storage** → buat bucket **`avatars`**, set public.
5. (Untuk upload foto) **Settings → API** → salin `service_role` key.

### 3.3 venv + `.env`

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -U pip && pip install -r requirements-dev.txt
cp .env.example .env
# edit .env: DATABASE_URL=<session pooler>, DEBUG=True, ALLOW_REMOTE_TESTS=True
```

### 3.4 Migrasi + seed + superuser

```bash
python manage.py makemigrations accounts alerts news map guides family common
python manage.py migrate
python manage.py seed_demo
python manage.py createsuperuser
```

### 3.5 Jalankan

```bash
python manage.py runserver
curl http://127.0.0.1:8000/api/health/
```

Harapan: `{"status":"success","data":{"db":"ok","version":"0.1.0"}}`

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

### 4.2 `runserver` me-redirect ke HTTPS

`DEBUG=False` memasang `SECURE_SSL_REDIRECT=True`. Pastikan `.env` ada dan `DEBUG=True`.

### 4.3 `Tenant or user not found`

Username pooler harus `postgres.<project_ref>`, bukan `postgres`.

### 4.4 Semua request lambat setelah idle

Supabase free pause setelah 7 hari low-activity. Buka dashboard untuk membangunkan.

---

## 5. Checklist verifikasi lokal

| # | Perintah | Harapan |
|---|---|---|
| 1 | `python manage.py check` | 0 issue |
| 2 | `python manage.py migrate` | tabel `accounts_user`, `alerts`, `family_*`, `audit_logs` dibuat |
| 3 | `python manage.py test` | semua test lulus |
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
| Tanpa cron | `/api/alerts/latest/` dan `/api/dashboard/` memicu sync BMKG (cache 60 s) |
| FCM sinkron | alert tetap tersimpan walau FCM gagal; respons menyertakan `fcm_error` |
| Approval wajib | gabung grup = `pending` sampai admin menyetujui (`FR-25` BRD) |
| Admin terakhir dilindungi | tidak bisa keluar/dikeluarkan/ditolak (`LAST_ADMIN_*`) |
| Seed ditandai `unverified` | kontak & posko tidak diklaim resmi sebelum diverifikasi BPBD |
| `audit_logs` P0 | dicatat di endpoint officer/editor lewat `log_action()` |
