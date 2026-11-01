from rest_framework.permissions import BasePermission

OFFICER_ROLES = {"officer", "superadmin"}
EDITOR_ROLES = {"editor", "superadmin"}


class _RolePermission(BasePermission):
    roles: set[str] = set()

    def has_permission(self, request, view):
        user = request.user
        return bool(user and user.is_authenticated and user.role in self.roles)


class IsOfficer(_RolePermission):
    roles = OFFICER_ROLES


class IsEditor(_RolePermission):
    roles = EDITOR_ROLES


class IsSuperAdmin(_RolePermission):
    roles = {"superadmin"}