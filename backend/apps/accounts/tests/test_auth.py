from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import User


class AuthFlowTest(TestCase):
    def setUp(self):
        self.client = APIClient()

    def _register(self, email="warga@example.com", password="Password123"):
        return self.client.post(
            "/api/auth/register/",
            {
                "email": email,
                "full_name": "Budi Santoso",
                "password": password,
                "password_confirm": password,
            },
            format="json",
        )

    def test_register_membuat_profil_dan_token(self):
        response = self._register()
        self.assertEqual(response.status_code, 201, response.content)
        body = response.json()
        self.assertEqual(body["status"], "success")
        self.assertIn("access", body["data"]["tokens"])
        self.assertEqual(body["data"]["user"]["role"], "citizen")

        user = User.objects.get(email="warga@example.com")
        self.assertTrue(hasattr(user, "profile"))
        self.assertNotEqual(user.password, "Password123")

    def test_email_duplikat_ditolak(self):
        self._register()
        response = self._register()
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["code"], "VALIDATION_ERROR")

    def test_konfirmasi_password_beda_ditolak(self):
        response = self.client.post(
            "/api/auth/register/",
            {
                "email": "lain@example.com",
                "full_name": "Siti",
                "password": "Password123",
                "password_confirm": "Password124",
            },
            format="json",
        )
        self.assertEqual(response.status_code, 400)

    def test_password_lemah_ditolak(self):
        response = self._register(password="password")
        self.assertEqual(response.status_code, 400)

    def test_login_me_dan_logout(self):
        self._register()
        login = self.client.post(
            "/api/auth/login/",
            {"email": "warga@example.com", "password": "Password123"},
            format="json",
        )
        self.assertEqual(login.status_code, 200, login.content)
        tokens = login.json()["data"]["tokens"]

        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {tokens['access']}")
        me = self.client.get("/api/me/")
        self.assertEqual(me.status_code, 200)
        self.assertEqual(me.json()["data"]["email"], "warga@example.com")

        logout = self.client.post(
            "/api/auth/logout/", {"refresh": tokens["refresh"]}, format="json"
        )
        self.assertEqual(logout.status_code, 200)

    def test_login_password_salah_ditolak(self):
        self._register()
        response = self.client.post(
            "/api/auth/login/",
            {"email": "warga@example.com", "password": "SalahBanget1"},
            format="json",
        )
        self.assertEqual(response.status_code, 401)

    def test_me_tanpa_token_401(self):
        self.assertEqual(self.client.get("/api/me/").status_code, 401)

    def test_patch_me_dan_preferensi(self):
        self._register()
        login = self.client.post(
            "/api/auth/login/",
            {"email": "warga@example.com", "password": "Password123"},
            format="json",
        )
        access = login.json()["data"]["tokens"]["access"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")

        patch = self.client.patch(
            "/api/me/",
            {"full_name": "Budi Baru", "profile": {"phone": "08123456789"}},
            format="json",
        )
        self.assertEqual(patch.status_code, 200, patch.content)
        self.assertEqual(patch.json()["data"]["full_name"], "Budi Baru")

        pref = self.client.patch(
            "/api/me/preferences/", {"news_enabled": False}, format="json"
        )
        self.assertEqual(pref.status_code, 200)
        self.assertFalse(pref.json()["data"]["news_enabled"])
