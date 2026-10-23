import 'package:iamhere/common/base/result/result.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_snapshot.dart';
import 'package:iamhere/feature/geofence/model/delivery_event.dart';
import 'package:iamhere/feature/geofence/model/location_label_formatter.dart';
import 'package:iamhere/feature/geofence/service/fcm_arrival_service.dart';
import 'package:iamhere/feature/geofence/service/sms_notification_service.dart';
import 'package:iamhere/feature/geofence/service/notification_delivery_state.dart';

class DeliveryDispatchResult {
  final bool anyChannelSucceeded;
  final bool hasQueuedChannel;

  const DeliveryDispatchResult({
    required this.anyChannelSucceeded,
    required this.hasQueuedChannel,
  });
}

class DeliveryDispatcher {
  final SmsNotificationService _smsNotificationService;
  final FcmArrivalService _fcmArrivalService;

  const DeliveryDispatcher(
    this._smsNotificationService,
    this._fcmArrivalService,
  );

  Future<DeliveryDispatchResult> send(
    GeofenceDeliverySnapshot snapshot, {
    required String body,
  }) async {
    var anySuccess = false;
    var hasQueuedChannel = false;
    final event = DeliveryEvent.fromStoredName(snapshot.deliveryEventType);

    if (snapshot.smsPhoneNumbers.isNotEmpty) {
      // FCM 본문에는 길이 제한이 없으므로 SMS 로 나가는 값만 잘라낸다.
      final smsBody = clampSmsBody(body);
      if (smsBody.length != body.length) {
        AppLogger.warning(
          'BG_QUEUE: SMS body truncated to $smsBodyMaxLength characters',
        );
      }
      final smsResult = await _smsNotificationService.sendSmsToRecipients(
        phoneNumbers: snapshot.smsPhoneNumbers,
        body: smsBody,
        location: snapshot.geofence.fullLocation,
        type: event.notificationType,
      );
      if (smsResult case Success(data: final state)) {
        anySuccess = true;
        hasQueuedChannel |= state == NotificationDeliveryState.queued;
      }
    }

    if (snapshot.serverUserIds.isNotEmpty) {
      final fcmResult = await _fcmArrivalService.sendGeofenceNotifications(
        receiverUserIds: snapshot.serverUserIds,
        body: body,
        location: snapshot.geofence.fullLocation,
        type: event.notificationType,
      );
      if (fcmResult is Success) anySuccess = true;
    }

    return DeliveryDispatchResult(
      anyChannelSucceeded: anySuccess,
      hasQueuedChannel: hasQueuedChannel,
    );
  }
}
