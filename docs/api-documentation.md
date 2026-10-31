# API Documentation — SIGAP Backend

**Versi:** 1.0  
**Base URL Produksi:** `https://sigap-backend.onrender.com`  
**Base URL Development:** `http://localhost:8000`  
**Format:** REST API JSON  
**Autentikasi:** JWT Bearer Token (`Authorization: Bearer <access_token>`)

---

## Konvensi Umum

### Format Response Sukses
```json
{
  "status": "success",
  "data": { ... },
  "message": "Operasi berhasil"
}
```

### Format Response Gagal
```json
{
  "status": "error",
  "code": "VALIDATION_ERROR",
  "message": "Email sudah terdaftar",
  "errors": {
    "email": ["Email ini sudah digunakan."]
  }
}
```

### HTTP Status Codes
| Code | Arti |
|---|---|
| `200 OK` | Request berhasil |
| `201 Created` | Data berhasil dibuat |
| `400 Bad Request` | Validasi input gagal |
| `401 Unauthorized` | Token tidak valid atau kadaluarsa |
| `403 Forbidden` | Tidak memiliki izin (role tidak cukup) |
| `404 Not Found` | Data tidak ditemukan |
| `429 Too Many Requests` | Rate limit tercapai |
| `500 Internal Server Error` | Error server |

### Aturan Autentikasi
| Simbol | Keterangan |
|---|---|
| 🔓 | Publik — tidak perlu token |
| 🔒 | Butuh token JWT login (semua role) |
| 👮 | Butuh role `officer` atau `superadmin` |
| ✏️ | Butuh role `editor` atau `superadmin` |
| 🛡️ | Butuh role `superadmin` |

---

## 1. Autentikasi & Akun

### `POST /api/auth/register/` 🔓
Mendaftarkan akun baru.

**Request Body:**
```json
{
  "email": "warga@gmail.com",
  "full_name": "Budi Santoso",
  "password": "Password123",
  "password_confirm": "Password123"
}
```

**Validasi:**
- `email` — harus format email valid, belum pernah terdaftar
- `password` — minimal 8 karakter, mengandung huruf dan angka
- `password_confirm` — harus sama dengan `password`

**Response 201:**
```json
{
  "status": "success",
  "data": {
    "user": {
      "id": "uuid-...",
      "email": "warga@gmail.com",
      "full_name": "Budi Santoso",
      "role": "citizen"
    },
    "tokens": {
      "access": "eyJ...",
      "refresh": "eyJ..."
    }
  },
  "message": "Akun berhasil dibuat"
}
```

---

### `POST /api/auth/login/` 🔓
Masuk ke akun dan mendapatkan token JWT.

**Request Body:**
```json
{
  "email": "warga@gmail.com",
  "password": "Password123"
}
```

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "user": {
      "id": "uuid-...",
      "email": "warga@gmail.com",
      "full_name": "Budi Santoso",
      "role": "citizen"
    },
    "tokens": {
      "access": "eyJ...",
      "refresh": "eyJ..."
    }
  }
}
```

---

### `POST /api/auth/token/refresh/` 🔓
Memperbarui access token menggunakan refresh token.

**Request Body:**
```json
{
  "refresh": "eyJ..."
}
```

**Response 200:**
```json
{
  "access": "eyJ..."
}
```

---

### `POST /api/auth/logout/` 🔒
Logout dan blacklist refresh token.

**Request Body:**
```json
{
  "refresh": "eyJ..."
}
```

**Response 200:**
```json
{
  "status": "success",
  "message": "Logout berhasil"
}
```

---

### `POST /api/auth/password/reset/` 🔓
Memulai proses reset password (kirim email).

**Request Body:**
```json
{
  "email": "warga@gmail.com"
}
```

**Response 200:**
```json
{
  "status": "success",
  "message": "Link reset password telah dikirim ke email Anda."
}
```

> ⚠️ **Catatan Tim:** Response selalu 200 meskipun email tidak ditemukan (security best practice — jangan bocorkan apakah email terdaftar).

---

### `GET /api/me/` 🔒
Melihat data profil pengguna yang sedang login.

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "id": "uuid-...",
    "email": "warga@gmail.com",
    "full_name": "Budi Santoso",
    "role": "citizen",
    "date_joined": "2026-10-15T08:00:00Z",
    "profile": {
      "phone": "08123456789",
      "photo_url": "https://xyz.supabase.co/storage/v1/object/...",
      "primary_area": "Padang Barat",
      "address_note": "Jl. Veteran No. 12"
    }
  }
}
```

