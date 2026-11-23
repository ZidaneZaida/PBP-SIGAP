from django.urls import path

from apps.accounts.views import (
    DeviceTokenView,
    LoginView,
    LogoutView,
    MeView,
    PasswordChangeView,
    PasswordResetConfirmView,
    PasswordResetRequestView,
    PreferencesView,
    RefreshView,
    RegisterView,
    UploadPhotoView,
)

app_name = "accounts"

urlpatterns = [
    path("auth/register/", RegisterView.as_view(), name="register"),
    path("auth/login/", LoginView.as_view(), name="login"),
    path("auth/token/refresh/", RefreshView.as_view(), name="token-refresh"),
    path("auth/logout/", LogoutView.as_view(), name="logout"),
    path("auth/password/reset/", PasswordResetRequestView.as_view(), name="password-reset"),
    path(
        "auth/password/reset/confirm/",
        PasswordResetConfirmView.as_view(),
        name="password-reset-confirm",
    ),
    path(
        "auth/password/change/",
        PasswordChangeView.as_view(),
        name="password-change",
    ),
    path("me/", MeView.as_view(), name="me"),
    path("me/upload-photo/", UploadPhotoView.as_view(), name="me-upload-photo"),
    path("me/preferences/", PreferencesView.as_view(), name="me-preferences"),
    path("me/device-token/", DeviceTokenView.as_view(), name="me-device-token"),
]
