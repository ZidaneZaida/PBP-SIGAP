"""Lazy-fetch data gempa BMKG + simpan alert relevan Padang."""

import logging
from datetime import datetime

import requests
from django.conf import settings
from django.core.cache import cache
from django.utils import timezone

from apps.alerts.models import Alert, Source
from apps.common.geo import haversine_m

logger = logging.getLogger(__name__)

CACHE_KEY = "bmkg:gempadirasakan"
BMKG_SOURCE_NAME = "BMKG"


def bmkg_source():
    source, _ = Source.objects.get_or_create(
        name=BMKG_SOURCE_NAME,
        defaults={
            "source_url": "https://data.bmkg.go.id",
            "source_type": Source.SourceType.GOVERNMENT_API,
            "description": "Badan Meteorologi, Klimatologi, dan Geofisika",
        },
    )
    return source


def _parse_dt(raw):
    if not raw:
        return None
    try:
        return datetime.fromisoformat(str(raw).replace("Z", "+00:00"))
    except ValueError:
        return None


def _parse_float(raw):
    try:
        return float(str(raw).replace(" km", "").strip())
    except (TypeError, ValueError):
        return None


def _to_meter_coords(raw):
    try:
        lat_s, lon_s = str(raw).split(",")
        return float(lat_s), float(lon_s)
    except (ValueError, AttributeError):
        return None, None


def parse_gempa(item):
    lat, lon = _to_meter_coords(item.get("Coordinates"))
    if lat is None:
        return None

    distance_km = haversine_m(settings.PADANG_LAT, settings.PADANG_LON, lat, lon) / 1000
    if distance_km > settings.PADANG_RADIUS_KM:
        return None

    return {
        "latitude": lat,
        "longitude": lon,
        "magnitude": _parse_float(item.get("Magnitude")),
        "depth_km": _parse_float(item.get("Kedalaman")),
        "felt_description": (item.get("Dirasakan") or "")[:300],
        "wilayah": (item.get("Wilayah") or "")[:300],
        "bmkg_datetime": _parse_dt(item.get("DateTime")),
        "distance_km": round(distance_km, 1),
    }


def fetch_bmkg_earthquakes(force=False):
    """Ambil gempa relevan dari BMKG (cache 60 detik)."""
    if not force:
        cached = cache.get(CACHE_KEY)
        if cached is not None:
            return cached

    try:
        response = requests.get(settings.BMKG_GEMPA_URL, timeout=6)
        response.raise_for_status()
        items = response.json()["Infogempa"]["gempa"]
    except (requests.RequestException, KeyError, ValueError) as exc:
        logger.warning("Gagal mengambil data BMKG: %s", exc)
        cache.set(CACHE_KEY, [], 30)
        return []

    parsed = [row for row in (parse_gempa(item) for item in items) if row]
    cache.set(CACHE_KEY, parsed, settings.BMKG_CACHE_TTL)
    return parsed


def sync_bmkg_alerts():
    """Simpan gempa yang belum ada. Mengembalikan (created, skipped)."""
    source = bmkg_source()
    created = skipped = 0

    for row in fetch_bmkg_earthquakes():
        if not row["bmkg_datetime"]:
            skipped += 1
            continue
        _, was_created = Alert.objects.get_or_create(
            source=source,
            bmkg_datetime=row["bmkg_datetime"],
            defaults={
                "disaster_type": Alert.DisasterType.EARTHQUAKE,
                "title": f"Gempa M{row['magnitude']} — {row['wilayah']}"[:300],
                "description": (
                    f"Gempa magnitudo {row['magnitude']} pada kedalaman "
                    f"{row['depth_km']} km. {row['wilayah']}."
                ),
                "affected_area": row["wilayah"] or "Kota Padang",
                "latitude": row["latitude"],
                "longitude": row["longitude"],
                "magnitude": row["magnitude"],
                "depth_km": int(row["depth_km"]) if row["depth_km"] else None,
                "felt_description": row["felt_description"],
                "status": Alert.Status.ACTIVE,
                "published_at": row["bmkg_datetime"],
                "is_from_bmkg": True,
                "source_reference_url": "https://data.bmkg.go.id/gempabumi/",
            },
        )
        if was_created:
            created += 1
        else:
            skipped += 1

    return created, skipped


def latest_active_alert():
    return (
        Alert.objects.filter(status=Alert.Status.ACTIVE)
        .select_related("source")
        .order_by("-published_at")
        .first()
    )


def expire_stale_alerts():
    now = timezone.now()
    return Alert.objects.filter(
        status=Alert.Status.ACTIVE, expires_at__lt=now
    ).update(status=Alert.Status.EXPIRED)
