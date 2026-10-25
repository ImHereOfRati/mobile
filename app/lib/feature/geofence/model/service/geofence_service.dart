import 'dart:convert';

import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/geofence/model/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/model/repository/geofence_local_repository.dart';
import 'package:iamhere/feature/geofence/model/repository/geofence_server_recipient_entity.dart';
import 'package:iamhere/feature/geofence/model/repository/geofence_server_recipient_local_repository.dart';
import 'package:iamhere/feature/geofence/model/service/fcm_arrival_service.dart';
import 'package:iamhere/feature/geofence/model/service/native_geofence_registrar_interface.dart';
import 'package:iamhere/feature/geofence/model/type/geofence_draft.dart';
import 'package:iamhere/feature/geofence/model/type/geofence_repeat.dart';
import 'package:iamhere/feature/geofence/model/type/recipient_option.dart';
import 'package:injectable/injectable.dart';

/// 알림 장소의 저장, 켜고 끄기, 삭제. DB 저장과 OS 지오펜스 등록을 함께 맞춘다.
@injectable
class GeofenceService {
  final GeofenceLocalRepository _geofences;
  final GeofenceServerRecipientLocalRepository _recipients;
  final NativeGeofenceRegistrarInterface _registrar;
  final FcmArrivalService _fcm;

  GeofenceService(
    this._geofences,
    this._recipients,
    this._registrar,
    this._fcm,
  );

  Future<List<GeofenceEntity>> findAll() => _geofences.findAll();

  /// 수정 화면에 채울 초안. 장소가 없으면 null.
  Future<GeofenceDraft?> loadDraft(int id) async {
    final entity = (await _geofences.findAll())
        .where((item) => item.id == id)
        .firstOrNull;
    if (entity == null) return null;
    final server = await _recipients.findByGeofenceId(id);
    return GeofenceDraft.fromEntity(
      entity,
      deviceContactIds: _decodeContactIds(entity.contactIds),
      serverRecipientKeys: {
        for (final item in server) item.friendRelationshipId,
      },
    );
  }

  /// 초안을 저장하고, 켜져 있으면 OS 지오펜스에 등록한다.
  Future<GeofenceEntity> save(
    GeofenceDraft draft,
    List<RecipientOption> options,
  ) async {
    final existing = draft.id == null
        ? null
        : (await _geofences.findAll())
              .where((item) => item.id == draft.id)
              .firstOrNull;
    var entity = GeofenceEntity(
      id: draft.id,
      name: draft.name.trim(),
      address: draft.address.trim(),
      lat: draft.latitude,
      lng: draft.longitude,
      radius: draft.radius.meters.toDouble(),
      message: draft.message.trim(),
      contactIds: jsonEncode(draft.deviceContactIds.toList()),
      isActive: draft.active,
      awaitingDeparture: existing?.awaitingDeparture ?? false,
      eventType: draft.eventType.name,
      repeatType: draft.repeat.name,
      customDaysBitmask: draft.repeat == GeofenceRepeat.custom
          ? draft.customDaysBitmask
          : null,
    );

    if (existing == null) {
      entity = await _geofences.save(entity);
    } else {
      await _geofences.update(entity);
    }

    final geofenceId = entity.id!;
    await _recipients.deleteByGeofenceId(geofenceId);
    final receiverUserIds = <String>[];
    for (final option in options) {
      final server = option.server;
      if (server == null || !draft.serverRecipientKeys.contains(option.key)) {
        continue;
      }
      await _recipients.save(
        GeofenceServerRecipientEntity(
          geofenceId: geofenceId,
          friendRelationshipId: server.friendRelationshipId,
          friendUserId: server.friendUserId,
          friendEmail: server.friendEmail,
          friendAlias: server.friendAlias,
        ),
      );
      receiverUserIds.add(server.friendUserId);
    }
    if (receiverUserIds.isNotEmpty) {
      // 받는 사람에게 대상자로 등록됐음을 알린다. 알림 실패가 저장을 막지는 않는다.
      await _fcm.sendGeofenceNotifications(
        receiverUserIds: receiverUserIds,
        body: '위치 알림 대상자로 등록되었습니다.',
        location: entity.fullLocation,
        type: 'LOCATION_TARGET',
      );
    }
    if (entity.isActive) {
      await _registrar.register(entity);
    } else {
      await _registrar.unregister(geofenceId);
    }
    return entity;
  }

  Future<GeofenceEntity> setActive(int id, bool active) async {
    await _geofences.updateActiveStatus(id, active);
    final entity = (await _geofences.findAll()).firstWhere(
      (item) => item.id == id,
    );
    if (active) {
      await _registrar.register(entity);
    } else {
      await _registrar.unregister(id);
    }
    return entity;
  }

  Future<void> delete(int id) async {
    await _registrar.unregister(id);
    await _recipients.deleteByGeofenceId(id);
    await _geofences.delete(id);
  }

  Future<void> updateAddress(int id, String address) =>
      _geofences.updateAddress(id, address);

  static Set<String> _decodeContactIds(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return {for (final value in decoded) value.toString()};
      }
    } catch (error, stack) {
      AppLogger.error('Contact id decode failed', error, stack);
    }
    return {};
  }
}
