from django.urls import path

from apps.map.views import (
    AssistancePointListView,
    NearbyView,
    OfficerAssistancePointDetailView,
    OfficerAssistancePointView,
    OfficerRiskZoneDetailView,
    OfficerRiskZoneView,
    RiskZoneLayerView,
)

app_name = "map"

urlpatterns = [
    path("map/nearby/", NearbyView.as_view(), name="nearby"),
    path("map/risk-zones/", RiskZoneLayerView.as_view(), name="risk-zones"),
    path("assistance-points/", AssistancePointListView.as_view(), name="points"),
    path(
        "officer/assistance-points/",
        OfficerAssistancePointView.as_view(),
        name="officer-point-create",
    ),
    path(
        "officer/assistance-points/<uuid:pk>/",
        OfficerAssistancePointDetailView.as_view(),
        name="officer-point-detail",
    ),
    path(
        "officer/risk-zones/",
        OfficerRiskZoneView.as_view(),
        name="officer-zone-create",
    ),
    path(
        "officer/risk-zones/<uuid:pk>/",
        OfficerRiskZoneDetailView.as_view(),
        name="officer-zone-detail",
    ),
]
