"""Admin laporan kerusakan bangunan."""

from django.contrib import admin

from apps.damage_assessment.models import DamageReport


@admin.register(DamageReport)
class DamageReportAdmin(admin.ModelAdmin):
    """Panel verifikasi cepat untuk petugas BPBD.

    `list_editable` sengaja tidak dipakai: verifikasi harus lewat endpoint
    teraudit agar tercatat siapa yang menyetujui dan kapan.
    """

    list_display = (
        "id",
        "damage_level",
        "user",
        "latitude",
        "longitude",
        "is_verified_by_officer",
        "created_at",
    )
    list_filter = ("damage_level", "is_verified_by_officer", "created_at")
    search_fields = ("user__email", "user__full_name", "description")
    readonly_fields = ("id", "created_at", "updated_at", "verified_at", "verified_by")
    autocomplete_fields = ("user",)
    date_hierarchy = "created_at"
