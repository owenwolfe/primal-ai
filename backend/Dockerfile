FROM python:3.12-slim@sha256:5e2bdb1b0d542d5039cffb8181c65930093949194a65c365dfb1b0fe13a4fa5b AS build
COPY --from=ghcr.io/astral-sh/uv:0.13.8@sha256:5cc1805e2426484abca4ad46ea783bab281fdb225fd82d8ce6d66a81254bac85 /uv /usr/local/bin/uv
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --locked --no-dev --no-cache

FROM python:3.12-slim@sha256:5e2bdb1b0d542d5039cffb8181c65930093949194a65c365dfb1b0fe13a4fa5b
ENV PATH="/app/.venv/bin:$PATH" PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
WORKDIR /app
COPY --from=build /app/.venv /app/.venv
COPY primal ./primal
RUN useradd --uid 10001 --no-create-home app
USER 10001
EXPOSE 8000
CMD ["sh", "-c", "exec gunicorn primal.wsgi:application --no-control-socket --bind 0.0.0.0:${PORT:-8000} --workers 2 --timeout 30 --limit-request-line 4094"]
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
