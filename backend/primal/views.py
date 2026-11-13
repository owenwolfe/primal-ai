import json

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

from primal.evaluation import RULES, evaluate
from primal.middleware import error


def health(request):
    if request.method != "GET":
        return method_error("GET")
    return JsonResponse(
        {"status": "ok", "serviceVersion": "0.1.0", "rulesVersion": RULES["version"]}
    )


def method_error(allowed):
    response = error("METHOD_NOT_ALLOWED", "This method is not supported.", 405)
    response["Allow"] = allowed
    return response


@csrf_exempt
def evaluate_label(request):
    # Public, stateless native-client endpoint. No cookie/session authentication.
    if request.method != "POST":
        return method_error("POST")
    if request.content_type != "application/json":
        return error("UNSUPPORTED_MEDIA_TYPE", "Send application/json.", 415)
    try:
        payload = json.loads(request.body)
    except (ValueError, UnicodeDecodeError, RecursionError):
        return error("INVALID_JSON", "The request must contain valid JSON.", 400)
    if not isinstance(payload, dict) or set(payload) != {"ingredientText"}:
        return error("INVALID_REQUEST", "Provide only ingredientText.", 422)
    text = payload["ingredientText"]
    if not isinstance(text, str) or not text.strip() or len(text) > 8000:
        return error("INVALID_TEXT", "Enter between 1 and 8,000 characters of ingredients.", 422)
    try:
        text.encode("utf-8")
    except UnicodeEncodeError:
        return error("INVALID_TEXT", "Use valid Unicode text for the ingredient list.", 422)
    try:
        result = evaluate(text)
    except ValueError as exc:
        return error("INVALID_LABEL", str(exc), 422)
    return JsonResponse(result)


def not_found(request, exception):
    return error("NOT_FOUND", "This endpoint does not exist.", 404)


def server_error(request):
    return error("SERVER_ERROR", "We could not evaluate the label. Please try again.", 500)
