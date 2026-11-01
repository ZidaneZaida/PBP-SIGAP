"""Grup keluarga, keanggotaan (dengan approval), dan status keselamatan."""

import secrets
import uuid
from datetime import timedelta

from django.conf import settings
from django.db import models
from django.utils import timezone

from apps.common.models import TimeStampedModel

INVITE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
INVITE_LENGTH = 8
INVITE_TTL_HOURS = 24


def generate_invite_code():
    return "".join(secrets.choice(INVITE_ALPHABET) for _ in range(INVITE_LENGTH))


class FamilyGroup(TimeStampedModel):
    name = models.CharField(max_length=150)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="family_groups"
    )
    invite_code = models.CharField(max_length=INVITE_LENGTH, unique=True)
    invite_code_expires_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "family_groups"
        verbose_name = "Grup Keluarga"
        verbose_name_plural = "Grup Keluarga"

    def __str__(self):
        return self.name

    def save(self, *args, **kwargs):
        if not self.invite_code:
            self.invite_code = self._unique_code()
        if not self.invite_code_expires_at:
            self.invite_code_expires_at = timezone.now() + timedelta(hours=INVITE_TTL_HOURS)
        super().save(*args, **kwargs)

    def _unique_code(self):
        for _ in range(20):
            code = generate_invite_code()
            if not FamilyGroup.objects.filter(invite_code=code).exists():
                return code
        raise RuntimeError("Gagal membuat kode undangan unik")

    @property
    def is_invite_valid(self):
        return bool(self.invite_code_expires_at and self.invite_code_expires_at > timezone.now())

    def regenerate_invite(self):
        self.invite_code = self._unique_code()
        self.invite_code_expires_at = timezone.now() + timedelta(hours=INVITE_TTL_HOURS)
        self.save(update_fields=["invite_code", "invite_code_expires_at", "updated_at"])


class FamilyMembership(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending", "Menunggu Persetujuan"
        ACTIVE = "active", "Aktif"
        REJECTED = "rejected", "Ditolak"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    family_group = models.ForeignKey(
        FamilyGroup, on_delete=models.CASCADE, related_name="memberships"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="family_memberships"
    )
    is_group_admin = models.BooleanField(default=False)
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.PENDING
    )
    requested_at = models.DateTimeField(auto_now_add=True)
    joined_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "family_memberships"
        ordering = ["requested_at"]
        verbose_name = "Keanggotaan Keluarga"
        verbose_name_plural = "Keanggotaan Keluarga"
        constraints = [
            models.UniqueConstraint(
                fields=["family_group", "user"], name="uniq_group_member"
            )
        ]
        indexes = [
            models.Index(fields=["family_group", "status"]),
            models.Index(fields=["user", "status"]),
        ]

    def approve(self):
        self.status = self.Status.ACTIVE
        self.joined_at = timezone.now()
        self.save(update_fields=["status", "joined_at"])

    def __str__(self):
        return f"{self.user_id} @ {self.family_group_id}"


class SafetyStatus(models.Model):
    class Value(models.TextChoices):
        SAFE = "safe", "Aman"
        NEED_HELP = "need_help", "Butuh Bantuan"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    family_group = models.ForeignKey(
        FamilyGroup, on_delete=models.CASCADE, related_name="safety_statuses"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="safety_statuses"
    )
    status = models.CharField(max_length=20, choices=Value.choices)
    message = models.TextField(blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    location_note = models.TextField(blank=True)
    battery_level = models.SmallIntegerField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "safety_statuses"
        ordering = ["-created_at"]
        verbose_name = "Status Keselamatan"
        verbose_name_plural = "Status Keselamatan"
        constraints = [
            models.CheckConstraint(
                condition=models.Q(battery_level__gte=0, battery_level__lte=100)
                | models.Q(battery_level__isnull=True),
                name="battery_level_range",
            )
        ]
        indexes = [
            models.Index(fields=["family_group", "user", "-created_at"]),
        ]

    def __str__(self):
        return f"{self.user_id} {self.status}"
