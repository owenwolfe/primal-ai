# Infrastructure Plan

> Planning only. This document describes future work. No installations, configuration changes, containers, workflows, deployments, or implementation files were created by this planning process.

## 1. Project and User Experience

- **Application:** Native iPhone food-label scanner focused on whole-food ingredient preferences.
- **Primary users:** Younger shoppers interested in understanding ingredients and food processing.
- **Primary task:** Photograph a label, review recognized text, and receive a rating with ingredient explanations and references.
- **Selected platform:** Native iOS, SwiftUI, and a Python/Django backend.
- **Camera experience:** Capture nutrition facts and the ingredient list, which may require separate photos; nutrition facts alone do not identify ingredients.
- **Device requirements:** iPhone camera permission; physical iPhone verification before beta releases; simulator for automated UI checks.
- **Connectivity:** Text recognition runs locally; obtaining a rating requires internet access.
- **MVP scope:** Camera scan and result display; search, saved history, accounts, and shared catalog are deferred.

## 2. Connectivity and Application Shape

- **Model:** Web-enabled mobile client with a stateless backend; no account or cross-device persistence in the MVP.
- **Flow:** Camera → Apple Vision text recognition → user correction → HTTPS request to Django → rating, explanation, and references.
- **Components:** One iOS application and one deployable Django service; no microservices or background workers initially.
- **API:** Django JSON endpoint with explicit request validation and a versioned response contract; URLSession in Swift.
- **Backend behavior:** Apply deterministic, versioned ingredient rules to supplied text; return unmatched or incomplete data explicitly.
- **Research:** Ship reviewed ingredient rules and citation metadata with backend releases; do not make every scan depend on a live literature search.
- **Rating meaning:** Describe alignment with the selected whole-food preferences; keep preference rules and supporting scientific findings identifiable.
- **Unresolved product rules:** Ingredient categories, sugar definitions, weighting, and rating scale require a product specification before implementation.
- **Recognition:** Long or unfamiliar names alone are not an implemented classification rule; use explicit ingredient identities and documented criteria.

## 3. Selected Technology Stack

| Area | Technology | Purpose | Version policy |
|---|---|---|---|
| Mobile language/UI | Swift and SwiftUI | Native screens and application state | Pin supported Xcode/Swift combination |
| Native SDKs | AVFoundation, Vision, URLSession | Camera, local text recognition, HTTPS | Match pinned iOS SDK; set minimum iOS target during implementation |
| Mobile dependencies/build | Swift Package Manager and Xcode | Resolve dependencies, simulator builds, signed archives | Commit Package.resolved when external packages exist |
| Backend language | Python | Ingredient evaluation and data integrations | Supported stable Python compatible with Django; pin minor version |
| Backend framework | Django | JSON API; future catalog administration | Supported Django LTS; pin resolved dependencies |
| Python packages | uv | Reproducible dependency resolution | Pin uv; commit uv.lock; enforce locked installation |
| Production server | Gunicorn | Serve Django in a Linux container | Pin through uv.lock |
| Rule/reference storage | Versioned JSON bundled with backend | Ingredient rules and reviewed source metadata | Include rule version in every result |

## 4. Storage and Persistence

- **MVP storage:** No durable user/product database; image and recognized-text processing is transient.
- **Phone:** Keep the active scan in memory; no saved-history feature in this release.
- **Backend:** Read-only bundled rules and references; no retained photos, submitted label text, or request-body logging.
- **Django configuration:** Omit database-backed admin, authentication, and session applications from the MVP runtime.
- **Object storage:** Not required because photos stay on the phone and are not retained by the backend.
- **Recovery:** Rebuild rules and service images from Git tags; preserve previous successful release artifacts.
- **Research sources:** Assume “pubnet” means PubMed; use NCBI E-utilities for reference collection during development when confirmed.
- **Source records:** Preserve PMID/URL, title, publication date, review date, and the specific rule supported; do not assume full-text reuse rights.

