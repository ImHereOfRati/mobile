import 'package:iamhere/core/result/result.dart';
import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/geofence/delivery/geofence_delivery_snapshot.dart';
import 'package:iamhere/feature/geofence/model/delivery_event.dart';
import 'package:iamhere/feature/geofence/model/location_label_formatter.dart';
import 'package:iamhere/feature/geofence/model/service/fcm_arrival_service.dart';
import 'package:iamhere/feature/geofence/model/service/sms_notification_service.dart';
import 'package:iamhere/feature/geofence/model/service/sms_daily_quota_service.dart';
import 'package:iamhere/feature/geofence/model/notification_delivery_state.dart';

class DeliveryDispatchResult {
  final bool anyChannelSucceeded;
  final bool hasQueuedChannel;
  final bool smsSkippedForQuota;

  const DeliveryDispatchResult({
    required this.anyChannelSucceeded,
    required this.hasQueuedChannel,
    this.smsSkippedForQuota = false,
  });
}

class DeliveryDispatcher {
  final SmsNotificationService _smsNotificationService;
  final FcmArrivalService _fcmArrivalService;
  final SmsDailyQuotaService _smsQuotaService;

  DeliveryDispatcher(
    this._smsNotificationService,
    this._fcmArrivalService, {
    SmsDailyQuotaService? smsQuotaService,
  }) : _smsQuotaService = smsQuotaService ?? SmsDailyQuotaService();

  Future<DeliveryDispatchResult> send(
    GeofenceDeliverySnapshot snapshot, {
    required String body,
  }) async {
    var anySuccess = false;
    var hasQueuedChannel = false;
    var smsSkippedForQuota = false;
    final event = DeliveryEvent.fromStoredName(snapshot.deliveryEventType);

    if (snapshot.smsPhoneNumbers.isNotEmpty) {
      final quota = await _smsQuotaService.load();
      if (quota.allows(snapshot.smsPhoneNumbers.length)) {
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
          try {
            await _smsQuotaService.recordAccepted(
              snapshot.smsPhoneNumbers.length,
            );
          } catch (error, stack) {
            AppLogger.error(
              'BG_QUEUE: SMS quota usage could not be saved',
              error,
              stack,
            );
          }
          anySuccess = true;
          hasQueuedChannel |= state == NotificationDeliveryState.queued;
        }
      } else {
        smsSkippedForQuota = true;
        AppLogger.warning(
          'BG_QUEUE: SMS skipped because the daily device-contact limit was reached',
        );
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
      smsSkippedForQuota: smsSkippedForQuota,
    );
  }
}
