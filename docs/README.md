# 📁 Dokumentasi Backend SIGAP

Folder ini berisi seluruh dokumentasi teknis untuk pengembangan backend aplikasi **SIGAP (Siaga Bencana Kota Padang)**.

## 📄 Daftar Dokumen

| Dokumen | Deskripsi |
|---|---|
| [`backend-requirements.md`](./backend-requirements.md) | Kebutuhan sistem & spesifikasi teknis backend (BRD → Teknis) |
| [`database-schema.md`](./database-schema.md) | Desain model dan skema tabel database (PostgreSQL + PostGIS via Supabase) |
| [`api-documentation.md`](./api-documentation.md) | Dokumentasi lengkap seluruh endpoint REST API |

## 🛠 Tech Stack

| Komponen | Teknologi | Keterangan |
|---|---|---|
| **Backend Framework** | Django 5.x + Django REST Framework 3.x | Python |
| **Database** | PostgreSQL (via Supabase Free Tier) + PostGIS | Spasial GIS untuk koordinat |
| **Hosting Backend** | Render.com (Free Tier) | HTTPS otomatis |
| **Push Notification** | Firebase Cloud Messaging (FCM) | Peringatan darurat < 1 menit |
| **Cache / Queue** | Redis (Upstash Free Tier) | Cache BMKG, task queue |
| **Static Files** | WhiteNoise | Untuk Django Admin |
| **Auth** | JWT (djangorestframework-simplejwt) | Token-based |
| **Data Spasial** | GeoDjango + PostGIS | Radius posko, zona risiko |

