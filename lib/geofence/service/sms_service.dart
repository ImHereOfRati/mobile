import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:iamhere/geofence/model/message_send_request.dart';
import 'package:iamhere/geofence/model/multiple_message_send_request.dart';
import 'package:iamhere/geofence/service/notification_service.dart';
import 'package:iamhere/shared/base/result/result.dart';
import 'package:injectable/injectable.dart';

/// SMS sending service with proper dependency injection and error handling
@lazySingleton
class SmsService {
  final Dio _dio;
  final NotificationService _notificationService;

  static const _sendSmsToSingleApiPath = '/api/v1/message/send';
  static const _sendSmsToMultiApiPath = '/api/v1/message/multipleSend';

  SmsService(this._dio, this._notificationService);

  /// Send SMS to one or more recipients
  /// Returns Result<void> indicating success or failure
  Future<Result<void>> sendSms({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    try {
      if (phoneNumbers.isEmpty) {
        return Failure('No phone numbers provided');
      }

      final cleanPhoneNumbers = _extractOnlyNumberFromPhoneNumber(phoneNumbers);

      if (cleanPhoneNumbers.isEmpty) {
        return Failure('No valid phone numbers after cleaning');
      }

      if (cleanPhoneNumbers.length == 1) {
        return await _sendSingleSms(
          phoneNumber: cleanPhoneNumbers[0],
          message: message,
        );
      } else {
        return await _sendMultiSms(
          phoneNumbers: cleanPhoneNumbers,
          message: message,
        );
      }
    } catch (e) {
      log('Error sending SMS: $e');
      return Failure('Error sending SMS: $e');
    }
  }

  /// Extract and clean phone numbers (digits only)
  List<String> _extractOnlyNumberFromPhoneNumber(List<String> phoneNumbers) {
    return phoneNumbers
        .map((phone) => phone.replaceAll(RegExp(r'[^\d]'), ''))
        .where((phone) => phone.isNotEmpty)
        .toList();
  }

  /// Send SMS to a single recipient
  Future<Result<void>> _sendSingleSms({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final response = await _dio.post(
        _sendSmsToSingleApiPath,
        data: MessageSendRequest(
          message: message,
          receiverNumber: phoneNumber,
        ).toJson(),
      );

      final isSuccess =
          (response.statusCode == 200 || response.statusCode == 201);

      if (!isSuccess) {
        return Failure('SMS send failed with status ${response.statusCode}');
      }

      // Send FCM notification on success
      final notificationResult = await _notificationService
          .sendNotificationToMe();
      if (notificationResult is Failure) {
        log('Warning: SMS sent but FCM notification failed');
      }

      return Success(null);
    } catch (e) {
      log('Error sending single SMS: $e');
      return Failure('Error sending SMS: $e');
    }
  }

  /// Send SMS to multiple recipients
  Future<Result<void>> _sendMultiSms({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    try {
      final requests = phoneNumbers
          .map(
            (phone) =>
                MessageSendRequest(message: message, receiverNumber: phone),
          )
          .toList();

      final response = await _dio.post(
        _sendSmsToMultiApiPath,
        data: MultipleMessageSendRequest(requests: requests).toJson(),
      );

      final isSuccess =
          (response.statusCode == 200 || response.statusCode == 201);

      if (!isSuccess) {
        return Failure('SMS send failed with status ${response.statusCode}');
      }

      // Send FCM notification on success
      final notificationResult = await _notificationService
          .sendNotificationToMe();
      if (notificationResult is Failure) {
        log('Warning: SMS sent but FCM notification failed');
      }

      return Success(null);
    } catch (e) {
      log('Error sending multi SMS: $e');
      return Failure('Error sending SMS: $e');
    }
  }
}
