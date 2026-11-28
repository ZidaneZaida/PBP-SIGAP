"""Uji endpoint penilaian kerusakan bangunan (Fase A — BE-01..BE-04)."""

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.damage_assessment.models import DamageReport
from apps.map.models import AssistancePoint


class DamageReportCreateTest(TestCase):
    """Sinkronisasi laporan dari aplikasi warga."""

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email="warga@sigap.id", password="SandiSigap2026"
        )
        self.payload = {
            "latitude": -0.9481,
            "longitude": 100.3529,
            "damage_level": "moderate",
            "confidence_score": 0.82,
            "description": "Retak diagonal pada dinding bata sisi timur.",
        }

    def test_warga_dapat_mengirim_laporan(self):
        self.client.force_authenticate(self.user)
        response = self.client.post("/api/damage-reports/", self.payload, format="json")

        self.assertEqual(response.status_code, 201, response.content)
        body = response.json()["data"]
        self.assertEqual(body["damage_level"], "moderate")
        self.assertIsNone(body["is_verified_by_officer"])
        self.assertEqual(DamageReport.objects.filter(user=self.user).count(), 1)

    def test_tamu_tidak_boleh_mengirim_laporan(self):
        response = self.client.post("/api/damage-reports/", self.payload, format="json")
        self.assertEqual(response.status_code, 401)

    def test_koordinat_di_luar_padang_ditolak(self):
        self.client.force_authenticate(self.user)
        payload = {**self.payload, "latitude": -6.2, "longitude": 106.8}
        response = self.client.post("/api/damage-reports/", payload, format="json")

        self.assertEqual(response.status_code, 400, response.content)
        self.assertIn("latitude", response.json()["errors"])

    def test_confidence_di_luar_rentang_ditolak(self):
        self.client.force_authenticate(self.user)
        payload = {**self.payload, "confidence_score": 85}
        response = self.client.post("/api/damage-reports/", payload, format="json")

        self.assertEqual(response.status_code, 400, response.content)
        self.assertIn("confidence_score", response.json()["errors"])

    def test_laporan_tanpa_foto_tetap_tersimpan(self):
        """Foto opsional: unggahan gagal tidak boleh membuang data kerusakan."""
        self.client.force_authenticate(self.user)
        response = self.client.post("/api/damage-reports/", self.payload, format="json")

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.json()["data"]["image_url"], "")

    def test_kirim_ulang_client_report_id_tidak_membuat_duplikat(self):
        """Retry antrean offline harus idempoten, bukan menciptakan laporan ganda."""
        self.client.force_authenticate(self.user)
        payload = {**self.payload, "client_report_id": "vision_1730000000000"}

        first = self.client.post("/api/damage-reports/", payload, format="json")
        second = self.client.post("/api/damage-reports/", payload, format="json")

        self.assertEqual(first.status_code, 201, first.content)
        self.assertEqual(second.status_code, 200, second.content)
        self.assertEqual(first.json()["data"]["id"], second.json()["data"]["id"])
        self.assertEqual(DamageReport.objects.filter(user=self.user).count(), 1)

    def test_client_report_id_sama_milik_user_lain_tetap_dibuat(self):
        """Constraint unik berlaku per pengguna, bukan global."""
        self.client.force_authenticate(self.user)
        shared_id = "vision_1730000000001"
        payload = {**self.payload, "client_report_id": shared_id}
        self.client.post("/api/damage-reports/", payload, format="json")

        other = User.objects.create_user(email="lain2@sigap.id", password="SandiSigap2026")
        self.client.force_authenticate(other)
        response = self.client.post("/api/damage-reports/", payload, format="json")

        self.assertEqual(response.status_code, 201, response.content)
        self.assertEqual(DamageReport.objects.count(), 2)

    def test_riwayat_my_hanya_milik_pengguna_sendiri(self):
        other = User.objects.create_user(email="lain@sigap.id", password="SandiSigap2026")
        DamageReport.objects.create(
            user=other,
            latitude=-0.94,
            longitude=100.36,
            damage_level="minor",
            confidence_score=0.7,
        )
        mine = DamageReport.objects.create(
            user=self.user,
            latitude=-0.95,
            longitude=100.35,
            damage_level="critical",
            confidence_score=0.91,
        )

        self.client.force_authenticate(self.user)
        response = self.client.get("/api/damage-reports/my/")

        self.assertEqual(response.status_code, 200)
        ids = [row["id"] for row in response.json()["data"]]
        self.assertEqual(ids, [str(mine.id)])


