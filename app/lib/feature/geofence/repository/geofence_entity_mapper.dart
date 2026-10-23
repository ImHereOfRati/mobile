import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';

/// Maps geofence entities to and from the persisted row shape.
///
/// This keeps database column names and legacy serialized snapshot keys out of
/// orchestration code while preserving the current storage contract.
class GeofenceEntityMapper {
  const GeofenceEntityMapper();

  Map<String, dynamic> toDatabaseMap(GeofenceEntity entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'address': entity.address,
      'lat': entity.lat,
      'lng': entity.lng,
      'radius': entity.radius,
      'message': entity.message,
      'contact_ids': entity.contactIds,
      'is_active': entity.isActive ? 1 : 0,
      'awaiting_departure': entity.awaitingDeparture ? 1 : 0,
      'event_type': entity.eventType,
      'repeat_type': entity.repeatType,
      'custom_days_bitmask': entity.customDaysBitmask,
    };
  }

  GeofenceEntity fromDatabaseMap(Map<String, dynamic> map) {
    return GeofenceEntity(
      id: map['id'] as int?,
      name: map['name'] as String,
      address: map['address'] as String? ?? '',
      lat: map['lat'] as double,
      lng: map['lng'] as double,
      radius: map['radius'] as double,
      message: map['message'] as String,
      contactIds: map['contact_ids'] as String? ?? '[]',
      isActive: (map['is_active'] as int? ?? 0) == 1,
      awaitingDeparture: (map['awaiting_departure'] as int? ?? 0) == 1,
      serverRecipientCount: map['server_recipient_count'] as int? ?? 0,
      eventType: map['event_type'] as String? ?? 'arrival',
      repeatType: map['repeat_type'] as String? ?? 'none',
      customDaysBitmask: map['custom_days_bitmask'] as int?,
    );
  }
}
