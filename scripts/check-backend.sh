#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
uv sync --project backend --locked
backend/.venv/bin/ruff check backend
backend/.venv/bin/ruff format --check backend
DJANGO_DEBUG=1 backend/.venv/bin/python backend/manage.py check
DJANGO_DEBUG=1 backend/.venv/bin/pytest backend/tests --cov=backend/primal --cov-branch --cov-report=term-missing
