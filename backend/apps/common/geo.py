from math import asin, cos, radians, sin, sqrt

EARTH_RADIUS_M = 6_371_000
METERS_PER_DEGREE_LAT = 111_320


def haversine_m(lat1, lon1, lat2, lon2):
    """Jarak dua koordinat dalam meter."""
    dlat = radians(lat2 - lat1)
    dlon = radians(lon2 - lon1)
    a = (
        sin(dlat / 2) ** 2
        + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon / 2) ** 2
    )
    return 2 * EARTH_RADIUS_M * asin(sqrt(a))


def bbox(lat, lon, radius_m):
    """Kotak pembatas kasar untuk mempersempit query sebelum haversine."""
    dlat = radius_m / METERS_PER_DEGREE_LAT
    dlon = radius_m / (METERS_PER_DEGREE_LAT * max(0.01, cos(radians(lat))))
    return (
        (lat - dlat, lat + dlat),
        (lon - dlon, lon + dlon),
    )