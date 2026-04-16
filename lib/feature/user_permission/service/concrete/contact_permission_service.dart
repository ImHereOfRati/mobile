import 'package:iamhere/feature/user_permission/model/permission_state.dart'
    as userPermissionModel;
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactPermissionService implements PermissionServiceInterface {
  @override
  Future<bool> isPermissionGranted() async {
    return await Permission.contacts.isGranted;
  }

  @override
  Future<userPermissionModel.PermissionState> requestPermission() async {
    final status = await Permission.contacts.request();
    return _mapToPermissionState(status);
  }

  @override
  Future<userPermissionModel.PermissionState> checkPermissionStatus() async {
    final status = await Permission.contacts.status;
    return _mapToPermissionState(status);
  }

  userPermissionModel.PermissionState _mapToPermissionState(
    PermissionStatus status,
  ) {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return userPermissionModel
            .PermissionState
            .grantedAlways; // 또는 grantedWhenInUse
      case PermissionStatus.denied:
        return userPermissionModel.PermissionState.denied;
      case PermissionStatus.restricted:
        return userPermissionModel
            .PermissionState
            .denied; // 정책상 불가도 거부로 처리하거나 별도 상태 정의
      case PermissionStatus.permanentlyDenied:
        return userPermissionModel.PermissionState.permanentlyDenied;
      case PermissionStatus.provisional: // iOS 임시 권한
        return userPermissionModel.PermissionState.grantedWhenInUse;
    }
  }
}
