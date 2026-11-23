"""Helper amplop response."""

from rest_framework.response import Response


def ok(data=None, message=None, status_code=200):
    payload = {"status": "success", "data": data}
    if message:
        payload["message"] = message
    return Response(payload, status=status_code)
