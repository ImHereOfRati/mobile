import 'dart:async';
import 'dart:developer';

import 'package:geolocator/geolocator.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/concrete/locate_permission_service.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class LocationMonitoringService {
  final LocatePermissionService _permissionService;
  StreamSubscription<Position>? _positionStreamSubscription;

  LocationMonitoringService(this._permissionService);

  Future<Stream<Position>> activateLocationTracking(
    Function(Position position) onPositionUpdate,
  ) async {
    await stopLocationMonitoring();
    log('위치 관제 시스템 가동 시작');

    try {
      await _ensureLocationPermission();

      final locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      final positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      );

      _positionStreamSubscription = positionStream.listen(
        onPositionUpdate,
        onError: (error) => log('위치 스트림 에러: $error'),
        cancelOnError: false,
      );

      log('위치 관제 시스템 정상 가동 중');
      return positionStream;
    } catch (e) {
      log('위치 관제 가동 실패: $e');
      rethrow;
    }
  }

  Future<void> _ensureLocationPermission() async {
    final permissionState = await _permissionService
        .requestLocationPermissions();

    if (permissionState != PermissionState.grantedAlways &&
        permissionState != PermissionState.grantedWhenInUse) {
      log('위치 권한 거부됨: ${permissionState.name}');
      throw Exception('위치 권한이 필요합니다. 설정에서 권한을 허용해주세요.');
    }
  }

  Future<void> stopLocationMonitoring() async {
    if (_positionStreamSubscription != null) {
      log('위치 관제 시스템 중단');
      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
    }
  }
}
