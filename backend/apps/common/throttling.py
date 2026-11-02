"""Throttle DRF dengan dukungan jendela waktu bebas (mis. `5/10min`).

DRF bawaan hanya menerima `<n>/<s|m|h|d>`; `10min` membuat `period[0]`
menjadi `'1'` dan `parse_rate()` melempar KeyError.
"""

from rest_framework.throttling import ScopedRateThrottle

_UNITS = {
    "s": 1,
    "sec": 1,
    "second": 1,
    "seconds": 1,
    "m": 60,
    "min": 60,
    "minute": 60,
    "minutes": 60,
    "h": 3600,
    "hour": 3600,
    "hours": 3600,
    "d": 86400,
    "day": 86400,
    "days": 86400,
}


def parse_window(rate):
    """'5/10min' -> (5, 600). Mengembalikan (None, None) untuk rate kosong."""
    if not rate:
        return (None, None)
    amount, _, period = str(rate).partition("/")
    digits = "".join(ch for ch in period if ch.isdigit()) or "1"
    unit = "".join(ch for ch in period if ch.isalpha()).lower() or "s"
    if unit not in _UNITS:
        raise ValueError(f"Satuan throttle tidak dikenal: {period!r}")
    return (int(amount), int(digits) * _UNITS[unit])


class FlexibleScopedRateThrottle(ScopedRateThrottle):
    """ScopedRateThrottle yang memakai parse_window()."""

    def parse_rate(self, rate):
        return parse_window(rate)
