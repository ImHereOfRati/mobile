import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_repository.dart';
import 'package:iamhere/feature/geofence/repository/geofence_server_recipient_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_server_recipient_repository.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:iamhere/feature/record/repository/geofence_record_repository.dart';
import 'package:iamhere/feature/record/repository/notification_repository.dart';
import 'package:iamhere/feature/user_permission/service/concrete/locate_permission_service.dart';
import 'package:iamhere/shell/bridge/bridge_handler_registry.dart';
import 'package:iamhere/shell/bridge/geofence_device_bridge_handlers.dart';

void main() {
  test('owns every geofence and device bridge method', () {
    final handlers = _handlers().build();

    expect(handlers.keys.toSet(), geofenceAndDeviceBridgeMethodNames);
  });

  test(
    'maps persisted geofences and recipients to the bridge contract',
    () async {
      final handlers = _handlers().build();

      expect(await handlers['queryGeofences']!({'limit': 20}), {
        'items': [
          {
            'id': 7,
            'name': '집',
            'address': '서울',
            'latitude': 37.5,
            'longitude': 127.0,
            'radiusMeters': 250,
            'eventType': 'arrival',
            'repeatType': 'none',
            'message': '도착',
            'active': true,
            'awaitingDeparture': false,
            'deviceContactIds': ['1'],
            'serverRecipients': [
              {
                'friendRelationshipId': 'friend-1',
                'friendEmail': 'friend@example.com',
                'friendAlias': '친구',
              },
            ],
            'createdAt': '2026-01-01T00:00:00.000Z',
            'updatedAt': '2026-01-02T00:00:00.000Z',
          },
        ],
      });
    },
  );
}

GeofenceDeviceBridgeHandlers _handlers() {
  return GeofenceDeviceBridgeHandlers(
    geofences: _Geofences(),
    recipients: _Recipients(),
    records: _Records(),
    notifications: _Notifications(),
    loadDeviceContacts: () async => const [],
    notifyServerRecipients:
        ({required receiverEmails, required location}) async {},
    registrar: _Registrar(),
    location: LocatePermissionService(),
  );
}

class _Geofences implements GeofenceRepository {
  @override
  Future<List<GeofenceEntity>> findAll() async => [
    GeofenceEntity(
      id: 7,
      name: '집',
      address: '서울',
      lat: 37.5,
      lng: 127,
      radius: 250,
      message: '도착',
      contactIds: '["1"]',
      isActive: true,
      createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      updatedAt: DateTime.parse('2026-01-02T00:00:00Z'),
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Recipients implements GeofenceServerRecipientRepository {
  @override
  Future<List<GeofenceServerRecipientEntity>> findByGeofenceId(int id) async =>
      [
        GeofenceServerRecipientEntity(
          geofenceId: id,
          friendRelationshipId: 'friend-1',
          friendEmail: 'friend@example.com',
          friendAlias: '친구',
        ),
      ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Records implements GeofenceRecordRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Notifications implements NotificationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Registrar implements NativeGeofenceRegistrarInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
