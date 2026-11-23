from django.urls import path

from apps.news.views import (
    EditorNewsDetailView,
    EditorNewsListCreateView,
    NewsDetailView,
    NewsListView,
)

app_name = "news"

urlpatterns = [
    path("news/", NewsListView.as_view(), name="list"),
    path("news/<str:key>/", NewsDetailView.as_view(), name="detail"),
    path("editor/news/", EditorNewsListCreateView.as_view(), name="editor-list"),
    path("editor/news/<uuid:pk>/", EditorNewsDetailView.as_view(), name="editor-detail"),
]
