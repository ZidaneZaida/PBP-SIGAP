from rest_framework.views import exception_handler as drf_exception_handler

CODE_BY_STATUS = {
    400: "VALIDATION_ERROR",
    401: "UNAUTHORIZED",
    403: "FORBIDDEN",
    404: "NOT_FOUND",
    405: "METHOD_NOT_ALLOWED",
    409: "CONFLICT",
    429: "RATE_LIMITED",
}

DEFAULT_MESSAGE = {
    400: "Data tidak valid.",
    401: "Token tidak valid atau sudah kedaluwarsa.",
    403: "Anda tidak memiliki izin untuk aksi ini.",
    404: "Data tidak ditemukan.",
    405: "Metode tidak diizinkan.",
    409: "Permintaan bertentangan dengan data saat ini.",
    429: "Terlalu banyak permintaan. Coba lagi nanti.",
}


def api_exception_handler(exc, context):
    """Ubah error DRF menjadi amplop `{status, code, message, errors}`."""
    response = drf_exception_handler(exc, context)
    if response is None:
        return None

    detail = response.data
    errors = None
    message = DEFAULT_MESSAGE.get(response.status_code, "Terjadi kesalahan.")

    if isinstance(detail, dict) and set(detail) == {"detail"}:
        message = str(detail["detail"])
    elif isinstance(detail, dict):
        errors = detail
        message = _first_error(detail) or message
    elif isinstance(detail, list):
        message = "; ".join(str(item) for item in detail) or message

    payload = {
        "status": "error",
        "code": CODE_BY_STATUS.get(response.status_code)
        or getattr(exc, "default_code", None)
        or "ERROR",
        "message": message,
    }
    if errors:
        payload["errors"] = errors

    response.data = payload
    return response


def _first_error(errors):
    for value in errors.values():
        if isinstance(value, (list, tuple)) and value:
            return str(value[0])
        if isinstance(value, str):
            return value
    return None