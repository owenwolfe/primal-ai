# Primal MVP

## Product scope and current state

A native iPhone app that photographs or imports an English ingredient label, recognizes text
on the device, lets the shopper correct it, and requests an explainable preference evaluation.
Manual text entry works independently of the camera. iOS 17 is the initial minimum target.

The implementation includes SwiftUI screens, camera/OCR adapters, an ephemeral API client,
a stateless Django application, a draft rule bundle, an Xcode project, and test/CI definitions.
Accounts, search, saved history, shared catalog, nutrition calculations, barcode lookup,
live research retrieval, and medical/allergen assessments are outside this MVP.
There is no database or cloud provisioning.

## Boundaries

```text
ScanView / ResultView / ConnectionView
                  |
              ScanModel
              /       \
       Recognizing    Evaluating
           |              |
     Apple Vision      APIClient / URLSession
                          |
                POST /api/v1/evaluations
                          |
               Django request validation
                          |
                evaluate(ingredientText)
                          |
                   rules.json
```

The view model owns active scan state and guards against results arriving after reset.
OCR and networking use separate protocols so neither is embedded in a view. The evaluator
is ordinary Python with no HTTP, database, or external-service dependency.
UI primitives share a compact palette and native Dynamic Type text styles. Ingredient
detail rows use text as well as symbols so meaning does not depend on color.

## Contract and evolution

`contracts/openapi.json` is the public contract. `contracts/evaluation.json` is a shared
example asserted against the backend and decoded by XCTest. Backend contract tests validate
all result states against the JSON Schema. URL paths use API version `v1`; `schemaVersion`
identifies the response shape and `rulesVersion` identifies the independent preference model.

Keep existing fields and meanings stable. Extend responses with optional fields. Swift's
decoder ignores extra fields; category strings have fallback presentation. Changes to the
meaning of existing fields require a new contract and an installed-client compatibility plan.
Requests intentionally reject unknown fields in v1 to catch misspellings.

Before adding a feature, identify its owner. History should consume evaluation results through
a new persistence boundary; it should not make views depend on a database. A future catalog
should remain separate from text evaluation. Do not introduce a generic plugin system or
microservices until a concrete need warrants them.

## Draft preference policy

`draft-1` is an explicit product assumption, not reviewed scientific evidence:

- Exact aliases match a small bundled English ingredient vocabulary.
- Whole foods and culinary staples align with this preference model.
- Added sweeteners and selected additives trigger a preference review.
- Unmatched or compound ingredients prevent an overall rating.
- Names alone do not imply safety, danger, degree of processing, or nutrient amounts.

There is no numeric health score or scientific citation claim. The interface displays the
methodology and basis of each finding. Before public release, review the categories and
aliases against product requirements. If scientific findings are introduced, store reviewed
source identifiers, dates, and the specific claim supported separately from preference rules.

Parsing preserves compound ingredients as a single unknown item; it does not silently classify
their components. Malformed brackets and nutrition panels return an actionable error.
The user must confirm that the submitted ingredient list is complete; the system cannot detect
every truncated or incorrectly recognized label. An allergen statement is never a safety check.

## Privacy and security

The active photo/text/result are transient app state. Only confirmed ingredient text is sent;
the server has no persistence and does not log request bodies. The API address is the only
app preference stored locally. Transport sessions are ephemeral with no cookie store/cache.
Release app builds accept HTTPS API addresses; development builds permit HTTP for local testing.

The backend reads at most 32 KiB of a request before rejecting it. It validates text type,
Unicode, length (8,000 code points), ingredient count (100), JSON shape, and content type.
It sets no-store response headers, disables production debug output, requires a production
secret, redirects HTTP to HTTPS, and loads bundled rules at startup. No shared API secret is
embedded in the app. Errors have stable machine codes and readable retry instructions.

