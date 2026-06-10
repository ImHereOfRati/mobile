import 'package:iamhere/feature/user_permission/model/permission_state.dart';

enum CenterAddAction { enroll, showPermissionGuide }

class CenterAddActionResolver {
  const CenterAddActionResolver();

  CenterAddAction resolve(PermissionState status) {
    if (status == PermissionState.grantedAlways ||
        status == PermissionState.grantedWhenInUse) {
      return CenterAddAction.enroll;
    }

    return CenterAddAction.showPermissionGuide;
  }
}
