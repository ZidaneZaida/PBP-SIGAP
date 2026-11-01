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
| Docker + Compose | untuk PostgreSQL lokal |

Instalasi prasyarat di Debian/Ubuntu:

```bash
sudo apt install python3.13-venv
sudo usermod -aG docker "$USER"   # logout lalu login agar berlaku
```

Jika Docker tidak memungkinkan, buat project kedua di Supabase dan arahkan
`DATABASE_URL` ke connection string **session pooler** (port 5432).

## Menjalankan backend

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
cp .env.example .env          # isi SECRET_KEY & DATABASE_URL
docker compose up -d          # PostgreSQL 16 di localhost:5432
python manage.py migrate
python manage.py runserver
```

Cek: `curl http://127.0.0.1:8000/api/health/`

Dokumentasi lengkap: [`docs/README.md`](docs/README.md)

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
