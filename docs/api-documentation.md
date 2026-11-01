# API Documentation — SIGAP Backend

**Versi:** 2.0 (hasil audit 11 Februari 2026)
**Base URL Produksi:** `https://sigap-backend.onrender.com`
**Base URL Development:** `http://localhost:8000`
**Format:** REST API JSON
**Autentikasi:** JWT Bearer (`Authorization: Bearer <access_token>`)

---

## Konvensi Umum

### Amplop Response

Semua response (kecuali respons mentah GeoJSON yang tetap **dibungkus** di dalam `data`) memakai bentuk berikut.

**Sukses:**
```json
{ "status": "success", "data": { }, "message": "Operasi berhasil" }
```

**Gagal:**
```json
{
  "status": "error",
  "code": "VALIDATION_ERROR",
  "message": "Data tidak valid",
  "errors": { "email": ["Email ini sudah digunakan."] }
}
```

### Pagination

`count`, `next`, `previous`, `results` berada di **level atas**, bukan di dalam `data`:

```json
{
  "status": "success",
  "count": 42,
  "next": "https://sigap-backend.onrender.com/api/alerts/?page=2",
  "previous": null,
  "results": [ { } ]
}
```

Default `page_size=10`, maksimum 30 (alerts/news), 50 (assistance-points).

### HTTP Status

| Code | Arti |
|---|---|
| `200` | Berhasil |
| `201` | Dibuat |
| `204` | Berhasil tanpa body |
| `400` | Validasi gagal |
| `401` | Token tidak valid/kadaluarsa |
| `403` | Role tidak cukup / bukan anggota grup |
| `404` | Tidak ditemukan |
| `409` | Konflik (sudah menjadi anggota, admin terakhir, kode masih berlaku) |
| `429` | Rate limit |
| `500` | Error server |

### Aturan Akses

| Simbol | Keterangan |
|---|---|
| 🔓 | Publik |
| 🔒 | Butuh JWT (semua role) |
| 👮 | `officer` atau `superadmin` |
| ✏️ | `editor` atau `superadmin` |
| 🛡️ | `superadmin` |
| 👪 | Anggota grup aktif (`family_memberships.status='active'`) |

### Catatan Operasional

- Instance Render Free spin down setelah 15 menit idle. Request pertama dapat memakan ±50 detik. Frontend wajib menampilkan skeleton loading.
- `X-Request-ID` dikembalikan pada setiap response untuk keperluan log.

---

## 1. Autentikasi

### `POST /api/auth/register/` 🔓

```json
{
  "email": "warga@gmail.com",
  "full_name": "Budi Santoso",
  "password": "Password123",
  "password_confirm": "Password123"
}
```

**Validasi:** email format + unik; password ≥ 8 karakter, mengandung huruf dan angka; `password_confirm` sama.

**Response 201:**
```json
{
  "status": "success",
  "data": {
    "user": { "id": "uuid", "email": "warga@gmail.com", "full_name": "Budi Santoso", "role": "citizen" },
    "tokens": { "access": "eyJ...", "refresh": "eyJ..." }
  },
  "message": "Akun berhasil dibuat"
}
```

Rate limit: 10 request / IP / jam.

---

### `POST /api/auth/login/` 🔓

```json
{ "email": "warga@gmail.com", "password": "Password123" }
```

**Response 200:** sama seperti register.

Rate limit: 5 kegagalan / IP / 10 menit → `429` dengan `Retry-After`.

---

### `POST /api/auth/token/refresh/` 🔓

```json
{ "refresh": "eyJ..." }
```

**Response 200:**
```json
{ "status": "success", "data": { "access": "eyJ...", "refresh": "eyJ..." } }
```

Rotation aktif: refresh lama masuk blacklist.

---

### `POST /api/auth/logout/` 🔒

```json
{ "refresh": "eyJ..." }
```

**Response 200:** `{ "status": "success", "message": "Logout berhasil" }`

---

### `POST /api/auth/password/reset/` 🔓

```json
{ "email": "warga@gmail.com" }
```

