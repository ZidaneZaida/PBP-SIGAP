from rest_framework.renderers import JSONRenderer


class ApiJSONRenderer(JSONRenderer):
    """Bungkus payload ke `{status, data, message}`.

    Payload yang sudah berbentuk amplop (punya kunci `status`) dilewatkan
    apa adanya — dipakai oleh pagination dan exception handler.
    """

    def render(self, data, accepted_media_type=None, renderer_context=None):
        response = (renderer_context or {}).get("response")

        if response is None or (isinstance(data, dict) and "status" in data):
            return super().render(data, accepted_media_type, renderer_context)

        payload = {
            "status": "success" if response.status_code < 400 else "error",
            "data": data,
        }
        return super().render(payload, accepted_media_type, renderer_context)