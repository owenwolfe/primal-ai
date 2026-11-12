#!/bin/sh
# PR code runs only on unprivileged runners; no credentials enter this process.
set -eu
cd "$(dirname "$0")/.."
kind=${1:?python or swift required}
base=${BASE_SHA:-}
if [ -z "$base" ]; then
  echo 'Coverage comparison requires a PR base; current report retained.'
  exit 0
fi
case "$kind" in python|swift) ;; *) exit 2 ;; esac
if ! git cat-file -e "$base:coverage-policy.json" 2>/dev/null; then
  echo 'First infrastructure PR: coverage baseline will be established after merge.'
  exit 0
fi
worktree=$(mktemp -d /tmp/primal-coverage.XXXXXX)
cleanup() {
  if [ "$kind" = python ]; then
    docker compose -p "primal-base-$$" -f "$worktree/compose.yaml" down --remove-orphans
  fi
  git worktree remove --force "$worktree"
}
trap cleanup EXIT HUP INT TERM
git worktree add --detach "$worktree" "$base"
export LOCAL_UID="$(id -u)" LOCAL_GID="$(id -g)"
if [ "$kind" = python ]; then
  (cd "$worktree" && docker compose -p "primal-base-$$" run --build --rm backend python scripts/verify.py test)
  docker compose run --rm -v "$worktree:/baseline:ro" backend python scripts/check_coverage.py \
    /baseline/reports/coverage.json reports/coverage.json --base-policy /baseline/coverage-policy.json
else
  (cd "$worktree" && sh scripts/native-check.sh)
  # xccov comparison uses Python standard library; no Python dependencies needed.
  python3 scripts/check_coverage.py "$worktree/reports/swift-coverage.json" \
    reports/swift-coverage.json --kind swift --base-policy "$worktree/coverage-policy.json"
fi
