import 'dart:developer' as dev;

import 'package:iamhere/feature/geofence/background/geofence_background_callback.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/service/missing_background_location_exception.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:iamhere/shared/util/app_logger.dart';
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
      AppLogger.debug('NativeGeofenceRegistrar: Initialized successfully');
    } catch (e) {
      AppLogger.error('NativeGeofenceRegistrar: Initialize failed', e);
      rethrow;
    }
  }

  Future<void> _ensureBackgroundLocationPermission() async {
    final state = await _permissionService.checkPermissionStatus();
    if (state != PermissionState.grantedAlways) {
      AppLogger.warning('NativeGeofenceRegistrar: Permission check failed. Current: ${state.name}');
      throw MissingBackgroundLocationException(
        state,
        '백그라운드 위치 권한(항상 허용)이 필요합니다. 현재: ${state.name}',
      );
    }
  }

  @override
  Future<void> register(GeofenceEntity geofence) async {
    if (geofence.id == null) {
      AppLogger.warning('NativeGeofenceRegistrar: register skipped - geofence.id is null (${geofence.name})');
      return;
    }
    if (!geofence.isActive) {
      AppLogger.debug('NativeGeofenceRegistrar: register skipped - geofence inactive (${geofence.name})');
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

    AppLogger.debug('NativeGeofenceRegistrar: Registering "${geofence.name}" (ID: ${geofence.id}) '
        'at [${geofence.lat}, ${geofence.lng}] with radius ${geofence.radius}m');

    try {
      await NativeGeofenceManager.instance.createGeofence(
        zone,
        geofenceTriggered,
      );
      AppLogger.debug('NativeGeofenceRegistrar: Successfully registered "${geofence.name}"');
    } catch (e) {
      AppLogger.error('NativeGeofenceRegistrar: Registration failed for "${geofence.name}"', e);
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
      AppLogger.debug('NativeGeofenceRegistrar: Unregistered geofence ID: $geofenceId');
    } catch (e) {
      AppLogger.error('NativeGeofenceRegistrar: Unregister failed for ID: $geofenceId', e);
    }
  }

  @override
  Future<void> syncAll(List<GeofenceEntity> activeGeofences) async {
    AppLogger.debug('NativeGeofenceRegistrar: Starting syncAll with ${activeGeofences.length} items');
    
    // iOS 20개 제한 대응: 앞의 N개만 선택 (정책: id 오름차순 = 등록순).
    final selected = activeGeofences.where((g) => g.isActive).toList();
    selected.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    final effective = selected.take(_maxIosRegions).toList();

    // 등록할 활성 항목이 있을 때만 권한 게이트를 통과시킨다.
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
      AppLogger.debug('NativeGeofenceRegistrar: Currently registered in OS: $registered');
      
      for (final id in registered) {
        if (!effectiveIds.contains(id)) {
          try {
            await NativeGeofenceManager.instance.removeGeofenceById(id);
            AppLogger.debug('NativeGeofenceRegistrar: Removed stale geofence ID: $id');
          } catch (e) {
            AppLogger.error('NativeGeofenceRegistrar: Failed to remove stale geofence ID: $id', e);
          }
        }
      }
    } catch (e) {
      AppLogger.error('NativeGeofenceRegistrar: syncAll - getRegisteredGeofenceIds failed', e);
    }

    // 목록에 있는 것 등록.
    for (final geofence in effective) {
      await register(geofence);
    }

    final skipped = selected.length - effective.length;
    if (skipped > 0) {
      AppLogger.warning(
        'NativeGeofenceRegistrar: syncAll - $skipped geofence(s) skipped due to iOS ${_maxIosRegions}-region cap',
      );
    }
    AppLogger.debug('NativeGeofenceRegistrar: syncAll completed');
  }

  @override
  Future<List<String>> getRegisteredIds() async {
    await initialize();
    try {
      final ids = await NativeGeofenceManager.instance.getRegisteredGeofenceIds();
      AppLogger.debug('NativeGeofenceRegistrar: Registered IDs: $ids');
      return ids;
    } catch (e) {
      AppLogger.error('NativeGeofenceRegistrar: getRegisteredIds failed', e);
      return const [];
    }
  }
}
