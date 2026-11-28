from django.apps import AppConfig


class DamageAssessmentConfig(AppConfig):
    """Modul penilaian kerusakan bangunan pasca-gempa (SIGAP-Vision).

    Dipisahkan dari `apps.alerts` karena bounded context berbeda:
    `alerts` mengelola data seismik BMKG yang read-heavy, sedangkan modul ini
    menerima laporan warga yang write-heavy dan diagregasi untuk heatmap.
    """

    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.damage_assessment"
    verbose_name = "Penilaian Kerusakan Bangunan"
