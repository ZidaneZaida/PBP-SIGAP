"""Query radius tanpa PostGIS."""

from apps.common.geo import bbox, haversine_m
from apps.map.models import AssistancePoint

DEFAULT_RADIUS_M = 5000
MAX_RADIUS_M = 20000
MAX_RESULTS = 50


def nearby_points(lat, lon, radius_m=DEFAULT_RADIUS_M, category=None):
    radius_m = max(100, min(int(radius_m), MAX_RADIUS_M))

    qs = AssistancePoint.objects.filter(is_active=True)
    if category:
        qs = qs.filter(category=category)

    (lat_min, lat_max), (lon_min, lon_max) = bbox(lat, lon, radius_m)
    qs = qs.filter(
        latitude__range=(lat_min, lat_max),
        longitude__range=(lon_min, lon_max),
    )

    rows = [
        (point, haversine_m(lat, lon, point.latitude, point.longitude))
        for point in qs
    ]
    rows = [row for row in rows if row[1] <= radius_m]
    rows.sort(key=lambda row: row[1])
    return [(point, round(distance, 1)) for point, distance in rows[:MAX_RESULTS]], radius_m
