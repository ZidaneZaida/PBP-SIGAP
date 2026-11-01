"""Layanan akun: email reset password + upload foto Supabase."""

import logging
import uuid

import requests
from django.conf import settings
from django.contrib.auth.tokens import default_token_generator
from django.core.mail import send_mail
from django.utils.encoding import force_bytes
from django.utils.http import urlsafe_base64_encode
from rest_framework.exceptions import ValidationError

logger = logging.getLogger(__name__)

MAX_PHOTO_BYTES = 5 * 1024 * 1024
ALLOWED_PHOTO_TYPES = {"image/jpeg": "jpg", "image/png": "png"}


def build_reset_link(user):
    uid = urlsafe_base64_encode(force_bytes(user.pk))
    token = default_token_generator.make_token(user)
    base = settings.FRONTEND_BASE_URL.rstrip("/")
    return f"{base}/reset-password?uid={uid}&token={token}"


def send_password_reset_email(user):
    link = build_reset_link(user)
    send_mail(
        subject="Reset kata sandi SIGAP",
        message=(
            f"Halo {user.full_name},\n\n"
            f"Klik tautan berikut untuk mengatur ulang kata sandi:\n{link}\n\n"
            "Abaikan email ini bila Anda tidak meminta reset kata sandi."
        ),
        from_email=None,
        recipient_list=[user.email],
        fail_silently=True,
    )


def upload_avatar(user, uploaded_file):
    if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_KEY:
        raise ValidationError("Penyimpanan foto belum dikonfigurasi.")

    content_type = uploaded_file.content_type
    if content_type not in ALLOWED_PHOTO_TYPES:
        raise ValidationError({"photo": ["Format harus JPEG atau PNG."]})
    if uploaded_file.size > MAX_PHOTO_BYTES:
        raise ValidationError({"photo": ["Ukuran maksimum 5 MB."]})

    ext = ALLOWED_PHOTO_TYPES[content_type]
    path = f"{user.id}-{uuid.uuid4().hex[:8]}.{ext}"
    bucket = settings.SUPABASE_BUCKET_AVATARS
    url = f"{settings.SUPABASE_URL.rstrip('/')}/storage/v1/object/{bucket}/{path}"

    response = requests.post(
        url,
        headers={
            "Authorization": f"Bearer {settings.SUPABASE_SERVICE_KEY}",
            "Content-Type": content_type,
            "x-upsert": "true",
        },
        data=uploaded_file.read(),
        timeout=15,
    )
    if response.status_code >= 400:
        logger.error("Upload avatar gagal: %s %s", response.status_code, response.text[:200])
        raise ValidationError("Gagal mengunggah foto. Coba lagi.")

    return f"{settings.SUPABASE_URL.rstrip('/')}/storage/v1/object/public/{bucket}/{path}"
