# SIGAP — Siaga Bencana Kota Padang

Monorepo aplikasi SIGAP: frontend Flutter (`app/`) dan backend Django (`backend/`).

## Struktur

```
PBP-SIGAP/
├── app/          Flutter (Android, Web, Linux, macOS, Windows, iOS)
├── backend/      Django 5.2 + DRF (REST API)
├── docs/         Dokumentasi teknis backend
│   └── product/  PRD & BRD
└── .github/      CI (backend lint+test, flutter analyze+build)
```

## Prasyarat

| Tool | Versi |
|---|---|
| Python | 3.13+ (termasuk `venv` + `pip`) |
| Flutter | 3.47+ (Dart 3.13) |
| Akun Supabase | free tier (database dev **dan** produksi) |

Instalasi prasyarat di Debian/Ubuntu:

```bash
sudo apt install python3.13-venv
```

Tidak ada database lokal: dev & produksi memakai Supabase (lihat `docs/backend-implementation.md`).

## Menjalankan backend

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -U pip && pip install -r requirements-dev.txt
cp .env.example .env      # isi DATABASE_URL (session pooler) + DEBUG=True
python manage.py makemigrations
python manage.py migrate
python manage.py seed_demo
python manage.py createsuperuser
python manage.py runserver
```

Cek: `curl http://127.0.0.1:8000/api/health/`

Panduan lengkap + troubleshooting: [`docs/backend-implementation.md`](docs/backend-implementation.md)

## Menjalankan aplikasi

```bash
cd app
flutter pub get
flutter run -d linux
```

Menghubungkan ke backend:

```bash
# Linux desktop / web
flutter run -d linux --dart-define=API_BASE_URL=http://127.0.0.1:8000

# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Tanpa `--dart-define`, aplikasi memakai `http://127.0.0.1:8000`.

## Deploy (gratis)

| Komponen | Platform | Root |
|---|---|---|
| Backend API | Render Web Service (Free) | `backend/` |
| Web app | Render Static Site (Free) | `app/` → `build/web` |
| Database | Supabase (Free, Supavisor pooler) | — |

Batas free tier dan konsekuensinya: [`docs/backend-audit.md`](docs/backend-audit.md).

## Aturan commit

- `git add -A` (bukan `-am`) agar file baru di `app/` dan `backend/` ikut ter-stage.
- Satu commit per milestone.
