"""Pengiriman push notification via FCM. Gagal kirim tidak boleh menggagalkan request."""

import json
import logging

from django.conf import settings

from apps.accounts.models import DeviceToken

logger = logging.getLogger(__name__)

_app = None
_initialized = False


def _firebase_app():
    global _app, _initialized
    if _initialized:
        return _app
    _initialized = True

    raw = settings.FIREBASE_CREDENTIALS_JSON
    if not raw:
        logger.info("FCM dilewati: FIREBASE_CREDENTIALS_JSON kosong")
        return None

    try:
        import firebase_admin
        from firebase_admin import credentials

        if not firebase_admin._apps:
            firebase_admin.initialize_app(credentials.Certificate(json.loads(raw)))
        _app = firebase_admin.get_app()
    except Exception:
        logger.exception("Inisialisasi Firebase gagal")
        _app = None
    return _app


def send_to_tokens(tokens, title, body, data=None):
    """Kirim ke daftar token. Mengembalikan jumlah yang berhasil."""
    tokens = [t for t in tokens if t]
    if not tokens:
        return 0
    if _firebase_app() is None:
        return 0

    try:
        from firebase_admin import messaging

        message = messaging.MulticastMessage(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
            tokens=tokens,
        )
        response = messaging.send_each_for_multicast(message)
        _cleanup(tokens, response)
        return response.success_count
    except Exception:
        logger.exception("Pengiriman FCM gagal")
        return 0


def _cleanup(tokens, response):
    dead = []
    for token, result in zip(tokens, response.responses, strict=False):
        if result.exception and "registration-token-not-registered" in str(result.exception):
            dead.append(token)
    if dead:
        DeviceToken.objects.filter(fcm_token__in=dead).delete()


def send_to_users(users, title, body, data=None, preference="alert_enabled"):
    tokens = list(
        DeviceToken.objects.filter(user__in=users).values_list("fcm_token", flat=True)
    )
    return send_to_tokens(tokens, title, body, data)


def send_to_group(group, title, body, data=None, exclude_user=None):
    from apps.family.models import FamilyMembership

    members = FamilyMembership.objects.filter(
        family_group=group, status=FamilyMembership.Status.ACTIVE
    ).select_related("user")
    if exclude_user is not None:
        members = members.exclude(user=exclude_user)

    users = [m.user for m in members if m.user.profile.family_enabled]
    return send_to_users(users, title, body, data)
