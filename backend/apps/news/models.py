"""Berita kebencanaan."""

from django.conf import settings
from django.db import models
from django.utils.text import slugify

from apps.common.models import TimeStampedModel


class NewsArticle(TimeStampedModel):
    class Category(models.TextChoices):
        EARTHQUAKE = "earthquake", "Gempa Bumi"
        TSUNAMI = "tsunami", "Tsunami"
        FLOOD = "flood", "Banjir"
        LANDSLIDE = "landslide", "Longsor"
        GENERAL = "general", "Umum"

    source = models.ForeignKey(
        "alerts.Source",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="news",
    )
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="news_written"
    )
    title = models.CharField(max_length=400)
    slug = models.SlugField(max_length=450, unique=True, blank=True)
    summary = models.TextField(blank=True)
    content = models.TextField()
    thumbnail_url = models.TextField(blank=True)
    category = models.CharField(max_length=30, choices=Category.choices)
    area_tags = models.JSONField(default=list, blank=True)
    is_published = models.BooleanField(default=False)
    published_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "news_articles"
        ordering = ["-published_at", "-created_at"]
        verbose_name = "Berita"
        verbose_name_plural = "Berita"
        indexes = [
            models.Index(fields=["is_published", "-published_at"]),
            models.Index(fields=["category"]),
        ]

    def __str__(self):
        return self.title

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = self._unique_slug()
        super().save(*args, **kwargs)

    def _unique_slug(self):
        base = slugify(self.title)[:400] or "berita"
        candidate = base
        counter = 2
        while NewsArticle.objects.filter(slug=candidate).exclude(pk=self.pk).exists():
            candidate = f"{base}-{counter}"
            counter += 1
        return candidate
