"""Endpoint peringatan bencana."""

import logging

from django.utils import timezone
from django.utils.dateparse import parse_date
from rest_framework.generics import ListAPIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView

from apps.alerts.models import Alert
from apps.alerts.serializers import (
    AlertDetailSerializer,
    AlertListSerializer,
    AlertWriteSerializer,
)
from apps.alerts.services import latest_active_alert, sync_bmkg_alerts
from apps.common.audit import log_action
from apps.common.permissions import IsOfficer
from apps.common.responses import ok
from apps.notifications import fcm

logger = logging.getLogger(__name__)


class AlertListView(ListAPIView):
    permission_classes = [AllowAny]
    serializer_class = AlertListSerializer

    def get_queryset(self):
        qs = Alert.objects.select_related("source")
        params = self.request.query_params

        status = params.get("status", "active")
        if status != "all":
            qs = qs.filter(status=status)
        if dtype := params.get("disaster_type"):
            qs = qs.filter(disaster_type=dtype)
        if raw := params.get("date_from"):
            if date := parse_date(raw):
                qs = qs.filter(published_at__date__gte=date)
        if raw := params.get("date_to"):
            if date := parse_date(raw):
                qs = qs.filter(published_at__date__lte=date)
        return qs.order_by("-published_at")


class AlertLatestView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        try:
            sync_bmkg_alerts()
        except Exception:
            logger.exception("Sinkronisasi BMKG gagal")

        alert = latest_active_alert()
        data = AlertDetailSerializer(alert).data if alert else None
        return ok(
            {"alert": data, "source_updated_at": getattr(alert, "published_at", None)},
            "Data dapat tertunda hingga 60 detik dari sumber.",
        )


class AlertDetailView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk):
        alert = Alert.objects.select_related("source").filter(pk=pk).first()
        if not alert:
            from rest_framework.exceptions import NotFound

            raise NotFound("Peringatan tidak ditemukan.")
        return ok(AlertDetailSerializer(alert).data)


class OfficerAlertListCreateView(APIView):
    permission_classes = [IsAuthenticated, IsOfficer]

    def get(self, request):
        qs = Alert.objects.select_related("source").order_by("-published_at")[:50]
        return ok(AlertListSerializer(qs, many=True).data)

    def post(self, request):
        serializer = AlertWriteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        alert = serializer.save(
            created_by=request.user,
            status=Alert.Status.ACTIVE,
            published_at=timezone.now(),
        )

        sent = 0
        fcm_error = None
        try:
            from apps.accounts.models import DeviceToken

            tokens = list(
                DeviceToken.objects.filter(
                    user__profile__alert_enabled=True, user__is_active=True
                ).values_list("fcm_token", flat=True)
            )
            sent = fcm.send_to_tokens(
                tokens,
                title=alert.title,
                body=alert.affected_area,
                data={"type": "alert", "alert_id": str(alert.id)},
            )
        except Exception as exc:
            logger.exception("Gagal mengirim FCM")
            fcm_error = str(exc)

        log_action(request, "create_alert", alert)

        payload = AlertDetailSerializer(alert).data
        payload["notified_devices"] = sent
        if fcm_error:
            payload["fcm_error"] = fcm_error
        return ok(payload, f"Peringatan aktif. Notifikasi dikirim ke {sent} perangkat.", 201)


class OfficerAlertDetailView(APIView):
    permission_classes = [IsAuthenticated, IsOfficer]

    def patch(self, request, pk):
        alert = Alert.objects.filter(pk=pk).first()
        if not alert:
            from rest_framework.exceptions import NotFound

            raise NotFound("Peringatan tidak ditemukan.")

        status = request.data.get("status")
        if status not in Alert.Status.values:
            from rest_framework.exceptions import ValidationError

            raise ValidationError({"status": "Nilai status tidak valid."})

        old = alert.status
        alert.status = status
        alert.save(update_fields=["status", "updated_at"])
        log_action(
            request,
            "update_alert_status",
            alert,
            details={"old": old, "new": status},
        )
        return ok(AlertDetailSerializer(alert).data, "Status peringatan diperbarui")
