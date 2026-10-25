import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 이 기기에서 권한 안내를 이미 마쳤는지 기억한다.
///
/// 저장값이 없는 상태(`false`)가 앱을 처음 설치한 상태다. 안내를 끝내거나
/// 건너뛰면 `true`로 바꿔, 같은 안내를 다시 띄우지 않는다.
class PermissionOnboardingService {
  static const _completedKey = 'permission_onboarding_completed_v1';

  final FlutterSecureStorage _storage;

  const PermissionOnboardingService(this._storage);

  Future<bool> isCompleted() async =>
      await _storage.read(key: _completedKey) == 'true';

  Future<void> markCompleted() =>
      _storage.write(key: _completedKey, value: 'true');
}
