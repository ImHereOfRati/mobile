import 'package:iamhere/feature/user_permission/model/permission_state.dart'
    as user_permission_model;
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactPermissionService implements PermissionServiceInterface {
  @override
  Future<bool> isPermissionGranted() async {
    return await Permission.contacts.isGranted;
  }

  @override
  Future<user_permission_model.PermissionState> requestPermission() async {
    final status = await Permission.contacts.request();
    return _mapToPermissionState(status);
  }

  @override
  Future<user_permission_model.PermissionState> checkPermissionStatus() async {
    final status = await Permission.contacts.status;
    return _mapToPermissionState(status);
  }

  user_permission_model.PermissionState _mapToPermissionState(
    PermissionStatus status,
  ) {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return user_permission_model
            .PermissionState
            .grantedAlways; // 또는 grantedWhenInUse
      case PermissionStatus.denied:
        return user_permission_model.PermissionState.denied;
      case PermissionStatus.restricted:
        return user_permission_model
            .PermissionState
            .denied; // 정책상 불가도 거부로 처리하거나 별도 상태 정의
      case PermissionStatus.permanentlyDenied:
        return user_permission_model.PermissionState.permanentlyDenied;
      case PermissionStatus.provisional: // iOS 임시 권한
        return user_permission_model.PermissionState.grantedWhenInUse;
    }
  }
}
