import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/common/component/navigation/default_view/navigation_bar/center_add_action_resolver.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';

void main() {
  const resolver = CenterAddActionResolver();

  test('항상 허용 권한이면 enroll 액션을 반환한다', () {
    expect(
      resolver.resolve(PermissionState.grantedAlways),
      CenterAddAction.enroll,
    );
  });

  test('사용 중 권한이면 enroll 액션을 반환한다', () {
    expect(
      resolver.resolve(PermissionState.grantedWhenInUse),
      CenterAddAction.enroll,
    );
  });

  test('권한이 없으면 guide 액션을 반환한다', () {
    expect(
      resolver.resolve(PermissionState.denied),
      CenterAddAction.showPermissionGuide,
    );
  });
}
