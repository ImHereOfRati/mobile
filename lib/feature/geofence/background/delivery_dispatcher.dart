import 'package:iamhere/common/base/result/result.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_snapshot.dart';
import 'package:iamhere/feature/geofence/model/delivery_event.dart';
import 'package:iamhere/feature/geofence/service/fcm_arrival_service.dart';
import 'package:iamhere/feature/geofence/service/sms_notification_service.dart';

class DeliveryDispatcher {
  final SmsNotificationService _smsNotificationService;
  final FcmArrivalService _fcmArrivalService;

  const DeliveryDispatcher(
    this._smsNotificationService,
    this._fcmArrivalService,
  );

  Future<bool> send(
    GeofenceDeliverySnapshot snapshot, {
    required String body,
  }) async {
    var anySuccess = false;
    final event = DeliveryEvent.fromStoredName(snapshot.deliveryEventType);

    if (snapshot.smsPhoneNumbers.isNotEmpty) {
      final smsResult = await _smsNotificationService.sendSmsToRecipients(
        phoneNumbers: snapshot.smsPhoneNumbers,
        body: body,
        location: snapshot.geofence.fullLocation,
        type: event.notificationType,
      );
      if (smsResult is Success) anySuccess = true;
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

    return anySuccess;
  }
}
