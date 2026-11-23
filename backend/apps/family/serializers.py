from rest_framework import serializers

from apps.family.models import FamilyGroup, SafetyStatus


class FamilyGroupSerializer(serializers.ModelSerializer):
    class Meta:
        model = FamilyGroup
        fields = [
            "id",
            "name",
            "invite_code",
            "invite_code_expires_at",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "invite_code",
            "invite_code_expires_at",
            "created_at",
        ]


class JoinGroupSerializer(serializers.Serializer):
    invite_code = serializers.CharField(max_length=8)


class TransferAdminSerializer(serializers.Serializer):
    user_id = serializers.UUIDField()


class SafetyStatusWriteSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=SafetyStatus.Value.choices)
    message = serializers.CharField(required=False, allow_blank=True, max_length=500)
    location_note = serializers.CharField(required=False, allow_blank=True, max_length=300)
    share_location = serializers.BooleanField(default=False)
    latitude = serializers.FloatField(required=False, allow_null=True)
    longitude = serializers.FloatField(required=False, allow_null=True)
    battery_level = serializers.IntegerField(
        required=False, allow_null=True, min_value=0, max_value=100
    )

    def validate(self, attrs):
        if attrs.get("share_location"):
            lat, lon = attrs.get("latitude"), attrs.get("longitude")
            if lat is None or lon is None:
                raise serializers.ValidationError(
                    {"share_location": "latitude dan longitude wajib bila berbagi lokasi."}
                )
            if not -90 <= lat <= 90:
                raise serializers.ValidationError({"latitude": "Di luar rentang -90..90."})
            if not -180 <= lon <= 180:
                raise serializers.ValidationError({"longitude": "Di luar rentang -180..180."})
        return attrs


def member_payload(membership):
    return {
        "user_id": str(membership.user_id),
        "full_name": membership.user.full_name,
        "is_group_admin": membership.is_group_admin,
        "latest_status": (
            {
                "status": membership.latest_status,
                "message": membership.latest_message or "",
                "location_note": membership.latest_note or "",
                "battery_level": membership.latest_battery,
                "reported_at": membership.latest_at,
            }
            if membership.latest_status
            else None
        ),
    }