Selalu `200`, baik email terdaftar maupun tidak (mencegah enumerasi akun).

**Response 200:**
```json
{ "status": "success", "message": "Jika email terdaftar, tautan reset telah dikirim." }
```

---

### `POST /api/auth/password/reset/confirm/` 🔓

```json
{
  "uid": "MQ",
  "token": "c9x1-8f2a0b7d",
  "new_password": "PasswordBaru123",
  "new_password_confirm": "PasswordBaru123"
}
```

**Response 200:** `{ "status": "success", "message": "Kata sandi berhasil diubah." }`
**Response 400:** `{ "status": "error", "code": "INVALID_TOKEN", "message": "Tautan tidak valid atau sudah kedaluwarsa." }`

---

### `POST /api/auth/password/change/` 🔒

```json
{ "old_password": "Password123", "new_password": "PasswordBaru123" }
```

**Response 200:** `{ "status": "success", "message": "Kata sandi diperbarui." }`

---

## 2. Profil Saya

### `GET /api/me/` 🔒

```json
{
  "status": "success",
  "data": {
    "id": "uuid",
    "email": "warga@gmail.com",
    "full_name": "Budi Santoso",
    "role": "citizen",
    "date_joined": "2026-10-15T08:00:00Z",
    "profile": {
      "phone": "08123456789",
      "photo_url": "https://[ref].supabase.co/storage/v1/object/public/avatars/...",
      "primary_area": "Padang Barat",
      "address_note": "Jl. Veteran No. 12"
    }
  }
}
```

---

### `PATCH /api/me/` 🔒

Semua field opsional.

```json
{
  "full_name": "Budi Santoso Baru",
  "profile": {
    "phone": "08111111111",
    "primary_area": "Kuranji",
    "address_note": "Kompleks Perumahan Baru"
  }
}
```

`role` **tidak dapat** diubah lewat endpoint ini (hanya Django Admin).

---

### `POST /api/me/upload-photo/` 🔒

`multipart/form-data`, field `photo` (JPEG/PNG, maks 5 MB).

**Response 200:**
```json
{ "status": "success", "data": { "photo_url": "https://[ref].supabase.co/storage/v1/object/public/avatars/uuid.jpg" } }
```

---

### `GET /api/me/preferences/` 🔒

```json
{
  "status": "success",
  "data": { "alert_enabled": true, "news_enabled": true, "family_enabled": true }
}
```

---

### `PATCH /api/me/preferences/` 🔒

```json
{ "alert_enabled": true, "news_enabled": false, "family_enabled": true }
```

> `alert_enabled=false` tetap tidak mematikan peringatan darurat level `awas` (kebijakan keselamatan).

---

### `POST /api/me/device-token/` 🔒

```json
{ "fcm_token": "fcm-token...", "platform": "android" }
```

`platform` ∈ `android`, `web`. Token yang sudah terdaftar untuk user lain dipindahkan ke user ini (`update_or_create`).

**Response 201:** `{ "status": "success", "message": "Token perangkat terdaftar." }`

---

### `DELETE /api/me/device-token/` 🔒

```json
{ "fcm_token": "fcm-token..." }
```

Dipanggil sebelum user logout agar tidak menerima notifikasi akun lama.

---

### `DELETE /api/me/` 🔒

Menghapus akun. **Tindakan permanen.**

Perilaku:
- `email` diganti `deleted-<uuid>@sigap.invalid`, `full_name` → `Pengguna Dihapus`, password di-unusable-kan.
- `photo_url` dihapus dari Supabase Storage.
- `family_memberships` → `status='rejected'`, `is_group_admin=False`; grup tanpa admin aktif ditandai untuk peninjauan.
- `safety_statuses`, `device_tokens` dihapus.
- `audit_logs` dipertahankan (aktor menjadi `null`).

**Response 200:** `{ "status": "success", "message": "Akun dihapus." }`

---

## 3. Dashboard

### `GET /api/dashboard/` 🔓

