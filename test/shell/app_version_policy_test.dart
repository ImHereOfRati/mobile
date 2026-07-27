import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/shell/app_version_policy.dart';

void main() {
  test(
    'requires an update only when current is below the configured minimum',
    () {
      expect(
        AppVersionPolicy.requiresUpdate(
          currentVersion: '2.0.0',
          minimumVersion: '2.1.0',
        ),
        isTrue,
      );
      expect(
        AppVersionPolicy.requiresUpdate(
          currentVersion: '2.1.0',
          minimumVersion: '2.1.0',
        ),
        isFalse,
      );
      expect(
        AppVersionPolicy.requiresUpdate(
          currentVersion: '3.0.0',
          minimumVersion: '2.1.0',
        ),
        isFalse,
      );
    },
  );

  test('fails open when the Remote Config value is absent or malformed', () {
    expect(
      AppVersionPolicy.requiresUpdate(
        currentVersion: '2.0.0',
        minimumVersion: null,
      ),
      isFalse,
    );
    expect(
      AppVersionPolicy.requiresUpdate(
        currentVersion: '2.0.0',
        minimumVersion: 'latest',
      ),
      isFalse,
    );
  });
}
