from django.contrib import admin

from apps.guides.models import EmergencyContact, Guide


@admin.register(EmergencyContact)
class EmergencyContactAdmin(admin.ModelAdmin):
    list_display = (
        "name",
        "category",
        "phone_number",
        "is_verified",
        "is_active",
        "sort_order",
    )
    list_filter = ("category", "is_verified", "is_active")
    search_fields = ("name", "phone_number")
    list_editable = ("is_verified", "is_active", "sort_order")


@admin.register(Guide)
class GuideAdmin(admin.ModelAdmin):
    list_display = ("title", "disaster_type", "phase", "sort_order", "is_published")
    list_filter = ("disaster_type", "phase", "is_published")
    search_fields = ("title", "content")