Satu request untuk layar utama. Field yang datanya kosong dikirim `null` — frontend wajib menampilkan "Data belum tersedia".

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "alert": {
      "id": "uuid",
      "disaster_type": "earthquake",
      "title": "Gempa M5.8, 24 km Barat Daya Kota Padang",
      "severity": null,
      "status": "active",
      "affected_area": "24 km Barat Daya Kota Padang",
      "magnitude": 5.8,
      "source_name": "BMKG",
      "published_at": "2026-10-31T02:30:00Z"
    },
    "news": [
      { "id": "uuid", "title": "BPBD Padang Imbau Warga Waspada Banjir", "category": "flood", "published_at": "2026-10-30T09:00:00Z" }
    ],
    "family_summary": {
      "group_id": "uuid",
      "group_name": "Keluarga Pak Ahmad",
      "active_members": 4,
      "safe": 2,
      "need_help": 1,
      "no_report": 1
    },
    "assistance_point_count": 27,
    "generated_at": "2026-10-31T02:31:00Z"
  }
}
```

`family_summary` bernilai `null` bila user belum bergabung ke grup mana pun.
`alert` bernilai `null` bila tidak ada peringatan aktif.

---

## 4. Peringatan Bencana (Alerts)

### `GET /api/alerts/` 🔓

| Parameter | Default | Keterangan |
|---|---|---|
| `status` | `active` | `active`, `expired`, `cancelled`, `all` |
| `disaster_type` | – | `earthquake`, `tsunami`, `flood`, `landslide`, `extreme_weather` |
| `date_from` / `date_to` | – | ISO date, filter `published_at` |
| `page` / `page_size` | 1 / 10 | Maks 30 |

**Response 200 (paginated):**
```json
{
  "status": "success",
  "count": 42,
  "next": "/api/alerts/?page=2",
  "previous": null,
  "results": [
    {
      "id": "uuid",
      "disaster_type": "earthquake",
      "title": "Gempa M5.8 Wilayah Padang",
      "severity": null,
      "status": "active",
      "affected_area": "24 km Barat Daya Kota Padang",
      "magnitude": 5.8,
      "depth_km": 10,
      "source": { "name": "BMKG", "source_url": "https://data.bmkg.go.id" },
      "published_at": "2026-10-31T02:30:00Z",
      "expires_at": null
    }
  ]
}
```

---

### `GET /api/alerts/latest/` 🔓

Peringatan aktif paling baru. Memicu **lazy-fetch** BMKG (`gempadirasakan.json`) dengan cache 60 detik.

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "alert": {
      "id": "uuid",
      "disaster_type": "earthquake",
      "title": "Gempa M5.8, 24 km Barat Daya Kota Padang",
      "severity": null,
      "status": "active",
      "magnitude": 5.8,
      "depth_km": 10,
      "felt_description": "III - IV Padang",
      "affected_area": "24 km Barat Daya Kota Padang",
      "latitude": -0.95,
      "longitude": 100.35,
      "source": { "name": "BMKG", "source_url": "https://data.bmkg.go.id" },
      "published_at": "2026-10-31T02:30:00Z",
      "source_updated_at": "2026-10-31T02:30:00Z"
    }
  },
  "message": "Data dapat tertunda hingga 60 detik dari sumber."
}
```

`alert` = `null` bila tidak ada peringatan aktif dalam radius 300 km dari Padang.

> `source_updated_at` adalah waktu data dari sumber, **bukan** waktu cache. Frontend wajib menampilkan waktu ini.

---

### `GET /api/alerts/{id}/` 🔓

**Response 200:** detail lengkap + `description`, `source_reference_url`, `expires_at`, `updated_at`.

---

### `POST /api/officer/alerts/` 👮

```json
{
  "disaster_type": "flood",
  "title": "Banjir di Kawasan Alai",
  "description": "Banjir setinggi 50 cm di kawasan Alai sejak pukul 05.00.",
  "severity": "waspada",
  "affected_area": "Kelurahan Alai, Padang Utara",
  "latitude": -0.89,
  "longitude": 100.36,
  "source_reference_url": "https://bpbd-padang.go.id/...",
  "expires_at": "2026-10-31T12:00:00Z"
}
```

