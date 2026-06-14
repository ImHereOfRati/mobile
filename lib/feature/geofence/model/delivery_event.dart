import 'package:iamhere/feature/geofence/model/event_type.dart';
import 'package:native_geofence/native_geofence.dart';

enum DeliveryEvent {
  arrival('ARRIVAL', '안녕하세요! {location}에 도착했습니다.'),
  departure('DEPARTURE', '안녕하세요! {location}에서 출발했습니다.');

  final String notificationType;
  final String defaultMessageTemplate;

  const DeliveryEvent(this.notificationType, this.defaultMessageTemplate);

  static DeliveryEvent? fromNativeEvent(GeofenceEvent event) {
    switch (event) {
      case GeofenceEvent.enter:
      case GeofenceEvent.dwell:
        return DeliveryEvent.arrival;
      case GeofenceEvent.exit:
        return DeliveryEvent.departure;
    }
  }

  static DeliveryEvent? fromEventType(EventType eventType) {
    switch (eventType) {
      case EventType.arrival:
        return DeliveryEvent.arrival;
      case EventType.departure:
        return DeliveryEvent.departure;
      case EventType.both:
        return null;
    }
  }

  static DeliveryEvent fromStoredName(String? name) {
    switch (name) {
      case 'departure':
      case 'exit':
        return DeliveryEvent.departure;
      case 'arrival':
      case 'enter':
      case 'dwell':
      default:
        return DeliveryEvent.arrival;
    }
  }
}
