from django.contrib import admin

from apps.family.models import FamilyGroup, FamilyMembership, SafetyStatus


class MembershipInline(admin.TabularInline):
    model = FamilyMembership
    extra = 0
    readonly_fields = ("requested_at", "joined_at")


@admin.register(FamilyGroup)
class FamilyGroupAdmin(admin.ModelAdmin):
    list_display = ("name", "created_by", "invite_code", "invite_code_expires_at")
    search_fields = ("name", "invite_code", "created_by__email")
    inlines = [MembershipInline]


@admin.register(FamilyMembership)
class FamilyMembershipAdmin(admin.ModelAdmin):
    list_display = ("user", "family_group", "status", "is_group_admin", "joined_at")
    list_filter = ("status", "is_group_admin")
    search_fields = ("user__email", "family_group__name")


@admin.register(SafetyStatus)
class SafetyStatusAdmin(admin.ModelAdmin):
    list_display = ("user", "family_group", "status", "battery_level", "created_at")
    list_filter = ("status",)
    search_fields = ("user__email", "family_group__name")
    date_hierarchy = "created_at"
