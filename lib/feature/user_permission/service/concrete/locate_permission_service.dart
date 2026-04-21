import 'package:geolocator/geolocator.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

@lazySingleton
class LocatePermissionService implements PermissionServiceInterface {
  @override
  Future<PermissionState> requestPermission() async {
    return await requestLocationPermissions();
  }

  @override
  Future<PermissionState> checkPermissionStatus() async {
    final alwaysStatus = await Permission.locationAlways.status;
    final whenInUseStatus = await Permission.locationWhenInUse.status;

    if (alwaysStatus.isGranted) {
      return PermissionState.grantedAlways;
    } else if (whenInUseStatus.isGranted || whenInUseStatus.isLimited) {
      return PermissionState.grantedWhenInUse;
    } else if (whenInUseStatus.isPermanentlyDenied) {
      return PermissionState.permanentlyDenied;
    } else if (whenInUseStatus.isRestricted) {
      return PermissionState.restricted;
    } else {
      return PermissionState.denied;
    }
  }

  @override
  Future<bool> isPermissionGranted() async {
    final status = await checkPermissionStatus();
    return status == PermissionState.grantedAlways ||
        status == PermissionState.grantedWhenInUse;
  }

  // 위치 특화 메서드

  /// 현재 사용자 위치 가져오기.
  ///
  /// UI 에서 init/build 중 호출되므로 이 메서드 내부에서는 권한을 요청하지 않는다.
  /// 권한 획득은 [LocationPermissionGuideView] 에서 명시적으로 수행한다.
  Future<Position> getCurrentUserLocation() async {
    final status = await checkPermissionStatus();

    if (status == PermissionState.grantedAlways ||
        status == PermissionState.grantedWhenInUse) {
      final LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );
      return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
    }

    throw Exception("위치 권한이 충분히 허용되지 않았습니다. 현재 상태: ${status.name}");
  }

  /// 위치 권한 요청.
  ///
  /// 먼저 '앱 사용 중' 권한을 시스템 다이얼로그로 요청하고, 그 결과 상태만 반환한다.
  /// '항상 허용' 상향 요청이 필요한 경우에는 [LocationPermissionGuideView] 가
  /// 별도로 설정 앱 진입을 안내하므로, 이 메서드에서는 설정 앱을 자동으로 열지 않는다.
  Future<PermissionState> requestLocationPermissions() async {
    final whenInUseStatus = await Permission.locationWhenInUse.request();

    if (whenInUseStatus.isGranted || whenInUseStatus.isLimited) {
      final alwaysStatus = await Permission.locationAlways.status;
      return alwaysStatus.isGranted
          ? PermissionState.grantedAlways
          : PermissionState.grantedWhenInUse;
    }

    if (whenInUseStatus.isPermanentlyDenied) {
      return PermissionState.permanentlyDenied;
    }
    if (whenInUseStatus.isRestricted) {
      return PermissionState.restricted;
    }
    return PermissionState.denied;
  }
}