## 5. Testing Tools

| Layer | Tools | Planned scope | Execution |
|---|---|---|---|
| Mobile unit/integration | XCTest | Text processing, response decoding, API errors, rule-version display | Local and PR |
| Mobile UI | XCUITest | Capture entry, supplied label fixture, correction, loading, results, retry, permission denial | Simulator PR and release |
| Backend unit/integration | pytest, pytest-django | Ingredient identities, aliases, rating boundaries, references, API validation | Local and PR |
| Cross-component | Versioned JSON fixtures | Swift decoding and Django responses agree | PR |
| Physical camera | Manual iPhone smoke check | Real labels, glare, incomplete labels, permission prompts, network failure | Before TestFlight distribution |

- Automated camera tests use supplied images through a test-only capture seam; simulator success does not replace physical camera verification.
- External literature calls use recorded/synthetic responses; tests do not require a working PubMed connection.

## 6. Test Analysis

| Capability | Tool | Policy |
|---|---|---|
| Python coverage | coverage.py via pytest-cov | Measure backend rating/parser modules; report branch and line coverage |
| Swift coverage | Xcode coverage and xccov | Measure application-owned label-processing logic; exclude generated code and fixtures |
| Regression check | Small CI coverage comparison utility | Block decreases in core-module coverage against the PR base |
| Reports | GitHub Actions artifacts | Upload machine-readable reports and summaries; no external paid coverage service |

- Establish the first tested baseline before enforcing comparisons; compare module coverage percentages at reported precision, with no regression allowance.
- Generate the baseline from the exact base revision using trusted CI; baseline changes follow the same review path as code.
- Run core behavioral fixtures even when line coverage is unchanged; no mutation testing or hosted dashboard selected.
- These tools are free; GitHub Actions usage remains subject to account/repository allowances.

## 7. Static Analysis and Security

| Check | Tool | Planned enforcement |
|---|---|---|
| Swift formatting/style | Apple's swift-format lint | Block PRs on formatting/style findings |
| Swift type/compile checks | Swift compiler through Xcode | Build with strict warnings for application-owned code |
| Python format/lint | Ruff | Block formatting, lint, and selected complexity findings |
| Python types | mypy with django-stubs | Block type errors in application modules |
| Python dependencies | pip-audit against locked runtime packages | Block known vulnerabilities pending reviewed resolution |
| Swift dependencies | OSV-Scanner on Package.resolved when present | Block known vulnerabilities in external dependencies |
| Secrets | Gitleaks | Scan PR changes and release source; block detected credentials |
| Container vulnerabilities | Trivy | Scan backend image; block fixable high/critical runtime vulnerabilities |

- Use environment-provided secrets, HTTPS, explicit allowed hosts, bounded input sizes, timeouts, and request throttling.
- No shared server secret embedded in the iPhone app; no user login required for the selected MVP.
- Disable Django debug mode in hosting; exclude submitted food text and photos from diagnostic output.

## 8. Development Technologies Requiring Manual Installation

| Technology | Purpose/machines | Version policy | Future installation/verification | Why outside Docker |
|---|---|---|---|---|
| Git | All workstations | Supported stable | Platform installer; verify version | Host source checkout |
| macOS and Xcode with command-line tools | iOS developers and native CI | Pin supported release and simulator runtime | Apple distribution; verify selected Xcode and SDK | Native iOS builds/signing require Apple's environment |
| Docker Desktop or Engine with Compose | Backend developers | Supported stable; align Compose behavior | Vendor installer; verify engine/Compose | Host container runtime |
| Physical iPhone and TestFlight | Release tester | Supported iOS target | Install TestFlight and trust development setup as needed | Real camera and beta verification |

- **Docker supplies:** Python, uv, Django, Gunicorn, Python checks, and backend dependencies; host Python is optional.
- **CI supplies:** Pinned scanning utilities and swift-format if not included in the pinned Xcode toolchain.
- **Not required:** Node.js, Android Studio, local PostgreSQL, and a host Python environment.
- Linux can support backend work; the current Linux workspace cannot perform native iPhone builds locally.