---

### `PATCH /api/me/` 🔒
Memperbarui profil pengguna.

**Request Body (semua field opsional):**
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

---

### `POST /api/me/upload-photo/` 🔒
Upload foto profil (multipart form-data).

**Request:** `multipart/form-data`
- `photo` — file gambar (JPEG/PNG, maks 5 MB)

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "photo_url": "https://xyz.supabase.co/storage/v1/object/..."
  }
}
```

---

### `GET /api/me/preferences/` 🔒
Melihat preferensi notifikasi.

**Response 200:**
```json
{
  "alert_enabled": true,
  "news_enabled": true,
  "family_enabled": true
}
```

---

### `PATCH /api/me/preferences/` 🔒
Memperbarui preferensi notifikasi.

**Request Body:**
```json
{
  "alert_enabled": true,
  "news_enabled": false,
  "family_enabled": true
}
```

---

### `POST /api/me/device-token/` 🔒
Mendaftarkan atau memperbarui FCM device token.

**Request Body:**
```json
{
  "fcm_token": "fcm-token-dari-firebase-sdk...",
  "platform": "android"
}
```

---

## 2. Peringatan Bencana (Alerts)

### `GET /api/alerts/` 🔓
Mendapatkan daftar peringatan bencana (riwayat dan aktif).

**Query Parameters:**
| Parameter | Tipe | Default | Keterangan |
|---|---|---|---|
| `status` | string | `active` | Filter: `active`, `expired`, `cancelled`, `all` |
| `disaster_type` | string | - | Filter: `earthquake`, `tsunami`, `flood`, `landslide` |
| `page` | integer | `1` | Nomor halaman |
| `page_size` | integer | `10` | Jumlah item per halaman (maks 50) |

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "count": 42,
    "next": "/api/alerts/?page=2",
    "previous": null,
    "results": [
      {
        "id": "uuid-...",
        "disaster_type": "earthquake",
        "title": "Gempa M5.8 Wilayah Padang",
        "severity": "siaga",
        "status": "active",
        "affected_area": "24 km Barat Daya Kota Padang",
        "source": {
          "name": "BMKG",
          "url": "https://bmkg.go.id"
        },
        "location": {
          "latitude": -0.95,
          "longitude": 100.35
        },
        "published_at": "2026-10-31T02:30:00Z",
        "expires_at": null
      }
    ]
  }
}
```

---

### `GET /api/alerts/latest/` 🔓
Mendapatkan peringatan aktif paling terbaru (dioptimasi dengan Redis cache, TTL 90 detik).

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "alert": { ... },
    "is_cached": true,
    "cached_at": "2026-10-31T02:30:45Z"
  }
}
```

---

### `GET /api/alerts/{id}/` 🔓
Detail satu peringatan beserta instruksi keselamatan.

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "id": "uuid-...",
    "disaster_type": "earthquake",
    "title": "Gempa M5.8 Wilayah Padang",
    "description": "Telah terjadi gempa bumi dengan kekuatan M5.8...",
    "severity": "siaga",
    "status": "active",
    "affected_area": "24 km Barat Daya Kota Padang",
    "source": {
      "name": "BMKG",
      "source_url": "https://data.bmkg.go.id/...",
      "checked_at": "2026-10-31T02:29:00Z"
    },
    "source_reference_url": "https://bmkg.go.id/gempa/...",
    "location": {
      "latitude": -0.95,
      "longitude": 100.35
    },
    "published_at": "2026-10-31T02:30:00Z",
    "expires_at": null,
    "updated_at": "2026-10-31T02:30:00Z"
  }
}
```

