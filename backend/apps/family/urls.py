from django.urls import path

from apps.family.views import (
    ApproveMemberView,
    CreateGroupView,
    DeleteGroupView,
    JoinGroupView,
    LeaveGroupView,
    MembersView,
    MyGroupsView,
    PendingView,
    RegenerateInviteView,
    RejectMemberView,
    RemoveMemberView,
    SubmitStatusView,
    TransferAdminView,
)

app_name = "family"

urlpatterns = [
    path("family/groups/", CreateGroupView.as_view(), name="create"),
    path("family/my-groups/", MyGroupsView.as_view(), name="my-groups"),
    path("family/join/", JoinGroupView.as_view(), name="join"),
    path("family/groups/<uuid:group_id>/members/", MembersView.as_view(), name="members"),
    path("family/groups/<uuid:group_id>/pending/", PendingView.as_view(), name="pending"),
    path(
        "family/groups/<uuid:group_id>/members/<uuid:user_id>/approve/",
        ApproveMemberView.as_view(),
        name="approve",
    ),
    path(
        "family/groups/<uuid:group_id>/members/<uuid:user_id>/reject/",
        RejectMemberView.as_view(),
        name="reject",
    ),
    path(
        "family/groups/<uuid:group_id>/members/<uuid:user_id>/",
        RemoveMemberView.as_view(),
        name="remove-member",
    ),
    path(
        "family/groups/<uuid:group_id>/transfer-admin/",
        TransferAdminView.as_view(),
        name="transfer-admin",
    ),
    path(
        "family/groups/<uuid:group_id>/status/",
        SubmitStatusView.as_view(),
        name="status",
    ),
    path(
        "family/groups/<uuid:group_id>/regenerate-invite/",
        RegenerateInviteView.as_view(),
        name="regenerate-invite",
    ),
    path(
        "family/groups/<uuid:group_id>/leave/",
        LeaveGroupView.as_view(),
        name="leave",
    ),
    path("family/groups/<uuid:group_id>/", DeleteGroupView.as_view(), name="delete"),
]
