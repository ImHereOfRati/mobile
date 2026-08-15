import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/friend/repository/contact_repository.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_repository.dart';
import 'package:iamhere/feature/geofence/repository/geofence_server_recipient_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_server_recipient_repository.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:iamhere/feature/record/repository/geofence_record_repository.dart';
import 'package:iamhere/feature/record/repository/notification_repository.dart';
import 'package:iamhere/feature/user_permission/service/concrete/locate_permission_service.dart';
import 'package:iamhere/shell/bridge/geofence_device_bridge_handlers.dart';

void main() {
  test('persists a migrated geofence address through the bridge', () async {
    final geofences = _Geofences();
    final handler = GeofenceDeviceBridgeHandlers(
      geofences: geofences,
      contacts: _Contacts(),
      recipients: _Recipients(),
      records: _Records(),
      notifications: _Notifications(),
      loadDeviceContacts: () async => const [],
      loadDeviceContactPicker: () async => null,
      notifyServerRecipients:
          ({required receiverUserIds, required location}) async {},
      registrar: _Registrar(),
      location: LocatePermissionService(),
    ).build()['updateGeofenceAddress']!;

    final updated = await handler({'id': 7, 'address': '서울특별시 중구'});

    expect(geofences.address, '서울특별시 중구');
    expect((updated as Map<String, Object?>)['address'], '서울특별시 중구');
  });
}

class _Geofences implements GeofenceRepository {
  String address = '';

  @override
  Future<List<GeofenceEntity>> findAll() async => [
    GeofenceEntity(
      id: 7,
      name: '회사',
      address: address,
      lat: 37.5665,
      lng: 126.978,
      radius: 500,
      message: '도착했습니다.',
      contactIds: '[]',
    ),
  ];

  @override
  Future<void> updateAddress(int id, String address) async {
    this.address = address;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Contacts implements ContactRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Recipients implements GeofenceServerRecipientRepository {
  @override
  Future<List<GeofenceServerRecipientEntity>> findByGeofenceId(int id) async =>
      const [];

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
