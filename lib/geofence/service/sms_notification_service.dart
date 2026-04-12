import 'dart:developer';

import 'package:iamhere/geofence/service/sms_service.dart';
import 'package:iamhere/shared/base/result/result.dart';
import 'package:injectable/injectable.dart';

/// SMS notification sending service
@injectable
class SmsNotificationService {
  final SmsService _smsService;

  SmsNotificationService(this._smsService);

  /// Send SMS to multiple recipients
  /// Returns Result<void> indicating success or failure
  Future<Result<void>> sendSmsToRecipients({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    try {
      if (phoneNumbers.isEmpty) {
        log('No phone numbers to send SMS to');
        return Failure('No recipients specified');
      }

      final result = await _smsService.sendSms(
        phoneNumbers: phoneNumbers,
        message: message,
      );

      if (result is Success) {
        log('SMS sent successfully to ${phoneNumbers.length} recipients');
        return Success(null);
      } else {
        log('SMS sending failed: ${result}');
        return Failure('Failed to send SMS');
      }
    } catch (e) {
      log('Error sending SMS: $e');
      return Failure('Error sending SMS: $e');
    }
  }
}
