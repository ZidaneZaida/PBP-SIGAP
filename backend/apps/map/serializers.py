from rest_framework import serializers

from apps.map.models import AssistancePoint, RiskZone


class AssistancePointSerializer(serializers.ModelSerializer):
    class Meta:
        model = AssistancePoint
        fields = [
            "id",
            "name",
            "category",
            "address",
            "phone",
            "latitude",
            "longitude",
            "capacity",
            "operational_hours",
            "verification_status",
            "verified_at",
            "notes",
            "is_active",
        ]
        read_only_fields = ["verified_at"]

    def validate(self, attrs):
        lat = attrs.get("latitude", getattr(self.instance, "latitude", None))
        lon = attrs.get("longitude", getattr(self.instance, "longitude", None))
        if lat is not None and not -90 <= lat <= 90:
            raise serializers.ValidationError({"latitude": "Di luar rentang -90..90."})
        if lon is not None and not -180 <= lon <= 180:
            raise serializers.ValidationError({"longitude": "Di luar rentang -180..180."})
        return attrs


class RiskZoneSerializer(serializers.ModelSerializer):
    class Meta:
        model = RiskZone
        fields = [
            "id",
            "name",
            "hazard_type",
            "risk_level",
            "geojson",
            "description",
            "source_notes",
            "updated_at",
        ]

    def validate_geojson(self, value):
        if not isinstance(value, dict):
            raise serializers.ValidationError("Harus objek GeoJSON.")
        if value.get("type") not in {"Polygon", "MultiPolygon"}:
            raise serializers.ValidationError(
                "Tipe geometri harus Polygon atau MultiPolygon."
            )
        if not value.get("coordinates"):
            raise serializers.ValidationError("coordinates tidak boleh kosong.")
        return value
