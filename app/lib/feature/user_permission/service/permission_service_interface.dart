import 'package:iamhere/feature/user_permission/model/permission_state.dart';

abstract class PermissionServiceInterface {
  Future<PermissionState> requestPermission();

  Future<PermissionState> checkPermissionStatus();

  Future<bool> isPermissionGranted();
}
