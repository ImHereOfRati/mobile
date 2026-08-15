import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart' as geo;
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_repository.dart';
import 'package:iamhere/feature/geofence/repository/geofence_server_recipient_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_server_recipient_repository.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:iamhere/feature/record/repository/geofence_record_repository.dart';
import 'package:iamhere/feature/record/repository/notification_repository.dart';
import 'package:iamhere/feature/user_permission/service/concrete/locate_permission_service.dart';
import 'package:iamhere/shell/bridge/bridge_handler_registry.dart';

typedef ServerRecipientNotifier =
    Future<void> Function({
      required List<String> receiverUserIds,
      required String location,
    });

class GeofenceDeviceBridgeHandlers {
  final GeofenceRepository geofences;
  final GeofenceServerRecipientRepository recipients;
  final GeofenceRecordRepository records;
  final NotificationRepository notifications;
  final Future<List<Map<String, Object?>>> Function() loadDeviceContacts;
  final ServerRecipientNotifier notifyServerRecipients;
  final NativeGeofenceRegistrarInterface registrar;
  final LocatePermissionService location;

  GeofenceDeviceBridgeHandlers({
    required this.geofences,
    required this.recipients,
    required this.records,
    required this.notifications,
    required this.loadDeviceContacts,
    required this.notifyServerRecipients,
    required this.registrar,
    required this.location,
  });

  Map<String, BridgeMethodHandler> build() => {
    'registerGeofence': _register,
    'unregisterGeofence': _unregister,
    'setGeofenceActive': _setActive,
    'updateGeofenceAddress': _updateAddress,
    'syncGeofences': (_) => _sync(),
    'getNativeGeofenceState': _nativeState,
    'queryGeofences': _queryGeofences,
    'queryRecords': _queryRecords,
    'queryNotifications': _queryNotifications,
    'deleteRecord': _deleteRecord,
    'deleteAllRecords': (_) => records.deleteAll(),
    'deleteAllNotifications': (_) => notifications.deleteAll(),
    'getDeviceContacts': (_) => _deviceContacts(),
    'getCurrentPosition': (_) => _currentPosition(),
    'getLocationServiceStatus': (_) => _locationServiceStatus(),
  };

  Future<Map<String, Object?>> _register(Object? params) async {
    final map = _map(params);
    final all = await geofences.findAll();
    final id = (map['id'] as num?)?.toInt();
    final existing = id == null
        ? null
        : all.where((item) => item.id == id).firstOrNull;
    var entity = GeofenceEntity(
      id: id,
      name: _string(map, 'name'),
      address: map['address'] as String? ?? '',
      lat: _number(map, 'latitude'),
      lng: _number(map, 'longitude'),
      radius: _number(map, 'radiusMeters'),
      message: map['message'] as String? ?? '',
      contactIds: jsonEncode(
        (map['deviceContactIds'] as List? ?? const [])
            .map((value) => value.toString())
            .toList(),
      ),
      isActive: map['active'] == true,
      awaitingDeparture: existing?.awaitingDeparture ?? false,
      eventType: map['eventType'] as String? ?? 'arrival',
      repeatType: map['repeatType'] as String? ?? 'none',
      customDaysBitmask: (map['customDaysBitmask'] as num?)?.toInt(),
    );

    if (existing == null) {
      entity = await geofences.save(entity);
    } else {
      await geofences.update(entity);
    }

    final savedId = entity.id!;
    await recipients.deleteByGeofenceId(savedId);
    final receiverUserIds = <String>[];
    for (final raw in map['serverRecipients'] as List? ?? const []) {
      final recipient = _map(raw);
      final email = _string(recipient, 'friendEmail');
      await recipients.save(
        GeofenceServerRecipientEntity(
          geofenceId: savedId,
          friendRelationshipId: _string(recipient, 'friendRelationshipId'),
          friendUserId: _string(recipient, 'friendUserId'),
          friendEmail: email,
          friendAlias: recipient['friendAlias'] as String? ?? '',
        ),
      );
      receiverUserIds.add(_string(recipient, 'friendUserId'));
    }
    if (receiverUserIds.isNotEmpty) {
      await notifyServerRecipients(
        receiverUserIds: receiverUserIds,
        location: entity.fullLocation,
      );
    }
    if (entity.isActive) {
      await registrar.register(entity);
    } else {
      await registrar.unregister(savedId);
    }
    return _geofenceJson(entity);
  }

  Future<void> _unregister(Object? params) async {
    final id = _id(params);
    await registrar.unregister(id);
    await recipients.deleteByGeofenceId(id);
    await geofences.delete(id);
  }

  Future<Map<String, Object?>> _setActive(Object? params) async {
    final map = _map(params);
    final id = (map['id'] as num).toInt();
    final active = map['active'] as bool;
    await geofences.updateActiveStatus(id, active);
    final entity = (await geofences.findAll()).firstWhere(
      (item) => item.id == id,
    );
    if (active) {
      await registrar.register(entity);
    } else {
      await registrar.unregister(id);
    }
    return _geofenceJson(entity);
  }

