"""Endpoint laporan kerusakan: sinkronisasi warga, heatmap publik, verifikasi petugas."""

from django.core.cache import cache
from django.db import IntegrityError, transaction
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework.exceptions import ValidationError
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView

from apps.common.audit import log_action
from apps.common.permissions import IsOfficer
from apps.common.responses import ok
from apps.common.throttling import FlexibleScopedRateThrottle
from apps.damage_assessment.models import DamageReport
from apps.damage_assessment.serializers import (
    DamageReportSerializer,
    DamageVerifySerializer,
)
from apps.damage_assessment.services import (
    HEATMAP_CACHE_KEY,
    HEATMAP_CACHE_TTL,
    HEATMAP_GRID_DEGREES,
    flush_heatmap_cache,
    heatmap_points,
    heatmap_summary,
    upload_damage_photo,
)


class DamageReportListCreateView(APIView):
    """Terima laporan baru dan tampilkan riwayat milik pengguna.

    ``GET`` sengaja hanya mengembalikan laporan milik pemanggil; data warga lain
    tidak boleh bocor lewat endpoint ini.
    """

    permission_classes = [IsAuthenticated]
    parser_classes = [JSONParser, MultiPartParser, FormParser]
    throttle_classes = [FlexibleScopedRateThrottle]
    throttle_scope = "damage_report"

    def get(self, request):
        """Daftar laporan milik pengguna, terbaru lebih dulu."""
        rows = DamageReport.objects.filter(user=request.user)[:100]
        return ok(DamageReportSerializer(rows, many=True).data)

    def post(self, request):
        """Simpan laporan hasil pemindaian SIGAP-Vision.

        Idempoten terhadap ``client_report_id``: pengiriman ulang antrean offline
        mengembalikan laporan yang sudah ada (HTTP 200) alih-alih membuat duplikat.

        Foto bersifat opsional: bila unggahan gagal atau storage belum
        dikonfigurasi, laporan tetap diterima agar data kerusakan tidak hilang.
        """
        serializer = DamageReportSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        client_report_id = serializer.validated_data.get("client_report_id") or None
        if client_report_id is not None:
            existing = DamageReport.objects.filter(
                user=request.user, client_report_id=client_report_id
            ).first()
            if existing is not None:
                return ok(
                    DamageReportSerializer(existing).data,
                    "Laporan ini sudah pernah diterima server.",
                )

        try:
            # atomic() wajib: IntegrityError menandai transaksi luar sebagai gagal.
            with transaction.atomic():
                report = serializer.save(user=request.user)
        except IntegrityError:
            if client_report_id is None:
                raise
            existing = DamageReport.objects.get(
                user=request.user, client_report_id=client_report_id
            )
            return ok(
                DamageReportSerializer(existing).data,
                "Laporan ini sudah pernah diterima server.",
            )

        image = serializer.validated_data.get("image")
        if image is not None:
            try:
                report.image_url = upload_damage_photo(report, image)
                report.save(update_fields=["image_url"])
            except ValidationError as exc:
                # Foto adalah bonus, bukan syarat: laporkan peringatan tanpa
                # menggagalkan laporan kerusakan yang sudah terkirim.
                return ok(
                    DamageReportSerializer(report).data,
                    _photo_warning(exc),
                    201,
                )

        return ok(
            DamageReportSerializer(report).data,
            "Laporan kerusakan diterima dan menunggu verifikasi petugas.",
            201,
        )


class MyDamageReportsView(APIView):
    """Riwayat laporan kerusakan milik pengguna yang sedang masuk.

    Dipisahkan dari [DamageReportListCreateView] karena aplikasi Flutter
    memanggil path `/my/` khusus untuk baca; menulis tetap lewat koleksi.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request):
        """Daftar laporan milik pengguna, terbaru lebih dulu."""
        rows = DamageReport.objects.filter(user=request.user)[:100]
        return ok(DamageReportSerializer(rows, many=True).data)


class DamageReportHeatmapView(APIView):
    """Layer heatmap kerusakan untuk peta publik."""

    permission_classes = [AllowAny]
    throttle_classes = [FlexibleScopedRateThrottle]
    throttle_scope = "public_heatmap"

    def get(self, request):
        """Titik agregat per grid area, plus ringkasan angka.

        Hasil di-cache singkat: endpoint ini publik dan melakukan agregasi
        seluruh tabel, sehingga tanpa cache mudah dijadikan vektor beban.
        """
        cached = cache.get(HEATMAP_CACHE_KEY)
        if cached is not None:
            return ok(cached)

        payload = {
            "points": heatmap_points(),
            "summary": heatmap_summary(),
            "grid_degrees": HEATMAP_GRID_DEGREES,
        }
        cache.set(HEATMAP_CACHE_KEY, payload, HEATMAP_CACHE_TTL)
        return ok(payload)


class OfficerDamageReportPendingView(APIView):
    """Antrean laporan yang belum diverifikasi (khusus petugas BPBD)."""

    permission_classes = [IsAuthenticated, IsOfficer]

    def get(self, request):
        """Daftar laporan menunggu, terlama lebih dulu agar tidak menumpuk."""
        rows = DamageReport.objects.filter(
            is_verified_by_officer__isnull=True
        ).select_related("user").order_by("created_at")[:100]
        return ok(DamageReportSerializer(rows, many=True).data)


class OfficerDamageReportVerifyView(APIView):
    """Verifikasi atau tolak satu laporan kerusakan."""

    permission_classes = [IsAuthenticated, IsOfficer]

    def patch(self, request, pk):
        """Tetapkan status verifikasi laporan.

        ``approved=true`` memasukkan laporan ke heatmap publik;
        ``approved=false`` menyembunyikannya tanpa menghapus data.
        """
        report = get_object_or_404(DamageReport, pk=pk)
        serializer = DamageVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        approved = serializer.validated_data["approved"]
        report.is_verified_by_officer = approved
        report.verified_at = timezone.now()
        report.verified_by = request.user
        report.save(
            update_fields=["is_verified_by_officer", "verified_at", "verified_by", "updated_at"]
        )
        # Heatmap publik harus segera mencerminkan keputusan petugas.
        flush_heatmap_cache()

        log_action(
            request,
            "verify_damage_report" if approved else "reject_damage_report",
            report,
            details={"note": serializer.validated_data.get("note", "")},
        )
        message = (
            "Laporan diverifikasi dan masuk heatmap publik."
            if approved
            else "Laporan ditolak dan disembunyikan dari heatmap."
        )
        return ok(DamageReportSerializer(report).data, message)


def _photo_warning(exc) -> str:
    """Pesan ramah saat laporan tersimpan tetapi fotonya gagal diunggah."""
    detail = getattr(exc, "detail", None)
    if isinstance(detail, dict):
        first = next(iter(detail.values()), "")
        if isinstance(first, list) and first:
            first = first[0]
        return f"Laporan tersimpan tanpa foto: {first}"
    return f"Laporan tersimpan tanpa foto: {detail or 'unggahan gagal'}"
