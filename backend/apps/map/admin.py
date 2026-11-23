from django.contrib import admin

from apps.map.models import AssistancePoint, RiskZone


@admin.register(AssistancePoint)
class AssistancePointAdmin(admin.ModelAdmin):
    list_display = (
        "name",
        "category",
        "verification_status",
        "is_active",
        "latitude",
        "longitude",
    )
    list_filter = ("category", "verification_status", "is_active")
    search_fields = ("name", "address")
    list_editable = ("verification_status", "is_active")


@admin.register(RiskZone)
class RiskZoneAdmin(admin.ModelAdmin):
    list_display = ("name", "hazard_type", "risk_level", "updated_at")
    list_filter = ("hazard_type", "risk_level")
    search_fields = ("name", "description")
