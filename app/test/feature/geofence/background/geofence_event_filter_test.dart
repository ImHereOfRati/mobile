import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/geofence/background/geofence_event_filter.dart';
import 'package:iamhere/feature/geofence/model/delivery_event.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';

GeofenceEntity _geofence({bool awaitingDeparture = false}) => GeofenceEntity(
      id: 1,
      name: '집',
      lat: 37.0,
      lng: 127.0,
      radius: 100.0,
      message: '',
      contactIds: '[]',
      awaitingDeparture: awaitingDeparture,
    );

void main() {
  group('GeofenceEventFilter.shouldHandle — arrival 전용', () {
    test('arrival 이벤트 → true', () {
      expect(
        GeofenceEventFilter.shouldHandle(
          _geofence(),
          EventType.arrival,
          DeliveryEvent.arrival,
        ),
        isTrue,
      );
    });

    test('departure 이벤트 → false', () {
      expect(
        GeofenceEventFilter.shouldHandle(
          _geofence(),
          EventType.arrival,
          DeliveryEvent.departure,
        ),
        isFalse,
      );
    });
  });

  group('GeofenceEventFilter.shouldHandle — departure 전용', () {
    test('departure 이벤트 → true', () {
      expect(
        GeofenceEventFilter.shouldHandle(
          _geofence(),
          EventType.departure,
          DeliveryEvent.departure,
        ),
        isTrue,
      );
    });

    test('arrival 이벤트 → false', () {
      expect(
        GeofenceEventFilter.shouldHandle(
          _geofence(),
          EventType.departure,
          DeliveryEvent.arrival,
        ),
        isFalse,
      );
    });
  });

  group('GeofenceEventFilter.shouldHandle — both', () {
    test('awaitingDeparture=false + arrival → true (첫 도착 허용)', () {
      expect(
        GeofenceEventFilter.shouldHandle(
          _geofence(awaitingDeparture: false),
          EventType.both,
          DeliveryEvent.arrival,
        ),
        isTrue,
      );
    });

    test('awaitingDeparture=true + arrival → false (중복 도착 차단)', () {
      expect(
        GeofenceEventFilter.shouldHandle(
          _geofence(awaitingDeparture: true),
          EventType.both,
          DeliveryEvent.arrival,
        ),
        isFalse,
      );
    });

    test('awaitingDeparture=true + departure → true (출발 허용)', () {
      expect(
        GeofenceEventFilter.shouldHandle(
          _geofence(awaitingDeparture: true),
          EventType.both,
          DeliveryEvent.departure,
        ),
        isTrue,
      );
    });

    test('awaitingDeparture=false + departure → false (도착 전 출발 차단)', () {
      expect(
        GeofenceEventFilter.shouldHandle(
          _geofence(awaitingDeparture: false),
          EventType.both,
          DeliveryEvent.departure,
        ),
        isFalse,
      );
    });
  });
}
