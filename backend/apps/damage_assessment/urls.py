"""Rute API modul penilaian kerusakan."""

from django.urls import path

from apps.damage_assessment.views import (
    DamageReportHeatmapView,
    DamageReportListCreateView,
    MyDamageReportsView,
    OfficerDamageReportPendingView,
    OfficerDamageReportVerifyView,
)

app_name = "damage_assessment"

urlpatterns = [
    path(
        "damage-reports/",
        DamageReportListCreateView.as_view(),
        name="list-create",
    ),
    # Alias khusus baca: aplikasi Flutter memakai `/my/` untuk riwayat pengguna.
    path(
        "damage-reports/my/",
        MyDamageReportsView.as_view(),
        name="my-reports",
    ),
    path(
        "damage-reports/heatmap/",
        DamageReportHeatmapView.as_view(),
        name="heatmap",
    ),
    path(
        "officer/damage-reports/pending/",
        OfficerDamageReportPendingView.as_view(),
        name="officer-pending",
    ),
    path(
        "officer/damage-reports/<uuid:pk>/verify/",
        OfficerDamageReportVerifyView.as_view(),
        name="officer-verify",
    ),
]
