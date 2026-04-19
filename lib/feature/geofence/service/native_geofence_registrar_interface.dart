import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';

/// OS 네이티브 지오펜스(Geofence) 등록/해제/동기화 인터페이스.
///
/// 구현체는 `native_geofence` 플러그인(또는 동급)을 통해 OS 의
/// 저전력 지오펜스 서비스에 영역을 등록/제거한다.
///
/// iOS 는 최대 20 개, Android 는 최대 100 개 리전 제한이 있다.
abstract class NativeGeofenceRegistrarInterface {
  /// 플러그인 초기화. 앱 시작 시 1회 호출되어야 한다.
  Future<void> initialize();

  /// 지오펜스 1건을 OS에 등록한다.
  /// - `isActive == false` 이거나 `id == null` 이면 no-op.
  Future<void> register(GeofenceEntity geofence);

  /// OS 로부터 지정한 ID의 지오펜스를 제거한다.
  Future<void> unregister(int geofenceId);

  /// 전달된 활성 지오펜스 목록과 OS 의 등록 상태를 동기화한다.
  ///
  /// - OS에 있고 목록에 없는 것 → 제거
  /// - 목록에 있고 OS에 없는 것 → 등록
  /// - iOS 20개 초과 시 앞의 N개만 등록 (정책은 구현체 책임)
  Future<void> syncAll(List<GeofenceEntity> activeGeofences);

  /// 현재 OS 에 등록된 지오펜스 ID 목록을 조회한다.
  Future<List<String>> getRegisteredIds();
}
