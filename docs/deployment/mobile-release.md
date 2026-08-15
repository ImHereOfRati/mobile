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

## iOS (when the Apple prerequisites are complete)

Configure the production Firebase iOS app, APNs key, URL schemes, signing
team, and `GoogleService-Info.plist` first. Then run the equivalent archive and
TestFlight internal-test flow. No iOS upload is authorized by this task.

## Post-release activation and rollback

After the mobile build is installed in internal testing, verify that it reads
the backend `base_url` and supports bridge contract `1.3.0`. Only then publish
the matching immutable web URL as `web_app_url`. Roll back by restoring the
previous compatible `web_app_url`; do not point an older mobile binary at a
web bundle requiring a newer bridge contract.
