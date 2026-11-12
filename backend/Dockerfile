# syntax=docker/dockerfile:1
FROM ghcr.io/astral-sh/uv:0.13.7@sha256:96f40d3904aad8d0bd010539001d36c8e2188b981e1334471a90c4a1d93bb490 AS uv
FROM python:3.14-slim-bookworm@sha256:3fe1a0b6c2d6b2ebb572906cdabeca75aeb558c0c17db5ffefbcf8094871c32b AS base
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 \
    UV_PROJECT_ENVIRONMENT=/opt/venv UV_PYTHON_DOWNLOADS=never \
    UV_LINK_MODE=copy \
    PATH="/opt/venv/bin:$PATH"
WORKDIR /app

FROM base AS bootstrap
COPY --from=uv /uv /usr/local/bin/uv

FROM bootstrap AS dependencies
COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv uv sync --locked --no-dev --no-install-project

FROM dependencies AS development
RUN --mount=type=cache,target=/root/.cache/uv uv sync --locked --no-install-project
WORKDIR /workspace
# One-shot infrastructure checks, not a pretend Django service.
USER 10001:10001
CMD ["python", "scripts/verify.py"]

FROM base AS runtime
# The runtime installs nothing; remove pip and its unrelated vendored dependencies.
RUN --mount=from=uv,source=/uv,target=/usr/local/bin/uv uv pip uninstall --system pip
COPY --from=dependencies /opt/venv /opt/venv
COPY --chown=10001:10001 . /app
USER 10001:10001
# Application implementation must supply a real WSGI module before this can run.
CMD ["sh", "-c", "exec gunicorn --bind 0.0.0.0:${PORT:-8000} --access-logfile - \"${DJANGO_WSGI_MODULE:?Set DJANGO_WSGI_MODULE after implementing the Django application}\""]
