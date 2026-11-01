"""Endpoint grup keluarga & status keselamatan."""

from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import NotFound, ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from apps.common.responses import ok
from apps.family.models import FamilyGroup, FamilyMembership, SafetyStatus
from apps.family.serializers import (
    FamilyGroupSerializer,
    JoinGroupSerializer,
    SafetyStatusWriteSerializer,
    TransferAdminSerializer,
    member_payload,
)
from apps.family.services import (
    active_admin_count,
    active_membership,
    group_by_invite_code,
    members_with_latest_status,
    require_admin,
    require_member,
)
from apps.notifications import fcm


def _get_group(pk):
    group = FamilyGroup.objects.filter(pk=pk).first()
    if group is None:
        raise NotFound("Grup keluarga tidak ditemukan.")
    return group


def _get_membership(group, user_id):
    membership = FamilyMembership.objects.filter(
        family_group=group, user_id=user_id
    ).first()
    if membership is None:
        raise NotFound("Anggota tidak ditemukan di grup ini.")
    return membership


class CreateGroupView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = FamilyGroupSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        with transaction.atomic():
            group = serializer.save(created_by=request.user)
            FamilyMembership.objects.create(
                family_group=group,
                user=request.user,
                is_group_admin=True,
                status=FamilyMembership.Status.ACTIVE,
                joined_at=timezone.now(),
            )

        data = FamilyGroupSerializer(group).data
        data["is_group_admin"] = True
        return ok(data, "Grup keluarga dibuat", 201)


class MyGroupsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        memberships = (
            FamilyMembership.objects.filter(user=request.user)
            .select_related("family_group")
            .order_by("requested_at")
        )

        results = []
        for membership in memberships:
            group = membership.family_group
            results.append(
                {
                    "id": str(group.id),
                    "name": group.name,
                    "is_group_admin": membership.is_group_admin,
                    "status": membership.status,
                    "member_count": group.memberships.filter(
                        status=FamilyMembership.Status.ACTIVE
                    ).count(),
                    "pending_count": group.memberships.filter(
                        status=FamilyMembership.Status.PENDING
                    ).count(),
                    "need_help_count": SafetyStatus.objects.filter(
                        family_group=group, status=SafetyStatus.Value.NEED_HELP
                    ).values("user").distinct().count(),
                }
            )
        return ok(results)


class JoinGroupView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = JoinGroupSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        group = group_by_invite_code(serializer.validated_data["invite_code"])
        if group is None or not group.is_invite_valid:
            raise ValidationError(
                {"invite_code": "Kode undangan tidak valid atau sudah kedaluwarsa."}
            )

        existing = active_membership(group, request.user)
        if existing:
            raise ValidationError({"invite_code": "Anda sudah menjadi anggota grup ini."})

        membership, created = FamilyMembership.objects.get_or_create(
            family_group=group,
            user=request.user,
            defaults={"status": FamilyMembership.Status.PENDING},
        )
        if not created and membership.status == FamilyMembership.Status.PENDING:
            return ok(
                {"family_group": {"id": str(group.id), "name": group.name},
                 "status": membership.status,
                 "requested_at": membership.requested_at},
                "Permintaan sebelumnya masih menunggu persetujuan.",
            )
        if not created:
            membership.status = FamilyMembership.Status.PENDING
            membership.requested_at = timezone.now()
            membership.save(update_fields=["status", "requested_at"])

        return ok(
            {
                "family_group": {"id": str(group.id), "name": group.name},
                "status": membership.status,
                "requested_at": membership.requested_at,
            },
            "Permintaan bergabung dikirim. Menunggu persetujuan admin grup.",
        )


class MembersView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, group_id):
        group = _get_group(group_id)
        require_member(group, request.user)
        members = [member_payload(m) for m in members_with_latest_status(group)]
        return ok({"group": {"id": str(group.id), "name": group.name}, "members": members})


class PendingView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, group_id):
        group = _get_group(group_id)
        require_admin(group, request.user)
        rows = FamilyMembership.objects.filter(
            family_group=group, status=FamilyMembership.Status.PENDING
        ).select_related("user")
        return ok(
            [
                {
                    "user_id": str(row.user_id),
                    "full_name": row.user.full_name,
                    "email": row.user.email,
                    "requested_at": row.requested_at,
                }
                for row in rows
            ]
        )