## 9. Docker Plan

- **Role:** Backend development and production packaging; mobile work remains in Xcode.
- **Future files:** backend/Dockerfile, backend/.dockerignore, compose.yaml.
- **Services:** One Django service; no database container for the MVP.
- **Development:** Bind backend source into the container; development-only reload; bind port 8000 to loopback.
- **Device testing:** Use an HTTPS development endpoint or explicitly configured LAN access; simulator loopback is not physical-iPhone loopback.
- **Volumes:** No persistent data volume; dependency environment lives outside the source bind mount.
- **Secrets:** Supply untracked local environment values and hosted environment settings; never embed credentials in images.
- **Production:** Multi-stage build, locked dependencies, minimal Python runtime, non-root user, Gunicorn, platform PORT binding, and a /health endpoint.
- **Health check:** Verify process and rule-bundle load; expose service and rules versions without secrets.
- **Hardening:** Exclude caches, Git metadata, development dependencies, and local credentials; scan the final image.
- **Future development command:** `docker compose up --build` (proposed only; not executed).
- **Future native packaging:** Xcode archive/export on macOS using the committed signing/export configuration.

## 10. GitHub Actions Plan

### A. Automated pull-request checks

- **Future file:** .github/workflows/pr-checks.yml; primary trigger: pull_request.
- **Runners:** Ubuntu for backend/container checks; macOS with pinned Xcode and iPhone simulator for native checks.
- **Permissions:** contents: read by default; no deployment credentials on PR jobs; pin third-party actions to reviewed commit SHAs.
- **Jobs:** Checkout/runtime setup → locked dependency resolution → formatting/type/security checks and tests → coverage comparison → package/image validation → combined required check.
- **Parallelism:** Backend and native jobs can run independently; combined required check waits for both and image scanning.
- **Services:** No database/service containers; start the backend container for a synthetic API smoke check.
- **Caching:** Key uv downloads by OS/runtime/uv.lock; Swift dependencies by Xcode and Package.resolved; never cache signing keys.
- **Baseline:** Test the exact base revision for coverage or consume a verified artifact tied to that revision; never execute untrusted PR code with secrets.
- **Artifacts:** Python coverage, native xcresult/coverage, UI screenshots, smoke-check output, and scan reports; redact sensitive values.
- **Merge blockers:** Formatting, lint/types/compiler, behavioral tests, core coverage regression, API smoke, build validation, selected vulnerability and secret checks.
- **Proposed protection:** Require combined check, current-base validation, review, and no direct protected-branch pushes.

### B. New-release deployment

- **Future file:** .github/workflows/release.yml; trigger: deliberate v* tag from the protected branch.
- **Destination:** TestFlight plus managed container hosting; Render is a proposed default provider, not a separately confirmed selection.
- **Order:** Revalidate tagged source → build/scan immutable backend image → approve beta environment → deploy exact image → verify API → sign/upload app → verify processed TestFlight build.
- **Image delivery:** Publish to GHCR under the release tag and digest; configure the hosting service to deploy the exact image digest via its API.
- **Permissions:** contents: read; packages: write only in image publication; secrets available only to approved release jobs.
- **Signing:** Apple Developer Program membership, registered bundle ID, distribution certificate/private key, provisioning profile, and App Store Connect API credentials.
- **Key handling:** Import signing material into a temporary macOS keychain and remove it when the job ends.
- **Artifacts:** Signed IPA/archive, dSYMs, image digest, source/rules version, and release notes; increment iOS build number for each upload.
- **Migrations:** None in MVP. Backend changes must remain compatible with installed beta clients.
- **Verification:** HTTPS /health plus synthetic evaluation; verify TestFlight processing, then complete physical-camera smoke before inviting testers.
- **Store processing:** External testing may require Apple's beta review; upload success alone is not tester availability.
- **Failure/rollback:** Stop distribution on API failure; redeploy prior image digest; withdraw faulty beta build and upload a corrected build with a higher build number.

