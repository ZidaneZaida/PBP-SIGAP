from django.test import TestCase
from rest_framework.test import APIClient

from apps.map.models import AssistancePoint
from apps.map.services import nearby_points

PADANG = (-0.9492, 100.3543)


class HaversineRadiusTest(TestCase):
    def setUp(self):
        AssistancePoint.objects.create(
            name="Dekat",
            category="evacuation_point",
            latitude=-0.9481,
            longitude=100.3529,
        )
        AssistancePoint.objects.create(
            name="Jauh",
            category="evacuation_point",
            latitude=-0.3055,
            longitude=100.3691,
        )

    def test_radius_5km_hanya_mengembalikan_titik_dekat(self):
        rows, radius = nearby_points(*PADANG, radius_m=5000)
        self.assertEqual(radius, 5000)
        self.assertEqual([point.name for point, _ in rows], ["Dekat"])
        self.assertLess(rows[0][1], 5000)

    def test_radius_dibatasi_maksimum(self):
        _, radius = nearby_points(*PADANG, radius_m=999999)
        self.assertEqual(radius, 20000)

    def test_filter_kategori(self):
        rows, _ = nearby_points(*PADANG, radius_m=5000, category="hospital")
        self.assertEqual(rows, [])


class NearbyEndpointTest(TestCase):
    def setUp(self):
        self.client = APIClient()
        AssistancePoint.objects.create(
            name="Lapangan Imam Bonjol",
            category="evacuation_point",
            latitude=-0.9481,
            longitude=100.3529,
        )

    def test_butuh_parameter_lat_lon(self):
        self.assertEqual(self.client.get("/api/map/nearby/").status_code, 400)

    def test_mengembalikan_distance_meters(self):
        response = self.client.get(
            "/api/map/nearby/?lat=-0.9492&lon=100.3543&radius=5000"
        )
        self.assertEqual(response.status_code, 200, response.content)
        results = response.json()["data"]["results"]
        self.assertEqual(len(results), 1)
        self.assertIn("distance_meters", results[0])


class RiskZoneLayerTest(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_feature_collection_kosong(self):
        response = self.client.get("/api/map/risk-zones/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"]["type"], "FeatureCollection")
