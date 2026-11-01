"""Kontak darurat terverifikasi + panduan kesiapsiagaan."""

from django.conf import settings
from django.db import models

from apps.common.models import TimeStampedModel


class EmergencyContact(TimeStampedModel):
    class Category(models.TextChoices):
        POLICE = "police", "Polisi"
        BPBD = "bpbd", "BPBD"
        SAR = "sar", "SAR/Basarnas"
        HOSPITAL = "hospital", "Rumah Sakit"
        FIRE = "fire", "Pemadam Kebakaran"
        AMBULANCE = "ambulance", "Ambulans"
        OTHER = "other", "Lainnya"

    name = models.CharField(max_length=200)
    category = models.CharField(max_length=30, choices=Category.choices)
    phone_number = models.CharField(max_length=20)
    description = models.TextField(blank=True)
    area = models.CharField(max_length=100, default="Kota Padang")
    is_verified = models.BooleanField(default=False)
    verified_at = models.DateTimeField(null=True, blank=True)
    verified_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="contacts_verified",
    )
    is_active = models.BooleanField(default=True)
    sort_order = models.IntegerField(default=0)

    class Meta:
        db_table = "emergency_contacts"
        ordering = ["sort_order", "name"]
        verbose_name = "Kontak Darurat"
        verbose_name_plural = "Kontak Darurat"
        indexes = [models.Index(fields=["is_active", "sort_order"])]

    def __str__(self):
        return f"{self.name} ({self.phone_number})"


class Guide(TimeStampedModel):
    class DisasterType(models.TextChoices):
        EARTHQUAKE = "earthquake", "Gempa Bumi"
        TSUNAMI = "tsunami", "Tsunami"
        FLOOD = "flood", "Banjir"
        LANDSLIDE = "landslide", "Longsor"
        GENERAL = "general", "Umum"

    class Phase(models.TextChoices):
        BEFORE = "before", "Sebelum"
        DURING = "during", "Saat"
        AFTER = "after", "Sesudah"

    disaster_type = models.CharField(max_length=30, choices=DisasterType.choices)
    phase = models.CharField(max_length=20, choices=Phase.choices)
    title = models.CharField(max_length=300)
    content = models.TextField()
    icon_name = models.CharField(max_length=50, blank=True)
    reviewed_source = models.TextField(blank=True)
    reviewed_at = models.DateField(null=True, blank=True)
    sort_order = models.IntegerField(default=0)
    is_published = models.BooleanField(default=True)

    class Meta:
        db_table = "guides"
        ordering = ["disaster_type", "phase", "sort_order"]
        verbose_name = "Panduan"
        verbose_name_plural = "Panduan"
        indexes = [models.Index(fields=["disaster_type", "phase", "sort_order"])]

    def __str__(self):
        return self.title