**Response 201:** objek alert + `"message": "Peringatan aktif. Notifikasi dikirim ke N perangkat."`

FCM dikirim sinkron setelah alert tersimpan. Bila FCM gagal: alert tetap dibuat, response menyertakan `"fcm_error": "..."`.

---

### `PATCH /api/officer/alerts/{id}/` 👮

```json
{ "status": "expired" }
```

Perubahan status **tidak** memicu notifikasi baru.

---

## 5. Berita (News)

### `GET /api/news/` 🔓

| Parameter | Keterangan |
|---|---|
| `category` | `earthquake`, `tsunami`, `flood`, `landslide`, `general` |
| `area` | Filter `area_tags` |
| `page` / `page_size` | Default 10, maks 30 |

**Response 200:**
```json
{
  "status": "success",
  "count": 120,
  "next": "/api/news/?page=2",
  "previous": null,
  "results": [
    {
      "id": "uuid",
      "title": "BPBD Padang Imbau Warga Waspada Banjir",
      "slug": "bpbd-padang-imbau-warga-waspada-banjir",
      "summary": "Memasuki musim hujan, BPBD Kota Padang mengingatkan...",
      "thumbnail_url": "https://...",
      "category": "flood",
      "area_tags": ["Padang Barat", "Alai"],
      "author": { "full_name": "Tim Redaksi SIGAP" },
      "source": { "name": "BPBD Kota Padang" },
      "published_at": "2026-10-30T09:00:00Z"
    }
  ]
}
```

---

### `GET /api/news/{id}/` 🔓

Detail lengkap termasuk `content`. Boleh juga diakses lewat slug: `GET /api/news/{slug}/`.

---

### `POST /api/editor/news/` ✏️

```json
{
  "title": "Judul Berita",
  "summary": "Ringkasan singkat",
  "content": "Isi berita dalam **Markdown**...",
  "category": "flood",
  "area_tags": ["Padang Barat", "Alai"],
  "source_id": "uuid-source-bpbd",
  "is_published": true
}
```

`slug` dibuat otomatis; bila bertabrakan → `judul-2`.

---

### `PATCH /api/editor/news/{id}/` ✏️

Semua field opsional. `author_id` **tetap** penerbit awal.

---

### `DELETE /api/editor/news/{id}/` ✏️

**Response 204** (soft delete tidak dipakai; data benar-benar dihapus dan dicatat di `audit_logs`).

---

## 6. Peta & Titik Bantuan

### `GET /api/map/nearby/` 🔓

| Parameter | Wajib | Keterangan |
|---|---|---|
| `lat` | ✅ | Latitude pengguna, contoh `-0.9492` |
| `lon` | ✅ | Longitude pengguna, contoh `100.3543` |
| `radius` | ❌ | Meter, default `5000`, maks `20000` |
| `category` | ❌ | `evacuation_point`, `emergency_post`, `hospital`, `health_center`, `relief_point` |

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "center": { "latitude": -0.9492, "longitude": 100.3543 },
    "radius_meters": 5000,
    "results": [
      {
        "id": "uuid",
        "name": "Lapangan Imam Bonjol",
        "category": "evacuation_point",
        "address": "Jl. Imam Bonjol, Padang",
        "phone": null,
        "latitude": -0.9481,
        "longitude": 100.3529,
        "distance_meters": 320.5,
        "verification_status": "verified",
        "verified_at": "2026-09-01T00:00:00Z",
        "capacity": 5000,
        "operational_hours": "Saat darurat"
      }
    ]
  }
}
```

`distance_meters` dibulatkan 1 desimal. Maksimum 50 hasil.

---

### `GET /api/map/risk-zones/` 🔓

| Parameter | Keterangan |
|---|---|
| `hazard_type` | `earthquake`, `tsunami`, `flood`, `landslide` |
| `risk_level` | `low`, `medium`, `high`, `very_high` |

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "geometry": { "type": "Polygon", "coordinates": [[[100.32, -0.85], [100.35, -0.85]]] },
        "properties": {
          "id": "uuid",
          "name": "Zona Bahaya Tsunami Pesisir Bungus",
          "hazard_type": "tsunami",
          "risk_level": "very_high",
          "description": "Kawasan pesisir dengan risiko tsunami sangat tinggi",
          "source": "BPBD Kota Padang",
          "updated_at": "2026-07-01T00:00:00Z"
        }
      }
    ]
  }
}
```

