from django.db import DatabaseError, connection
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView


class HealthView(APIView):
    """Cek liveness + koneksi database."""

    permission_classes = [AllowAny]
    throttle_classes = []
    authentication_classes = []

    def get(self, request):
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
        except DatabaseError:
            return Response({"db": "down", "version": "0.1.0"}, status=503)
        return Response({"db": "ok", "version": "0.1.0"})