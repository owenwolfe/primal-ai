"""Verify a running backend over HTTP. Uses synthetic ingredient text only."""

import json
import sys
import urllib.error
import urllib.request

base = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8000"
with urllib.request.urlopen(base + "/health", timeout=5) as response:
    assert json.load(response)["status"] == "ok"
for text, rating, status in [
    ("oats, almonds, salt", "aligned", "complete"),
    ("oats, honey", "review", "complete"),
    ("oats, unfamiliar ingredient", None, "partial"),
]:
    request = urllib.request.Request(
        base + "/api/v1/evaluations",
        data=json.dumps({"ingredientText": text}).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=5) as response:
        result = json.load(response)
        assert result["rating"] == rating, result
        assert result["status"] == status, result
        assert response.headers["Cache-Control"] == "no-store"
try:
    urllib.request.urlopen(base + "/api/v1/evaluations", timeout=5)
except urllib.error.HTTPError as error:
    assert error.code == 405
    assert json.load(error)["error"]["code"] == "METHOD_NOT_ALLOWED"
else:
    raise AssertionError("GET evaluation unexpectedly succeeded")
print("API smoke passed: health, aligned, review, partial, and method validation.")