---

### `GET /api/assistance-points/` 🔓

| Parameter | Default | Keterangan |
|---|---|---|
| `category` | – | Filter kategori |
| `verification_status` | `verified` | `verified`, `unverified`, `outdated`, `all` |

**Response 200:** paginated (maks 50/page), item sama seperti `nearby` tanpa `distance_meters`.

---

### `POST /api/officer/assistance-points/` 👮

```json
{
  "name": "Posko Banjir RW 03 Alai",
  "category": "emergency_post",
  "address": "Jl. Alai Parak Kopi No. 5",
  "latitude": -0.8935,
  "longitude": 100.3612,
  "phone": "0751-12345",
  "capacity": 200,
  "operational_hours": "24 Jam",
  "notes": "Tersedia makanan dan air bersih"
}
```

Validasi: `latitude` ∈ [-90, 90], `longitude` ∈ [-180, 180].

---

### `PATCH /api/officer/assistance-points/{id}/` 👮

Termasuk `verification_status` dan `verified_at` (diisi otomatis saat diubah ke `verified`).

---

### `POST /api/officer/risk-zones/` 👮

```json
{
  "name": "Zona Bahaya Tsunami Bungus",
  "hazard_type": "tsunami",
  "risk_level": "very_high",
  "geojson": { "type": "Polygon", "coordinates": [[[100.32, -0.85]]] },
  "description": "...",
  "source_notes": "BPBD Kota Padang, 2026"
}
```

`geojson.type` wajib `Polygon` atau `MultiPolygon`.

---

### `PATCH /api/officer/risk-zones/{id}/` 👮

Semua field opsional. `geojson` divalidasi dengan aturan yang sama.

---

## 7. Keluarga & Status Keselamatan

### `POST /api/family/groups/` 🔒

```json
{ "name": "Keluarga Pak Ahmad" }
```

**Response 201:**
```json
{
  "status": "success",
  "data": {
    "id": "uuid",
    "name": "Keluarga Pak Ahmad",
    "invite_code": "SIGAP8KM",
    "invite_code_expires_at": "2026-11-01T10:00:00Z",
    "is_group_admin": true,
    "created_at": "2026-10-31T10:00:00Z"
  }
}
```

Pembuat otomatis menjadi anggota `active` + admin grup.

---

### `GET /api/family/my-groups/` 🔒

```json
{
  "status": "success",
  "data": [
    {
      "id": "uuid",
      "name": "Keluarga Pak Ahmad",
      "is_group_admin": true,
      "status": "active",
      "member_count": 5,
      "pending_count": 1,
      "need_help_count": 1
    }
  ]
}
```

---

### `POST /api/family/join/` 🔒

```json
{ "invite_code": "SIGAP8KM" }
```

**Response 200 (menunggu persetujuan):**
```json
{
  "status": "success",
  "data": {
    "family_group": { "id": "uuid", "name": "Keluarga Pak Ahmad" },
    "status": "pending",
    "requested_at": "2026-10-31T10:05:00Z"
  },
  "message": "Permintaan bergabung dikirim. Menunggu persetujuan admin grup."
}
```

**Error:**
```json
{ "status": "error", "code": "INVALID_INVITE_CODE", "message": "Kode undangan tidak valid atau sudah kedaluwarsa." }
```

Sudah menjadi anggota aktif → `409 ALREADY_MEMBER`.

---