---

### `POST /api/officer/alerts/` 👮
Membuat peringatan manual oleh petugas BPBD.

**Request Body:**
```json
{
  "disaster_type": "flood",
  "title": "Banjir di Kawasan Alai",
  "description": "Telah terjadi banjir setinggi 50 cm di kawasan Alai...",
  "severity": "waspada",
  "affected_area": "Kelurahan Alai, Padang Utara",
  "location": {
    "latitude": -0.89,
    "longitude": 100.36
  },
  "source_reference_url": "https://bpbd-padang.go.id/...",
  "expires_at": "2026-10-31T12:00:00Z"
}
```

---

### `PATCH /api/officer/alerts/{id}/` 👮
Mengupdate status peringatan (misal: menandai peringatan sudah expired atau cancelled).

**Request Body:**
```json
{
  "status": "expired"
}
```

---

## 3. Berita Kebencanaan (News)

### `GET /api/news/` 🔓
Daftar berita kebencanaan yang dipublikasikan.

**Query Parameters:**
| Parameter | Tipe | Keterangan |
|---|---|---|
| `category` | string | Filter: `earthquake`, `tsunami`, `flood`, `landslide`, `general` |
| `page` | integer | Nomor halaman |
| `page_size` | integer | Default 10, maks 30 |

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "count": 120,
    "next": "/api/news/?page=2",
    "previous": null,
    "results": [
      {
        "id": "uuid-...",
        "title": "BPBD Padang Imbau Warga Waspada Banjir",
        "slug": "bpbd-padang-imbau-warga-waspada-banjir",
        "summary": "Memasuki musim hujan, BPBD Kota Padang mengingatkan...",
        "thumbnail_url": "https://...",
        "category": "flood",
        "author": {
          "full_name": "Tim Redaksi SIGAP"
        },
        "source": {
          "name": "BPBD Kota Padang"
        },
        "published_at": "2026-10-30T09:00:00Z"
      }
    ]
  }
}
```

---

### `GET /api/news/{id}/` 🔓
Detail artikel berita lengkap.

---

### `POST /api/editor/news/` ✏️
Membuat artikel berita baru.

**Request Body:**
```json
{
  "title": "Judul Berita",
  "summary": "Ringkasan singkat",
  "content": "Isi berita dalam format **Markdown**...",
  "category": "flood",
  "area_tags": ["Padang Barat", "Alai"],
  "source_id": "uuid-source-bpbd",
  "is_published": true
}
```

---

### `PATCH /api/editor/news/{id}/` ✏️
Mengedit artikel berita.

### `DELETE /api/editor/news/{id}/` ✏️
Menghapus artikel berita.

---

## 4. Peta & Titik Bantuan (Map)

### `GET /api/map/nearby/` 🔓
Titik bantuan terdekat dalam radius tertentu dari koordinat yang diberikan.

**Query Parameters:**
| Parameter | Tipe | Wajib | Keterangan |
|---|---|---|---|
| `lat` | float | ✅ | Latitude pengguna (contoh: `-0.9492`) |
| `lon` | float | ✅ | Longitude pengguna (contoh: `100.3543`) |
| `radius` | integer | ❌ | Radius dalam meter, default `5000`, maks `20000` |
| `category` | string | ❌ | Filter: `evacuation_point`, `emergency_post`, `hospital`, `health_center` |

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "center": { "latitude": -0.9492, "longitude": 100.3543 },
    "radius_meters": 5000,
    "results": [
      {
        "id": "uuid-...",
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

---

### `GET /api/map/risk-zones/` 🔓
Layer zona risiko bencana Kota Padang dalam format GeoJSON.

**Query Parameters:**
| Parameter | Tipe | Keterangan |
|---|---|---|
| `hazard_type` | string | Filter: `earthquake`, `tsunami`, `flood`, `landslide` |
| `risk_level` | string | Filter: `low`, `medium`, `high`, `very_high` |

**Response 200:**
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Polygon",
        "coordinates": [[[100.32, -0.85], [100.35, -0.85], ...]]
      },
      "properties": {
        "id": "uuid-...",
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
```

