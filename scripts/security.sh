#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p reports
case "${1:-source}" in
  source)
    docker run --rm -v "$PWD:/repo:ro" zricethezav/gitleaks:v8.30.0 \
      dir /repo --redact --no-banner --gitleaks-ignore-path /repo/.gitleaksignore
    # No Swift lockfile is fabricated when there are no external Swift packages.
    find ios -name Package.resolved -print | while IFS= read -r lock; do
      docker run --rm -v "$PWD:/repo:ro" ghcr.io/google/osv-scanner:v2.3.3 \
        scan source --lockfile "/repo/$lock"
    done
    ;;
  image)
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock:ro \
      aquasec/trivy:0.69.3 image --scanners vuln --ignore-unfixed \
      --severity HIGH,CRITICAL --exit-code 1 "${2:-primal-runtime:local}"
    ;;
  *) echo 'Usage: sh scripts/security.sh source|image [image-name]' >&2; exit 2 ;;
esac