Before exposing the service publicly, configure trusted TLS termination, explicit allowed hosts,
ingress request limits/rate limits, operational monitoring, and dependency/container scanning.
`TRUST_PROXY=1` is valid only when the proxy strips incoming forwarded-protocol headers.
No production deployment or signing credentials are included.
HSTS preload is deliberately not requested for an unprovisioned hostname; Django's deployment
check reports this as a warning. Decide on domain-wide preload only with the domain owner.

## Acceptance and verification

- A shopper can type ingredients, submit them, and inspect each finding.
- The example `oats, almonds, honey` yields preference review.
- `oats, mystery ingredient` withholds the overall rating.
- Request failures preserve the text for retry; editing invalidates previous results.
- Camera denial/unavailability has a readable alternative; empty OCR can be retried.
- Reset prevents an earlier network operation from changing a new scan.
- No photo is included in an API request.

`scripts/check-backend.sh` runs formatting, lint, Django checks, behavioral and contract tests.
`scripts/smoke-api.py` verifies a real running Gunicorn service over HTTP.
`scripts/check-ios.sh` starts a synthetic-label backend on port 8765, chooses an installed
iPhone simulator, and runs unit/UI tests. Port 8765 must be free. The UI tests use the real
backend and inject only its base URL via the normal user-defaults mechanism.

Mac verification is still required: compile/test both configurations, inspect the interface at
large text sizes, test dark mode and VoiceOver, and exercise portrait photo OCR on real labels.
Physical-device checks must cover glare, rotated images, incomplete lists, camera permission
denial, offline/retry, and a reachable HTTPS backend. Distribution additionally needs a unique
bundle ID, signing team, app icon, privacy disclosures, reviewed rules, and TestFlight validation.

### Local verification, 2026-11-12

On the macOS workstation, the locked Python 3.12 environment installed successfully.
`sh scripts/check-backend.sh` passed lint, formatting, Django checks, and all 39 tests
with 93% combined line/branch coverage. The API now handles JSON decoder recursion limits
with the existing `INVALID_JSON` error rather than an unhandled server error; its regression
test submits a deeply nested request below the 32 KiB body limit.
`python3 scripts/smoke-api.py` also passed against a local Gunicorn server.

Docker Desktop was subsequently installed. The Compose image built, its container became
healthy, and the HTTP smoke test passed against the containerized API. Test containers and
their Compose network were removed afterward; the image and build cache were retained.
Xcode 26.3 is now installed on macOS 15.6.1. The iOS 26.2 arm64 simulator runtime was
installed and Xcode's first-launch component update completed. Direct Debug and Release
app-target builds passed using:

```sh
xcodebuild -project ios/Primal.xcodeproj -target Primal -configuration Debug \
  -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO SYMROOT=/tmp/primal-target-build
# Repeat with -configuration Release for the optimized build.
```

The Debug app installed and launched on the iPhone 17 Pro simulator, and its opening screen
was visually inspected. The local Compose backend was left running for interactive testing.
Unit/UI tests remain unverified: `scripts/check-ios.sh` fails during destination discovery
with “iOS 26.2 is not installed,” even though simctl can boot that runtime and direct SDK
builds succeed. Explicit simulator SDK overrides and the first-launch component update did
not resolve it. Investigate scheme/platform destination discovery before claiming native tests
pass. Logs for this workstation session are in `/tmp/primal-native-check.log` and
`/tmp/primal-release-build.log`; these temporary files are not repository artifacts.
No deployment or signing was performed. Existing v1 request/response fields and evaluator
behavior are unchanged.

## Primary implementation references

- [Apple Vision text recognition](https://developer.apple.com/documentation/vision/recognizing-text-in-images)
- [Django JSON responses](https://docs.djangoproject.com/en/5.2/ref/request-response/)
- [Django deployment checklist](https://docs.djangoproject.com/en/5.2/howto/deployment/checklist/)
- [Gunicorn release notes](https://gunicorn.org/news/) for the current HTTP parser behavior.