---

### `GET /api/assistance-points/` 🔓
Daftar semua titik bantuan terverifikasi (tanpa filter radius).

**Query Parameters:**
| Parameter | Tipe | Keterangan |
|---|---|---|
| `category` | string | Filter berdasarkan kategori |
| `verification_status` | string | `verified`, `unverified` (default: `verified`) |

---

### `POST /api/officer/assistance-points/` 👮
Menambahkan titik bantuan baru.

**Request Body:**
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

---

### `PATCH /api/officer/assistance-points/{id}/` 👮
Memperbarui data titik bantuan.

---

## 5. Keluarga & Status Keselamatan (Family)

### `POST /api/family/groups/` 🔒
Membuat grup keluarga baru.

**Request Body:**
```json
{
  "name": "Keluarga Pak Ahmad"
}
```

**Response 201:**
```json
{
  "status": "success",
  "data": {
    "id": "uuid-...",
    "name": "Keluarga Pak Ahmad",
    "invite_code": "SIGAP8K",
    "invite_code_expires_at": "2026-11-01T10:00:00Z",
    "created_at": "2026-10-31T10:00:00Z"
  }
}
```

---

### `POST /api/family/join/` 🔒
Bergabung ke grup keluarga menggunakan kode undangan.

**Request Body:**
```json
{
  "invite_code": "SIGAP8K"
}
```

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "family_group": {
      "id": "uuid-...",
      "name": "Keluarga Pak Ahmad"
    },
    "role": "member",
    "joined_at": "2026-10-31T10:05:00Z"
  }
}
```

**Error jika kode expired atau tidak valid:**
```json
{
  "status": "error",
  "code": "INVALID_INVITE_CODE",
  "message": "Kode undangan tidak valid atau sudah kadaluarsa."
}
```

---

### `GET /api/family/my-groups/` 🔒
Mendapatkan daftar semua grup keluarga yang diikuti.

**Response 200:**
```json
{
  "status": "success",
  "data": [
    {
      "id": "uuid-...",
      "name": "Keluarga Pak Ahmad",
      "role": "admin",
      "member_count": 5,
      "latest_alert_count": 1
    }
  ]
}
```

---

### `GET /api/family/groups/{group_id}/members/` 🔒
Status keselamatan terbaru seluruh anggota di satu grup. 

> Hanya bisa diakses oleh anggota grup tersebut.

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "group": {
      "id": "uuid-...",
      "name": "Keluarga Pak Ahmad"
    },
    "members": [
      {
        "user_id": "uuid-...",
        "full_name": "Budi Santoso",
        "role": "admin",
        "latest_status": {
          "status": "safe",
          "message": "Di rumah, kondisi baik",
          "location_note": "Jl. Veteran No. 12",
          "battery_level": 80,
          "reported_at": "2026-10-31T09:30:00Z"
        }
      },
      {
        "user_id": "uuid-...",
        "full_name": "Siti Aminah",
        "role": "member",
        "latest_status": null
      }
    ]
  }
}
```

> **Catatan:** Anggota dengan `latest_status: null` ditampilkan sebagai "Belum ada konfirmasi" di UI, **bukan** "Tidak aman".

---

### `POST /api/family/groups/{group_id}/status/` 🔒
Mengirimkan status keselamatan terbaru.

**Request Body:**
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

