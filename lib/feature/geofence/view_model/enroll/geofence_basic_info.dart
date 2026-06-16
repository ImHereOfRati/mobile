import 'package:iamhere/feature/geofence/model/event_type.dart';

class GeofenceBasicInfo {
  final String name;
  final String address;
  final String message;
  final EventType eventType;
  final bool nameEdited;

  const GeofenceBasicInfo({
    this.name = '',
    this.address = '',
    // 비워두면 저장 시 이벤트 타입별 기본 메시지가 적용된다.
    this.message = '',
    this.eventType = EventType.arrival,
    this.nameEdited = false,
  });

  GeofenceBasicInfo copyWith({
    String? name,
    String? address,
    String? message,
    EventType? eventType,
    bool? nameEdited,
  }) {
    return GeofenceBasicInfo(
      name: name ?? this.name,
      address: address ?? this.address,
      message: message ?? this.message,
      eventType: eventType ?? this.eventType,
      nameEdited: nameEdited ?? this.nameEdited,
    );
  }
}
