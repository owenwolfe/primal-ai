#!/bin/bash
# Release-only: requires protected environment and a completed application project.
set -euo pipefail
cd "$(dirname "$0")/.."
umask 077
signing_dir=$(mktemp -d "${RUNNER_TEMP:?}/primal-signing.XXXXXX")
keychain="$signing_dir/distribution.keychain-db"
profile_path=''
original_keychains=()
while IFS= read -r item; do
  original_keychains+=("$item")
done < <(security list-keychains -d user | sed 's/^[[:space:]]*"//;s/"$//')
cleanup() {
  set +e
  security list-keychains -d user -s "${original_keychains[@]}"
  security delete-keychain "$keychain" 2>/dev/null || true
  if [ -n "$profile_path" ]; then rm -f "$profile_path"; fi
  rm -f "$signing_dir/distribution.p12" "$signing_dir/profile.mobileprovision" \
    "$signing_dir/private_keys/AuthKey_${ASC_KEY_ID}.p8"
  rmdir "$signing_dir/private_keys" "$signing_dir" 2>/dev/null || true
}
trap cleanup EXIT
export SIGNING_DIR="$signing_dir"
python3 - <<'PY'
import base64
import os
from pathlib import Path
directory = Path(os.environ['SIGNING_DIR'])
(directory / 'distribution.p12').write_bytes(base64.b64decode(os.environ['IOS_DISTRIBUTION_P12'], validate=True))
(directory / 'profile.mobileprovision').write_bytes(base64.b64decode(os.environ['IOS_PROVISIONING_PROFILE'], validate=True))
(directory / 'private_keys').mkdir()
(directory / 'private_keys' / f"AuthKey_{os.environ['ASC_KEY_ID']}.p8").write_text(os.environ['ASC_PRIVATE_KEY'])
PY
keychain_password=$(openssl rand -hex 32)
security create-keychain -p "$keychain_password" "$keychain"
security set-keychain-settings -lut 21600 "$keychain"
security unlock-keychain -p "$keychain_password" "$keychain"
security import "$signing_dir/distribution.p12" -k "$keychain" -P "$IOS_CERT_PASSWORD" \
  -T /usr/bin/codesign -T /usr/bin/security >/dev/null
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$keychain_password" "$keychain" >/dev/null
security list-keychains -d user -s "$keychain" "${original_keychains[@]}"
uuid=$(security cms -D -i "$signing_dir/profile.mobileprovision" | plutil -extract UUID raw -o - -)
mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles" reports
candidate_profile="$HOME/Library/MobileDevice/Provisioning Profiles/$uuid.mobileprovision"
if [ -e "$candidate_profile" ]; then echo 'Refusing to overwrite an existing provisioning profile' >&2; exit 1; fi
cp "$signing_dir/profile.mobileprovision" "$candidate_profile"
profile_path="$candidate_profile"
# The application must consume API_BASE_URL through its build configuration.
xcodebuild archive -project ios/Primal.xcodeproj -scheme Primal -configuration Release \
  -destination generic/platform=iOS -archivePath reports/Primal.xcarchive \
  -onlyUsePackageVersionsFromResolvedFile DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
  PRODUCT_BUNDLE_IDENTIFIER="$IOS_BUNDLE_ID" CURRENT_PROJECT_VERSION="${GITHUB_RUN_NUMBER:?}.${GITHUB_RUN_ATTEMPT:?}" \
  API_BASE_URL="$API_BASE_URL" OTHER_CODE_SIGN_FLAGS="--keychain $keychain"
xcodebuild -exportArchive -archivePath reports/Primal.xcarchive \
  -exportOptionsPlist ios/ExportOptions.plist -exportPath reports/export
cp reports/export/*.ipa reports/Primal.ipa
shasum -a 256 reports/Primal.ipa > reports/checksums.txt
export API_PRIVATE_KEYS_DIR="$signing_dir/private_keys"
xcrun altool --validate-app --type ios -f reports/Primal.ipa --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
xcrun altool --upload-app --type ios -f reports/Primal.ipa --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
echo 'Upload complete. Confirm processing and beta-review status in App Store Connect before inviting testers.'
