# Primal

A native iPhone ingredient-label scanner for whole-food preferences. Photograph a label,
review the on-device OCR text, and get an ingredient-by-ingredient explanation from Django.

This is an initial MVP implementation. Ratings use an explicitly labeled **draft preference
model**, not a medical, nutritional, allergen, or food-safety assessment. Unknown ingredients
prevent an overall rating. Rule review and native verification are required before public release.

## Run the backend

Install [uv](https://docs.astral.sh/uv/getting-started/installation/) and use Python 3.12:

```sh
uv sync --project backend --locked
DJANGO_DEBUG=1 backend/.venv/bin/python backend/manage.py runserver 127.0.0.1:8000
```

In another terminal:

```sh
python3 scripts/smoke-api.py
```

Alternatively, with Docker and Compose:

```sh
docker compose up --build -d --wait
python3 scripts/smoke-api.py
docker compose down --remove-orphans
```

Compose binds to host loopback and has no database or persistent volume. Rebuild after source
changes. It is a local-development configuration, not a public hosting configuration.

Example request:

```sh
curl http://127.0.0.1:8000/api/v1/evaluations \
  -H 'Content-Type: application/json' \
  -d '{"ingredientText":"oats, almonds, honey"}'
```

`GET /health` confirms service/rule loading. See [the OpenAPI contract](contracts/openapi.json)
and [shared fixture](contracts/evaluation.json) for response and error shapes.

## Run the iPhone app

On a Mac with Xcode 16 or later and an installed iOS simulator:

1. Open `ios/Primal.xcodeproj` and select the shared **Primal** scheme.
2. Select an iPhone simulator and Run. No external Swift packages are needed.
3. Start the backend on that Mac. The Debug simulator app defaults to `http://localhost:8000`.
4. Tap the example label or enter ingredients, then **Understand this label**.
5. Use **Connection** to point to a different backend. Release builds require HTTPS.

To run on an iPhone, select your signing team and replace `com.example.primal` with your
bundle identifier. Use a reachable HTTPS API address; the phone cannot reach your Mac through
`localhost`. The photo picker works with supplied label images; the simulator has no camera.
Camera permission is requested only when photographing a label. You can always type ingredients.

`API_BASE_URL` is an optional Xcode build setting for a default server address; Connection
settings override it on that device. No API key belongs in the app. The app retains only the
active scan in memory and the chosen server address in user defaults.

## Checks

```sh
sh scripts/check-backend.sh
# macOS only; starts a test backend on port 8765:
sh scripts/check-ios.sh
git diff --check
```

Native checks need uv, Xcode, and an installed iPhone simulator. The committed Xcode project
includes unit and UI targets. After adding Swift files, regenerate its file references with
`python3 scripts/generate-xcode-project.py`; no third-party project generator is needed.

GitHub Actions defines backend checks, a Docker HTTP smoke test, and native simulator tests.
Workflow definitions are included; a successful hosted run has not yet been observed.

## Structure and extension points

| Path | Purpose |
| --- | --- |
| `ios/Primal/` | SwiftUI screens, scan state, camera, OCR, typed API client |
| `ios/PrimalTests/`, `ios/PrimalUITests/` | Native contract/state and end-to-end tests |
| `backend/primal/` | Stateless Django API and independent preference evaluator |
| `backend/primal/rules.json` | Versioned draft ingredient rules and explanations |
| `backend/tests/` | Behavioral, validation, and JSON Schema contract tests |
| `contracts/` | OpenAPI contract and fixture shared with Swift tests |
| `scripts/` | Local checks, project generation, and HTTP smoke test |

See [architecture and rule policy](docs/architecture.md) for boundaries and release requirements.
Accounts, history, search, catalog, and persistence are deferred. The protocols separating OCR,
networking, and scan state allow those features to be added without embedding services in views.

## Production configuration

The Docker runtime is non-root and uses Gunicorn with locked dependencies. Before hosting,
set `DJANGO_SECRET_KEY` to a generated secret and `ALLOWED_HOSTS` to your service hostname;
leave `DJANGO_DEBUG` unset. `PORT` defaults to 8000. Configure HTTPS termination and, only
behind a proxy that sanitizes forwarded headers, set `TRUST_PROXY=1`. Add ingress rate and
request limits before public access. This repository has no automatic deployment or real secrets.

Never commit credentials, `.env`, scan photos, build artifacts, or reports.
Alternative to health scanner apps such as Yuka for those simply looking for clean ingredients.

The planned MVP is a native iPhone camera scanner with a Python/Django backend.
Infrastructure is present; the iOS app, Django application, rating logic, and health/API
endpoints are **not implemented**. Shared search and self-managed PostgreSQL are future features.
See [the infrastructure plan](infrastructure_plan.md) for the selected direction.

## Repository map

| Location | Current contents |
|---|---|
| `backend/` | Python manifest/lockfile and Docker stages; no application source |
| `ios/Config/` | Native compiler quality configuration; no Xcode project or screens |
| `scripts/` | Local checks, coverage comparison, Docker probes, release-only tooling |
| `tests/infrastructure/` | Toolchain/configuration probes; no product tests |
| `compose.yaml` | One-shot backend tooling container; no running web service/database |
| `.github/workflows/` | PR checks and guarded beta release definition |
| `infrastructure_plan.md` | Planning decisions, deferred database/catalog, research assumptions |
| `AGENTS.md`, `.agents/skills/` | Project guidance and existing local skills |

## Getting Started

1. Install [Git](https://git-scm.com/downloads) and verify `git --version`.
2. Install [Docker Desktop](https://docs.docker.com/desktop/) on Mac/Windows, or
   [Docker Engine](https://docs.docker.com/engine/install/) with the Compose plugin on Linux.
   Start Docker and verify `docker info` and `docker compose version`.
   Linux users need permission to access the Docker socket; follow Docker's documented setup.
3. Clone the repository and enter its root. No database, Node.js, or host Python is needed
   for the Docker route. BuildKit must be enabled (default in current Docker releases).
4. Configure bind-mount ownership if your user ID differs from 1000:

   ```sh
   cp .env.example .env
   # Edit LOCAL_UID / LOCAL_GID to match id -u / id -g (Linux).
   docker compose config --quiet
   ```

   `.env` is ignored and used only for Compose interpolation. Infrastructure checks require
   no secrets. Future Django secrets belong in local untracked settings or Render settings.
5. Build and verify the complete local infrastructure:

   ```sh
   sh scripts/docker-smoke.sh
   ```

   This enforces locked installs, runs format/lint/types and the infrastructure tests,
   emits coverage reports, builds the runtime image, and verifies dependencies as a non-root user.
   Its disposable Compose project is cleaned up automatically. Images/build caches are retained.
6. Run individual checks or a shell when needed:

   ```sh
   docker compose build backend
   docker compose run --rm backend python scripts/verify.py
   docker compose run --rm backend python scripts/verify.py format
   docker compose run --rm backend python scripts/verify.py lint
   docker compose run --rm backend python scripts/verify.py types
   docker compose run --rm backend python scripts/verify.py test
   docker compose run --rm backend sh
   docker compose down --remove-orphans
   ```

   `docker compose up --build` also runs the one-shot checks and exits; it does not start an API.
   There are no exposed ports, persistent data volumes, or background services yet.
7. Run the network-dependent security checks separately:

   ```sh
   docker compose run --rm backend uv export --project backend --locked --no-dev --no-emit-project --no-hashes -o reports/runtime-requirements.txt
   docker compose run --rm backend python scripts/verify.py audit
   sh scripts/security.sh source
   sh scripts/security.sh image primal-runtime:local
   docker compose down --remove-orphans
   ```

   `source` scans for secrets and audits Swift lockfiles if any exist. `image` scans the locally
   built runtime for fixable high/critical vulnerabilities. `.gitleaksignore` contains one reviewed
   fingerprint for ordinary prose in an existing floor-plan skill; no directory is excluded.
   Scanners need internet access; the image scan mounts the local Docker socket read-only.

### Native development prerequisites

Use a Mac with a supported macOS version and install **Xcode 26.6** from
[Apple Developer downloads](https://developer.apple.com/download/all/).
The CI runner is `macos-26`; the version is explicit in `toolchain.json` and workflow settings.
Open Xcode once, accept its license, and install the iOS simulator components when prompted.

```sh
sudo xcode-select --switch /Applications/Xcode_26.6.app/Contents/Developer
xcodebuild -version
xcrun simctl list devices available
sh scripts/native-check.sh
```

Currently this checks the native toolchain; it does not build/test a nonexistent app.
When application development creates `ios/Primal.xcodeproj`, share a `Primal` scheme with
XCTest/XCUITest targets, attach `ios/Config/Quality.xcconfig`, choose the minimum iOS version,
and configure a simulator destination with `IOS_TEST_DESTINATION`.
No Swift dependency lockfile is generated until external dependencies exist.
Use a physical iPhone for camera/permission verification before inviting beta testers.
Docker cannot supply Xcode, Apple signing, the simulator, or physical camera testing.

### Optional host Python workflow

For checks without Docker, install Python 3.14 from [Python.org](https://www.python.org/downloads/)
and uv 0.13.7 from [the official uv instructions](https://docs.astral.sh/uv/getting-started/installation/).
Then, from the repository root:

```sh
uv sync --project backend --locked
uv run --project backend --locked python scripts/verify.py
```

Python tools never require Docker when available on the host; Docker smoke/image checks do.
The Django type-checker plugin is deferred until real Django settings exist; `django-stubs`
is installed now. Tests configure only an empty, database-free Django test harness.

## Versions, dependencies, and coverage

Python 3.14 and uv 0.13.7 images are pinned by digest; Django is restricted to supported 5.2 LTS.
`backend/uv.lock` records exact resolved runtime/development dependencies and hashes.
`toolchain.json` records native/scanner versions. Update pins and digests through reviewed PRs
and rerun the full smoke/security checks. CI Actions are pinned to commit SHAs.
The runtime image removes the base image's unused pip installer and its vendored libraries;
application dependencies are copied from the locked uv environment.

To intentionally update dependencies, use the selected package manager inside the existing container:

```sh
docker compose run --rm backend uv lock --project backend --upgrade
docker compose build backend
sh scripts/docker-smoke.sh
```

Reports go under ignored `reports/`. Current coverage measures infrastructure scripts only;
it is not a product-quality claim. `coverage-policy.json` intentionally contains no core modules.
When real rating/label-processing modules exist, add their stable relative path prefixes to that
policy and the coverage source configuration, add their behavioral tests, and establish a reviewed
baseline. Swift results normalize checkout paths before comparison. Core decreases block CI once
configured; release readiness requires nonempty Python and Swift core coverage selections.
No paid coverage service or mutation tool is required. GitHub Actions usage allowances still apply.

## GitHub configuration and release readiness

PR CI runs backend checks in Docker on Ubuntu and native checks on macOS. It caches BuildKit
layers and Swift dependency downloads, uploads reports, and exposes **Required checks** as the
combined status. After pushing, configure branch protection on `main` to require that status,
review, current-base validation, and no direct/force pushes. No repository settings were changed.
The first infrastructure PR establishes the coverage harness; subsequent PRs compare the exact base
revision in an isolated worktree with no release secrets. Release tags must point to commits on main.

The `v*` release workflow is deliberately blocked until the Django entrypoint, native project,
export options, core coverage selections, and release configuration exist. It validates before
publishing, scans the runtime, publishes a commit-tagged GHCR image, asks Render to deploy the
exact image digest, verifies `/health`, then signs and uploads the app. Store processing and
physical-camera approval are manual steps before tester invitations; upload does not mean approval.
**Do not run release scripts locally during infrastructure work.**

Configure the protected GitHub environment `beta` with required reviewers, and restrict deployments
to release tags. These are manual prerequisites, not created by this task:

| Location | Names | Purpose |
|---|---|---|
| GitHub `beta` secrets | `RENDER_API_KEY` | Render API deployment access |
| GitHub `beta` variables | `RENDER_SERVICE_ID`, `API_BASE_URL`, `DJANGO_WSGI_MODULE` | Existing image-backed service, HTTPS API URL, future WSGI entrypoint |
| GitHub `beta` variables | `IOS_BUNDLE_ID`, `APPLE_TEAM_ID` | Registered Apple app/team identity |
| GitHub `beta` secrets | `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY` | App Store Connect API key identifiers and raw P8 contents |
| GitHub `beta` secrets | `IOS_DISTRIBUTION_P12`, `IOS_CERT_PASSWORD`, `IOS_PROVISIONING_PROFILE` | Base64 P12/profile and certificate password |
| Render service settings | `DJANGO_SECRET_KEY`, `ALLOWED_HOSTS`, `DJANGO_WSGI_MODULE` | Future Django production settings; keep DEBUG disabled |
| Render registry credentials | `GHCR_READ_TOKEN` if private | Read-only access to the published GHCR image |
| GitHub automatic token | `GITHUB_TOKEN` | Package publication only in the image job |

You need Apple Developer Program membership, App Store Connect access with a registered app,
distribution signing assets, GitHub/GHCR access, and a Render account. None are needed for local
infrastructure checks. Never paste secret values into repository files or chat.

Create the Render image-backed web service later using its dashboard and the matching GHCR image
repository, disable automatic deploys, set `/health` as the health check once implemented, and
configure environment settings and registry credentials. The service's first provisioning/deploy
is a separate authorized operation. [Render image deployment](https://render.com/docs/deploying-an-image)
and [deploy API](https://api-docs.render.com/reference/create-deploy) document these settings.
No cloud resources or provider configuration have been created here.

Application implementation must supply `backend/manage.py`, its actual WSGI module, the `/health`
endpoint, safe production settings, rule data, request limits, and synthetic API tests before release.
It must also create the native app, reference the API build setting, and provide
`ios/ExportOptions.plist` with manual distribution signing/profile mappings. The signing script
uses a temporary keychain, restores the original search list, and removes its imported profile/key files.

If release validation or backend health fails, distribution stops. For recovery, deploy the previous
known-good digest using Render; withdraw a faulty TestFlight build and upload a fixed build with
a higher build number. Release scripts retain no production data and perform no database migrations.

## Troubleshooting

- **Docker socket denied/unavailable:** Start Docker or arrange socket access using Docker's official
  instructions; do not change the socket to world-writable. This workspace required elevated Docker access.
- **Bind-mount files not writable:** Set `LOCAL_UID`/`LOCAL_GID`; the development container uses your
  selected UID, while runtime images always use non-root UID 10001.
- **Locked install fails:** Check network access and that manifest/lockfile agree. Update with uv deliberately;
  do not remove `--locked` to mask a stale lockfile.
- **Xcode version missing:** Install/select the pinned version or review an aligned toolchain/CI update.
  Hosted runner inventories can change; confirm the pinned Xcode remains available before merging upgrades.
- **No API responds on port 8000:** Expected at this stage. Add the application entrypoint during product
  implementation before configuring server startup, port mapping, reload, or runtime health checks.
- **Physical iPhone cannot reach a future local backend:** Phone loopback is not the Mac; configure an
  HTTPS development endpoint or deliberate LAN access when a real backend exists.

## Verification status

Verified locally: locked dependency installation, Compose parsing, development/runtime builds,
non-root runtime imports, formatting, lint, types, infrastructure probes, coverage reports,
Actionlint workflow validation, ignore rules, runtime dependency audit, and secret scanning.
The hardened image passed the configured fixable high/critical vulnerability gate.
Native Xcode checks, GitHub-hosted jobs, signing, Render deployment, TestFlight upload, and Apple
processing require their respective external environment and were not executed in this Linux workspace.