> **Aturan Privasi:** `latitude` dan `longitude` **hanya disimpan** jika `share_location: true`. Jika `false`, koordinat langsung diabaikan oleh backend meskipun dikirimkan.

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "id": "uuid-...",
    "status": "safe",
    "message": "Saya aman di rumah, tidak ada kerusakan.",
    "created_at": "2026-10-31T10:15:00Z"
  },
  "message": "Status keselamatan berhasil dikirim."
}
```

---

### `POST /api/family/groups/{group_id}/regenerate-invite/` 🔒
Membuat ulang kode undangan (hanya bisa dilakukan oleh admin grup).

---

### `DELETE /api/family/groups/{group_id}/leave/` 🔒
Keluar dari grup keluarga.

---

## 6. Kontak Darurat & Panduan

### `GET /api/emergency-contacts/` 🔓
Daftar kontak darurat resmi Kota Padang.

**Response 200:**
```json
{
  "status": "success",
  "data": [
    {
      "id": "uuid-...",
      "name": "BPBD Kota Padang",
      "category": "bpbd",
      "phone_number": "0751-892929",
      "description": "Badan Penanggulangan Bencana Daerah Kota Padang",
      "is_verified": true,
      "verified_at": "2026-09-01T00:00:00Z"
    },
    {
      "name": "Basarnas Pos SAR Padang",
      "category": "sar",
      "phone_number": "0751-55555",
      ...
    }
  ]
}
```

---

### `GET /api/guides/` 🔓
Daftar panduan kesiapsiagaan.

**Query Parameters:**
| Parameter | Keterangan |
|---|---|
| `disaster_type` | Filter: `earthquake`, `tsunami`, `flood`, `landslide` |
| `phase` | Filter: `before`, `during`, `after` |

**Response 200:**
```json
{
  "status": "success",
  "data": [
    {
      "id": "uuid-...",
      "disaster_type": "earthquake",
      "phase": "during",
      "title": "Langkah Saat Gempa Berlangsung",
      "content": "1. Jangan panik...\n2. Segera berlindung di bawah meja...",
      "icon_name": "earthquake_during",
      "reviewed_source": "BMKG & BPBD",
      "reviewed_at": "2026-01-01",
      "sort_order": 1
    }
  ]
}
```

---

## 7. Laporan Warga (P1 — Post MVP)

### `POST /api/reports/` 🔒
Mengirimkan laporan kejadian bencana.

**Request Body (multipart/form-data):**
| Field | Tipe | Wajib | Keterangan |
|---|---|---|---|
| `category` | string | ✅ | `earthquake`, `flood`, dll. |
| `description` | string | ✅ | Deskripsi kejadian |
| `incident_time` | datetime | ❌ | Waktu kejadian |
| `location_note` | string | ❌ | Keterangan lokasi teks |
| `share_location` | boolean | ❌ | Izin bagikan koordinat |
| `latitude` | float | ❌ | Diproses hanya jika `share_location: true` |
| `longitude` | float | ❌ | Diproses hanya jika `share_location: true` |
| `photo` | file | ❌ | Foto kejadian (JPEG/PNG, maks 10 MB) |

**Response 201:**
```json
{
  "status": "success",
  "data": {
    "id": "uuid-...",
    "moderation_status": "pending",
    "message_to_user": "Laporan Anda telah diterima dan sedang dalam proses peninjauan oleh tim SIGAP."
  }
}
```

---

### `GET /api/reports/my-reports/` 🔒
Melihat riwayat laporan yang pernah dikirim oleh pengguna.

---

## 8. Endpoint Admin (Django Admin Panel)

> Seluruh endpoint admin dikelola langsung via **Django Admin** di URL:  
> `https://sigap-backend.onrender.com/admin/`
>
> Fitur yang tersedia di Django Admin:
> - Manajemen user dan role (CRUD akun, set role `officer`/`editor`)
> - CRUD sumber data (`sources`)
> - Buat/edit/hapus peringatan manual (`alerts`)
> - Publish/edit/hapus berita (`news_articles`)
> - Kelola titik bantuan dan zona risiko (`assistance_points`, `risk_zones`)
> - Kelola kontak darurat (`emergency_contacts`)
> - Kelola panduan kesiapsiagaan (`guides`)
> - Moderasi laporan warga (`incident_reports`)
> - Lihat audit log (`audit_logs`)