### `GET /api/family/groups/{group_id}/members/` 👪

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "group": { "id": "uuid", "name": "Keluarga Pak Ahmad" },
    "members": [
      {
        "user_id": "uuid",
        "full_name": "Budi Santoso",
        "is_group_admin": true,
        "latest_status": {
          "status": "safe",
          "message": "Di rumah, kondisi baik",
          "location_note": "Jl. Veteran No. 12",
          "battery_level": 80,
          "reported_at": "2026-10-31T09:30:00Z"
        }
      },
      {
        "user_id": "uuid",
        "full_name": "Siti Aminah",
        "is_group_admin": false,
        "latest_status": null
      }
    ]
  }
}
```

Hanya anggota `status='active'`. `latest_status: null` → UI "Belum ada konfirmasi", **bukan** "tidak aman".

---

### `GET /api/family/groups/{group_id}/pending/` 👪

Khusus admin grup. Daftar permintaan bergabung.

```json
{
  "status": "success",
  "data": [
    { "user_id": "uuid", "full_name": "Rina", "email": "rina@gmail.com", "requested_at": "2026-10-31T10:05:00Z" }
  ]
}
```

---

### `POST /api/family/groups/{group_id}/members/{user_id}/approve/` 👪

Khusus admin grup. `status` → `active`, `joined_at` diisi, FCM dikirim ke user.

**Response 200:** `{ "status": "success", "message": "Anggota disetujui." }`

---

### `POST /api/family/groups/{group_id}/members/{user_id}/reject/` 👪

Khusus admin grup. `status` → `rejected`. User dapat mengirim permintaan baru kapan saja.

---

### `DELETE /api/family/groups/{group_id}/members/{user_id}/` 👪

Khusus admin grup. Mengeluarkan anggota aktif.

**Response 409** bila mencoba mengeluarkan admin terakhir: `LAST_ADMIN_CANNOT_BE_REMOVED`.

---

### `POST /api/family/groups/{group_id}/transfer-admin/` 👪

```json
{ "user_id": "uuid" }
```

Khusus admin grup. Admin lama tetap anggota biasa.

---

### `POST /api/family/groups/{group_id}/status/` 👪

```json
{
  "status": "safe",
  "message": "Saya aman di rumah, tidak ada kerusakan.",
  "location_note": "Jl. Veteran No. 12, Padang Barat",
  "share_location": true,
  "latitude": -0.9350,
  "longitude": 100.3610,
  "battery_level": 75
}
```

**Aturan privasi:** `latitude`/`longitude` **hanya disimpan** bila `share_location: true`. Jika `false`, koordinat diabaikan meski dikirim.

**Response 201:**
```json
{
  "status": "success",
  "data": {
    "id": "uuid",
    "status": "safe",
    "message": "Saya aman di rumah, tidak ada kerusakan.",
    "location_shared": true,
    "created_at": "2026-10-31T10:15:00Z"
  },
  "message": "Status keselamatan terkirim."
}
```

FCM data+notification dikirim ke seluruh anggota `active` lain yang mengaktifkan `family_enabled`.

---

### `POST /api/family/groups/{group_id}/regenerate-invite/` 👪

Khusus admin grup. Ditolak (`429`) bila kode sebelumnya masih berlaku > 12 jam.

**Response 200:**
```json
{ "status": "success", "data": { "invite_code": "K7M2ZQ9A", "invite_code_expires_at": "2026-11-02T10:00:00Z" } }
```

---

### `DELETE /api/family/groups/{group_id}/leave/` 👪

**Response 409** bila admin terakhir: `LAST_ADMIN_CANNOT_LEAVE`.

---

### `DELETE /api/family/groups/{group_id}/` 👪

Hapus grup (khusus admin grup). Menghapus semua `family_memberships` dan `safety_statuses` grup tersebut.

**Response 204.**

---

## 8. Kontak Darurat & Panduan

### `GET /api/emergency-contacts/` 🔓

| Parameter | Keterangan |
|---|---|
| `category` | `police`, `bpbd`, `sar`, `hospital`, `fire`, `ambulance`, `other` |
| `verified_only` | default `true` |

**Response 200:**
```json
{
  "status": "success",
  "data": [
    {
      "id": "uuid",
      "name": "BPBD Kota Padang",
      "category": "bpbd",
      "phone_number": "0751-892929",
      "description": "Badan Penanggulangan Bencana Daerah Kota Padang",
      "area": "Kota Padang",
      "is_verified": true,
      "verified_at": "2026-09-01T00:00:00Z"
    }
  ]
}
```

---

### `GET /api/guides/` 🔓

| Parameter | Keterangan |
|---|---|
| `disaster_type` | `earthquake`, `tsunami`, `flood`, `landslide`, `general` |
| `phase` | `before`, `during`, `after` |

**Response 200:**
```json
{
  "status": "success",
  "data": [
    {
      "id": "uuid",
      "disaster_type": "earthquake",
      "phase": "during",
      "title": "Langkah Saat Gempa Berlangsung",
      "content": "1. Jangan panik...\n2. Berlindung di bawah meja...",
      "icon_name": "earthquake_during",
      "reviewed_source": "BMKG & BPBD",
      "reviewed_at": "2026-01-01",
      "sort_order": 1
    }
  ]
}
```

---

## 9. Laporan Warga (P1 — Fase 4)

### `POST /api/reports/` 🔒

`multipart/form-data`:

| Field | Wajib | Keterangan |
|---|---|---|
| `category` | ✅ | `earthquake`, `flood`, `landslide`, `tsunami`, `other` |
| `description` | ✅ | Maks 2000 karakter |
| `incident_time` | ❌ | ISO datetime |
| `location_note` | ❌ | Teks |
| `share_location` | ❌ | Default `false` |
| `latitude` / `longitude` | ❌ | Diabaikan bila `share_location=false` |
| `photo` | ❌ | JPEG/PNG, maks 10 MB |

**Response 201:**
```json
{
  "status": "success",
  "data": {
    "id": "uuid",
    "moderation_status": "pending",
    "message_to_user": "Laporan diterima dan sedang ditinjau."
  }
}
```

---

### `GET /api/reports/my-reports/` 🔒

Paginated. Setiap item menyertakan `moderation_status` dan `review_notes`.

---

## 10. Django Admin

URL: `https://sigap-backend.onrender.com/admin/`

