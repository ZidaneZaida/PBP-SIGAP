"""Peringatan bencana: sumber metadata + alert (BMKG / manual petugas)."""

from django.conf import settings
from django.db import models

from apps.common.models import TimeStampedModel


class Source(TimeStampedModel):
    class SourceType(models.TextChoices):
        GOVERNMENT_API = "government_api", "API Pemerintah"
        GOVERNMENT_MANUAL = "government_manual", "Input Petugas"
        VERIFIED_MEDIA = "verified_media", "Media Terverifikasi"

    name = models.CharField(max_length=200, unique=True)
    source_url = models.TextField(blank=True)
    source_type = models.CharField(max_length=30, choices=SourceType.choices)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    checked_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "sources"
        ordering = ["name"]
        verbose_name = "Sumber Data"
        verbose_name_plural = "Sumber Data"

    def __str__(self):
        return self.name


class Alert(TimeStampedModel):
    class DisasterType(models.TextChoices):
        EARTHQUAKE = "earthquake", "Gempa Bumi"
        TSUNAMI = "tsunami", "Tsunami"
        FLOOD = "flood", "Banjir"
        LANDSLIDE = "landslide", "Longsor"
        EXTREME_WEATHER = "extreme_weather", "Cuaca Ekstrem"

    class Severity(models.TextChoices):
        WASPADA = "waspada", "Waspada"
        SIAGA = "siaga", "Siaga"
        AWAS = "awas", "Awas"

    class Status(models.TextChoices):
        ACTIVE = "active", "Aktif"
        EXPIRED = "expired", "Kedaluwarsa"
        CANCELLED = "cancelled", "Dibatalkan"

    source = models.ForeignKey(
        Source, null=True, blank=True, on_delete=models.SET_NULL, related_name="alerts"
    )
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="alerts_created",
    )
    disaster_type = models.CharField(max_length=30, choices=DisasterType.choices)
    title = models.CharField(max_length=300)
    description = models.TextField(blank=True)
    severity = models.CharField(
        max_length=20, choices=Severity.choices, null=True, blank=True
    )
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)
    affected_area = models.CharField(max_length=300)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    depth_km = models.SmallIntegerField(null=True, blank=True)
    magnitude = models.FloatField(null=True, blank=True)
    felt_description = models.CharField(max_length=300, blank=True)
    source_reference_url = models.TextField(blank=True)
    published_at = models.DateTimeField()
    expires_at = models.DateTimeField(null=True, blank=True)
    bmkg_datetime = models.DateTimeField(null=True, blank=True)
    is_from_bmkg = models.BooleanField(default=False)

    class Meta:
        db_table = "alerts"
        ordering = ["-published_at"]
        verbose_name = "Peringatan"
        verbose_name_plural = "Peringatan"
        constraints = [
            models.UniqueConstraint(
                fields=["source", "bmkg_datetime"], name="uniq_alert_bmkg"
            )
        ]
        indexes = [
            models.Index(fields=["status"]),
            models.Index(fields=["disaster_type"]),
            models.Index(fields=["-published_at"]),
        ]

    def __str__(self):
        return self.title