class ApproveMemberView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, group_id, user_id):
        group = _get_group(group_id)
        require_admin(group, request.user)
        membership = _get_membership(group, user_id)
        membership.approve()
        fcm.send_to_users(
            [membership.user],
            "Permintaan bergabung disetujui",
            f"Anda kini anggota grup {group.name}.",
            {"type": "family_join", "group_id": str(group.id)},
        )
        return ok(message="Anggota disetujui")


class RejectMemberView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, group_id, user_id):
        group = _get_group(group_id)
        require_admin(group, request.user)
        membership = _get_membership(group, user_id)
        if membership.is_group_admin and active_admin_count(group) <= 1:
            raise ValidationError({"detail": "Admin terakhir tidak dapat ditolak."})
        membership.status = FamilyMembership.Status.REJECTED
        membership.is_group_admin = False
        membership.save(update_fields=["status", "is_group_admin"])
        return ok(message="Permintaan ditolak")


class RemoveMemberView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, group_id, user_id):
        group = _get_group(group_id)
        require_admin(group, request.user)
        membership = _get_membership(group, user_id)
        if membership.is_group_admin and active_admin_count(group) <= 1:
            raise ValidationError(
                {"detail": "Admin terakhir tidak dapat dikeluarkan."}, code="last_admin"
            )
        membership.delete()
        return ok(message="Anggota dikeluarkan")


class TransferAdminView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, group_id):
        group = _get_group(group_id)
        current = require_admin(group, request.user)
        serializer = TransferAdminSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        target = _get_membership(group, serializer.validated_data["user_id"])
        if target.status != FamilyMembership.Status.ACTIVE:
            raise ValidationError({"user_id": "Anggota belum aktif."})

        with transaction.atomic():
            current.is_group_admin = False
            current.save(update_fields=["is_group_admin"])
            target.is_group_admin = True
            target.save(update_fields=["is_group_admin"])
        return ok(message="Status admin dipindahkan")


class SubmitStatusView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, group_id):
        group = _get_group(group_id)
        require_member(group, request.user)

        serializer = SafetyStatusWriteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        share = data.get("share_location", False)

        status = SafetyStatus.objects.create(
            family_group=group,
            user=request.user,
            status=data["status"],
            message=data.get("message", ""),
            location_note=data.get("location_note", ""),
            latitude=data.get("latitude") if share else None,
            longitude=data.get("longitude") if share else None,
            battery_level=data.get("battery_level"),
        )

        fcm.send_to_group(
            group,
            f"Status {request.user.full_name}",
            "Aman" if status.status == SafetyStatus.Value.SAFE else "Butuh bantuan",
            {"type": "family_status", "group_id": str(group.id)},
            exclude_user=request.user,
        )

        return ok(
            {
                "id": str(status.id),
                "status": status.status,
                "message": status.message,
                "location_shared": share,
                "created_at": status.created_at,
            },
            "Status keselamatan terkirim",
            201,
        )


class RegenerateInviteView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, group_id):
        group = _get_group(group_id)
        require_admin(group, request.user)
        if group.invite_code_expires_at:
            remaining = group.invite_code_expires_at - timezone.now()
            if remaining.total_seconds() > 12 * 3600:
                raise ValidationError(
                    {"detail": "Kode sebelumnya masih berlaku lebih dari 12 jam."}
                )
        group.regenerate_invite()
        return ok(
            {
                "invite_code": group.invite_code,
                "invite_code_expires_at": group.invite_code_expires_at,
            }
        )


class LeaveGroupView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, group_id):
        group = _get_group(group_id)
        membership = require_member(group, request.user)
        if membership.is_group_admin and active_admin_count(group) <= 1:
            raise ValidationError(
                {"detail": "Admin terakhir tidak dapat keluar sebelum memindahkan status admin."},
                code="last_admin",
            )
        membership.delete()
        return ok(message="Anda keluar dari grup")


class DeleteGroupView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, group_id):
        group = _get_group(group_id)
        require_admin(group, request.user)
        group.delete()
        return ok(message="Grup keluarga dihapus")
