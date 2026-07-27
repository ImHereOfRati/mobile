import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android analytics collection and consent default to denied', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    _expectAndroidMetaDataFalse(
      manifest,
      'firebase_analytics_collection_enabled',
    );
    _expectAndroidMetaDataFalse(
      manifest,
      'google_analytics_default_allow_analytics_storage',
    );
    _expectAndroidMetaDataFalse(
      manifest,
      'google_analytics_default_allow_ad_storage',
    );
    _expectAndroidMetaDataFalse(
      manifest,
      'google_analytics_default_allow_ad_user_data',
    );
    _expectAndroidMetaDataFalse(
      manifest,
      'google_analytics_default_allow_ad_personalization_signals',
    );
  });

  test('iOS analytics collection and consent default to denied', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

    _expectPlistBooleanFalse(
      infoPlist,
      'FIREBASE_ANALYTICS_COLLECTION_ENABLED',
    );
    _expectPlistBooleanFalse(
      infoPlist,
      'GOOGLE_ANALYTICS_DEFAULT_ALLOW_ANALYTICS_STORAGE',
    );
    _expectPlistBooleanFalse(
      infoPlist,
      'GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_STORAGE',
    );
    _expectPlistBooleanFalse(
      infoPlist,
      'GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_USER_DATA',
    );
    _expectPlistBooleanFalse(
      infoPlist,
      'GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_PERSONALIZATION_SIGNALS',
    );
  });
}

void _expectAndroidMetaDataFalse(String manifest, String key) {
  expect(
    manifest,
    matches(
      RegExp(
        '<meta-data\\s+android:name="$key"\\s+android:value="false"\\s*/>',
      ),
    ),
  );
}

void _expectPlistBooleanFalse(String infoPlist, String key) {
  expect(infoPlist, matches(RegExp('<key>$key</key>\\s*<false/>')));
}
