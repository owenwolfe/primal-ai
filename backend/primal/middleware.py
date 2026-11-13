from io import BytesIO

from django.core.exceptions import DisallowedHost
from django.http import JsonResponse


def error(code, message, status):
    return JsonResponse({"error": {"code": code, "message": message}}, status=status)


class APIBoundary:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        try:
            request.get_host()
        except DisallowedHost:
            response = error("INVALID_HOST", "This host is not allowed.", 400)
            response["Cache-Control"] = "no-store"
            return response
        # Check before reading the body, including requests with no Content-Length.
        body = request.read(32769)
        if len(body) > 32768:
            response = error("BODY_TOO_LARGE", "The label request is too large.", 413)
        else:
            # Restore Django's cached body for the view after the bounded stream read.
            request._body = body
            request._stream = BytesIO(body)
            response = self.get_response(request)
        response["Cache-Control"] = "no-store"
        return response
