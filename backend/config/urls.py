"""URL root SIGAP."""

from django.contrib import admin
from django.http import JsonResponse
from django.urls import include, path


def root_view(request):
    return JsonResponse(
        {
            "status": "success",
            "message": "SIGAP Backend API is running.",
        }
    )


urlpatterns = [
    path("", root_view, name="root_index"),
    path("admin/", admin.site.urls),
    path("api/", include("apps.common.urls")),
    path("api/", include("apps.accounts.urls")),
    path("api/", include("apps.alerts.urls")),
    path("api/", include("apps.news.urls")),
    path("api/", include("apps.map.urls")),
    path("api/", include("apps.guides.urls")),
    path("api/", include("apps.family.urls")),
]

admin.site.site_header = "SIGAP — Siaga Bencana Kota Padang"
admin.site.site_title = "SIGAP Admin"


def handler404(request, exception):
    return JsonResponse(
        {"status": "error", "code": "NOT_FOUND", "message": "Endpoint tidak ditemukan."},
        status=404,
    )


def handler500(request):
    return JsonResponse(
        {
            "status": "error",
            "code": "SERVER_ERROR",
            "message": "Terjadi kesalahan pada server.",
        },
        status=500,
    )
