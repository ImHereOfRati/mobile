import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:iamhere/core/dio/properties/api_config.dart';
import 'package:iamhere/feature/friend/service/fcm_notification_service.dart';
import 'package:iamhere/feature/geofence/model/message_send_request.dart';
import 'package:iamhere/feature/geofence/model/multiple_message_send_request.dart';
import 'package:iamhere/feature/setting/service/user_me_service_interface.dart';
import 'package:iamhere/shared/base/result/result.dart';
import 'package:injectable/injectable.dart';

/// SMS sending service with proper dependency injection and error handling
@lazySingleton
class SmsService {
  final Dio _dio;
  final FcmNotificationService _fcmNotificationService;
  final UserMeServiceInterface _userMeService;

  SmsService(this._dio, this._fcmNotificationService, this._userMeService);

  /// Send SMS to one or more recipients
  /// Returns Result<void> indicating success or failure
  Future<Result<void>> sendSms({
    required List<String> phoneNumbers,
    required String location,
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
          location: location,
        );
      } else {
        return await _sendMultiSms(
          phoneNumbers: cleanPhoneNumbers,
          location: location,
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
    required String location,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.smsArrivalPath,
        data: MessageSendRequest(
          location: location,
          receiverNumber: phoneNumber,
        ).toJson(),
      );

      final isSuccess =
          (response.statusCode == 200 || response.statusCode == 201);

      if (!isSuccess) {
        return Failure('SMS send failed with status ${response.statusCode}');
      }

      await _notifyDeliveryResultToMe(location);

      return Success(null);
    } catch (e) {
      log('Error sending single SMS: $e');
      return Failure('Error sending SMS: $e');
    }
  }

  /// Send SMS to multiple recipients
  Future<Result<void>> _sendMultiSms({
    required List<String> phoneNumbers,
    required String location,
  }) async {
    try {
      final requests = phoneNumbers
          .map(
            (phone) =>
                MessageSendRequest(location: location, receiverNumber: phone),
          )
          .toList();

      final response = await _dio.post(
        ApiConfig.smsMultipleArrivalPath,
        data: MultipleMessageSendRequest(requests: requests).toJson(),
      );

      final isSuccess =
          (response.statusCode == 200 || response.statusCode == 201);

      if (!isSuccess) {
        return Failure('SMS send failed with status ${response.statusCode}');
      }

      await _notifyDeliveryResultToMe(location);

      return Success(null);
    } catch (e) {
      log('Error sending multi SMS: $e');
      return Failure('Error sending SMS: $e');
    }
  }

  /// SMS 발송 성공 후 본인에게 FCM으로 발송 결과 통보
  Future<void> _notifyDeliveryResultToMe(String location) async {
    try {
      final myInfo = await _userMeService.fetchMyInfo();
      if (myInfo == null) {
        log('Warning: Could not fetch user info for delivery result notification');
        return;
      }

      final result = await _fcmNotificationService.notifyDeliveryResult(
        receiverEmail: myInfo.userEmail,
        type: 'ARRIVAL',
        body: '$location 도착 알림이 성공적으로 전송되었습니다.',
      );

      if (result is Failure) {
        log('Warning: SMS sent but delivery result notification failed');
      }
    } catch (e) {
      log('Warning: SMS sent but delivery result notification error: $e');
    }
  }
}
