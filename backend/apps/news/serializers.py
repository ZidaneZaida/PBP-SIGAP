from rest_framework import serializers

from apps.alerts.serializers import SourceSerializer
from apps.news.models import NewsArticle


class AuthorSerializer(serializers.Serializer):
    full_name = serializers.CharField()


class NewsListSerializer(serializers.ModelSerializer):
    author = AuthorSerializer(read_only=True)
    source = SourceSerializer(read_only=True)

    class Meta:
        model = NewsArticle
        fields = [
            "id",
            "title",
            "slug",
            "summary",
            "thumbnail_url",
            "category",
            "area_tags",
            "author",
            "source",
            "published_at",
        ]


class NewsDetailSerializer(NewsListSerializer):
    class Meta(NewsListSerializer.Meta):
        fields = NewsListSerializer.Meta.fields + ["content", "updated_at"]


class NewsWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = NewsArticle
        fields = [
            "title",
            "summary",
            "content",
            "category",
            "area_tags",
            "thumbnail_url",
            "source",
            "is_published",
        ]

    def validate_area_tags(self, value):
        if not isinstance(value, list):
            raise serializers.ValidationError("Harus berupa daftar string.")
        return [str(item)[:50] for item in value][:20]
