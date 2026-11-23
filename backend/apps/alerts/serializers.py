"""Serializer alert."""

from rest_framework import serializers

from apps.alerts.models import Alert, Source


class SourceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Source
        fields = ["name", "source_url"]


class AlertListSerializer(serializers.ModelSerializer):
    source = SourceSerializer(read_only=True)

    class Meta:
        model = Alert
        fields = [
            "id",
            "disaster_type",
            "title",
            "severity",
            "status",
            "affected_area",
            "magnitude",
            "depth_km",
            "source",
            "published_at",
            "expires_at",
        ]


class AlertDetailSerializer(AlertListSerializer):
    class Meta(AlertListSerializer.Meta):
        fields = AlertListSerializer.Meta.fields + [
            "description",
            "felt_description",
            "latitude",
            "longitude",
            "source_reference_url",
            "is_from_bmkg",
            "updated_at",
        ]


class AlertWriteSerializer(serializers.ModelSerializer):
    severity = serializers.ChoiceField(
        choices=Alert.Severity.choices, required=False, allow_null=True
    )

    class Meta:
        model = Alert
        fields = [
            "disaster_type",
            "title",
            "description",
            "severity",
            "affected_area",
            "latitude",
            "longitude",
            "source_reference_url",
            "expires_at",
        ]

    def validate(self, attrs):
        if not attrs.get("description"):
            raise serializers.ValidationError(
                {"description": "Deskripsi peringatan wajib diisi."}
            )
        lat = attrs.get("latitude")
        lon = attrs.get("longitude")
        if lat is not None and not -90 <= lat <= 90:
            raise serializers.ValidationError({"latitude": "Di luar rentang -90..90."})
        if lon is not None and not -180 <= lon <= 180:
            raise serializers.ValidationError({"longitude": "Di luar rentang -180..180."})
        return attrs
