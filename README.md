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
