#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
expected=$(python3 -c 'import json; print(json.load(open("toolchain.json"))["xcode"])')
actual=$(xcodebuild -version | head -n 1)
[ "$actual" = "Xcode $expected" ] || { echo "Expected Xcode $expected; found $actual" >&2; exit 1; }
xcrun swift-format --version
if find ios -name '*.swift' -print -quit | read -r _; then
  xcrun swift-format lint --strict --recursive ios
fi
if [ ! -d ios/Primal.xcodeproj ]; then
  echo 'Native toolchain verified. App project and XCTest/XCUITest targets are not created yet.'
  exit 0
fi
mkdir -p reports
xcodebuild -resolvePackageDependencies -project ios/Primal.xcodeproj -scheme Primal
xcodebuild test -project ios/Primal.xcodeproj -scheme Primal \
  -destination "${IOS_TEST_DESTINATION:?Set an available iPhone simulator destination}" \
  -onlyUsePackageVersionsFromResolvedFile -enableCodeCoverage YES \
  -resultBundlePath reports/native.xcresult CODE_SIGNING_ALLOWED=NO \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES GCC_TREAT_WARNINGS_AS_ERRORS=YES
xcrun xccov view --report --json reports/native.xcresult > reports/swift-coverage.json
