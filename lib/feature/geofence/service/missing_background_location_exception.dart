import 'package:iamhere/feature/user_permission/model/permission_state.dart';

/// 지오펜스 등록/동기화 시 백그라운드 위치 권한(또는 GPS 서비스)이
/// 충족되지 않아 OS 등록을 진행할 수 없을 때 던져지는 예외.
///
/// 호출자는 이 예외를 catch 하여 [LocationPermissionGuideView] 로 사용자를
/// 유도해야 한다. [state] 를 통해 권한 vs GPS 비활성 케이스를 구분할 수 있다.
class MissingBackgroundLocationException implements Exception {
  final PermissionState state;
  final String message;

  const MissingBackgroundLocationException(this.state, this.message);

  @override
  String toString() =>
      'MissingBackgroundLocationException(state=$state): $message';
}