| Model | Aksi |
|---|---|
| User & Profil | CRUD akun, ubah `role`, aktif/nonaktif |
| Sources | CRUD |
| Alerts | CRUD, ubah status |
| News | CRUD, publish/unpublish |
| Assistance Points | CRUD, ubah `verification_status` |
| Risk Zones | CRUD (input GeoJSON) |
| Emergency Contacts | CRUD, verifikasi |
| Guides | CRUD |
| Incident Reports (P1) | Moderasi |
| Audit Logs | Read-only |

Admin hanya untuk `is_staff=True`. Semua aksi tercatat di `audit_logs`.

---

## 11. Endpoint Internal

### `POST /api/internal/sync-bmkg/`

Opsional. Dipanggil penjadwal eksternal gratis (GitHub Actions `*/10 * * * *`) untuk menyimpan riwayat gempa. **Tidak wajib** — endpoint publik sudah melakukan lazy-fetch.

Header wajib: `X-Internal-Token: $INTERNAL_SYNC_TOKEN`

**Response 200:**
```json
{ "status": "success", "data": { "fetched": 15, "created": 2, "skipped": 13 } }
```

---

## 12. Ringkasan Endpoint

| Method | Endpoint | Auth | Keterangan |
|---|---|---|---|
| POST | `/api/auth/register/` | 🔓 | Registrasi |
| POST | `/api/auth/login/` | 🔓 | Login |
| POST | `/api/auth/token/refresh/` | 🔓 | Refresh (rotasi) |
| POST | `/api/auth/logout/` | 🔒 | Blacklist refresh |
| POST | `/api/auth/password/reset/` | 🔓 | Minta tautan reset |
| POST | `/api/auth/password/reset/confirm/` | 🔓 | **Baru** — set password baru |
| POST | `/api/auth/password/change/` | 🔒 | **Baru** — ganti password |
| GET | `/api/me/` | 🔒 | Profil |
| PATCH | `/api/me/` | 🔒 | Update profil |
| DELETE | `/api/me/` | 🔒 | **Baru** — hapus akun |
| POST | `/api/me/upload-photo/` | 🔒 | Upload foto |
| GET | `/api/me/preferences/` | 🔒 | Preferensi notifikasi |
| PATCH | `/api/me/preferences/` | 🔒 | Update preferensi |
| POST | `/api/me/device-token/` | 🔒 | Daftar FCM token |
| DELETE | `/api/me/device-token/` | 🔒 | **Baru** — hapus FCM token |
| GET | `/api/dashboard/` | 🔓 | **Baru** — agregat dashboard |
| GET | `/api/alerts/` | 🔓 | Daftar + filter |
| GET | `/api/alerts/latest/` | 🔓 | Alert aktif (lazy-fetch BMKG) |
| GET | `/api/alerts/{id}/` | 🔓 | Detail |
| POST | `/api/officer/alerts/` | 👮 | Buat alert manual |
| PATCH | `/api/officer/alerts/{id}/` | 👮 | Ubah status |
| GET | `/api/news/` | 🔓 | Daftar berita |
| GET | `/api/news/{id}/` | 🔓 | Detail (id atau slug) |
| POST | `/api/editor/news/` | ✏️ | Buat berita |
| PATCH | `/api/editor/news/{id}/` | ✏️ | Edit berita |
| DELETE | `/api/editor/news/{id}/` | ✏️ | Hapus berita |
| GET | `/api/map/nearby/` | 🔓 | Radius (haversine) |
| GET | `/api/map/risk-zones/` | 🔓 | GeoJSON layer |
| GET | `/api/assistance-points/` | 🔓 | Semua titik bantuan |
| POST | `/api/officer/assistance-points/` | 👮 | Tambah titik |
| PATCH | `/api/officer/assistance-points/{id}/` | 👮 | Update titik |
| POST | `/api/officer/risk-zones/` | 👮 | **Baru** — tambah zona |
| PATCH | `/api/officer/risk-zones/{id}/` | 👮 | **Baru** — update zona |
| POST | `/api/family/groups/` | 🔒 | Buat grup |
| GET | `/api/family/my-groups/` | 🔒 | Grup yang diikuti |
| POST | `/api/family/join/` | 🔒 | Ajukan bergabung |
| GET | `/api/family/groups/{id}/members/` | 👪 | Status anggota |
| GET | `/api/family/groups/{id}/pending/` | 👪 | **Baru** — permintaan bergabung |
| POST | `/api/family/groups/{id}/members/{uid}/approve/` | 👪 | **Baru** — setujui |
| POST | `/api/family/groups/{id}/members/{uid}/reject/` | 👪 | **Baru** — tolak |
| DELETE | `/api/family/groups/{id}/members/{uid}/` | 👪 | **Baru** — keluarkan |
| POST | `/api/family/groups/{id}/transfer-admin/` | 👪 | **Baru** — pindah admin |
| POST | `/api/family/groups/{id}/status/` | 👪 | Kirim status |
| POST | `/api/family/groups/{id}/regenerate-invite/` | 👪 | Buat ulang kode |
| DELETE | `/api/family/groups/{id}/leave/` | 👪 | Keluar grup |
| DELETE | `/api/family/groups/{id}/` | 👪 | **Baru** — hapus grup |
| GET | `/api/emergency-contacts/` | 🔓 | Kontak darurat |
| GET | `/api/guides/` | 🔓 | Panduan |
| POST | `/api/reports/` | 🔒 | Laporan warga (P1) |
| GET | `/api/reports/my-reports/` | 🔒 | Riwayat laporan (P1) |
| POST | `/api/internal/sync-bmkg/` | token | Opsional, penjadwal eksternal |

**Total:** 51 endpoint. **Baru dari versi 1.0:** 13 endpoint (ditandai **Baru**).