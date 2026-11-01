from unittest.mock import patch

from django.core.cache import cache
from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.alerts.models import Alert

BMKG_PAYLOAD = {
    "Infogempa": {
        "gempa": [
            {
                "Tanggal": "01 Nov 2026",
                "Jam": "12:38:59 WIB",
                "DateTime": "2026-11-01T05:38:59+00:00",
                "Coordinates": "-0.95,100.35",
                "Magnitude": "5.8",
                "Kedalaman": "10 km",
                "Wilayah": "24 km Barat Daya Kota Padang",
                "Potensi": "Tidak berpotensi tsunami",
                "Dirasakan": "III-IV Padang",
            },
            {
                "Tanggal": "01 Nov 2026",
                "Jam": "10:00:00 WIB",
                "DateTime": "2026-11-01T03:00:00+00:00",
                "Coordinates": "4.79,96.20",
                "Magnitude": "4.1",
                "Kedalaman": "6 km",
                "Wilayah": "Pidie Jaya, Aceh",
                "Dirasakan": "",
            },
        ]
    }
}


class _FakeResponse:
    def __init__(self, payload):
        self._payload = payload

    def raise_for_status(self):
        return None

    def json(self):
        return self._payload


class AlertSyncTest(TestCase):
    def setUp(self):
        cache.clear()
        self.client = APIClient()

    @patch("apps.alerts.services.requests.get")
    def test_hanya_gempa_dekat_padang_yang_disimpan(self, mock_get):
        mock_get.return_value = _FakeResponse(BMKG_PAYLOAD)

        response = self.client.get("/api/alerts/latest/")
        self.assertEqual(response.status_code, 200, response.content)

        self.assertEqual(Alert.objects.filter(is_from_bmkg=True).count(), 1)
        alert = Alert.objects.first()
        self.assertIsNone(alert.severity)
        self.assertEqual(alert.disaster_type, "earthquake")

        body = response.json()["data"]
        self.assertIsNotNone(body["alert"])

    @patch("apps.alerts.services.requests.get")
    def test_request_kedua_memakai_cache(self, mock_get):
        mock_get.return_value = _FakeResponse(BMKG_PAYLOAD)
        self.client.get("/api/alerts/latest/")
        self.client.get("/api/alerts/latest/")
        self.assertEqual(mock_get.call_count, 1)

    @patch("apps.alerts.services.requests.get")
    def test_bmkg_error_tidak_menggagalkan_request(self, mock_get):
        import requests

        mock_get.side_effect = requests.RequestException("timeout")
        response = self.client.get("/api/alerts/latest/")
        self.assertEqual(response.status_code, 200)
        self.assertIsNone(response.json()["data"]["alert"])


class AlertPermissionTest(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.citizen = User.objects.create_user(
            email="warga@example.com", password="Password123"
        )
        self.officer = User.objects.create_user(
            email="petugas@example.com", password="Password123", role="officer"
        )
        self.payload = {
            "disaster_type": "flood",
            "title": "Banjir Alai",
            "description": "Banjir 50 cm di Alai.",
            "severity": "waspada",
            "affected_area": "Alai, Padang Utara",
        }

    def test_warga_tidak_boleh_membuat_alert(self):
        self.client.force_authenticate(self.citizen)
        response = self.client.post("/api/officer/alerts/", self.payload, format="json")
        self.assertEqual(response.status_code, 403)

    def test_officer_dapat_membuat_alert(self):
        self.client.force_authenticate(self.officer)
        response = self.client.post("/api/officer/alerts/", self.payload, format="json")
        self.assertEqual(response.status_code, 201, response.content)
        self.assertEqual(response.json()["data"]["status"], "active")
