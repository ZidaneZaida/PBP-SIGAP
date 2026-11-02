"""Settings SIGAP — satu file, dibedakan lewat environment variable."""

import sys
from datetime import timedelta
from pathlib import Path

import environ
from django.core.exceptions import ImproperlyConfigured

BASE_DIR = Path(__file__).resolve().parent.parent

env = environ.Env()
environ.Env.read_env(BASE_DIR / ".env")

SECRET_KEY = env("SECRET_KEY", default="dev-insecure-key")
DEBUG = env.bool("DEBUG", default=False)
ALLOWED_HOSTS = env.list(
    "ALLOWED_HOSTS",
    default=["localhost", "127.0.0.1", ".onrender.com", ".vercel.app"],
)
if ".vercel.app" not in ALLOWED_HOSTS:
    ALLOWED_HOSTS.append(".vercel.app")

# --------------------------------------------------------------------------
# Applications
# --------------------------------------------------------------------------
DJANGO_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
]

THIRD_PARTY_APPS = [
    "corsheaders",
    "rest_framework",
    "rest_framework_simplejwt.token_blacklist",
]

LOCAL_APPS = [
    "apps.common",
    "apps.accounts",
    "apps.alerts",
    "apps.news",
    "apps.map",
    "apps.guides",
    "apps.family",
    "apps.notifications",
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"
ASGI_APPLICATION = "config.asgi.application"

# --------------------------------------------------------------------------
# Database — Supavisor session pooler (IPv4-compatible)
# --------------------------------------------------------------------------
DATABASES = {
    "default": env.db(
        "DATABASE_URL",
        default="postgres://postgres:postgres@127.0.0.1:5432/sigap",
    )
}

if DATABASES["default"]["ENGINE"] == "django.db.backends.sqlite3":
    _db_name = DATABASES["default"].get("NAME")
    if _db_name and not Path(_db_name).is_absolute():
        DATABASES["default"]["NAME"] = str(BASE_DIR / _db_name)

TEST_DB_NAME = env("TEST_DB_NAME", default="")
if TEST_DB_NAME:
    DATABASES["default"]["TEST"] = {"NAME": TEST_DB_NAME}

if "test" in sys.argv:
    _host = str(DATABASES["default"].get("HOST") or "")
    if _host not in {"", "localhost", "127.0.0.1"} and not env.bool(
        "ALLOW_REMOTE_TESTS", default=False
    ):
        raise ImproperlyConfigured(
            f"Test diarahkan ke database remote ({_host}). "
            "Set ALLOW_REMOTE_TESTS=True hanya bila DB tersebut bukan produksi."
        )

DATABASES["default"]["CONN_MAX_AGE"] = env.int("CONN_MAX_AGE", default=0)
DATABASES["default"]["DISABLE_SERVER_SIDE_CURSORS"] = True
DATABASES["default"]["CONN_HEALTH_CHECKS"] = env.bool(
    "CONN_HEALTH_CHECKS", default=True
)

# Konfigurasi koneksi PostgreSQL (Neon / Supabase)
if DATABASES["default"]["ENGINE"] == "django.db.backends.postgresql":
    DATABASES["default"].setdefault("OPTIONS", {}).update({
        "connect_timeout": 10,
    })

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# --------------------------------------------------------------------------
# Auth
# --------------------------------------------------------------------------
AUTH_USER_MODEL = "accounts.User"

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
        "OPTIONS": {"min_length": 8},
    },
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

PASSWORD_HASHERS = [
    "django.contrib.auth.hashers.Argon2PasswordHasher",
    "django.contrib.auth.hashers.PBKDF2PasswordHasher",
]

# --------------------------------------------------------------------------
# DRF
# --------------------------------------------------------------------------
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": ["rest_framework.permissions.AllowAny"],
    "DEFAULT_RENDERER_CLASSES": ["apps.common.renderers.ApiJSONRenderer"],
    "DEFAULT_PAGINATION_CLASS": "apps.common.pagination.ApiPageNumberPagination",
    "PAGE_SIZE": 10,
    "EXCEPTION_HANDLER": "apps.common.exceptions.api_exception_handler",
    "DEFAULT_THROTTLE_CLASSES": ["rest_framework.throttling.AnonRateThrottle"],
    # Jendela bebas (mis. 5/10min) ditangani apps.common.throttling.
    "DEFAULT_THROTTLE_RATES": {
        "anon": "120/min",
        "login": "5/10min",
        "register": "20/hour",
        "password_reset": "5/hour",
    },
    "TEST_REQUEST_DEFAULT_FORMAT": "json",
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(
        minutes=env.int("ACCESS_TOKEN_LIFETIME_MINUTES", default=60)
    ),
    "REFRESH_TOKEN_LIFETIME": timedelta(
        days=env.int("REFRESH_TOKEN_LIFETIME_DAYS", default=7)
    ),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
    "AUTH_HEADER_TYPES": ("Bearer",),
    "USER_ID_FIELD": "id",
    "USER_ID_CLAIM": "user_id",
}

