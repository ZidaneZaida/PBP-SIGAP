from django.test import TestCase
from rest_framework.test import APIClient


class HealthEndpointTest(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_health_mengembalikan_amplop_sukses(self):
        response = self.client.get("/api/health/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["status"], "success")
        self.assertEqual(response.json()["data"]["db"], "ok")

    def test_health_tanpa_token(self):
        response = self.client.get("/api/health/")
        self.assertNotIn("detail", response.json())


class ExceptionEnvelopeTest(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_404_memakai_amplop_error(self):
        response = self.client.get("/api/tidak-ada/")
        self.assertEqual(response.status_code, 404)


class HaversineTest(TestCase):
    def test_jarak_nol_untuk_koordinat_sama(self):
        from apps.common.geo import haversine_m

        self.assertEqual(haversine_m(-0.9492, 100.3543, -0.9492, 100.3543), 0.0)

    def test_jarak_padang_ke_bukittinggi_wajar(self):
        from apps.common.geo import haversine_m

        # Padang -> Bukittinggi ± 70 km garis lurus
        distance = haversine_m(-0.9492, 100.3543, -0.3055, 100.3691)
        self.assertAlmostEqual(distance / 1000, 71.5, delta=3)

class NotFoundEnvelopeTest(TestCase):
    """handler404 hanya aktif saat DEBUG=False."""

    def test_404_memakai_amplop_json_saat_debug_off(self):
        from django.test import override_settings

        with override_settings(DEBUG=False):
            response = self.client.get("/api/tidak-ada/")
        self.assertEqual(response.status_code, 404)
        self.assertEqual(response["Content-Type"], "application/json")
        body = response.json()
        self.assertEqual(body["status"], "error")
        self.assertEqual(body["code"], "NOT_FOUND")