### GitHub configuration required later

| Name | Type | Purpose |
|---|---|---|
| beta | Protected environment | Approval and scoped release secrets |
| GITHUB_TOKEN | Automatic scoped token | Publish backend image to GHCR |
| RENDER_API_KEY / RENDER_SERVICE_ID | Secret / variable | Deploy exact backend image on proposed host |
| GHCR_READ_TOKEN | Hosting-side secret, if image private | Allow hosting service to pull backend images |
| API_BASE_URL / IOS_BUNDLE_ID / APPLE_TEAM_ID | Variables | API endpoint and application identity |
| ASC_KEY_ID / ASC_ISSUER_ID / ASC_PRIVATE_KEY | Secrets | App Store Connect upload authentication |
| IOS_DISTRIBUTION_P12 / IOS_CERT_PASSWORD / IOS_PROVISIONING_PROFILE | Secrets | Native distribution signing |
| DJANGO_SECRET_KEY / ALLOWED_HOSTS | Hosting secret / setting | Django production configuration |
| Apple Developer, App Store Connect, hosting, GHCR | Accounts/services | Beta distribution and backend hosting |

## 11. Planned Repository Artifacts — Not Created by This Skill

- [ ] ios/ application project, Swift sources, asset catalog, XCTest/XCUITest targets, and signing/export configuration.
- [ ] Package.resolved if external Swift packages are introduced; pinned native toolchain information.
- [ ] backend/pyproject.toml, uv.lock, Django settings/API, Gunicorn setup, and versioned rules/reference data.
- [ ] Backend tests, label-image fixtures, API contract fixtures, and coverage comparison utility.
- [ ] swift-format, Ruff, mypy, coverage, and scanner configuration where needed.
- [ ] backend/Dockerfile, backend/.dockerignore, compose.yaml, and environment-variable example without secret values.
- [ ] .github/workflows/pr-checks.yml and .github/workflows/release.yml.
- [ ] Managed hosting definition and TestFlight upload configuration after provider confirmation.

## 12. Assumptions, Open Items, and Future Features

- **Deferred shared catalog:** User selected self-managed PostgreSQL; add searchable previously checked products, Django admin, and schema migrations later.
- **Future persistence setup:** Separate database service/container locally; persistent production storage, restricted connections, encrypted backups, and tested restore procedure managed by the operator.
- **Future accounts/history:** Decide identity and history visibility when introducing shared records; no account system is selected for MVP.
- **Future research automation:** Confirm PubMed intent, then plan reviewable imports using NCBI limits and available rights; no vector database or LLM service selected.
- **Before implementation:** Define ingredient rules, rating format, photo correction behavior, initial language, minimum iOS target, and compatible supported toolchain pins.
- **Assumption:** MVP rules and citations are reviewed release assets, allowing scans without live research retrieval or a database.
- **External prerequisites:** Acquire Mac/iPhone access, Apple membership/signing credentials, and hosting account; confirm managed hosting provider and budget.
- **Cost boundary:** Free testing/coverage tools do not imply free Apple membership, hosting, or unlimited CI minutes.

### Documentation consulted

- [Apple Vision text recognition](https://developer.apple.com/documentation/vision/recognizing-text-in-images) — local extraction from photos.
- [Apple build uploads](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds) — native upload requirements.
- [Django deployment checklist](https://docs.djangoproject.com/en/stable/howto/deployment/checklist/) — hosted production settings.
- [uv locked dependency synchronization](https://docs.astral.sh/uv/concepts/projects/sync/) — reproducible Python environments.
- [Render image deployment](https://render.com/docs/deploying-an-image) — proposed container hosting path.
- [NCBI E-utilities parameters](https://www.ncbi.nlm.nih.gov/books/NBK25499/) — future PubMed integration and limits.
