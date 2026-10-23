import 'package:iamhere/feature/geofence/model/delivery_event.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';

class GeofenceEventFilter {
  const GeofenceEventFilter._();

  static bool shouldHandle(
    GeofenceEntity geofence,
    EventType eventType,
    DeliveryEvent deliveryEvent,
  ) {
    switch (eventType) {
      case EventType.arrival:
        return deliveryEvent == DeliveryEvent.arrival;
      case EventType.departure:
        return deliveryEvent == DeliveryEvent.departure;
      case EventType.both:
        if (deliveryEvent == DeliveryEvent.arrival) {
          return !geofence.awaitingDeparture;
        }
        return geofence.awaitingDeparture;
    }
  }
}
