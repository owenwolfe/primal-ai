"""Release-only Render deployment; never invoked by local checks or PR jobs."""

import json
import os
import re
import time
from pathlib import Path
from typing import Any
from urllib.error import HTTPError
from urllib.request import Request, urlopen


def render_request(path: str, payload: dict[str, str] | None = None) -> dict[str, Any]:
    request = Request(
        "https://api.render.com/v1/" + path,
        data=json.dumps(payload).encode() if payload is not None else None,
        headers={
            "Authorization": "Bearer " + os.environ["RENDER_API_KEY"],
            "Content-Type": "application/json",
        },
        method="POST" if payload is not None else "GET",
    )
    # Fixed HTTPS API origin; never print response bodies or authorization headers.
    with urlopen(request, timeout=30) as response:  # noqa: S310
        result: dict[str, Any] = json.load(response)
        return result


def main() -> None:
    service = os.environ["RENDER_SERVICE_ID"]
    if not re.fullmatch(r"srv-[a-z0-9]+", service):
        raise SystemExit("Invalid Render service ID")
    image = Path("image-digest.txt").read_text().strip()
    if not re.fullmatch(r"ghcr.io/[a-z0-9_./-]+@sha256:[a-f0-9]{64}", image):
        raise SystemExit("An immutable GHCR digest is required")
    endpoint = os.environ["API_BASE_URL"].rstrip("/")
    if not endpoint.startswith("https://"):
        raise SystemExit("API_BASE_URL must use HTTPS")
    deployed = render_request(f"services/{service}/deploys", {"imageUrl": image})
    deploy_id = deployed["id"]
    if not re.fullmatch(r"dep-[a-z0-9]+", deploy_id):
        raise SystemExit("Invalid deploy response")
    for _ in range(90):
        status = render_request(f"services/{service}/deploys/{deploy_id}")["status"]
        if status == "live":
            break
        if status in {
            "build_failed",
            "update_failed",
            "pre_deploy_failed",
            "canceled",
            "deactivated",
        }:
            raise SystemExit("Render deployment failed; restore the previous image digest.")
        time.sleep(10)
    else:
        raise SystemExit("Render deployment timed out; inspect service before proceeding.")
    request = Request(endpoint + "/health")  # noqa: S310 -- HTTPS scheme checked above
    with urlopen(request, timeout=30) as response:  # noqa: S310
        if response.status != 200:
            raise SystemExit("Backend health verification failed")
    # Product implementation supplies a synthetic API smoke probe before release.
    print("Exact backend image deployed and /health returned HTTP 200.")


if __name__ == "__main__":
    try:
        main()
    except HTTPError as error:
        raise SystemExit(f"Release HTTP request failed with status {error.code}") from None
