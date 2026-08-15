import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/common/base/result/result.dart';
import 'package:iamhere/feature/geofence/background/delivery_dispatcher.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_snapshot.dart';
import 'package:iamhere/feature/geofence/model/location_label_formatter.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/service/fcm_arrival_service.dart';
import 'package:iamhere/feature/geofence/service/sms_notification_service.dart';

void main() {
  GeofenceDeliverySnapshot snapshot({
    List<String> smsPhoneNumbers = const [],
    List<String> serverUserIds = const [],
  }) {
    return GeofenceDeliverySnapshot(
      geofence: GeofenceEntity(
        id: 1,
        name: 'home',
        address: 'Seoul',
        lat: 37.0,
        lng: 127.0,
        radius: 100,
        message: '',
        contactIds: '[]',
      ),
      recipientNames: const [],
      smsPhoneNumbers: smsPhoneNumbers,
      serverUserIds: serverUserIds,
      deliveryEventType: 'arrival',
    );
  }

  test('한 채널이라도 성공하면 true 를 반환한다', () async {
    final dispatcher = DeliveryDispatcher(
      _FakeSmsNotificationService(Failure('sms failed')),
      _FakeFcmArrivalService(Success(null)),
    );

    final result = await dispatcher.send(
      snapshot(
        smsPhoneNumbers: const ['01012345678'],
        serverUserIds: const ['550e8400-e29b-41d4-a716-446655440000'],
      ),
      body: 'body',
    );

    expect(result, isTrue);
  });

  test('모든 채널이 실패하면 false 를 반환한다', () async {
    final dispatcher = DeliveryDispatcher(
      _FakeSmsNotificationService(Failure('sms failed')),
      _FakeFcmArrivalService(Failure('fcm failed')),
    );

    final result = await dispatcher.send(
      snapshot(
        smsPhoneNumbers: const ['01012345678'],
        serverUserIds: const ['550e8400-e29b-41d4-a716-446655440000'],
      ),
      body: 'body',
    );

    expect(result, isFalse);
  });

  test('서버 제한을 넘는 본문은 SMS 로만 잘라 보내고 FCM 은 그대로 보낸다', () async {
    final sms = _FakeSmsNotificationService(Success(null));
    final fcm = _FakeFcmArrivalService(Success(null));
    final dispatcher = DeliveryDispatcher(sms, fcm);
    final body = '[ImHere]\n${'가' * 40}';

    await dispatcher.send(
      snapshot(
        smsPhoneNumbers: const ['01012345678'],
        serverUserIds: const ['550e8400-e29b-41d4-a716-446655440000'],
      ),
      body: body,
    );

    expect(sms.lastBody, '[ImHere]\n${'가' * 36}');
    expect(sms.lastBody!.length, smsBodyMaxLength);
    expect(fcm.lastBody, body);
  });
}

class _FakeSmsNotificationService implements SmsNotificationService {
  final Result<void> result;
  String? lastBody;

  _FakeSmsNotificationService(this.result);

  @override
  Future<Result<void>> sendSmsToRecipients({
    required List<String> phoneNumbers,
    required String body,
    required String location,
    required String type,
  }) async {
    lastBody = body;
    return result;
  }
}

class _FakeFcmArrivalService implements FcmArrivalService {
  final Result<void> result;
  String? lastBody;

  _FakeFcmArrivalService(this.result);

  @override
  Future<Result<void>> sendGeofenceNotifications({
    required List<String> receiverUserIds,
    required String body,
    required String location,
    required String type,
  }) async {
    lastBody = body;
    return result;
  }
}
