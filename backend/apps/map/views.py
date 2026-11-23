"""Endpoint peta: radius, layer zona risiko, CRUD petugas."""

from django.utils import timezone
from rest_framework.exceptions import NotFound, ValidationError
from rest_framework.generics import ListAPIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView

from apps.common.audit import log_action
from apps.common.pagination import ApiPageNumberPagination
from apps.common.permissions import IsOfficer
from apps.common.responses import ok
from apps.map.models import AssistancePoint, RiskZone
from apps.map.serializers import AssistancePointSerializer, RiskZoneSerializer
from apps.map.services import DEFAULT_RADIUS_M, nearby_points


class NearbyView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        lat = _float_param(request, "lat")
        lon = _float_param(request, "lon")
        radius = _float_param(request, "radius", DEFAULT_RADIUS_M)
        category = request.query_params.get("category") or None

        rows, used_radius = nearby_points(lat, lon, radius, category)
        results = []
        for point, distance in rows:
            data = AssistancePointSerializer(point).data
            data["distance_meters"] = distance
            results.append(data)

        return ok(
            {
                "center": {"latitude": lat, "longitude": lon},
                "radius_meters": used_radius,
                "results": results,
            }
        )


class RiskZoneLayerView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        qs = RiskZone.objects.select_related("source")
        if hazard := request.query_params.get("hazard_type"):
            qs = qs.filter(hazard_type=hazard)
        if level := request.query_params.get("risk_level"):
            qs = qs.filter(risk_level=level)

        features = [
            {
                "type": "Feature",
                "geometry": zone.geojson,
                "properties": {
                    "id": str(zone.id),
                    "name": zone.name,
                    "hazard_type": zone.hazard_type,
                    "risk_level": zone.risk_level,
                    "description": zone.description,
                    "source": zone.source.name if zone.source else "",
                    "updated_at": zone.updated_at,
                },
            }
            for zone in qs
        ]
        return ok({"type": "FeatureCollection", "features": features})


class PointPagination(ApiPageNumberPagination):
    max_page_size = 50


class AssistancePointListView(ListAPIView):
    permission_classes = [AllowAny]
    serializer_class = AssistancePointSerializer
    pagination_class = PointPagination

    def get_queryset(self):
        qs = AssistancePoint.objects.filter(is_active=True)
        params = self.request.query_params
        if category := params.get("category"):
            qs = qs.filter(category=category)
        status = params.get("verification_status", "verified")
        if status != "all":
            qs = qs.filter(verification_status=status)
        return qs.order_by("name")



class OfficerAssistancePointView(APIView):
    permission_classes = [IsAuthenticated, IsOfficer]

    def post(self, request):
        serializer = AssistancePointSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        point = serializer.save()
        log_action(request, "create_posko", point)
        return ok(AssistancePointSerializer(point).data, "Titik bantuan dibuat", 201)


class OfficerAssistancePointDetailView(APIView):
    permission_classes = [IsAuthenticated, IsOfficer]

    def patch(self, request, pk):
        point = AssistancePoint.objects.filter(pk=pk).first()
        if not point:
            raise NotFound("Titik bantuan tidak ditemukan.")
        serializer = AssistancePointSerializer(point, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        point = serializer.save()
        if point.verification_status == AssistancePoint.Verification.VERIFIED and not point.verified_at:
            point.verified_at = timezone.now()
            point.save(update_fields=["verified_at"])
        log_action(request, "update_posko", point)
        return ok(AssistancePointSerializer(point).data, "Titik bantuan diperbarui")


class OfficerRiskZoneView(APIView):
    permission_classes = [IsAuthenticated, IsOfficer]

    def post(self, request):
        serializer = RiskZoneSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        zone = serializer.save()
        log_action(request, "create_risk_zone", zone)
        return ok(RiskZoneSerializer(zone).data, "Zona risiko dibuat", 201)


class OfficerRiskZoneDetailView(APIView):
    permission_classes = [IsAuthenticated, IsOfficer]

    def patch(self, request, pk):
        zone = RiskZone.objects.filter(pk=pk).first()
        if not zone:
            raise NotFound("Zona risiko tidak ditemukan.")
        serializer = RiskZoneSerializer(zone, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        zone = serializer.save()
        log_action(request, "update_risk_zone", zone)
        return ok(RiskZoneSerializer(zone).data, "Zona risiko diperbarui")


def _float_param(request, name, default=None):
    raw = request.query_params.get(name)
    if raw in (None, ""):
        if default is None:
            raise ValidationError({name: "Parameter wajib diisi."})
        return float(default)
    try:
        return float(raw)
    except ValueError as exc:
        raise ValidationError({name: "Harus berupa angka."}) from exc
