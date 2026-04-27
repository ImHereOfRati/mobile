import 'dart:developer';

import 'package:iamhere/feature/geofence/background/geofence_background_callback.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/service/missing_background_location_exception.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:injectable/injectable.dart';
import 'package:native_geofence/native_geofence.dart';

/// OS 네이티브 지오펜스 등록자. `native_geofence` 플러그인을 래핑한다.
///
/// GeofenceEntity.id(int) ↔ OS geofence id(String) 매핑은 id.toString() 사용.
///
/// `register`/`syncAll` 은 백그라운드 위치 권한(`PermissionState.grantedAlways`)이
/// 보장되어야 한다. 권한이 부족하면 [MissingBackgroundLocationException] 을 던진다.
/// `unregister`/`getRegisteredIds`/`initialize` 는 권한 검사 없이 동작한다.
@LazySingleton(as: NativeGeofenceRegistrarInterface)
class NativeGeofenceRegistrar implements NativeGeofenceRegistrarInterface {
  // iOS 최대 20개 제한 보수적 상한.
  static const int _maxIosRegions = 20;

  final PermissionServiceInterface _permissionService;

  bool _initialized = false;

  NativeGeofenceRegistrar(@Named('location') this._permissionService);

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await NativeGeofenceManager.instance.initialize();
      _initialized = true;
      log('NativeGeofenceRegistrar initialized');
    } catch (e) {
      log('NativeGeofenceRegistrar initialize failed: $e');
      rethrow;
    }
  }

  Future<void> _ensureBackgroundLocationPermission() async {
    final state = await _permissionService.checkPermissionStatus();
    if (state != PermissionState.grantedAlways) {
      throw MissingBackgroundLocationException(
        state,
        '백그라운드 위치 권한(항상 허용)이 필요합니다. 현재: ${state.name}',
      );
    }
  }

  @override
  Future<void> register(GeofenceEntity geofence) async {
    if (geofence.id == null) {
      log('register skipped: geofence.id is null (${geofence.name})');
      return;
    }
    if (!geofence.isActive) {
      log('register skipped: geofence inactive (${geofence.name})');
      return;
    }
    await _ensureBackgroundLocationPermission();
    await initialize();

    final zone = Geofence(
      id: geofence.id!.toString(),
      location: Location(latitude: geofence.lat, longitude: geofence.lng),
      radiusMeters: geofence.radius,
      triggers: const {GeofenceEvent.enter, GeofenceEvent.dwell},
      iosSettings: IosGeofenceSettings(initialTrigger: true),
      androidSettings: AndroidGeofenceSettings(
        initialTriggers: const {GeofenceEvent.enter, GeofenceEvent.dwell},
        expiration: null,
        loiteringDelay: Duration.zero,
        notificationResponsiveness: Duration.zero,
      ),
    );

    try {
      await NativeGeofenceManager.instance.createGeofence(
        zone,
        geofenceTriggered,
      );
      log('Geofence registered: ${geofence.name} (id=${geofence.id})');
    } catch (e) {
      log('register failed (${geofence.name}): $e');
      rethrow;
    }
  }

  @override
  Future<void> unregister(int geofenceId) async {
    await initialize();
    try {
      await NativeGeofenceManager.instance.removeGeofenceById(
        geofenceId.toString(),
      );
      log('Geofence unregistered: id=$geofenceId');
    } catch (e) {
      log('unregister failed (id=$geofenceId): $e');
    }
  }

  @override
  Future<void> syncAll(List<GeofenceEntity> activeGeofences) async {
    // iOS 20개 제한 대응: 앞의 N개만 선택 (정책: id 오름차순 = 등록순).
    final selected = activeGeofences.where((g) => g.isActive).toList();
    selected.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    final effective = selected.take(_maxIosRegions).toList();

    // 등록할 활성 항목이 있을 때만 권한 게이트를 통과시킨다.
    // OS 측 stale 제거는 권한과 무관하게 진행되어야 하므로 게이트는 등록 전에만 적용.
    if (effective.isNotEmpty) {
      await _ensureBackgroundLocationPermission();
    }

    await initialize();

    final effectiveIds = effective
        .map((g) => g.id?.toString())
        .whereType<String>()
        .toSet();

    // 현재 OS 등록된 것 중 목록에 없는 것 제거.
    try {
      final registered = await NativeGeofenceManager.instance
          .getRegisteredGeofenceIds();
      for (final id in registered) {
        if (!effectiveIds.contains(id)) {
          try {
            await NativeGeofenceManager.instance.removeGeofenceById(id);
            log('syncAll: removed stale geofence id=$id');
          } catch (e) {
            log('syncAll: remove stale failed id=$id: $e');
          }
        }
      }
    } catch (e) {
      log('syncAll: getRegisteredGeofenceIds failed: $e');
    }

    // 목록에 있는 것 등록(재등록은 createGeofence가 덮어쓰도록 플러그인에서 처리됨).
    for (final geofence in effective) {
      await register(geofence);
    }

    final skipped = selected.length - effective.length;
    if (skipped > 0) {
      log(
        'syncAll: $skipped geofence(s) skipped due to iOS ${_maxIosRegions}-region cap',
      );
    }
  }

  @override
  Future<List<String>> getRegisteredIds() async {
    await initialize();
    try {
      return await NativeGeofenceManager.instance.getRegisteredGeofenceIds();
    } catch (e) {
      log('getRegisteredIds failed: $e');
      return const [];
    }
  }
}