# --------------------------------------------------------------------------
# Cache — LocMem (satu instance, tanpa Redis)
# --------------------------------------------------------------------------
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
        "LOCATION": "sigap",
    }
}
BMKG_CACHE_TTL = env.int("BMKG_CACHE_TTL", default=60)

# --------------------------------------------------------------------------
# i18n
# --------------------------------------------------------------------------
LANGUAGE_CODE = "id"
TIME_ZONE = "Asia/Jakarta"
USE_I18N = True
USE_TZ = True

# --------------------------------------------------------------------------
# Static files (WhiteNoise)
# --------------------------------------------------------------------------
STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
STORAGES = {
    "default": {"BACKEND": "django.core.files.storage.FileSystemStorage"},
    "staticfiles": {"BACKEND": "whitenoise.storage.CompressedStaticFilesStorage"},
}

# --------------------------------------------------------------------------
# CORS & proxy
# --------------------------------------------------------------------------
CORS_ALLOWED_ORIGINS = env.list("CORS_ALLOWED_ORIGINS", default=[])
CORS_ALLOW_ALL_ORIGINS = False
if DEBUG:
    CORS_ALLOWED_ORIGIN_REGEXES = [
        r"^http://(localhost|127\.0\.0\.1)(:\d+)?$",
    ]

# Render berjalan di belakang proxy; tanpa ini rate limit per-IP salah hitung.
NUM_PROXIES = env.int("NUM_PROXIES", default=1)
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")

if not DEBUG and "test" not in sys.argv:
    SECURE_SSL_REDIRECT = env.bool("SECURE_SSL_REDIRECT", default=True)
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_HSTS_SECONDS = 0  # 0 di free tier agar rollback mudah

CSRF_TRUSTED_ORIGINS = env.list("CSRF_TRUSTED_ORIGINS", default=[])

# --------------------------------------------------------------------------
# Email — Brevo port 2525 di produksi, console saat dev
# --------------------------------------------------------------------------
EMAIL_HOST = env("EMAIL_HOST", default="")
EMAIL_PORT = env.int("EMAIL_PORT", default=2525)
EMAIL_HOST_USER = env("EMAIL_HOST_USER", default="")
EMAIL_HOST_PASSWORD = env("EMAIL_HOST_PASSWORD", default="")
EMAIL_USE_TLS = env.bool("EMAIL_USE_TLS", default=True)
DEFAULT_FROM_EMAIL = env("DEFAULT_FROM_EMAIL", default="SIGAP <no-reply@sigap.app>")
EMAIL_BACKEND = (
    "django.core.mail.backends.smtp.EmailBackend"
    if EMAIL_HOST and EMAIL_HOST_USER
    else "django.core.mail.backends.console.EmailBackend"
)

# --------------------------------------------------------------------------
# Integrasi eksternal
# --------------------------------------------------------------------------
FIREBASE_CREDENTIALS_JSON = env("FIREBASE_CREDENTIALS_JSON", default="")

SUPABASE_URL = env("SUPABASE_URL", default="")
SUPABASE_SERVICE_KEY = env("SUPABASE_SERVICE_KEY", default="")
SUPABASE_BUCKET_AVATARS = env("SUPABASE_BUCKET_AVATARS", default="avatars")

INTERNAL_SYNC_TOKEN = env("INTERNAL_SYNC_TOKEN", default="")
FRONTEND_BASE_URL = env("FRONTEND_BASE_URL", default="http://localhost:3000")

BMKG_GEMPA_URL = env(
    "BMKG_GEMPA_URL",
    default="https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json",
)
PADANG_LAT = env.float("PADANG_LAT", default=-0.9492)
PADANG_LON = env.float("PADANG_LON", default=100.3543)
PADANG_RADIUS_KM = env.int("PADANG_RADIUS_KM", default=300)

# --------------------------------------------------------------------------
# Logging
# --------------------------------------------------------------------------
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "simple": {"format": "{levelname} {asctime} {name} {message}", "style": "{"},
    },
    "handlers": {
        "console": {"class": "logging.StreamHandler", "formatter": "simple"},
    },
    "root": {"handlers": ["console"], "level": env("LOG_LEVEL", default="INFO")},
}
