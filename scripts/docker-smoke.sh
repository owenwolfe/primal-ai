#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
export LOCAL_UID="$(id -u)" LOCAL_GID="$(id -g)"
project="primal-smoke-$$"
cleanup() { docker compose -p "$project" down --volumes --remove-orphans; }
trap cleanup EXIT HUP INT TERM
docker compose -p "$project" config --quiet
docker compose -p "$project" build backend
docker compose -p "$project" run --rm backend
docker build --target runtime -t primal-runtime:local backend
docker run --rm --read-only --cap-drop ALL --security-opt no-new-privileges \
  --entrypoint python primal-runtime:local -c \
  'import os, django, gunicorn; assert os.getuid() != 0; print("Non-root runtime dependencies verified:", django.get_version())'
echo 'Infrastructure image verification complete. No application or health endpoint exists yet.'
