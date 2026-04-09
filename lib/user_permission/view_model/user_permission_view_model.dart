import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/user_permission/model/items/contact_permission_item.dart';
import 'package:iamhere/user_permission/model/items/fcm_permision_item.dart';
import 'package:iamhere/user_permission/model/items/location_permission_item.dart';
import 'package:iamhere/user_permission/model/items/sms_permission_item.dart';
import 'package:iamhere/user_permission/model/permission_item.dart';
import 'package:iamhere/user_permission/model/permission_state.dart';
import 'package:iamhere/user_permission/service/permission_service_interface.dart';
import 'package:iamhere/user_permission/service/permission_service_provider.dart';
import 'package:iamhere/user_permission/view_model/permissions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_permission_view_model.g.dart';

@Riverpod(keepAlive: true)
class UserPermissionViewModel extends _$UserPermissionViewModel {
  @override
  Future<List<PermissionItem>> build() async {
    return await _checkInitialStatuses();
  }

  /// 초기 권한 상태 확인 로직
  Future<List<PermissionItem>> _checkInitialStatuses() async {
    final initialList = [...permissions];

    for (int i = 0; i < initialList.length; i++) {
      final item = initialList[i];
      final permissionService = _getProperPermissionService(item);
      final isGranted = await permissionService.isPermissionGranted();

      if (isGranted) {
        initialList[i] = item.copyWith(isGranted: true);
      }
    }

    return initialList;
  }

  /// 특정 권한 요청 로직
  Future<bool> requestPermission(int index) async {
    if (!state.hasValue) return false;

    final currentList = [...state.requireValue];
    final targetPermission = currentList[index];

    final properPermissionService = _getProperPermissionService(
      targetPermission,
    );

    final permissionState = await properPermissionService.requestPermission();

    final isGranted =
        permissionState == PermissionState.grantedAlways ||
        permissionState == PermissionState.grantedWhenInUse;

    currentList[index] = targetPermission.copyWith(isGranted: isGranted);

    state = AsyncData(currentList);

    return isGranted;
  }

  PermissionServiceInterface _getProperPermissionService(PermissionItem item) {
    if (item is FcmAlertPermissionItem) {
      return ref.watch(fcmAlertPermissionServiceProvider);
    } else if (item is LocationPermissionItem) {
      return ref.watch(locationPermissionServiceProvider);
    } else if (item is ContactPermissionItem) {
      return ref.watch(contactPermissionServiceProvider);
    } else {
      throw ArgumentError('Unknown permission item type: ${item.runtimeType}');
    }
  }
}
