"""Titik bantuan & zona risiko. Tanpa PostGIS: koordinat float + GeoJSON."""

from django.db import models

from apps.common.models import TimeStampedModel


class AssistancePoint(TimeStampedModel):
    class Category(models.TextChoices):
        EVACUATION_POINT = "evacuation_point", "Titik Evakuasi"
        EMERGENCY_POST = "emergency_post", "Posko Darurat"
        HOSPITAL = "hospital", "Rumah Sakit"
        HEALTH_CENTER = "health_center", "Puskesmas"
        RELIEF_POINT = "relief_point", "Pos Bantuan"

    class Verification(models.TextChoices):
        VERIFIED = "verified", "Terverifikasi"
        UNVERIFIED = "unverified", "Belum Terverifikasi"
        OUTDATED = "outdated", "Data Usang"

    source = models.ForeignKey(
        "alerts.Source",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="assistance_points",
    )
    name = models.CharField(max_length=300)
    category = models.CharField(max_length=30, choices=Category.choices)
    address = models.TextField(blank=True)
    latitude = models.FloatField()
    longitude = models.FloatField()
    phone = models.CharField(max_length=20, blank=True)
    operational_hours = models.CharField(max_length=100, blank=True)
    capacity = models.IntegerField(null=True, blank=True)
    verification_status = models.CharField(
        max_length=20, choices=Verification.choices, default=Verification.UNVERIFIED
    )
    verified_at = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    notes = models.TextField(blank=True)

    class Meta:
        db_table = "assistance_points"
        ordering = ["name"]
        verbose_name = "Titik Bantuan"
        verbose_name_plural = "Titik Bantuan"
        indexes = [
            models.Index(fields=["is_active", "category"]),
            models.Index(fields=["latitude", "longitude"]),
            models.Index(fields=["verification_status"]),
        ]

    def __str__(self):
        return self.name


class RiskZone(TimeStampedModel):
    class HazardType(models.TextChoices):
        EARTHQUAKE = "earthquake", "Gempa Bumi"
        TSUNAMI = "tsunami", "Tsunami"
        FLOOD = "flood", "Banjir"
        LANDSLIDE = "landslide", "Longsor"

    class RiskLevel(models.TextChoices):
        LOW = "low", "Rendah"
        MEDIUM = "medium", "Sedang"
        HIGH = "high", "Tinggi"
        VERY_HIGH = "very_high", "Sangat Tinggi"

    source = models.ForeignKey(
        "alerts.Source",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="risk_zones",
    )
    name = models.CharField(max_length=200)
    hazard_type = models.CharField(max_length=30, choices=HazardType.choices)
    risk_level = models.CharField(max_length=20, choices=RiskLevel.choices)
    geojson = models.JSONField()
    description = models.TextField(blank=True)
    source_notes = models.TextField(blank=True)

    class Meta:
        db_table = "risk_zones"
        ordering = ["name"]
        verbose_name = "Zona Risiko"
        verbose_name_plural = "Zona Risiko"
        indexes = [models.Index(fields=["hazard_type"])]

    def __str__(self):
        return self.name
