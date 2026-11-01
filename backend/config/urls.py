"""URL root SIGAP."""

from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", include("apps.common.urls")),
]

admin.site.site_header = "SIGAP — Siaga Bencana Kota Padang"
admin.site.site_title = "SIGAP Admin"