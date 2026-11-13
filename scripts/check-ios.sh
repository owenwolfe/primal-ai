#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
command -v xcodebuild >/dev/null 2>&1 || {
    echo 'Native verification requires macOS and Xcode.' >&2
    exit 1
}
xcodebuild -version
uv sync --project backend --locked
# UI tests exercise the real local evaluator with synthetic labels, not mocked app results.
DJANGO_DEBUG=1 backend/.venv/bin/gunicorn --chdir backend primal.wsgi:application \
    --no-control-socket --bind 127.0.0.1:8765 --workers 1 &
BACKEND_PID=$!
trap 'kill "$BACKEND_PID" 2>/dev/null || true' EXIT INT TERM
ATTEMPTS=0
until python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8765/health', timeout=1)" 2>/dev/null; do
    kill -0 "$BACKEND_PID" || exit 1
    ATTEMPTS=$((ATTEMPTS + 1))
    [ "$ATTEMPTS" -lt 20 ] || { echo 'Test backend did not start.' >&2; exit 1; }
    sleep 1
done
# Use an installed iPhone simulator, rather than coupling tests to a device name.
SIMULATOR_ID=$(xcrun simctl list devices available --json | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
for runtime, entries in devices.items():
    if "iOS" in runtime:
        for device in entries:
            if device.get("isAvailable") and "iPhone" in device["name"]:
                print(device["udid"])
                sys.exit(0)
sys.exit("Install an iPhone simulator runtime in Xcode first.")
')
xcodebuild test -project ios/Primal.xcodeproj -scheme Primal \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -derivedDataPath /tmp/primal-derived-data CODE_SIGNING_ALLOWED=NO
