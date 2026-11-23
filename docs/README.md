# 📁 Dokumentasi Backend SIGAP

Folder ini berisi seluruh dokumentasi teknis untuk pengembangan backend **SIGAP (Siaga Bencana Kota Padang)**.

## 📄 Daftar Dokumen

| Dokumen | Deskripsi |
|---|---|
| [`backend-audit.md`](./backend-audit.md) | Hasil audit perencanaan: blocker teknis, inkonsistensi, keputusan |
| [`backend-requirements.md`](./backend-requirements.md) | Kebutuhan sistem & spesifikasi teknis backend (v2.0) |
| [`database-schema.md`](./database-schema.md) | Model dan skema tabel (PostgreSQL via Supabase, tanpa PostGIS) |
| [`api-documentation.md`](./api-documentation.md) | Dokumentasi seluruh endpoint REST API (51 endpoint) |
| [`backend-implementation.md`](./backend-implementation.md) | Status implementasi, langkah manual, troubleshooting |

## 📦 Dokumen Produk

| Dokumen | Deskripsi |
|---|---|
| [`PRD_SIGAP_Kota_Padang.md`](./PRD_SIGAP_Kota_Padang.md) | Product Requirements Document |
| [`BRD Aplikasi SIGAP (Siaga Bencana Kota Padang).md`](./BRD%20Aplikasi%20SIGAP%20%28Siaga%20Bencana%20Kota%20Padang%29.md) | Business Requirements Document |

## 🛠 Tech Stack

| Komponen | Teknologi | Keterangan |
|---|---|---|
| **Backend Framework** | Django 5.x + Django REST Framework 3.x | Python |
| **ORM** | Django ORM | Built-in, tanpa ORM eksternal |
| **Database** | PostgreSQL 15 (Supabase Free Tier) | Koneksi via Supavisor session pooler |
| **Hosting Backend** | Render.com (Free Tier) | 750 jam/bln, spin down 15 menit idle |
| **Push Notification** | Firebase Cloud Messaging (FCM) | Gratis |
| **Cache** | `LocMemCache` bawaan Django | TTL 60 detik untuk data BMKG |
| **Data Spasial** | `FloatField` + haversine | Tanpa PostGIS/GeoDjango |
| **Zona Risiko** | `JSONField` GeoJSON | Dirender langsung oleh `flutter_map` |
| **Email** | Brevo SMTP port 2525 | Free 300 email/hari |
| **Static Files** | WhiteNoise | Django Admin |
| **Auth** | JWT (`djangorestframework-simplejwt`) | Token-based |

## ⚠️ Batasan Free Tier

Tidak ada cron job, background worker, atau Redis. Data BMKG diambil secara **lazy** saat endpoint dipanggil dan di-cache 60 detik. Instance spin down setelah 15 menit idle (cold start ±50 detik).

Rincian lengkap: [`backend-audit.md` §7](./backend-audit.md).

