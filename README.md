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

Prasyarat disediakan lewat Miniconda (tanpa `sudo`, tanpa Docker):

```bash
conda create -n py313 python=3.13 -y                                   # interpreter
conda create -n pg16 -c conda-forge --override-channels postgresql=16 -y  # server DB
```

Dev memakai Postgres lokal (conda); staging/produksi memakai Supabase.
Detail: [`docs/backend-implementation.md`](docs/backend-implementation.md).

## Menjalankan backend

```bash
cd backend
~/miniconda3/envs/py313/bin/python -m venv server-django && source server-django/bin/activate
pip install -U pip && pip install -r requirements-dev.txt
make db-init db-start db-create   # Postgres lokal sekali di awal
cp .env.example .env                # default sudah menunjuk DB lokal
make check && make migrate && make seed && make superuser && make run
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
