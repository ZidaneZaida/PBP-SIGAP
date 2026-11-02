from django.contrib import admin

from apps.alerts.models import Alert, Source


@admin.register(Source)
class SourceAdmin(admin.ModelAdmin):
    list_display = ("name", "source_type", "is_active", "checked_at")
    list_filter = ("source_type", "is_active")
    search_fields = ("name",)


@admin.register(Alert)
class AlertAdmin(admin.ModelAdmin):
    list_display = (
        "title",
        "disaster_type",
        "severity",
        "status",
        "is_from_bmkg",
        "published_at",
    )
    list_filter = ("disaster_type", "severity", "status", "is_from_bmkg")
    search_fields = ("title", "affected_area")
    date_hierarchy = "published_at"
    readonly_fields = ("bmkg_datetime", "created_at", "updated_at")

