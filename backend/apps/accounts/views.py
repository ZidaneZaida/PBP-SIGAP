"""Endpoint autentikasi & profil."""

import uuid as uuid_lib

from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView

from apps.accounts.models import DeviceToken, UserProfile
from apps.accounts.serializers import (
    ChangePasswordSerializer,
    DeviceTokenSerializer,
    LoginSerializer,
    MeUpdateSerializer,
    PasswordResetConfirmSerializer,
    PasswordResetRequestSerializer,
    PreferencesSerializer,
    RegisterSerializer,
    UserSerializer,
)
from apps.accounts.services import send_password_reset_email, upload_avatar
from apps.common.responses import ok
from apps.common.throttling import FlexibleScopedRateThrottle


def _tokens_for(user):
    refresh = RefreshToken.for_user(user)
    return {"access": str(refresh.access_token), "refresh": str(refresh)}


def _auth_payload(user):
    return {"user": UserSerializer(user).data, "tokens": _tokens_for(user)}


class RegisterView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [FlexibleScopedRateThrottle]
    throttle_scope = "register"

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return ok(_auth_payload(user), "Akun berhasil dibuat", status_code=201)


class LoginView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [FlexibleScopedRateThrottle]
    throttle_scope = "login"

    def post(self, request):
        serializer = LoginSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        return ok(_auth_payload(serializer.validated_data["user"]))


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        token = request.data.get("refresh")
        if token:
            try:
                RefreshToken(token).blacklist()
            except Exception:
                pass
        return ok(message="Logout berhasil")


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return ok(UserSerializer(request.user).data)

    def patch(self, request):
        serializer = MeUpdateSerializer(
            instance=request.user, data=request.data, partial=True
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return ok(UserSerializer(request.user).data, "Profil diperbarui")

    def delete(self, request):
        user = request.user
        ua, _ = UserProfile.objects.get_or_create(user=user)
        if ua.photo_url:
            ua.photo_url = ""
            ua.save(update_fields=["photo_url"])

        user.device_tokens.all().delete()
        user.email = f"deleted-{uuid_lib.uuid4().hex}@sigap.invalid"
        user.full_name = "Pengguna Dihapus"
        user.is_active = False
        user.set_unusable_password()
        user.save(update_fields=["email", "full_name", "is_active", "password"])
        return ok(message="Akun dihapus")


class UploadPhotoView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        file = request.FILES.get("photo")
        if not file:
            return ok(message="Field 'photo' wajib diisi.", status_code=400)
        url = upload_avatar(request.user, file)
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        profile.photo_url = url
        profile.save(update_fields=["photo_url"])
        return ok({"photo_url": url})


class PreferencesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        return ok(PreferencesSerializer(profile).data)

    def patch(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        serializer = PreferencesSerializer(profile, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return ok(serializer.data, "Preferensi disimpan")


class DeviceTokenView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = DeviceTokenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        DeviceToken.objects.update_or_create(
            fcm_token=serializer.validated_data["fcm_token"],
            defaults={
                "user": request.user,
                "platform": serializer.validated_data["platform"],
            },
        )
        return ok(message="Token perangkat terdaftar", status_code=201)

    def delete(self, request):
        token = request.data.get("fcm_token")
        if token:
            DeviceToken.objects.filter(user=request.user, fcm_token=token).delete()
        return ok(message="Token perangkat dihapus")


class PasswordResetRequestView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [FlexibleScopedRateThrottle]
    throttle_scope = "password_reset"

    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        from apps.accounts.models import User

        user = User.objects.filter(
            email=serializer.validated_data["email"].lower(), is_active=True
        ).first()
        if user:
            send_password_reset_email(user)
        return ok(message="Jika email terdaftar, tautan reset telah dikirim.")


class PasswordResetConfirmView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return ok(message="Kata sandi berhasil diubah")


class PasswordChangeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(
            data=request.data, context={"request": request}
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return ok(message="Kata sandi diperbarui")


class RefreshView(TokenRefreshView):
    permission_classes = [AllowAny]
