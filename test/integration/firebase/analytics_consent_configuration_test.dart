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

