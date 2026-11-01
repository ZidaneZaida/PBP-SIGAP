from django.urls import path

from apps.alerts.views import (
    AlertDetailView,
    AlertLatestView,
    AlertListView,
    OfficerAlertDetailView,
    OfficerAlertListCreateView,
)

app_name = "alerts"

urlpatterns = [
    path("alerts/", AlertListView.as_view(), name="list"),
    path("alerts/latest/", AlertLatestView.as_view(), name="latest"),
    path("alerts/<uuid:pk>/", AlertDetailView.as_view(), name="detail"),
    path("officer/alerts/", OfficerAlertListCreateView.as_view(), name="officer-list"),
    path(
        "officer/alerts/<uuid:pk>/",
        OfficerAlertDetailView.as_view(),
        name="officer-detail",
    ),
]
