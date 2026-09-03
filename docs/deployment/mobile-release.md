# Mobile release guide (Android / iOS)

This document describes the mobile release procedure. It is an operator guide
only; this task does not upload an Android or iOS artifact to a store.

## Contracts to verify first

- Deploy the backend according to `ImHereServer/docs/infra/cicd.md` and verify
  its public origin and health endpoint.
- Publish the Firebase Remote Config `base_url` to that backend origin. The
  native shell reads this value before registering its Dio clients; the
  build-time origin is only an offline rollback fallback.
- Release the web bundle only at an immutable
  `/app/releases/<sha>/index.html` URL. Keep
  `web_app_url` on the currently compatible bridge version until the mobile
  build containing that bridge version is available.

## Local release checks

From `client/`:

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart analyze lib
flutter test test/feature/auth/service/auth_service_test.dart `
  test/feature/geofence/service/sms_service_test.dart `
  test/feature/geofence/service/fcm_arrival_service_test.dart
Push-Location web
pnpm bridge:check
Pop-Location
```

Run the complete Flutter test suite before store submission. Do not ignore
failures from stale or excluded tests; resolve them or document the exact
scope in the release record.

## Android

1. Increment `pubspec.yaml` version/build number. Never reuse a Play Console
   version code.
2. Confirm `android/key.properties` points to the backed-up
   `android/keystore/imhere-upload.jks`; keep the keystore and password out of
   git and CI logs.
3. Build the signed artifact with production configuration:

   ```powershell
   flutter build appbundle --release --dart-define-from-file=release-defines.json
   ```

   `release-defines.json` is an operator-managed, untracked Dart-define file;
   do not pass the Firebase Remote Config template as a Dart-define file.
   Verify the signing certificate with
   `./gradlew signingReport` and compare it with the Play upload certificate.

4. Upload the AAB to an internal test track manually, run a cold-start smoke
   test (login, terms, geofence registration, FCM/SMS), then promote through
   staged rollout.

## iOS

Archiving requires macOS with Xcode; the Windows workstation cannot produce an
IPA. Everything below runs from `client/` on the Mac.

### One-time Apple / Firebase setup

1. **Apple Developer Program** — the bundle id `com.kdongsu5509.iamhere` must
   exist as an App ID with the **Push Notifications** capability enabled, and
   the app record must exist in App Store Connect.
2. **APNs key** — create an APNs Auth Key (`.p8`) in the developer portal and
   upload it to Firebase console > Project settings > Cloud Messaging > Apple
   app configuration. Without it, FCM cannot deliver to iOS.
3. **Firebase iOS app** — already registered; the app reads its options from
   the `FIREBASE_IOS_*` keys in `iam_here_flutter_secret.env`, not from a
   bundled `GoogleService-Info.plist`. `FIREBASE_IOS_BUNDLE_ID` must equal
   `com.kdongsu5509.iamhere`.
4. **Kakao** — register the iOS platform with bundle id
   `com.kdongsu5509.iamhere` in the Kakao developers console. The URL scheme
   `kakao<native app key>` is already declared in `ios/Runner/Info.plist`.
5. **`ios/Signing.xcconfig`** — fill in the three values and commit them:

   | key | source |
   | --- | --- |
   | `DEVELOPMENT_TEAM` | Apple Developer team id (10 chars) |
   | `GOOGLE_IOS_CLIENT_ID` | Firebase console > iOS app > `GoogleService-Info.plist` > `CLIENT_ID` |
   | `GOOGLE_IOS_REVERSED_CLIENT_ID` | same file > `REVERSED_CLIENT_ID` |

   The file is included by `ios/Flutter/{Debug,Release}.xcconfig`;
   `GIDClientID` and the Google redirect URL scheme in `Info.plist` are
   substituted from it at build time. Leaving them empty ships a build whose
   Google login cannot complete.
6. **Remote Config** — publish `ios_store_url` with the real App Store id.
   The template ships a placeholder (`.../id0000000000`); the forced-update
   screen on iOS has no build-time fallback, so an unset value silently
   disables forced update on iOS.

### What the repo already configures

- `IPHONEOS_DEPLOYMENT_TARGET` 15.6 across project, target, and Podfile
  (firebase-ios-sdk 12.x needs 15.0+, native_geofence needs 14.0+).
- Automatic signing on the Runner target, with the team supplied by
  `Signing.xcconfig`.
- `ios/Runner/Runner.entitlements` with `aps-environment` (Xcode rewrites it
  to `production` when exporting for the App Store).
- `UIBackgroundModes` limited to `location` (geofencing) and
  `remote-notification` (FCM background handler). `workmanager` is guarded to
  Android, so `fetch`/`processing` are deliberately not declared — do not add
  a background mode the binary cannot justify to App Review.
- `PrivacyInfo.xcprivacy` is wired into the Runner Resources build phase, so
  it ships in the bundle.
- `ITSAppUsesNonExemptEncryption=false`, which skips the export-compliance
  prompt on every upload.

### Release run

```bash
bash scripts/ios_release_preflight.sh
```

The preflight verifies host tooling, the signing/client-id values, the
`FIREBASE_IOS_*` and Kakao secrets, and the Kakao URL scheme, then runs
`flutter pub get`, `build_runner`, `dart analyze lib`, and `pod install`. Note
that `ios/Podfile.lock` in git predates the current plugin set; the first
`pod install` on the Mac will rewrite it, and that change should be committed.

Then archive and upload:

```bash
flutter build ipa --release --dart-define-from-file=release-defines.json
```

`build/ios/archive/Runner.xcarchive` opens in Xcode Organizer; upload from
there, or push `build/ios/ipa/*.ipa` with Transporter. `CFBundleVersion` comes
from the pubspec build number, so bump `version:` in `pubspec.yaml` before any
re-upload — App Store Connect rejects a reused build number.

### Smoke test on TestFlight internal testing

Cold-start the installed build and verify, in order: Kakao login, Google
login, terms acceptance, geofence registration with **Always** location
permission granted, an arrival notification delivered while the app is
backgrounded, SMS send, and forced-update handling against a raised
`minimum_app_version`. Background geofencing cannot be validated in the
simulator; use a real device.

## Post-release activation and rollback

After the mobile build is installed in internal testing, verify that it reads
the backend `base_url` and supports bridge contract `1.3.0`. Only then publish
the matching immutable web URL as `web_app_url`. Roll back by restoring the
previous compatible `web_app_url`; do not point an older mobile binary at a
web bundle requiring a newer bridge contract.
