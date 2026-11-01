from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.family.models import FamilyGroup, FamilyMembership, SafetyStatus


class FamilyFlowTest(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.admin = User.objects.create_user(
            email="admin@example.com", full_name="Pak Ahmad", password="Password123"
        )
        self.member = User.objects.create_user(
            email="anggota@example.com", full_name="Budi", password="Password123"
        )

    def _login(self, user):
        self.client.force_authenticate(user)

    def _create_group(self):
        self._login(self.admin)
        response = self.client.post(
            "/api/family/groups/", {"name": "Keluarga Pak Ahmad"}, format="json"
        )
        self.assertEqual(response.status_code, 201, response.content)
        return response.json()["data"]

    def test_buat_grup_membuat_admin_aktif(self):
        data = self._create_group()
        self.assertEqual(len(data["invite_code"]), 8)
        membership = FamilyMembership.objects.get(family_group_id=data["id"])
        self.assertTrue(membership.is_group_admin)
        self.assertEqual(membership.status, FamilyMembership.Status.ACTIVE)

    def test_gabung_menunggu_persetujuan_lalu_disetujui(self):
        group = self._create_group()

        self._login(self.member)
        join = self.client.post(
            "/api/family/join/", {"invite_code": group["invite_code"]}, format="json"
        )
        self.assertEqual(join.status_code, 200, join.content)
        self.assertEqual(join.json()["data"]["status"], "pending")

        membership = FamilyMembership.objects.get(
            family_group_id=group["id"], user=self.member
        )
        self.assertEqual(membership.status, FamilyMembership.Status.PENDING)

        self._login(self.admin)
        members = self.client.get(f"/api/family/groups/{group['id']}/members/")
        self.assertEqual(len(members.json()["data"]["members"]), 1)

        approve = self.client.post(
            f"/api/family/groups/{group['id']}/members/{self.member.id}/approve/"
        )
        self.assertEqual(approve.status_code, 200, approve.content)

        members = self.client.get(f"/api/family/groups/{group['id']}/members/")
        self.assertEqual(len(members.json()["data"]["members"]), 2)

    def test_kode_undangan_salah_ditolak(self):
        self._login(self.member)
        response = self.client.post(
            "/api/family/join/", {"invite_code": "ZZZZZZZZ"}, format="json"
        )
        self.assertEqual(response.status_code, 400)

    def test_status_keselamatan_tersimpan_dan_tampil(self):
        group = self._create_group()
        self._login(self.admin)

        post = self.client.post(
            f"/api/family/groups/{group['id']}/status/",
            {
                "status": "safe",
                "message": "Aman di rumah",
                "share_location": False,
                "latitude": -0.9,
                "longitude": 100.3,
            },
            format="json",
        )
        self.assertEqual(post.status_code, 201, post.content)
        self.assertFalse(post.json()["data"]["location_shared"])

        saved = SafetyStatus.objects.get()
        self.assertIsNone(saved.latitude)
        self.assertIsNone(saved.longitude)

        members = self.client.get(f"/api/family/groups/{group['id']}/members/")
        payload = members.json()["data"]["members"][0]
        self.assertEqual(payload["latest_status"]["status"], "safe")

    def test_anggota_tanpa_laporan_latest_status_null(self):
        group = self._create_group()
        self._login(self.admin)
        members = self.client.get(f"/api/family/groups/{group['id']}/members/")
        self.assertIsNone(members.json()["data"]["members"][0]["latest_status"])

    def test_bukan_anggota_tidak_bisa_melihat(self):
        group = self._create_group()
        self._login(self.member)
        response = self.client.get(f"/api/family/groups/{group['id']}/members/")
        self.assertEqual(response.status_code, 403)

    def test_admin_terakhir_tidak_bisa_keluar(self):
        group = self._create_group()
        response = self.client.delete(f"/api/family/groups/{group['id']}/leave/")
        self.assertEqual(response.status_code, 400)

    def test_my_groups_menampilkan_jumlah_anggota(self):
        group = self._create_group()
        response = self.client.get("/api/family/my-groups/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"][0]["member_count"], 1)
        self.assertTrue(FamilyGroup.objects.filter(pk=group["id"]).exists())
