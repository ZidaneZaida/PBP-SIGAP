"""Pencatatan audit trail untuk aksi petugas/editor."""

import logging

from apps.common.models import AuditLog

logger = logging.getLogger(__name__)


def client_ip(request):
    forwarded = request.META.get("HTTP_X_FORWARDED_FOR")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.META.get("REMOTE_ADDR")


def log_action(request, action, instance=None, *, entity_type="", details=None):
    actor = request.user if getattr(request.user, "is_authenticated", False) else None
    try:
        AuditLog.objects.create(
            actor=actor,
            action=action,
            entity_type=entity_type or (instance._meta.label_lower if instance else ""),
            entity_id=getattr(instance, "id", None),
            details=details,
            ip_address=client_ip(request),
        )
    except Exception:
        logger.exception("Gagal mencatat audit log: %s", action)
