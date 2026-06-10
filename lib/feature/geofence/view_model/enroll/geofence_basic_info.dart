import 'package:iamhere/feature/geofence/model/event_type.dart';

class GeofenceBasicInfo {
  final String name;
  final String address;
  final String message;
  final EventType eventType;

  const GeofenceBasicInfo({
    this.name = '',
    this.address = '',
    this.message = '안녕하세요! {location}에 도착했습니다.',
    this.eventType = EventType.arrival,
  });

  GeofenceBasicInfo copyWith({
    String? name,
    String? address,
    String? message,
    EventType? eventType,
  }) {
    return GeofenceBasicInfo(
      name: name ?? this.name,
      address: address ?? this.address,
      message: message ?? this.message,
      eventType: eventType ?? this.eventType,
    );
  }
}
