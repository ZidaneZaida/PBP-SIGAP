"""Model laporan kerusakan bangunan hasil SIGAP-Vision.

Laporan dibuat on-device (offline) lalu disinkronkan saat internet pulih.
Alur verifikasi: warga kirim -> petugas BPBD verifikasi -> masuk heatmap publik.
"""

from django.conf import settings
from django.db import models
from django.db.models import Q

from apps.common.models import TimeStampedModel


class DamageReport(TimeStampedModel):
    """Satu hasil pemindaian kerusakan bangunan oleh warga.

    `is_verified_by_officer` memakai tiga status lewat satu kolom:

    - ``None``  -> menunggu verifikasi petugas
    - ``True``  -> diverifikasi, boleh tampil di heatmap publik
    - ``False`` -> ditolak petugas, tidak tampil di heatmap

    `ponytail:` satu kolom nullable menggantikan tabel riwayat verifikasi;
    tambahkan model `DamageReportReview` bila BPBD butuh jejak audit per perubahan.
    """

    class DamageLevel(models.TextChoices):
        MINOR = "minor", "Ringan (Non-Struktural)"
        MODERATE = "moderate", "Sedang (Waspada Dinding)"
        CRITICAL = "critical", "Kritis (Bahaya Struktur/Kolom)"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="damage_reports",
        help_text="Warga pemilik laporan.",
    )
    client_report_id = models.CharField(
        max_length=64,
        blank=True,
        default="",
        db_index=True,
        help_text=(
            "ID laporan yang dibuat aplikasi saat offline (mis. 'vision_1730...')."
            " Dipakai agar pengiriman ulang antrean tidak membuat laporan ganda."
        ),
    )
    latitude = models.FloatField(help_text="Lintang lokasi bangunan.")
    longitude = models.FloatField(help_text="Bujur lokasi bangunan.")
    damage_level = models.CharField(
        max_length=20,
        choices=DamageLevel.choices,
        help_text="Kelas kerusakan hasil analisis on-device.",
    )
    confidence_score = models.FloatField(
        help_text="Skor kepercayaan classifier, rentang 0.0 - 1.0.",
    )
    description = models.TextField(
        blank=True,
        default="",
        help_text="Ringkasan analisis/rekomendasi yang ditampilkan ke warga.",
    )
    image_url = models.URLField(
        blank=True,
        default="",
        max_length=500,
        help_text="URL foto di object storage. Kosong bila unggahan ditunda.",
    )
    is_verified_by_officer = models.BooleanField(
        null=True,
        blank=True,
        default=None,
        help_text="Kosong = menunggu verifikasi, True = sah, False = ditolak.",
    )
    verified_at = models.DateTimeField(null=True, blank=True)
    verified_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="verified_damage_reports",
    )

    class Meta:
        db_table = "damage_reports"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["user", "-created_at"], name="idx_dmg_user_created"),
            models.Index(fields=["-created_at"], name="idx_dmg_created"),
            models.Index(fields=["is_verified_by_officer"], name="idx_dmg_verified"),
        ]
        constraints = [
            # Retry antrean offline tidak boleh menghasilkan laporan ganda.
            models.UniqueConstraint(
                fields=["user", "client_report_id"],
                condition=~Q(client_report_id=""),
                name="uniq_dmg_user_client_report",
            ),
        ]
        verbose_name = "Laporan Kerusakan"
        verbose_name_plural = "Laporan Kerusakan"

    def __str__(self):
        return f"{self.get_damage_level_display()} @ {self.latitude:.4f},{self.longitude:.4f}"
