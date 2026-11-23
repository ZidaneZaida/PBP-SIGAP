"""Endpoint agregat untuk layar dashboard."""

import logging

from rest_framework.permissions import AllowAny
from rest_framework.views import APIView

from apps.common.responses import ok

logger = logging.getLogger(__name__)


class DashboardView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        from django.utils import timezone

        from apps.family.models import FamilyMembership, SafetyStatus
        from apps.map.models import AssistancePoint
        from apps.news.models import NewsArticle

        alert_data = None
        try:
            from apps.alerts.serializers import AlertListSerializer
            from apps.alerts.services import latest_active_alert, sync_bmkg_alerts

            sync_bmkg_alerts()
            alert = latest_active_alert()
            if alert:
                alert_data = AlertListSerializer(alert).data
        except Exception:
            logger.exception("Dashboard: gagal memuat alert")

        news = (
            NewsArticle.objects.filter(is_published=True)
            .order_by("-published_at")[:3]
            .values("id", "title", "category", "published_at")
        )

        family_summary = None
        user = request.user
        if getattr(user, "is_authenticated", False):
            membership = (
                FamilyMembership.objects.filter(
                    user=user, status=FamilyMembership.Status.ACTIVE
                )
                .select_related("family_group")
                .first()
            )
            if membership:
                group = membership.family_group
                active = FamilyMembership.objects.filter(
                    family_group=group, status=FamilyMembership.Status.ACTIVE
                )
                latest = {
                    row["user"]: row["status"]
                    for row in SafetyStatus.objects.filter(family_group=group)
                    .order_by("user", "-created_at")
                    .values("user", "status")
                    .distinct("user")
                }
                family_summary = {
                    "group_id": str(group.id),
                    "group_name": group.name,
                    "active_members": active.count(),
                    "safe": sum(1 for v in latest.values() if v == "safe"),
                    "need_help": sum(1 for v in latest.values() if v == "need_help"),
                    "no_report": max(0, active.count() - len(latest)),
                }

        return ok(
            {
                "alert": alert_data,
                "news": list(news),
                "family_summary": family_summary,
                "assistance_point_count": AssistancePoint.objects.filter(
                    is_active=True, verification_status="verified"
                ).count(),
                "generated_at": timezone.now(),
            }
        )
