#!/bin/sh
# Readiness only. Never print credentials or perform external writes.
set -eu
cd "$(dirname "$0")/.."
missing=0
for path in backend/manage.py ios/Primal.xcodeproj/project.pbxproj ios/ExportOptions.plist; do
  if [ ! -f "$path" ]; then
    echo "Release prerequisite missing: $path (application implementation required)" >&2
    missing=1
  fi
done
# The exact module paths must be selected when real application modules exist.
python3 -c 'import json; p=json.load(open("coverage-policy.json")); assert p["python"] and p["swift"], "Configure real core-module coverage before releasing"' || missing=1
if [ "${1:-}" = "credentials" ]; then
  for name in RENDER_API_KEY RENDER_SERVICE_ID API_BASE_URL IOS_BUNDLE_ID APPLE_TEAM_ID \
    ASC_KEY_ID ASC_ISSUER_ID ASC_PRIVATE_KEY IOS_DISTRIBUTION_P12 IOS_CERT_PASSWORD \
    IOS_PROVISIONING_PROFILE DJANGO_WSGI_MODULE; do
    if ! printenv "$name" >/dev/null || [ -z "$(printenv "$name")" ]; then
      echo "Release setting missing: $name" >&2
      missing=1
    fi
  done
fi
[ "$missing" -eq 0 ] || { echo 'Release blocked; see README release prerequisites.' >&2; exit 1; }
