from rest_framework import serializers

from apps.guides.models import EmergencyContact, Guide


class EmergencyContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmergencyContact
        fields = [
            "id",
            "name",
            "category",
            "phone_number",
            "description",
            "area",
            "is_verified",
            "verified_at",
        ]


class GuideSerializer(serializers.ModelSerializer):
    class Meta:
        model = Guide
        fields = [
            "id",
            "disaster_type",
            "phase",
            "title",
            "content",
            "icon_name",
            "reviewed_source",
            "reviewed_at",
            "sort_order",
        ]