  Future<Map<String, Object?>> _updateAddress(Object? params) async {
    final map = _map(params);
    final id = (map['id'] as num).toInt();
    final address = _string(map, 'address');
    await geofences.updateAddress(id, address);
    final entity = (await geofences.findAll()).firstWhere(
      (item) => item.id == id,
    );
    return _geofenceJson(entity);
  }

  Future<Map<String, Object?>> _sync() async {
    final active = (await geofences.findAll())
        .where((item) => item.isActive)
        .toList();
    await registrar.syncAll(active);
    final ids = (await registrar.getRegisteredIds())
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
    return {
      'registeredIds': ids.toList()..sort(),
      'skippedIds': active
          .map((item) => item.id!)
          .where((id) => !ids.contains(id))
          .toList(),
    };
  }

  Future<Map<String, Object?>> _nativeState(Object? params) async {
    final id = _id(params);
    final registered = (await registrar.getRegisteredIds()).contains(
      id.toString(),
    );
    return {'id': id, 'registered': registered};
  }

  Future<Map<String, Object?>> _queryGeofences(Object? params) async {
    final page = _page(params);
    final items = await geofences.findAll();
    return _slice(items, page, (item) => _geofenceJson(item));
  }

  Future<Map<String, Object?>> _queryRecords(Object? params) async {
    final page = _page(params);
    final items = await records.findAllOrderByCreatedAtDesc();
    return _slice(
      items,
      page,
      (item) => {
        'id': item.id!,
        'geofenceId': item.geofenceId,
        'geofenceName': item.geofenceName,
        'eventType': item.deliveryEventType,
        'status': item.status.name,
        'occurredAt': item.createdAt.toUtc().toIso8601String(),
        'message': item.message,
      },
    );
  }

  Future<Map<String, Object?>> _queryNotifications(Object? params) async {
    final page = _page(params);
    final items = await notifications.findAllOrderByCreatedAtDesc();
    return _slice(
      items,
      page,
      (item) => {
        'id': item.id!,
        'title': item.title,
        'body': item.body,
        if (item.path.isNotEmpty) 'path': item.path,
        if (item.senderAlias.isNotEmpty) 'senderAlias': item.senderAlias,
        'createdAt': item.createdAt.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> _deleteRecord(Object? params) => records.delete(_id(params));

  Future<List<Map<String, Object?>>> _deviceContacts() async {
    return loadDeviceContacts();
  }

  Future<Map<String, Object?>> _currentPosition() async {
    final position = await location.getCurrentUserLocation();
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracyMeters': position.accuracy,
      'capturedAt': position.timestamp.toUtc().toIso8601String(),
    };
  }

  Future<Map<String, Object?>> _locationServiceStatus() async => {
    'status': await geo.Geolocator.isLocationServiceEnabled()
        ? 'enabled'
        : 'disabled',
  };

  Future<Map<String, Object?>> _geofenceJson(GeofenceEntity entity) async {
    final serverRecipients = await recipients.findByGeofenceId(entity.id!);
    final contactIds = jsonDecode(entity.contactIds);
    return {
      'id': entity.id!,
      'name': entity.name,
      'address': entity.address,
      'latitude': entity.lat,
      'longitude': entity.lng,
      'radiusMeters': entity.radius.round(),
      'eventType': entity.eventType,
      'repeatType': entity.repeatType,
      if (entity.customDaysBitmask != null)
        'customDaysBitmask': entity.customDaysBitmask,
      'message': entity.message,
      'active': entity.isActive,
      'awaitingDeparture': entity.awaitingDeparture,
      'deviceContactIds': contactIds is List
          ? contactIds.map((value) => value.toString()).toList()
          : <String>[],
      'serverRecipients': serverRecipients
          .map(
            (item) => {
              'friendRelationshipId': item.friendRelationshipId,
              'friendUserId': item.friendUserId,
              'friendEmail': item.friendEmail,
              'friendAlias': item.friendAlias,
            },
          )
          .toList(),
    };
  }

  static Future<Map<String, Object?>> _slice<T>(
    List<T> items,
    ({int offset, int limit}) page,
    FutureOr<Map<String, Object?>> Function(T) encode,
  ) async {
    final start = page.offset.clamp(0, items.length);
    final end = (start + page.limit).clamp(start, items.length);
    final encoded = <Map<String, Object?>>[];
    for (final item in items.sublist(start, end)) {
      encoded.add(await encode(item));
    }
    return {
      'items': encoded,
      if (end < items.length) 'nextCursor': end.toString(),
    };
  }

  static ({int offset, int limit}) _page(Object? params) {
    final map = _map(params);
    final offset = int.tryParse(map['cursor'] as String? ?? '') ?? 0;
    final limit = ((map['limit'] as num?)?.toInt() ?? 20).clamp(1, 100);
    return (offset: offset, limit: limit);
  }

  static int _id(Object? params) => (_map(params)['id'] as num).toInt();
  static double _number(Map<String, Object?> map, String key) =>
      (map[key] as num).toDouble();
  static String _string(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Expected non-empty string "$key".');
    }
    return value;
  }

  static Map<String, Object?> _map(Object? value) {
    if (value is! Map) throw const FormatException('Expected object params.');
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
}
