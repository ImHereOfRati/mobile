import 'package:geolocator/geolocator.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:permission_handler/permission_handler.dart';

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

  //TODO : 아래 메서드 반드시 별도로 분리하여야한다.
  /// 현재 사용자 위치 가져오기
  Future<Position> getCurrentUserLocation() async {
    PermissionState status = await requestLocationPermissions();

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

  Future<PermissionState> requestLocationPermissions() async {
    // 2-1. 첫 번째: '앱 사용 중에만 허용' 권한 요청 (팝업으로 뜸)
    PermissionStatus whenInUseStatus = await Permission.locationWhenInUse
        .request();

    if (whenInUseStatus.isGranted || whenInUseStatus.isLimited) {
      // 2-2. 첫 번째 권한이 허용되었다면, '항상 허용' 권한 상태를 확인합니다.
      PermissionStatus alwaysStatus = await Permission.locationAlways.status;

      if (alwaysStatus.isGranted) {
        return PermissionState.grantedAlways;
      } else {
        await openAppSettings();
        alwaysStatus = await Permission.locationAlways.status;
      }

      if (alwaysStatus.isDenied) {}

      // 2-4. 최종 상태 반환
      if (alwaysStatus.isGranted) {
        return PermissionState.grantedAlways;
      } else {
        // '항상 허용'이 안 되었지만, '앱 사용 중에만 허용'은 된 상태
        return PermissionState.grantedWhenInUse;
      }
    }

    // 2-5. '앱 사용 중에만 허용'조차 거부된 경우
    if (whenInUseStatus.isDenied) {
      return PermissionState.denied;
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
