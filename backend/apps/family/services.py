"""Aturan bisnis grup keluarga."""

from django.db.models import OuterRef, Subquery
from rest_framework.exceptions import PermissionDenied

from apps.family.models import FamilyGroup, FamilyMembership, SafetyStatus


def active_membership(group, user):
    return FamilyMembership.objects.filter(
        family_group=group, user=user, status=FamilyMembership.Status.ACTIVE
    ).first()


def require_member(group, user):
    membership = active_membership(group, user)
    if membership is None:
        raise PermissionDenied("Anda bukan anggota aktif grup ini.")
    return membership


def require_admin(group, user):
    membership = require_member(group, user)
    if not membership.is_group_admin:
        raise PermissionDenied("Hanya admin grup yang dapat melakukan aksi ini.")
    return membership


def active_admin_count(group):
    return FamilyMembership.objects.filter(
        family_group=group,
        status=FamilyMembership.Status.ACTIVE,
        is_group_admin=True,
    ).count()


def members_with_latest_status(group):
    latest = SafetyStatus.objects.filter(
        family_group=group, user=OuterRef("user")
    ).order_by("-created_at")

    return (
        FamilyMembership.objects.filter(
            family_group=group, status=FamilyMembership.Status.ACTIVE
        )
        .select_related("user")
        .annotate(
            latest_status=Subquery(latest.values("status")[:1]),
            latest_message=Subquery(latest.values("message")[:1]),
            latest_note=Subquery(latest.values("location_note")[:1]),
            latest_battery=Subquery(latest.values("battery_level")[:1]),
            latest_at=Subquery(latest.values("created_at")[:1]),
        )
        .order_by("joined_at")
    )


def group_by_invite_code(code):
    return FamilyGroup.objects.filter(invite_code=code.strip().upper()).first()
