"""Serializer laporan kerusakan bangunan."""

from rest_framework import serializers

from apps.damage_assessment.models import DamageReport

# Bounding box kasar Kota Padang (termasuk perairan terdekat) untuk menolak
# koordinat di luar wilayah layanan. Cukup untuk trust boundary pertama;
# validasi presisi dilakukan petugas saat verifikasi.
PADANG_BBOX = {
    "lat_min": -1.10,
    "lat_max": -0.75,
    "lon_min": 100.25,
    "lon_max": 100.55,
}


class DamageReportSerializer(serializers.ModelSerializer):
    """Payload sinkronisasi laporan dari aplikasi Flutter.

    Mendukung dua jalur: `application/json` (foto belum/tidak diunggah) atau
    `multipart/form-data` dengan field `image` yang diunggah ke object storage.
    """

    image = serializers.ImageField(write_only=True, required=False)
    image_url = serializers.URLField(read_only=True)
    damage_level_display = serializers.CharField(
        source="get_damage_level_display", read_only=True
    )
    client_report_id = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=64,
        help_text=(
            "ID laporan versi aplikasi. Bila dikirim ulang dengan nilai sama,"
            " server mengembalikan laporan yang sudah ada."
        ),
    )

    class Meta:
        model = DamageReport
        fields = [
            "id",
            "client_report_id",
            "damage_level",
            "damage_level_display",
            "confidence_score",
            "latitude",
            "longitude",
            "description",
            "image",
            "image_url",
            "is_verified_by_officer",
            "created_at",
        ]
        read_only_fields = ["id", "is_verified_by_officer", "created_at"]

    def validate_confidence_score(self, value):
        """Skor harus berupa probabilitas 0..1, bukan persentase 0..100."""
        if not 0.0 <= value <= 1.0:
            raise serializers.ValidationError("Harus di antara 0.0 dan 1.0.")
        return value

    def validate_latitude(self, value):
        if not PADANG_BBOX["lat_min"] <= value <= PADANG_BBOX["lat_max"]:
            raise serializers.ValidationError(
                "Lokasi di luar wilayah layanan Kota Padang."
            )
        return value

    def validate_longitude(self, value):
        if not PADANG_BBOX["lon_min"] <= value <= PADANG_BBOX["lon_max"]:
            raise serializers.ValidationError(
                "Lokasi di luar wilayah layanan Kota Padang."
            )
        return value


class DamageHeatmapPointSerializer(serializers.ModelSerializer):
    """Titik minimal untuk layer heatmap peta publik."""

    class Meta:
        model = DamageReport
        fields = ["id", "latitude", "longitude", "damage_level", "created_at"]


class DamageVerifySerializer(serializers.Serializer):
    """Keputusan petugas atas satu laporan."""

    approved = serializers.BooleanField(
        help_text="True untuk memverifikasi, False untuk menolak.",
    )
    note = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=500,
        help_text="Catatan petugas (disimpan di audit log).",
    )
