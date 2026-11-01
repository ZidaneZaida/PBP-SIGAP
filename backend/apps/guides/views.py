"""Endpoint publik: kontak darurat + panduan."""

from rest_framework.permissions import AllowAny
from rest_framework.views import APIView

from apps.common.responses import ok
from apps.guides.models import EmergencyContact, Guide
from apps.guides.serializers import EmergencyContactSerializer, GuideSerializer


class EmergencyContactListView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        qs = EmergencyContact.objects.filter(is_active=True)
        if category := request.query_params.get("category"):
            qs = qs.filter(category=category)
        if request.query_params.get("verified_only", "true").lower() != "false":
            qs = qs.filter(is_verified=True)
        return ok(EmergencyContactSerializer(qs, many=True).data)


class GuideListView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        qs = Guide.objects.filter(is_published=True)
        if dtype := request.query_params.get("disaster_type"):
            qs = qs.filter(disaster_type=dtype)
        if phase := request.query_params.get("phase"):
            qs = qs.filter(phase=phase)
        return ok(GuideSerializer(qs, many=True).data)
