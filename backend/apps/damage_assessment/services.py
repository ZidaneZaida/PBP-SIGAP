"""Layanan laporan kerusakan: unggah foto + agregasi heatmap."""

import logging
import uuid

import requests
from django.conf import settings
from django.core.cache import cache
from django.db.models import Count, Max
from django.utils import timezone
from rest_framework.exceptions import ValidationError

from apps.damage_assessment.models import DamageReport

logger = logging.getLogger(__name__)

MAX_IMAGE_BYTES = 5 * 1024 * 1024
ALLOWED_IMAGE_TYPES = {"image/jpeg": "jpg", "image/png": "png"}

# Sisi grid agregasi heatmap dalam derajat. ~0.005 deg ≈ 550 m, mendekati
# skala satu kelurahan di Padang tanpa perlu data batas wilayah.
HEATMAP_GRID_DEGREES = 0.005

# Endpoint heatmap publik: cache singkat agar agregasi seluruh tabel tidak
# bisa dipakai sebagai vektor pembebanan.
HEATMAP_CACHE_KEY = "damage_heatmap_v1"
HEATMAP_CACHE_TTL = 30


def flush_heatmap_cache() -> None:
    """Kosongkan cache heatmap setelah data verifikasi berubah."""
    cache.delete(HEATMAP_CACHE_KEY)


def upload_damage_photo(report: DamageReport, uploaded_file) -> str:
    """Unggah foto kerusakan ke Supabase Storage dan kembalikan URL publiknya.

    Melempar ``ValidationError`` bila format/ukuran tidak sah atau storage belum
    dikonfigurasi. Pemanggil boleh mengabaikan kegagalan unggah: laporan tetap
    tersimpan tanpa foto (``image_url`` kosong).
    """
    if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_KEY:
        raise ValidationError("Penyimpanan foto belum dikonfigurasi.")

    content_type = uploaded_file.content_type
    if content_type not in ALLOWED_IMAGE_TYPES:
        raise ValidationError({"image": ["Format harus JPEG atau PNG."]})
    if uploaded_file.size > MAX_IMAGE_BYTES:
        raise ValidationError({"image": ["Ukuran maksimum 5 MB."]})

    ext = ALLOWED_IMAGE_TYPES[content_type]
    path = f"damage/{report.user_id}/{report.id}-{uuid.uuid4().hex[:8]}.{ext}"
    bucket = settings.SUPABASE_BUCKET_DAMAGE
    base = settings.SUPABASE_URL.rstrip("/")
    response = requests.post(
        f"{base}/storage/v1/object/{bucket}/{path}",
        headers={
            "Authorization": f"Bearer {settings.SUPABASE_SERVICE_KEY}",
            "Content-Type": content_type,
            "x-upsert": "true",
        },
        data=uploaded_file.read(),
        timeout=15,
    )
    if response.status_code >= 400:
        logger.error(
            "Upload foto kerusakan gagal: %s %s",
            response.status_code,
            response.text[:200],
        )
        raise ValidationError("Gagal mengunggah foto. Coba lagi.")

    return f"{base}/storage/v1/object/public/{bucket}/{path}"


def heatmap_points(*, include_pending: bool = False) -> list[dict]:
    """Agregasi laporan kerusakan menjadi titik heatmap berkelompok.

    Hanya laporan terverifikasi petugas yang dihitung secara default, sesuai
    alur di revisi arsitektur (laporan mentah belum layak jadi data publik).

    Pengelompokan memakai pembulatan koordinat ke grid ``HEATMAP_GRID_DEGREES``
    sehingga satu titik mewakili satu area kecil. Kelompok dengan dominasi
    tingkat kerusakan terberat membawa label tingkat tersebut.
    """
    qs = DamageReport.objects.all()
    if not include_pending:
        qs = qs.filter(is_verified_by_officer=True)

    buckets: dict[tuple[float, float], dict] = {}
    for row in qs.values_list(
        "latitude", "longitude", "damage_level", "created_at"
    ).iterator():
        lat, lon, level, created_at = row
        key = (
            round(lat / HEATMAP_GRID_DEGREES) * HEATMAP_GRID_DEGREES,
            round(lon / HEATMAP_GRID_DEGREES) * HEATMAP_GRID_DEGREES,
        )
        bucket = buckets.setdefault(
            key,
            {
                "latitude": round(key[0], 5),
                "longitude": round(key[1], 5),
                "total": 0,
                "by_level": {},
                "last_reported_at": created_at,
            },
        )
        bucket["total"] += 1
        bucket["by_level"][level] = bucket["by_level"].get(level, 0) + 1
        bucket["last_reported_at"] = max(bucket["last_reported_at"], created_at)

    severity_rank = {
        DamageReport.DamageLevel.MINOR: 1,
        DamageReport.DamageLevel.MODERATE: 2,
        DamageReport.DamageLevel.CRITICAL: 3,
    }
    points = []
    for bucket in buckets.values():
        dominant = max(
            bucket["by_level"],
            key=lambda level: (bucket["by_level"][level], severity_rank.get(level, 0)),
        )
        points.append(
            {
                "latitude": bucket["latitude"],
                "longitude": bucket["longitude"],
                "total": bucket["total"],
                "dominant_level": dominant,
                "by_level": bucket["by_level"],
                "last_reported_at": bucket["last_reported_at"].isoformat(),
            }
        )
    points.sort(key=lambda p: p["total"], reverse=True)
    return points


def heatmap_summary() -> dict:
    """Ringkasan angka untuk kartu statistik peta.

    ``pending`` dihitung terpisah agar pemantau tahu masih ada antrean
    verifikasi tanpa membocorkan lokasinya.
    """
    verified = DamageReport.objects.filter(is_verified_by_officer=True)
    pending = DamageReport.objects.filter(is_verified_by_officer__isnull=True)
    return {
        "total_verified": verified.count(),
        "total_pending": pending.count(),
        "total_rejected": DamageReport.objects.filter(
            is_verified_by_officer=False
        ).count(),
        "last_reported_at": DamageReport.objects.aggregate(
            latest=Max("created_at")
        )["latest"],
        "by_level": list(
            verified.values("damage_level")
            .annotate(count=Count("id"))
            .order_by("damage_level")
        ),
        "generated_at": timezone.now().isoformat(),
    }