class DamageHeatmapTest(TestCase):
    """Agregasi heatmap publik."""

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email="warga@sigap.id", password="SandiSigap2026"
        )
        # Dua laporan di area sama (terverifikasi) + satu laporan tertunda.
        for level in ("moderate", "critical"):
            DamageReport.objects.create(
                user=self.user,
                latitude=-0.9481,
                longitude=100.3529,
                damage_level=level,
                confidence_score=0.8,
                is_verified_by_officer=True,
                verified_at=timezone.now(),
            )
        DamageReport.objects.create(
            user=self.user,
            latitude=-0.9481,
            longitude=100.3529,
            damage_level="minor",
            confidence_score=0.6,
        )

    def test_heatmap_hanya_menampilkan_laporan_terverifikasi(self):
        response = self.client.get("/api/damage-reports/heatmap/")

        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertEqual(len(data["points"]), 1)
        point = data["points"][0]
        self.assertEqual(point["total"], 2)
        self.assertEqual(point["dominant_level"], "critical")
        self.assertEqual(data["summary"]["total_pending"], 1)

    def test_heatmap_dapat_diakses_tanpa_login(self):
        response = self.client.get("/api/damage-reports/heatmap/")
        self.assertEqual(response.status_code, 200)


class DamageOfficerVerificationTest(TestCase):
    """Alur verifikasi oleh petugas BPBD."""

    def setUp(self):
        self.client = APIClient()
        self.citizen = User.objects.create_user(
            email="warga@sigap.id", password="SandiSigap2026"
        )
        self.officer = User.objects.create_user(
            email="petugas@sigap.id", password="SandiSigap2026", role="officer"
        )
        self.report = DamageReport.objects.create(
            user=self.citizen,
            latitude=-0.9481,
            longitude=100.3529,
            damage_level="critical",
            confidence_score=0.88,
        )

    def test_warga_tidak_boleh_melihat_antrean_verifikasi(self):
        self.client.force_authenticate(self.citizen)
        response = self.client.get("/api/officer/damage-reports/pending/")
        self.assertEqual(response.status_code, 403)

    def test_officer_melihat_laporan_tertunda(self):
        self.client.force_authenticate(self.officer)
        response = self.client.get("/api/officer/damage-reports/pending/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.json()["data"]), 1)

    def test_officer_memverifikasi_laporan(self):
        self.client.force_authenticate(self.officer)
        response = self.client.patch(
            f"/api/officer/damage-reports/{self.report.id}/verify/",
            {"approved": True, "note": "Cocok dengan foto."},
            format="json",
        )

        self.assertEqual(response.status_code, 200, response.content)
        self.report.refresh_from_db()
        self.assertTrue(self.report.is_verified_by_officer)
        self.assertEqual(self.report.verified_by, self.officer)
        self.assertIsNotNone(self.report.verified_at)

    def test_officer_menolak_laporan(self):
        self.client.force_authenticate(self.officer)
        response = self.client.patch(
            f"/api/officer/damage-reports/{self.report.id}/verify/",
            {"approved": False},
            format="json",
        )

        self.assertEqual(response.status_code, 200, response.content)
        self.report.refresh_from_db()
        self.assertFalse(self.report.is_verified_by_officer)


class TsunamiShelterEndpointTest(TestCase):
    """Endpoint shelter TES memakai ulang AssistancePoint."""

    def setUp(self):
        self.client = APIClient()

    def test_hanya_shelter_terverifikasi_yang_tampil(self):
        AssistancePoint.objects.create(
            name="Gedung Youth Center",
            category=AssistancePoint.Category.EVACUATION_POINT,
            latitude=-0.9432,
            longitude=100.3617,
            capacity=2000,
            verification_status=AssistancePoint.Verification.VERIFIED,
        )
        AssistancePoint.objects.create(
            name="Titik Belum Diverifikasi",
            category=AssistancePoint.Category.EVACUATION_POINT,
            latitude=-0.94,
            longitude=100.36,
            verification_status=AssistancePoint.Verification.UNVERIFIED,
        )
        AssistancePoint.objects.create(
            name="RSUP Dr. M. Djamil",
            category=AssistancePoint.Category.HOSPITAL,
            latitude=-0.944,
            longitude=100.374,
            verification_status=AssistancePoint.Verification.VERIFIED,
        )

        response = self.client.get("/api/shelters/tsunami/")

        self.assertEqual(response.status_code, 200)
        names = [row["name"] for row in response.json()["data"]]
        self.assertEqual(names, ["Gedung Youth Center"])
