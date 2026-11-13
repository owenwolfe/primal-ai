# Project guidance

## Status and source of truth

Read `infrastructure_plan.md`, this file, and `README.md` before editing. Follow any deeper
instructions in the directory you change. The plan records confirmed choices; Render was
confirmed in the implementation conversation. Use `infra-planner` to revise platform/storage
decisions rather than silently substituting tools.

This is an infrastructure foundation for a SwiftUI iPhone scanner and Python/Django backend.
No product code exists. Camera, OCR integration, ratings, APIs, rules, accounts, catalog,
and production health endpoints belong to a separately scoped application task.
Shared PostgreSQL/search/history is deferred; do not introduce database services now.

## Repository map

- `backend/pyproject.toml`, `backend/uv.lock`: Python/Django tooling and locked dependencies.
- `backend/Dockerfile`, `backend/.dockerignore`, `compose.yaml`: backend-only containers.
- `ios/Config/Quality.xcconfig`, `.swift-format`: native quality settings.
- `ios/Primal.xcodeproj`, native screens and application source: **not created yet**.
- Django settings/entrypoints/API modules and rule/reference assets: **not created yet**.
- `scripts/`: verification, coverage, container probes, release-only scripts.
- `tests/infrastructure/`: local toolchain/configuration tests; no product tests.
- `.github/workflows/pr-checks.yml`, `release.yml`: required checks and guarded beta release.
- `toolchain.json`, `coverage-policy.json`: version pins and future core-module coverage paths.
- `README.md`, `infrastructure_plan.md`: setup instructions and decisions.
- `.agents/skills/`: existing user-maintained skill library; preserve unrelated changes.

## Skills and boundaries

- Planning: `infra-planner`; infrastructure implementation: `infra-builder`.
- Application work: `spec-driven-development`, `incremental-implementation`, and
  `api-and-interface-design` as appropriate to the requested work.
- Tests: `test-driven-development`; debugging: `debugging-and-error-recovery` when needed.
- UI/browser: `frontend-ui-engineering` for applicable UI work; browser-testing skills only
  if an actual browser surface is introduced. This project has no browser application.
- Security: `security-and-hardening`; CI: `ci-cd-and-automation`.
- Documentation: `documentation-and-adrs`; review: `code-review-and-quality`.
- Git: `git-workflow-and-versioning`; use `git-commit` only when a commit is requested.

Infrastructure-only changes must not add app screens, endpoints, rules, domain models,
authentication, or pretend product tests. Do not bootstrap a fake application to make CI green.
Document unavailable product checks accurately. Never deploy, publish, provision, upload,
or use real release credentials while doing infrastructure work.

## Verification commands

Run from the root:

```sh
sh scripts/docker-smoke.sh
docker compose run --rm backend uv export --project backend --locked --no-dev --no-emit-project --no-hashes -o reports/runtime-requirements.txt
docker compose run --rm backend python scripts/verify.py audit
sh scripts/security.sh source
sh scripts/security.sh image primal-runtime:local
docker compose down --remove-orphans
git diff --check
```

For narrower changes: `docker compose run --rm backend python scripts/verify.py format|lint|types|test`
(choose a single argument). Optional host equivalent:
`uv run --project backend --locked python scripts/verify.py`.
On a Mac with pinned Xcode: `sh scripts/native-check.sh`.
CI runs equivalent checks plus exact-base coverage comparisons and native toolchain validation.
Do not count infrastructure coverage as application coverage. Add real core paths and sources
with the application implementation; beta readiness requires both language policies populated.

## Docker and data lifecycle

Compose defaults to disposable, one-shot checks, with no exposed server port or database.
Use your host UID/GID for writable reports. Do not run uv sync in the mounted development
workspace inside Docker: dependencies are image-owned at `/opt/venv`; rebuild the image instead.
The smoke script cleans its unique project; clean normal Compose networks after manual checks.
Keep build caches/images for reuse; do not prune unrelated Docker resources.
No production data or persistent database volumes are currently configured.

## Change checklist

- Keep dependencies locked with uv; align reviewed version/digest changes across Docker,
  toolchain metadata, workflow settings, and README.
- Add meaningful probes for infrastructure behavior; no fabricated product success checks.
- Run relevant local checks and report exact limitations of unverified native/external steps.
- Review `git diff --check`, changed files, ignore rules, workflow permissions, and secret references.
- Update README/this map whenever paths or commands change; preserve unrelated user work.
- Never commit `.env`, keys, signing assets, reports, build output, or credentials.
