import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity_mapper.dart';

void main() {
  const mapper = GeofenceEntityMapper();

  test('toDatabaseMap preserves the existing geofence row contract', () {
    final entity = GeofenceEntity(
      id: 7,
      name: '집',
      address: '서울시 강남구',
      lat: 37.1,
      lng: 127.2,
      radius: 250,
      message: '도착',
      contactIds: '[1,2]',
      isActive: true,
      awaitingDeparture: true,
      eventType: 'both',
      repeatType: 'custom',
      customDaysBitmask: 42,
    );

    expect(mapper.toDatabaseMap(entity), {
      'id': 7,
      'name': '집',
      'address': '서울시 강남구',
      'lat': 37.1,
      'lng': 127.2,
      'radius': 250,
      'message': '도착',
      'contact_ids': '[1,2]',
      'is_active': 1,
      'awaiting_departure': 1,
      'event_type': 'both',
      'repeat_type': 'custom',
      'custom_days_bitmask': 42,
    });
  });

  test('fromDatabaseMap restores defaults for legacy nullable columns', () {
    final entity = mapper.fromDatabaseMap({
      'id': 3,
      'name': '회사',
      'lat': 37.5,
      'lng': 127.0,
      'radius': 500.0,
      'message': '출발',
    });

    expect(entity.id, 3);
    expect(entity.name, '회사');
    expect(entity.address, '');
    expect(entity.contactIds, '[]');
    expect(entity.isActive, false);
    expect(entity.awaitingDeparture, false);
    expect(entity.serverRecipientCount, 0);
    expect(entity.eventType, 'arrival');
    expect(entity.repeatType, 'none');
    expect(entity.customDaysBitmask, isNull);
  });

  test('legacy GeofenceEntity toMap/fromMap shims use the mapper contract', () {
    final entity = GeofenceEntity(
      id: 1,
      name: '학교',
      lat: 1.0,
      lng: 2.0,
      radius: 100.0,
      message: '메시지',
      contactIds: '[]',
      isActive: true,
    );

    final row = entity.toMap();
    final restored = GeofenceEntity.fromMap(row);

    expect(row, mapper.toDatabaseMap(entity));
    expect(restored.name, entity.name);
    expect(restored.isActive, true);
  });
}