---

## 9. Endpoint Internal (Background Worker)

Endpoint ini **tidak dipanggil oleh Flutter**, hanya digunakan oleh cron job internal backend:

### `POST /api/internal/sync-bmkg/` 
Dipanggil oleh Celery / django-crontab setiap 2 menit untuk mengambil data terbaru dari BMKG dan menyimpannya ke tabel `alerts`. Request harus membawa header secret internal (`X-Internal-Token`).

---

## 10. Ringkasan Semua Endpoint

| Method | Endpoint | Auth | Keterangan |
|---|---|---|---|
| POST | `/api/auth/register/` | 🔓 | Registrasi akun baru |
| POST | `/api/auth/login/` | 🔓 | Login & dapatkan token |
| POST | `/api/auth/token/refresh/` | 🔓 | Refresh access token |
| POST | `/api/auth/logout/` | 🔒 | Logout & blacklist token |
| POST | `/api/auth/password/reset/` | 🔓 | Request reset password |
| GET | `/api/me/` | 🔒 | Lihat profil sendiri |
| PATCH | `/api/me/` | 🔒 | Update profil |
| POST | `/api/me/upload-photo/` | 🔒 | Upload foto profil |
| GET | `/api/me/preferences/` | 🔒 | Lihat preferensi notifikasi |
| PATCH | `/api/me/preferences/` | 🔒 | Update preferensi notifikasi |
| POST | `/api/me/device-token/` | 🔒 | Daftar FCM token |
| GET | `/api/alerts/` | 🔓 | Daftar semua peringatan |
| GET | `/api/alerts/latest/` | 🔓 | Peringatan aktif terbaru (cached) |
| GET | `/api/alerts/{id}/` | 🔓 | Detail peringatan |
| POST | `/api/officer/alerts/` | 👮 | Buat peringatan manual |
| PATCH | `/api/officer/alerts/{id}/` | 👮 | Update status peringatan |
| GET | `/api/news/` | 🔓 | Daftar berita |
| GET | `/api/news/{id}/` | 🔓 | Detail berita |
| POST | `/api/editor/news/` | ✏️ | Buat berita baru |
| PATCH | `/api/editor/news/{id}/` | ✏️ | Edit berita |
| DELETE | `/api/editor/news/{id}/` | ✏️ | Hapus berita |
| GET | `/api/map/nearby/` | 🔓 | Titik bantuan terdekat (radius GIS) |
| GET | `/api/map/risk-zones/` | 🔓 | Layer zona risiko (GeoJSON) |
| GET | `/api/assistance-points/` | 🔓 | Semua titik bantuan |
| POST | `/api/officer/assistance-points/` | 👮 | Tambah titik bantuan |
| PATCH | `/api/officer/assistance-points/{id}/` | 👮 | Update titik bantuan |
| POST | `/api/family/groups/` | 🔒 | Buat grup keluarga |
| GET | `/api/family/my-groups/` | 🔒 | Grup keluarga yang diikuti |
| POST | `/api/family/join/` | 🔒 | Bergabung via kode invite |
| GET | `/api/family/groups/{id}/members/` | 🔒 | Status anggota grup |
| POST | `/api/family/groups/{id}/status/` | 🔒 | Kirim status keselamatan |
| POST | `/api/family/groups/{id}/regenerate-invite/` | 🔒 | Buat ulang kode invite |
| DELETE | `/api/family/groups/{id}/leave/` | 🔒 | Keluar dari grup |
| GET | `/api/emergency-contacts/` | 🔓 | Daftar kontak darurat |
| GET | `/api/guides/` | 🔓 | Panduan kesiapsiagaan |
| POST | `/api/reports/` | 🔒 | Kirim laporan warga (P1) |
| GET | `/api/reports/my-reports/` | 🔒 | Riwayat laporan saya (P1) |

