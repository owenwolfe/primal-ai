import json
from pathlib import Path

import pytest
from django.test import Client, override_settings


@pytest.fixture
def client():
    with override_settings(SECURE_SSL_REDIRECT=False):
        yield Client()


def post(client, payload):
    return client.post(
        "/api/v1/evaluations", data=json.dumps(payload), content_type="application/json"
    )


def test_shared_contract_fixture(client):
    fixture = json.loads((Path(__file__).parents[2] / "contracts/evaluation.json").read_text())
    response = post(client, fixture["request"])
    assert response.status_code == 200
    assert response.json() == fixture["response"]
    assert response["Cache-Control"] == "no-store"


@pytest.mark.parametrize(
    "payload",
    [
        None,
        [],
        {},
        {"ingredientText": 123},
        {"ingredientText": " "},
        {"ingredientText": "x" * 8001},
        {"ingredientText": "\ud800"},
        {"ingredientText": "oats", "unknownField": True},
    ],
)
def test_invalid_request(client, payload):
    response = post(client, payload)
    assert response.status_code == 422
    assert set(response.json()["error"]) == {"code", "message"}


def test_invalid_json(client):
    assert (
        client.post("/api/v1/evaluations", data=b"{", content_type="application/json").status_code
        == 400
    )


def test_deeply_nested_json_returns_a_readable_error(client):
    response = client.post(
        "/api/v1/evaluations",
        data=b"[" * 12000 + b"0" + b"]" * 12000,
        content_type="application/json",
    )
    assert response.status_code == 400
    assert response.json()["error"]["code"] == "INVALID_JSON"
    assert response["Cache-Control"] == "no-store"


def test_body_limit(client):
    response = client.post(
        "/api/v1/evaluations", data=b"x" * 33000, content_type="application/json"
    )
    assert response.status_code == 413


def test_methods_and_content_type(client):
    response = client.get("/api/v1/evaluations")
    assert response.status_code == 405
    assert response["Allow"] == "POST"
    assert (
        client.post("/api/v1/evaluations", data="oats", content_type="text/plain").status_code
        == 415
    )


def test_health_and_missing_endpoint(client):
    assert client.get("/health").json()["rulesVersion"] == "draft-1"
    assert client.get("/missing").json()["error"]["code"] == "NOT_FOUND"


def test_bad_label_is_actionable(client):
    response = post(client, {"ingredientText": "oats ("})
    assert response.status_code == 422
    assert response.json()["error"]["code"] == "INVALID_LABEL"


def test_https_redirect_in_production():
    with override_settings(SECURE_SSL_REDIRECT=True):
        assert Client().get("/health").status_code == 301


def test_untrusted_host_is_rejected(client):
    response = client.get("/health", HTTP_HOST="untrusted.example")
    assert response.status_code == 400
    assert response.json()["error"]["code"] == "INVALID_HOST"
