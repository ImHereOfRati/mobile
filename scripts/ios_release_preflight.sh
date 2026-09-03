#!/usr/bin/env bash
# iOS release preflight. Run from client/ on the macOS build machine before archiving.
# Read-only checks plus `flutter pub get` / `pod install`; it never uploads anything.
set -euo pipefail

cd "$(dirname "$0")/.."

fail=0
ok()   { printf '  ok   %s\n' "$1"; }
bad()  { printf '  FAIL %s\n' "$1"; fail=1; }
warn() { printf '  warn %s\n' "$1"; }

echo "== host =="
if [ "$(uname -s)" != "Darwin" ]; then
  bad "iOS archives require macOS; this host is $(uname -s)."
else
  ok "macOS $(sw_vers -productVersion)"
  if command -v xcodebuild >/dev/null 2>&1; then
    ok "$(xcodebuild -version | head -1)"
  else
    bad "xcodebuild not found; install Xcode and run 'sudo xcode-select -s /Applications/Xcode.app'."
  fi
  command -v pod >/dev/null 2>&1 || bad "CocoaPods not installed (gem install cocoapods)."
fi

echo "== signing / client ids (ios/Signing.xcconfig) =="
signing=ios/Signing.xcconfig
if [ ! -f "$signing" ]; then
  bad "$signing is missing."
else
  for key in DEVELOPMENT_TEAM GOOGLE_IOS_CLIENT_ID GOOGLE_IOS_REVERSED_CLIENT_ID; do
    value="$(sed -n "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*//p" "$signing" | head -1)"
    if [ -z "$value" ]; then
      bad "$key is empty in $signing."
    else
      ok "$key is set"
    fi
  done
fi

echo "== runtime secrets (iam_here_flutter_secret.env) =="
env_file=iam_here_flutter_secret.env
if [ ! -f "$env_file" ]; then
  bad "$env_file is missing; the app bundles it as a Flutter asset."
else
  for key in KAKAO_NATIVE_APP_KEY GOOGLE_SERVER_CLIENT_ID \
             FIREBASE_IOS_API_KEY FIREBASE_IOS_APP_ID FIREBASE_IOS_MESSAGING_SENDER_ID \
             FIREBASE_IOS_PROJECT_ID FIREBASE_IOS_STORAGE_BUCKET FIREBASE_IOS_BUNDLE_ID; do
    if grep -qE "^${key}=.+" "$env_file"; then ok "$key is set"; else bad "$key is missing or empty."; fi
  done
  bundle_id="$(sed -n 's/^FIREBASE_IOS_BUNDLE_ID=//p' "$env_file" | tr -d '\r' | head -1)"
  project_bundle_id=com.kdongsu5509.iamhere
  if [ -n "$bundle_id" ] && [ "$bundle_id" != "$project_bundle_id" ]; then
    bad "FIREBASE_IOS_BUNDLE_ID ($bundle_id) does not match PRODUCT_BUNDLE_IDENTIFIER ($project_bundle_id)."
  fi
fi

echo "== kakao url scheme =="
kakao_key="$(sed -n 's/^KAKAO_NATIVE_APP_KEY=//p' "$env_file" 2>/dev/null | tr -d '\r' | head -1)"
if [ -n "$kakao_key" ]; then
  if grep -q "<string>kakao${kakao_key}</string>" ios/Runner/Info.plist; then
    ok "Info.plist registers kakao${kakao_key}"
  else
    bad "Info.plist has no CFBundleURLSchemes entry 'kakao${kakao_key}'."
  fi
fi

echo "== version =="
version_line="$(sed -n 's/^version: //p' pubspec.yaml | head -1)"
ok "pubspec version $version_line (CFBundleVersion must be unused in App Store Connect)"

echo "== flutter =="
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart analyze lib

echo "== pods =="
(cd ios && pod install --repo-update)
if grep -q "Firebase" ios/Podfile.lock; then
  ok "Podfile.lock resolves the Firebase pods"
else
  bad "Podfile.lock has no Firebase pods; 'pod install' did not pick up the plugins."
fi

echo
if [ "$fail" -ne 0 ]; then
  echo "preflight FAILED - fix the items above before archiving."
  exit 1
fi
echo "preflight passed. Next: flutter build ipa --release, then upload via Transporter or Xcode Organizer."
