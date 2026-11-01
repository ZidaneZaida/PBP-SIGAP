"""Endpoint berita: publik read-only + CRUD editor."""

from django.utils import timezone
from rest_framework.exceptions import NotFound
from rest_framework.generics import ListAPIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView

from apps.common.audit import log_action
from apps.common.pagination import ApiPageNumberPagination
from apps.common.permissions import IsEditor
from apps.common.responses import ok
from apps.news.models import NewsArticle
from apps.news.serializers import (
    NewsDetailSerializer,
    NewsListSerializer,
    NewsWriteSerializer,
)


class NewsPagination(ApiPageNumberPagination):
    max_page_size = 30


class NewsListView(ListAPIView):
    permission_classes = [AllowAny]
    serializer_class = NewsListSerializer
    pagination_class = NewsPagination

    def get_queryset(self):
        qs = NewsArticle.objects.filter(is_published=True).select_related(
            "author", "source"
        )
        params = self.request.query_params
        if category := params.get("category"):
            qs = qs.filter(category=category)
        if area := params.get("area"):
            qs = qs.filter(area_tags__contains=[area])
        return qs.order_by("-published_at")


class NewsDetailView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, key):
        qs = NewsArticle.objects.select_related("author", "source")
        article = qs.filter(slug=key).first()
        if article is None:
            article = qs.filter(pk=key).first() if _is_uuid(key) else None
        if article is None or not article.is_published:
            raise NotFound("Berita tidak ditemukan.")
        return ok(NewsDetailSerializer(article).data)


class EditorNewsListCreateView(APIView):
    permission_classes = [IsAuthenticated, IsEditor]

    def get(self, request):
        qs = NewsArticle.objects.select_related("author", "source")[:50]
        return ok(NewsListSerializer(qs, many=True).data)

    def post(self, request):
        serializer = NewsWriteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        article = serializer.save(author=request.user)
        if article.is_published and not article.published_at:
            article.published_at = timezone.now()
            article.save(update_fields=["published_at"])
        log_action(request, "create_news", article)
        return ok(NewsDetailSerializer(article).data, "Berita dibuat", 201)


class EditorNewsDetailView(APIView):
    permission_classes = [IsAuthenticated, IsEditor]

    def patch(self, request, pk):
        article = NewsArticle.objects.filter(pk=pk).first()
        if not article:
            raise NotFound("Berita tidak ditemukan.")
        serializer = NewsWriteSerializer(article, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        article = serializer.save()
        if article.is_published and not article.published_at:
            article.published_at = timezone.now()
            article.save(update_fields=["published_at"])
        log_action(request, "update_news", article)
        return ok(NewsDetailSerializer(article).data, "Berita diperbarui")

    def delete(self, request, pk):
        article = NewsArticle.objects.filter(pk=pk).first()
        if not article:
            raise NotFound("Berita tidak ditemukan.")
        log_action(request, "delete_news", article, details={"title": article.title})
        article.delete()
        return ok(message="Berita dihapus")


def _is_uuid(value):
    import uuid

    try:
        uuid.UUID(str(value))
        return True
    except (ValueError, AttributeError, TypeError):
        return False
