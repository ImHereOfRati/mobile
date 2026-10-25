import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/geofence/model/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/model/service/auto_send_status_service.dart';
import 'package:iamhere/feature/geofence/model/service/geofence_service.dart';
import 'package:iamhere/feature/geofence/model/service/map_search_service.dart';
import 'package:iamhere/feature/terms/viewmodel/terms_acceptance_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'geofence_list_view_model.g.dart';

class GeofenceListState {
  final List<GeofenceEntity> items;
  final AutoSendStatus status;

  const GeofenceListState({required this.items, required this.status});

  GeofenceListState copyWith({
    List<GeofenceEntity>? items,
    AutoSendStatus? status,
  }) => GeofenceListState(
    items: items ?? this.items,
    status: status ?? this.status,
  );
}

@riverpod
class GeofenceListViewModel extends _$GeofenceListViewModel {
  late GeofenceService _geofences;
  late MapSearchService _maps;
  late AutoSendStatusService _statusService;

  @override
  Future<GeofenceListState> build(
    GeofenceService geofenceService,
    MapSearchService mapSearchService,
    AutoSendStatusService statusService,
  ) async {
    _geofences = geofenceService;
    _maps = mapSearchService;
    _statusService = statusService;
    return _load();
  }

  /// 로딩 화면으로 돌아가지 않고 장소와 상태를 다시 읽는다. 앱으로 돌아왔을 때 쓴다.
  Future<void> refresh() async {
    try {
      final next = await _load();
      if (ref.mounted) state = AsyncData(next);
    } catch (error, stack) {
      AppLogger.error('Geofence list refresh failed', error, stack);
    }
  }

  /// 백그라운드에서 도착 알림이 나가면 "출발 대기" 같은 상태가 바뀐다. 상태 표시줄은 그대로
  /// 두고 장소만 가볍게 다시 읽는다.
  Future<void> reloadItems() async {
    final current = state.value;
    if (current == null) return;
    try {
      final items = await _geofences.findAll();
      if (ref.mounted) state = AsyncData(current.copyWith(items: items));
    } catch (error, stack) {
      AppLogger.error('Geofence reload failed', error, stack);
    }
  }

  /// 성공하면 null, 실패하면 사용자에게 보여줄 메시지를 돌려준다.
  Future<String?> toggle(GeofenceEntity item, bool active) async {
    try {
      final updated = await _geofences.setActive(item.id!, active);
      _replace(updated);
      await _log('geofence_toggled', {'active': '$active'});
      return null;
    } catch (error, stack) {
      AppLogger.error('Geofence toggle failed', error, stack);
      return '알림 장소를 바꾸지 못했어요';
    }
  }

  Future<String?> delete(GeofenceEntity item) async {
    try {
      await _geofences.delete(item.id!);
      final current = state.value;
      if (current != null && ref.mounted) {
        state = AsyncData(
          current.copyWith(
            items: current.items.where((value) => value.id != item.id).toList(),
          ),
        );
      }
      await _log('geofence_deleted', {'event_type': item.eventType});
      return null;
    } catch (error, stack) {
      AppLogger.error('Geofence delete failed', error, stack);
      return '알림 장소를 삭제하지 못했어요';
    }
  }

  Future<GeofenceListState> _load() async {
    final results = await Future.wait([
      _geofences.findAll().then(_fillMissingAddresses),
      _statusService.load(),
    ]);
    return GeofenceListState(
      items: results[0] as List<GeofenceEntity>,
      status: results[1] as AutoSendStatus,
    );
  }

  /// 예전에 저장돼 주소가 비어 있는 장소는 좌표로 짧은 주소를 채운다. 오프라인이면
  /// 좌표 문자열로 대신해 목록이 비어 보이지 않게 한다.
  Future<List<GeofenceEntity>> _fillMissingAddresses(
    List<GeofenceEntity> items,
  ) {
    return Future.wait(
      items.map((item) async {
        if (item.address.trim().isNotEmpty) return item;
        final result = await _maps.reverseGeocode(item.lat, item.lng);
        final address =
            result?.shortLabel(item.lat, item.lng) ??
            '${item.lat.toStringAsFixed(4)}, ${item.lng.toStringAsFixed(4)}';
        try {
          await _geofences.updateAddress(item.id!, address);
          return item.copyWith(address: address);
        } catch (error, stack) {
          AppLogger.error('Geofence address update failed', error, stack);
          return item;
        }
      }),
    );
  }

  void _replace(GeofenceEntity updated) {
    final current = state.value;
    if (current == null || !ref.mounted) return;
    state = AsyncData(
      current.copyWith(
        items: [
          for (final item in current.items)
            item.id == updated.id ? updated : item,
        ],
      ),
    );
  }

  Future<void> _log(String name, Map<String, Object> parameters) async {
    try {
      await ref
          .read(authAnalyticsReporterProvider)
          .logEvent(name, parameters: parameters);
    } catch (error, stack) {
      AppLogger.error('Geofence analytics failed', error, stack);
    }
  }
}
