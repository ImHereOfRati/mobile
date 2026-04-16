import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:permission_handler/permission_handler.dart';

PermissionState convert(PermissionStatus status) {
  if (status.isGranted || status.isLimited) {
    return PermissionState.grantedAlways;
  } else if (status.isLimited) {
    return PermissionState.grantedWhenInUse;
  } else if (status.isPermanentlyDenied) {
    return PermissionState.permanentlyDenied;
  } else if (status.isRestricted) {
    return PermissionState.restricted;
  } else {
    return PermissionState.denied;
  }
}
