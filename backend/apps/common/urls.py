from django.urls import path

from apps.common.dashboard import DashboardView
from apps.common.views import HealthView

app_name = "common"

urlpatterns = [
    path("health/", HealthView.as_view(), name="health"),
    path("dashboard/", DashboardView.as_view(), name="dashboard"),
]
