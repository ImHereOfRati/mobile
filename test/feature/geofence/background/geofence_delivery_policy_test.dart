import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_policy.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_snapshot.dart';
import 'package:iamhere/feature/geofence/model/delivery_event.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';

void main() {
  GeofenceDeliverySnapshot snapshot({
    List<String> smsPhoneNumbers = const [],
    List<String> serverUserIds = const [],
    int? geofenceId = 42,
    String geofenceEventType = 'arrival',
    String deliveryEventType = 'arrival',
  }) {
    return GeofenceDeliverySnapshot(
      geofence: GeofenceEntity(
        id: geofenceId,
        name: 'home',
        address: 'Seoul',
        lat: 37.0,
        lng: 127.0,
        radius: 100.0,
        message: '',
        contactIds: '[]',
        eventType: geofenceEventType,
      ),
      recipientNames: const [],
      smsPhoneNumbers: smsPhoneNumbers,
      serverUserIds: serverUserIds,
      deliveryEventType: deliveryEventType,
    );
  }

  group('DeliverySuccessPolicy', () {
    const policy = DeliverySuccessPolicy();

    test('수신자가 없으면 채널 성공 없이도 완료로 본다', () {
      expect(
        policy.shouldComplete(snapshot: snapshot(), anyChannelSucceeded: false),
        isTrue,
      );
    });

    test('수신자가 있고 모든 채널이 실패하면 완료로 보지 않는다', () {
      expect(
        policy.shouldComplete(
          snapshot: snapshot(smsPhoneNumbers: ['01012345678']),
          anyChannelSucceeded: false,
        ),
        isFalse,
      );
    });

    test('수신자가 있더라도 한 채널이 성공하면 완료로 본다', () {
      expect(
        policy.shouldComplete(
          snapshot: snapshot(
            serverUserIds: ['550e8400-e29b-41d4-a716-446655440000'],
          ),
          anyChannelSucceeded: true,
        ),
        isTrue,
      );
    });
  });

  group('DeliveryRetryPolicy', () {
    const policy = DeliveryRetryPolicy(maxRetryCount: 4);

    test('retryCount 가 max 이하이면 terminal 이 아니다', () {
      expect(policy.isTerminalFailure(4), isFalse);
    });

    test('retryCount 가 max 를 초과하면 terminal 이다', () {
      expect(policy.isTerminalFailure(5), isTrue);
    });
  });

  group('DedupePolicy', () {
    const policy = DedupePolicy(bucketDuration: Duration(seconds: 5));

    test('같은 5초 bucket 안에서는 같은 key 를 만든다', () {
      final first = policy.buildKey(
        geofenceId: 42,
        event: DeliveryEvent.arrival,
        nowUtc: DateTime.fromMillisecondsSinceEpoch(4999, isUtc: true),
      );
      final second = policy.buildKey(
        geofenceId: 42,
        event: DeliveryEvent.arrival,
        nowUtc: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

      expect(first, second);
    });

    test('5초 bucket 경계가 바뀌면 다른 key 를 만든다', () {
      final beforeBoundary = policy.buildKey(
        geofenceId: 42,
        event: DeliveryEvent.arrival,
        nowUtc: DateTime.fromMillisecondsSinceEpoch(4999, isUtc: true),
      );
      final afterBoundary = policy.buildKey(
        geofenceId: 42,
        event: DeliveryEvent.arrival,
        nowUtc: DateTime.fromMillisecondsSinceEpoch(5000, isUtc: true),
      );

      expect(beforeBoundary, isNot(afterBoundary));
    });
  });

  group('GeofenceLifecyclePolicy', () {
    const policy = GeofenceLifecyclePolicy();

    test('both + arrival 성공은 awaitingDeparture=true 로 전이한다', () {
      expect(
        policy.afterSuccessfulDelivery(
          snapshot(geofenceEventType: 'both', deliveryEventType: 'arrival'),
        ),
        GeofenceLifecycleAction.markAwaitingDeparture,
      );
    });

    test('단일 이벤트 성공은 geofence 를 비활성화한다', () {
      expect(
        policy.afterSuccessfulDelivery(snapshot(geofenceEventType: 'arrival')),
        GeofenceLifecycleAction.deactivate,
      );
    });

    test('both + arrival terminal 실패는 awaitingDeparture=false 로 복원한다', () {
      expect(
        policy.afterTerminalFailure(
          snapshot(geofenceEventType: 'both', deliveryEventType: 'arrival'),
        ),
        GeofenceLifecycleAction.clearAwaitingDeparture,
      );
    });

    test('단일 이벤트 terminal 실패는 active 상태를 복원한다', () {
      expect(
        policy.afterTerminalFailure(snapshot(geofenceEventType: 'departure')),
        GeofenceLifecycleAction.restoreActive,
      );
    });

    test('id 없는 snapshot 은 lifecycle 변경을 하지 않는다', () {
      expect(
        policy.afterSuccessfulDelivery(snapshot(geofenceId: null)),
        GeofenceLifecycleAction.none,
      );
      expect(
        policy.afterTerminalFailure(snapshot(geofenceId: null)),
        GeofenceLifecycleAction.none,
      );
    });
  });
}
